/**
 *  Implementation of Http Client procedures and functions.
 *
 *  The original code was created by Simonov Denis
 *  for the open source project "IBSurgeon Http Client UDR".
 *
 *  Copyright (c) 2023 Simonov Denis <sim-mail@list.ru>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________.
**/


#include "UDR.h"
#include <string>
#include <memory>
#include <vector>
#include <map>
#include <algorithm>
#include <sstream>
#include <cstdarg>
#include <curl/curl.h>

constexpr unsigned int BUFFER_LARGE = 16384;
constexpr unsigned int MAX_SEGMENT_SIZE = 65535;

// trim from start (in place)
static inline void ltrim(std::string& s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
}

// trim from end (in place)
static inline void rtrim(std::string& s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

// trim from both ends (in place)
static inline void trim(std::string& s) {
    rtrim(s);
    ltrim(s);
}

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
class AutoCurlUrlCleanupClear
{
public:
    static void clear(T* ptr)
    {
        if (ptr)
            curl_url_cleanup(ptr);
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

template <typename T> class AutoCurlUrlCleanup : public Firebird::AutoImpl<T, AutoCurlUrlCleanupClear<T> >
{
public:
    AutoCurlUrlCleanup(T* ptr = nullptr)
        : Firebird::AutoImpl<T, AutoCurlUrlCleanupClear<T> >(ptr)
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
    Options,
    Trace,
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
    if (httpMethod == "OPTIONS") {
        return HttpMethod::Options;
    }
    if (httpMethod == "TRACE") {
        return HttpMethod::Trace;
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
#if CURL_AT_LEAST_VERSION(7,33,0)
    case CURL_HTTP_VERSION_2_0:
        preStatusText = "HTTP/2";
        break;
#endif		
#if CURL_AT_LEAST_VERSION(7,66,0)
    case CURL_HTTP_VERSION_3:
        preStatusText = "HTTP/3";
        break;
#endif			
    }
    preStatusText += " " + std::to_string(statusCode) + " ";

    auto start = headers.find(preStatusText);
    if (start == std::string::npos) return "";
    
    auto end = headers.find("\r\n", start + preStatusText.size());
    if (end == std::string::npos) {
        end = headers.find("\n", start + preStatusText.size());
    }
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

std::map<long, std::string> parseCurlOptions(const std::string& options)
{
    std::map<long, std::string> optionValues;
    size_t offset = 0;
    while (offset < options.size()) {
        size_t lPos = options.find("\r\n", offset);
        if (lPos == std::string::npos) {
            lPos = options.find("\n", offset);
        }
        std::string line = options.substr(offset, lPos - offset);
        trim(line);
        if (!line.empty()) {
            size_t eqPos = line.find("=");
            if (eqPos == std::string::npos)
                throw std::runtime_error("Invalid options string");
            std::string key = line.substr(0, eqPos);
            trim(key);
            std::transform(key.begin(), key.end(), key.begin(), ::toupper);
            std::string value = line.substr(eqPos + 1);
            trim(value);

            if (key == "CURLOPT_DNS_SERVERS") {
                optionValues[CURLOPT_DNS_SERVERS] = value;
            }
            else if (key == "CURLOPT_PORT") {
                optionValues[CURLOPT_PORT] = value;
            }
            else if (key == "CURLOPT_PROXY") {
                optionValues[CURLOPT_PROXY] = value;
            }
            else if (key == "CURLOPT_PRE_PROXY") {
                optionValues[CURLOPT_PRE_PROXY] = value;
            }
            else if (key == "CURLOPT_PROXYPORT") {
                optionValues[CURLOPT_PROXYPORT] = value;
            }
            else if (key == "CURLOPT_PROXYUSERPWD") {
                optionValues[CURLOPT_PROXYUSERPWD] = value;
            }
            else if (key == "CURLOPT_PROXYUSERNAME") {
                optionValues[CURLOPT_PROXYUSERNAME] = value;
            }
            else if (key == "CURLOPT_PROXYPASSWORD") {
                optionValues[CURLOPT_PROXYPASSWORD] = value;
            }
            else if (key == "CURLOPT_PROXY_TLSAUTH_USERNAME") {
                optionValues[CURLOPT_PROXY_TLSAUTH_USERNAME] = value;
            }
            else if (key == "CURLOPT_PROXY_TLSAUTH_PASSWORD") {
                optionValues[CURLOPT_PROXY_TLSAUTH_PASSWORD] = value;
            }
            else if (key == "CURLOPT_PROXY_TLSAUTH_TYPE") {
                optionValues[CURLOPT_PROXY_TLSAUTH_TYPE] = value;
            }
            else if (key == "CURLOPT_TLSAUTH_USERNAME") {
                optionValues[CURLOPT_TLSAUTH_USERNAME] = value;
            }
            else if (key == "CURLOPT_TLSAUTH_PASSWORD") {
                optionValues[CURLOPT_TLSAUTH_PASSWORD] = value;
            }
            else if (key == "CURLOPT_TLSAUTH_TYPE") {
                optionValues[CURLOPT_TLSAUTH_TYPE] = value;
            }
            else if (key == "CURLOPT_SSL_VERIFYHOST") {
                optionValues[CURLOPT_SSL_VERIFYHOST] = value;
            }
            else if (key == "CURLOPT_SSL_VERIFYPEER") {
                optionValues[CURLOPT_SSL_VERIFYPEER] = value;
            }
            else if (key == "CURLOPT_SSLCERT") {
                optionValues[CURLOPT_SSLCERT] = value;
            }
            else if (key == "CURLOPT_SSLKEY") {
                optionValues[CURLOPT_SSLKEY] = value;
            }
            else if (key == "CURLOPT_SSLCERTTYPE") {
                optionValues[CURLOPT_SSLCERTTYPE] = value;
            }
            else if (key == "CURLOPT_CAINFO") {
                optionValues[CURLOPT_CAINFO] = value;
            }
            else if (key == "CURLOPT_TIMEOUT") {
                optionValues[CURLOPT_TIMEOUT] = value;
            }
            else if (key == "CURLOPT_TIMEOUT_MS") {
                optionValues[CURLOPT_TIMEOUT_MS] = value;
            }
            else if (key == "CURLOPT_TCP_KEEPALIVE") {
                optionValues[CURLOPT_TCP_KEEPALIVE] = value;
            }
            else if (key == "CURLOPT_TCP_KEEPIDLE") {
                optionValues[CURLOPT_TCP_KEEPIDLE] = value;
            }
#if CURL_AT_LEAST_VERSION(7,25,0)
            else if (key == "CURLOPT_TCP_KEEPINTVL") {
                optionValues[CURLOPT_TCP_KEEPINTVL] = value;
            }
#endif
            else if (key == "CURLOPT_CONNECTTIMEOUT") {
                optionValues[CURLOPT_CONNECTTIMEOUT] = value;
            }
            else if (key == "CURLOPT_USERAGENT") {
                optionValues[CURLOPT_USERAGENT] = value;
            }
            else if (key == "CURLOPT_FOLLOWLOCATION") {
                optionValues[CURLOPT_FOLLOWLOCATION] = value;
            }
            else if (key == "CURLOPT_MAXREDIRS") {
                optionValues[CURLOPT_MAXREDIRS] = value;
            }
            else {
                throw std::runtime_error(std::string("Unsupported CURL option ") + key);
            }

        }
        if (lPos == std::string::npos)
            offset = options.size();
        else
            offset = lPos + 1;
    }
    return std::move(optionValues);
}

void setCurlOptions(CURL* curl, const std::map<long, std::string>& options) 
{
    for (const auto& [option, value] : options) {
        switch (option) {
        case CURLOPT_PORT:
            curl_easy_setopt(curl, CURLOPT_PORT, std::stol(value));
            break;

        case CURLOPT_DNS_SERVERS:
            curl_easy_setopt(curl, CURLOPT_DNS_SERVERS, value.c_str());
            break;

        case CURLOPT_PROXY:
            curl_easy_setopt(curl, CURLOPT_PROXY, value.c_str());
            break;

        case CURLOPT_PRE_PROXY:
            curl_easy_setopt(curl, CURLOPT_PRE_PROXY, value.c_str());
            break;

        case CURLOPT_PROXYPORT:
            curl_easy_setopt(curl, CURLOPT_PROXYPORT, std::stol(value));
            break;

        case CURLOPT_PROXYUSERPWD:
            curl_easy_setopt(curl, CURLOPT_PROXYUSERPWD, value.c_str());
            break;

        case CURLOPT_PROXYUSERNAME:
            curl_easy_setopt(curl, CURLOPT_PROXYUSERNAME, value.c_str());
            break;

        case CURLOPT_PROXYPASSWORD:
            curl_easy_setopt(curl, CURLOPT_PROXYPASSWORD, value.c_str());
            break;

        case CURLOPT_PROXY_TLSAUTH_USERNAME:
            curl_easy_setopt(curl, CURLOPT_PROXY_TLSAUTH_USERNAME, value.c_str());
            break;

        case CURLOPT_PROXY_TLSAUTH_PASSWORD:
            curl_easy_setopt(curl, CURLOPT_PROXY_TLSAUTH_PASSWORD, value.c_str());
            break;

        case CURLOPT_PROXY_TLSAUTH_TYPE:
            curl_easy_setopt(curl, CURLOPT_PROXY_TLSAUTH_TYPE, value.c_str());
            break;

        case CURLOPT_TLSAUTH_USERNAME:
            curl_easy_setopt(curl, CURLOPT_TLSAUTH_USERNAME, value.c_str());
            break;

        case CURLOPT_TLSAUTH_PASSWORD:
            curl_easy_setopt(curl, CURLOPT_TLSAUTH_PASSWORD, value.c_str());
            break;

        case CURLOPT_TLSAUTH_TYPE:
            curl_easy_setopt(curl, CURLOPT_TLSAUTH_TYPE, value.c_str());
            break;

        case CURLOPT_SSL_VERIFYHOST:
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, std::stol(value));
            break;

        case CURLOPT_SSL_VERIFYPEER:
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, std::stol(value));
            break;

        case CURLOPT_SSLCERT:
            curl_easy_setopt(curl, CURLOPT_SSLCERT, value.c_str());
            break;

        case CURLOPT_SSLKEY:
            curl_easy_setopt(curl, CURLOPT_SSLKEY, value.c_str());
            break;

        case CURLOPT_SSLCERTTYPE:
            curl_easy_setopt(curl, CURLOPT_SSLCERTTYPE, value.c_str());
            break;

        case CURLOPT_CAINFO:
            curl_easy_setopt(curl, CURLOPT_CAINFO, value.c_str());
            break;

        case CURLOPT_TIMEOUT:
            curl_easy_setopt(curl, CURLOPT_TIMEOUT, std::stol(value));
            break;

        case CURLOPT_TIMEOUT_MS:
            curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, std::stol(value));
            break;

        case CURLOPT_TCP_KEEPALIVE:
            curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, std::stol(value));
            break;

        case CURLOPT_TCP_KEEPIDLE:
            curl_easy_setopt(curl, CURLOPT_TCP_KEEPIDLE, std::stol(value));
            break;

#if CURL_AT_LEAST_VERSION(7,25,0)
        case CURLOPT_TCP_KEEPINTVL:
            curl_easy_setopt(curl, CURLOPT_TCP_KEEPINTVL, std::stol(value));
            break;
#endif

        case CURLOPT_CONNECTTIMEOUT:
            curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, std::stol(value));
            break;

        case CURLOPT_USERAGENT:
            curl_easy_setopt(curl, CURLOPT_USERAGENT, value.c_str());
            break;

        case CURLOPT_FOLLOWLOCATION:
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, std::stol(value));
            break;

        case CURLOPT_MAXREDIRS:
            curl_easy_setopt(curl, CURLOPT_MAXREDIRS, std::stol(value));
            break;
        }
    }
    // Some default values differ from those accepted in libCurl.
    if (options.find(CURLOPT_FOLLOWLOCATION) == options.cend()) {
        // go to the "Location:" specified in the HTTP header
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    }
    if (options.find(CURLOPT_MAXREDIRS) == options.cend()) {
        curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 50L);
    }
}



