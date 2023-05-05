﻿#include "UDR.h"
#include <curl/curl.h>
#include <string>
#include <memory>
#include <vector>
#include <sstream>

constexpr unsigned int BUFFER_LARGE = 16384;
constexpr unsigned int MAX_SEGMENT_SIZE = 65535;

template <typename T>
class AutoCurlCleanupClear
{
public:
    static void clear(T* ptr)
    {
        if (ptr)
            curl_easy_cleanup(ptr);
    }
};

template <typename T>
class AutoCurlHeadersFreeClear
{
public:
    static void clear(T* ptr)
    {
        if (ptr)
            curl_slist_free_all(ptr);
    }
};

template <typename T> class AutoCurlCleanup : public Firebird::AutoImpl<T, AutoCurlCleanupClear<T> >
{
public:
    AutoCurlCleanup(T* ptr = nullptr)
        : Firebird::AutoImpl<T, AutoCurlCleanupClear<T> >(ptr)
    {
    }
};

template <typename T> class AutoCurlHeadersFree : public Firebird::AutoImpl<T, AutoCurlHeadersFreeClear<T> >
{
public:
    AutoCurlHeadersFree(T* ptr = nullptr)
        : Firebird::AutoImpl<T, AutoCurlHeadersFreeClear<T> >(ptr)
    {
    }
};

enum class HttpMethod {
    Get,
    Head,
    Post,
    Put,
    Patch,
    Delete,
    None
};

HttpMethod getHttpMethod(const std::string& httpMethod)
{
    if (httpMethod == "GET") {
        return HttpMethod::Get;
    }
    if (httpMethod == "HEAD") {
        return HttpMethod::Head;
    }
    if (httpMethod == "POST") {
        return HttpMethod::Post;
    }
    if (httpMethod == "PUT") {
        return HttpMethod::Put;
    }
    if (httpMethod == "PATCH") {
        return HttpMethod::Patch;
    }
    if (httpMethod == "DELETE") {
        return HttpMethod::Delete;
    }
    return HttpMethod::None;
}

[[noreturn]]
void throwException(Firebird::ThrowStatusWrapper* const status, const char* message, ...)
{
    std::vector<char> buffer(BUFFER_LARGE);

    va_list ptr;
    va_start(ptr, message);
    vsnprintf(buffer.data(), BUFFER_LARGE, message, ptr);
    va_end(ptr);

    ISC_STATUS statusVector[] = {
        isc_arg_gds, isc_random,
        isc_arg_string, (ISC_STATUS)buffer.data(),
        isc_arg_end
    };
    throw Firebird::FbException(status, statusVector);
}

std::string extractResponseStatusText(long http_version, long statusCode, const std::string headers)
{
    // parse status text from header
    std::string preStatusText;
    switch (http_version) {
    case CURL_HTTP_VERSION_1_0:
        preStatusText = "HTTP/1.0";
        break;
    case CURL_HTTP_VERSION_1_1:
        preStatusText = "HTTP/1.1";
        break;
    case CURL_HTTP_VERSION_2_0:
        preStatusText = "HTTP/2";
        break;
    case CURL_HTTP_VERSION_3:
        preStatusText = "HTTP/3";
        break;
    }
    preStatusText += " " + std::to_string(statusCode) + " ";

    auto start = headers.find(preStatusText);
    if (start == std::string::npos) return "";
    
    auto end = headers.find("\r\n", start + preStatusText.size());
    if (end == std::string::npos) return "";
    
    auto offset = start + preStatusText.size();
    return headers.substr(offset, end - offset);
}

size_t read_callback(char* ptr, size_t size, size_t nmemb, void* userdata)
{
    std::istream* from = reinterpret_cast<std::istream*>(userdata);
    if (!from)
        return CURL_READFUNC_ABORT;

    if (from->eof()) return 0;

    const size_t capacity = size * nmemb;
    from->read(reinterpret_cast<char*>(ptr), capacity);

    return from->gcount();
}

size_t write_data(void* ptr, size_t size, size_t nmemb, void* stream) 
{
    std::string data((const char*)ptr, (size_t)size * nmemb);
    *((std::ostringstream*)stream) << data;
    return size * nmemb;
}

/*
  PROCEDURE SEND_REQUEST (
    METHOD               VARCHAR(6) NOT NULL,
    URL                  VARCHAR(1024) NOT NULL,
    REQUEST_BODY         BLOB SUB_TYPE TEXT,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB SUB_TYPE TEXT,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  EXTERNAL NAME 'http_client_udr!sendHttpRequest'
  ENGINE UDR;
*/