/*
  PROCEDURE SEND_REQUEST (
    METHOD               VARCHAR(7) NOT NULL,
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB SUB_TYPE BINARY,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB SUB_TYPE BINARY,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  EXTERNAL NAME 'http_client_udr!sendHttpRequest'
  ENGINE UDR;
*/

FB_UDR_BEGIN_PROCEDURE(sendHttpRequest)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(28, 0), method)
        (FB_INTL_VARCHAR(32765, 0), url)
        (FB_BLOB, body)
        (FB_INTL_VARCHAR(1024, 0), contentType)
        (FB_INTL_VARCHAR(32765, 0), headers)
        (FB_INTL_VARCHAR(32765, 0), options)
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
            throwException(status, "HTTP_METHOD can not be NULL.");
        }
        const std::string sHttpMethod(in->method.str, in->method.length);

        auto httpMethod = getHttpMethod(sHttpMethod);
        if (httpMethod == HttpMethod::None) {
            throwException(status, "Unsupported HTTP method %s.", sHttpMethod.c_str());
        }

        if (in->urlNull) {
            throwException(status, "URL can not be NULL.");
        }
        const std::string url(in->url.str, in->url.length);

        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Can't initialize CURL.");
        }

        // buffer for storing text errors
        char curlErrorBuffer[CURL_ERROR_SIZE];
        memset(curlErrorBuffer, 0, CURL_ERROR_SIZE);
        curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, curlErrorBuffer);

        // set url
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());

        // set Http method
        switch (httpMethod) {
        case HttpMethod::Get: 
            break;
        case HttpMethod::Head:
            curl_easy_setopt(curl, CURLOPT_NOBODY, 1L); // HEAD
            break;
        case HttpMethod::Post:
            curl_easy_setopt(curl, CURLOPT_POST, 1L); // POST
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
        case HttpMethod::Options:
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "OPTIONS");
            break;
        case HttpMethod::Trace:
            curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "TRACE");
            break;
        default:
            throwException(status, "HTTP method %s in not supported.", sHttpMethod.c_str());
        }
        
        if (!in->optionsNull) {
            std::string curlOptions(in->options.str, in->options.length);
            try {
                setCurlOptions(curl, parseCurlOptions(curlOptions));
            }
            catch (const std::runtime_error &e) {
                throwException(status, e.what());
            }
            catch (const std::invalid_argument& e) {
                throwException(status, e.what());
            }
            catch (const std::out_of_range& e) {
                throwException(status, e.what());
            }
        }

        // collecting headers
        struct curl_slist* headers = nullptr;
        // content-type
        if (!in->contentTypeNull) {
            std::string contentType(in->contentType.str, in->contentType.length);
            contentType = std::string("Content-Type: ") + contentType;
            headers = curl_slist_append(headers, contentType.c_str());
        }
        // other headers
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
        // auto-delete headers
        AutoCurlHeadersFree<curl_slist> autoHeaders(headers);
        // set headers
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
                    break;
                default:
                    bodyBlob->close(status);
                    bodyBlob.release();
                    eof = true;
                    break;
                }
            }
            // set beginning of stream
            requestBody.seekg(0, std::ios::beg);
            
            curl_easy_setopt(curl, CURLOPT_READDATA, &requestBody);
            curl_easy_setopt(curl, CURLOPT_READFUNCTION, read_callback);
        }

        // function called by cURL to record received headers 
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, &m_responseHeaders);
        curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, write_data);
        // function called by cURL to record the received data 
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &m_response);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);


        // execute a request
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

#if CURL_AT_LEAST_VERSION(7,50,0)
            curl_easy_getinfo(curl, CURLINFO_HTTP_VERSION, &m_http_version);
#else
	        m_http_version = CURL_HTTP_VERSION_1_1;
#endif
            m_needFetch = true;
        }
        else {
            std::string curlErrorMessage(curlErrorBuffer);
            if (curlErrorMessage.empty())
                curlErrorMessage.assign(curl_easy_strerror(curlResult));

            throwException(status, curlErrorMessage.c_str());
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

            const unsigned char bpb[] = {
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
            const unsigned char bpb[] = {
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
    STR VARCHAR(8191),
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!urlEncode'
  ENGINE UDR;
*/

FB_UDR_BEGIN_FUNCTION(urlEncode)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(32765, 0), str)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_INTL_VARCHAR(32765, 0), str)
    );

    FB_UDR_EXECUTE_FUNCTION
    {
        if (in->strNull) {
            out->strNull = true;
            return;
        }
        out->strNull = false;
        

        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Can't initialize CURL.");
        }

        char* output = curl_easy_escape(curl, in->str.str, in->str.length);
        if (output) {
            const std::string str(output);
            curl_free(output);

            out->str.length = std::min<short>(str.size(), 4096);
            str.copy(out->str.str, out->str.length);
        }

    }