FB_UDR_BEGIN_PROCEDURE(sendHttpRequest)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(24, 0), method)
        (FB_INTL_VARCHAR(4096, 0), url)
        (FB_BLOB, body)
        (FB_INTL_VARCHAR(1024, 0), contentType)
        (FB_INTL_VARCHAR(32765, 0), headers)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_SMALLINT, statusCode)
        (FB_INTL_VARCHAR(1024, 0), statusText)
        (FB_INTL_VARCHAR(1024, 0), contentType)
        (FB_BLOB, body)
        (FB_BLOB, headers)
    );

    FB_UDR_EXECUTE_PROCEDURE
    {
        m_att.reset(context->getAttachment(status));
        m_tra.reset(context->getTransaction(status));

        if (in->methodNull) {
            throwException(status, "HTTP_METHOD can not be NULL");
        }
        const std::string sHttpMethod(in->method.str, in->method.length);

        auto httpMethod = getHttpMethod(sHttpMethod);
        if (httpMethod == HttpMethod::None) {
            throwException(status, "Unsupported http method %s", sHttpMethod.c_str());
        }

        if (in->urlNull) {
            throwException(status, "URL can not be NULL");
        }
        const std::string url(in->url.str, in->url.length);

        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Cannot CURL init");
        }

        // буфер для сохранения текстовых ошибок
        char curlErrorBuffer[CURL_ERROR_SIZE];

        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, curlErrorBuffer);
        // устанавливаем URL
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());

        // устанавливаем метод
        switch (httpMethod) {
        case HttpMethod::Head:
            curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
            break;
        case HttpMethod::Post:
            curl_easy_setopt(curl, CURLOPT_POST, 1L);
            break;
        case HttpMethod::Put:
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT");
            break;
        case HttpMethod::Patch:
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
            break;
        case HttpMethod::Delete:
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");
            break;
        }

        // собираем заголовки
        struct curl_slist* headers = nullptr;
        // сначала content-type
        if (!in->contentTypeNull) {
            std::string contentType(in->contentType.str, in->contentType.length);
            contentType = std::string("Content-Type: ") + contentType;
            headers = curl_slist_append(headers, contentType.c_str());
        }
        // теперь все остальные
        if (!in->headersNull) {
            std::string sHeaders(in->headers.str, in->headers.length);
            std::size_t prev = 0, pos;
            while ((pos = sHeaders.find_first_of("\r\n", prev)) != std::string::npos)
            {
                if (pos > prev) {
                    std::string header = sHeaders.substr(prev, pos - prev);
                    if (!header.empty()) {
                        headers = curl_slist_append(headers, header.c_str());
                    }
                }
                prev = pos + 1;
            }
        }
        // автоудаление заголовков
        AutoCurlHeadersFree autoHeaders(headers);
        // устанавливаем заголовки, если есть
        if (headers) {
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        }

        std::stringstream requestBody{};
        if (!in->bodyNull) {
            Firebird::AutoRelease<Firebird::IBlob> bodyBlob(m_att->openBlob(status, m_tra, &in->body, 0, nullptr));
            bool eof = false;
            std::vector<char> vBuffer(MAX_SEGMENT_SIZE);
            auto buffer = vBuffer.data();
            while (!eof) {
                unsigned int l = 0;
                switch (bodyBlob->getSegment(status, MAX_SEGMENT_SIZE, buffer, &l))
                {
                case Firebird::IStatus::RESULT_OK:
                case Firebird::IStatus::RESULT_SEGMENT:
                    requestBody.write(buffer, l);
                    continue;
                default:
                    bodyBlob->close(status);
                    bodyBlob.release();
                    eof = true;
                    break;
                }
            }
            // ставим на начало
            requestBody.seekg(0, std::ios::beg);
            
            curl_easy_setopt(curl, CURLOPT_READDATA, &requestBody);
            curl_easy_setopt(curl, CURLOPT_READFUNCTION, read_callback);
        }


        // переходить по "Location:" указанному в HTTP заголовке  
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
        curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 50L);
        // не проверять сертификат удаленного сервера
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
        // не проверять Host SSL сертификата
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);

        // функция, вызываемая cURL для записи полученных заголовков   
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, &m_responseHeaders);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, write_data);
        // функция, вызываемая cURL для записи полученных данных   
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &m_response);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);


        // выполнить запрос
        CURLcode curlResult = curl_easy_perform(curl);

        if (curlResult == CURLE_OK) {
            out->statusCodeNull = false;
            if (curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &out->statusCode) != CURLE_OK) {
                throwException(status, curlErrorBuffer);
            }

            char* contentType = nullptr;
            if (curl_easy_getinfo(curl, CURLINFO_CONTENT_TYPE, &contentType) == CURLE_OK) {
                if (contentType) {
                    out->contentTypeNull = false;
                    m_resonseContentType.assign(contentType);
                }
                else {
                    out->contentTypeNull = true;
                }
            }
            else {
                throwException(status, curlErrorBuffer);
            }

            curl_easy_getinfo(curl, CURLINFO_HTTP_VERSION, &m_http_version);

            m_needFetch = true;
        }
        else {
            throwException(status, curlErrorBuffer);
        }


    }

    Firebird::AutoRelease<Firebird::IAttachment> m_att{ nullptr };
    Firebird::AutoRelease<Firebird::ITransaction> m_tra{ nullptr };

    bool m_needFetch = false;
    std::ostringstream m_response{};
    std::ostringstream m_responseHeaders{};
    std::string m_resonseContentType{ "" };
    long m_http_version = 0;

    FB_UDR_FETCH_PROCEDURE
    {
        if (!m_needFetch) {
            return false;
        }
        m_needFetch = !m_needFetch;
        // response headers
        const std::string headers = m_responseHeaders.str();
        out->headersNull = headers.empty();
        if (!out->headersNull) {
            auto statusText = extractResponseStatusText(m_http_version, out->statusCode, headers);
            out->statusTextNull = statusText.empty();
            if (!out->statusTextNull) {
                out->statusText.length = std::min<short>(statusText.size(), 1024);
                statusText.copy(out->statusText.str, out->statusText.length);
            }

            const UCHAR bpb[] = {
                isc_bpb_version1,
                isc_bpb_type, 1, isc_bpb_type_stream,
                isc_bpb_storage, 1, isc_bpb_storage_temp
            };

            Firebird::AutoRelease<Firebird::IBlob> headersBlob(
                m_att->createBlob(status, m_tra, &out->headers, sizeof(bpb), bpb)
            );

            size_t str_len = headers.length();
            size_t offset = 0;
            std::vector<char> vBuffer(MAX_SEGMENT_SIZE + 1);
            {
                char* buffer = vBuffer.data();
                while (str_len > 0) {
                    const auto len = std::min<unsigned int>(str_len, MAX_SEGMENT_SIZE);
                    memset(buffer, 0, MAX_SEGMENT_SIZE + 1);
                    memcpy(buffer, headers.data() + offset, len);
                    headersBlob->putSegment(status, len, buffer);
                    offset += len;
                    str_len -= len;
                }
            }
            headersBlob->close(status);
            headersBlob.release();
        }

        // response body
        const std::string response = m_response.str();
        out->bodyNull = response.empty();
        if (!out->bodyNull) {
            const UCHAR bpb[] = {
                isc_bpb_version1,
                isc_bpb_type, 1, isc_bpb_type_stream,
                isc_bpb_storage, 1, isc_bpb_storage_temp
            };

            Firebird::AutoRelease<Firebird::IBlob> responseBodyBlob(
                m_att->createBlob(status, m_tra, &out->body, sizeof(bpb), bpb)
            );

            size_t str_len = response.length();
            size_t offset = 0;
            std::vector<char> vBuffer(MAX_SEGMENT_SIZE + 1);
            {
                char* buffer = vBuffer.data();
                while (str_len > 0) {
                    const auto len = std::min<unsigned int>(str_len, MAX_SEGMENT_SIZE);
                    memset(buffer, 0, MAX_SEGMENT_SIZE + 1);
                    memcpy(buffer, response.data() + offset, len);
                    responseBodyBlob->putSegment(status, len, buffer);
                    offset += len;
                    str_len -= len;
                }
            }
            responseBodyBlob->close(status);
            responseBodyBlob.release();
        }
        // contentType
        if (!out->contentTypeNull) {
            out->contentType.length = std::min<short>(m_resonseContentType.size(), 1024);
            m_resonseContentType.copy(out->contentType.str, out->contentType.length);
        }

        return true;
    }