FB_UDR_END_FUNCTION

/*
  FUNCTION URL_DECODE (
    STR VARCHAR(8191),
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!urlDecode'
  ENGINE UDR;
*/

FB_UDR_BEGIN_FUNCTION(urlDecode)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(32765, 0), str)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_INTL_VARCHAR(32765, 0), str)
    );

    FB_UDR_EXECUTE_FUNCTION
    {
        if (in->strNull) {
            out->strNull = true;
            return;
        }
        out->strNull = false;


        AutoCurlCleanup<CURL> curl(curl_easy_init());

        if (!curl) {
            throwException(status, "Can't initialize CURL.");
        }

        int outLength = 0;
        char* output = curl_easy_unescape(curl, in->str.str, in->str.length, &outLength);
        if (output) {
            const std::string str(output, outLength);
            curl_free(output);

            out->str.length = std::min<short>(str.size(), 32765);
            str.copy(out->str.str, out->str.length);
        }

    }

FB_UDR_END_FUNCTION

/*
  PROCEDURE PARSE_URL (
    URL                  VARCHAR(8191)
  )
  RETURNS (
    URL_HOST             VARCHAR(256),
    URL_SCHEME           VARCHAR(64),
    URL_USER             VARCHAR(64),
    URL_PASSWORD         VARCHAR(64),
    URL_PORT             INTEGER,
    URL_PATH             VARCHAR(8191),
    URL_QUERY            VARCHAR(8191),
    URL_FRAGMENT         VARCHAR(8191)
  )
  EXTERNAL NAME 'http_client_udr!parseUrl'
  ENGINE UDR;
*/

FB_UDR_BEGIN_PROCEDURE(parseUrl)

    FB_UDR_MESSAGE(InMessage,
        (FB_INTL_VARCHAR(32765, 0), url)
    );

    FB_UDR_MESSAGE(OutMessage,
        (FB_INTL_VARCHAR(1024, 0), host)
        (FB_INTL_VARCHAR(256, 0), scheme)
        (FB_INTL_VARCHAR(256, 0), user)
        (FB_INTL_VARCHAR(256, 0), password)
        (FB_INTEGER, port)
        (FB_INTL_VARCHAR(32765, 0), path)
        (FB_INTL_VARCHAR(32765, 0), query)
        (FB_INTL_VARCHAR(32765, 0), fragment)
    );

    FB_UDR_EXECUTE_PROCEDURE
    {
        m_needFetch = !in->urlNull;
        if (!in->urlNull) {
            const std::string sUrl(in->url.str, in->url.length);

            AutoCurlUrlCleanup<CURLU> url(curl_url());
            auto rc = curl_url_set(url, CURLUPART_URL, sUrl.c_str(), 0);
            if (rc != CURLE_OK) {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // host
            char* host = nullptr;
            rc = curl_url_get(url, CURLUPART_HOST, &host, 0);
            if (!rc) {
                out->hostNull = false;
                if (host) {
                    const std::string sHost(host);
                    curl_free(host);

                    if (sHost.size() > 1024) {
                        throwException(status, "The HOST part of the URL is too long.");
                    }
                    out->host.length = std::min<short>(sHost.size(), 1024);
                    sHost.copy(out->host.str, out->host.length);
                }
                else {
                    out->hostNull = true;
                }
            }
            else if (rc == CURLUE_NO_HOST) {
                out->hostNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // scheme
            char* scheme = nullptr;
            rc = curl_url_get(url, CURLUPART_SCHEME, &scheme, 0);
            if (!rc) {
                out->schemeNull = false;
                if (host) {
                    const std::string sScheme(scheme);
                    curl_free(scheme);

                    if (sScheme.size() > 256) {
                        throwException(status, "The SCHEME part of the URL is too long.");
                    }
                    out->scheme.length = std::min<short>(sScheme.size(), 256);
                    sScheme.copy(out->scheme.str, out->scheme.length);
                }
                else {
                    out->schemeNull = true;
                }
            }
            else if (rc == CURLUE_NO_SCHEME) {
                out->schemeNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // user
            char* user = nullptr;
            rc = curl_url_get(url, CURLUPART_USER, &user, 0);
            if (!rc) {
                out->userNull = false;
                if (user) {
                    const std::string sUser(user);
                    curl_free(user);

                    if (sUser.size() > 256) {
                        throwException(status, "The USER part of the URL is too long.");
                    }
                    out->user.length = std::min<short>(sUser.size(), 256);
                    sUser.copy(out->user.str, out->user.length);
                }
                else {
                    out->userNull = true;
                }
            }
            else if (rc == CURLUE_NO_USER) {
                out->userNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // password
            char* password = nullptr;
            rc = curl_url_get(url, CURLUPART_PASSWORD, &password, 0);
            if (!rc) {
                out->passwordNull = false;
                if (password) {
                    const std::string sPassword(password);
                    curl_free(password);

                    if (sPassword.size() > 256) {
                        throwException(status, "The scheme PASSWORD of the URL is too long.");
                    }
                    out->password.length = std::min<short>(sPassword.size(), 256);
                    sPassword.copy(out->password.str, out->password.length);
                }
                else {
                    out->passwordNull = true;
                }
            }
            else if (rc == CURLUE_NO_PASSWORD) {
                out->passwordNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // port
            char* port = nullptr;
            rc = curl_url_get(url, CURLUPART_PORT, &port, 0);
            if (!rc) {
                out->portNull = false;
                if (port) {
                    const std::string sPort(port);
                    curl_free(port);

                    if (sPort.size() > 5) {
                        throwException(status, "The scheme PORT of the URL is too long.");
                    }
                    try {
                        out->port = std::stol(sPort);
                    }
                    catch (const std::invalid_argument& e) {
                        throwException(status, e.what());
                    }
                    catch (const std::out_of_range& e) {
                        throwException(status, e.what());
                    }
                }
                else {
                    out->portNull = true;
                }
            }
            else if (rc == CURLUE_NO_PORT) {
                out->portNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // path
            char* path = nullptr;
            rc = curl_url_get(url, CURLUPART_PATH, &path, 0);
            if (!rc) {
                out->pathNull = false;
                if (path) {
                    const std::string sPath(path);
                    curl_free(path);

                    if (sPath.size() > 32765) {
                        throwException(status, "The scheme PATH of the URL is too long.");
                    }
                    out->path.length = std::min<short>(sPath.size(), 32765);
                    sPath.copy(out->path.str, out->path.length);
                }
                else {
                    out->pathNull = true;
                }
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // query
            char* query = nullptr;
            rc = curl_url_get(url, CURLUPART_QUERY, &query, 0);
            if (!rc) {
                out->queryNull = false;
                if (query) {
                    const std::string sQuery(query);
                    curl_free(query);

                    if (sQuery.size() > 32765) {
                        throwException(status, "The scheme QUERY of the URL is too long.");
                    }
                    out->query.length = std::min<short>(sQuery.size(), 32765);
                    sQuery.copy(out->query.str, out->query.length);
                }
                else {
                    out->queryNull = true;
                }
            }
            else if (rc == CURLUE_NO_QUERY) {
                out->queryNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
            // fragment
            char* fragment = nullptr;
            rc = curl_url_get(url, CURLUPART_FRAGMENT, &fragment, 0);
            if (!rc) {
                out->fragmentNull = false;
                if (fragment) {
                    const std::string sFragment(fragment);
                    curl_free(fragment);

                    if (sFragment.size() > 32765) {
                        throwException(status, "The scheme FRAGMENT of the URL is too long.");
                    }
                    out->fragment.length = std::min<short>(sFragment.size(), 32765);
                    sFragment.copy(out->fragment.str, out->fragment.length);
                }
                else {
                    out->fragmentNull = true;
                }
            }
            else if (rc == CURLUE_NO_FRAGMENT) {
                out->fragmentNull = true;
            }
            else {
                std::string errorMessage(curl_url_strerror(rc));
                throwException(status, errorMessage.c_str());
            }
        }

    }

    bool m_needFetch = false;

    FB_UDR_FETCH_PROCEDURE
    {
        bool needFetch = m_needFetch;
        m_needFetch = false;
        return needFetch;
    }

FB_UDR_END_PROCEDURE



FB_UDR_IMPLEMENT_ENTRY_POINT