FB_UDR_END_PROCEDURE


/*
  FUNCTION URL_ENCODE (
    URL VARCHAR(1024),
  )
  RETURNS VARCHAR(1024)
  EXTERNAL NAME 'http_client_udr!urlEncode'
  ENGINE UDR;
*/

FB_UDR_BEGIN_FUNCTION(urlEncode)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(4096, 0), url)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_INTL_VARCHAR(4096, 0), url)
    );

    FB_UDR_EXECUTE_FUNCTION
    {
        if (in->urlNull) {
            out->urlNull = true;
            return;
        }
        out->urlNull = false;
        

        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Cannot CURL init");
        }

        char* output = curl_easy_escape(curl, in->url.str, in->url.length);
        if (output) {
            const std::string url(output);
            curl_free(output);

            out->url.length = std::min<short>(url.size(), 4096);
            url.copy(out->url.str, out->url.length);
        }

    }

FB_UDR_END_FUNCTION

/*
  FUNCTION URL_DECODE (
    URL VARCHAR(1024),
  )
  RETURNS VARCHAR(1024)
  EXTERNAL NAME 'http_client_udr!urlDecode'
  ENGINE UDR;
*/

FB_UDR_BEGIN_FUNCTION(urlDecode)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(4096, 0), url)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_INTL_VARCHAR(4096, 0), url)
    );

    FB_UDR_EXECUTE_FUNCTION
    {
        if (in->urlNull) {
            out->urlNull = true;
            return;
        }
        out->urlNull = false;


        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Cannot CURL init");
        }

        int outLength = 0;
        char* output = curl_easy_unescape(curl, in->url.str, in->url.length, &outLength);
        if (output) {
            const std::string url(output, outLength);
            curl_free(output);

            out->url.length = std::min<short>(url.size(), 4096);
            url.copy(out->url.str, out->url.length);
        }

    }

FB_UDR_END_FUNCTION

FB_UDR_IMPLEMENT_ENTRY_POINT