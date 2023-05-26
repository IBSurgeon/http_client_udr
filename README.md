# IBSurgeon HTTP Client UDR

The IBSurgeon HTTP Client UDR library is designed to work with HTTP services (REST-API and others).
The HTTP Client UDR is based on [libcurl](https://curl.se/libcurl/).

## Installing the HTTP Client UDR

To install HTTP Client UDR you need:

1. Unpack zip archive with dynamic libraries to `plugins/udr` directory
2. Execute the `sql/http_client_install.sql` script to register procedures and functions in the database.

You can download builds for Windows OS using the links:

* [HttpClientUdr_Win_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_Win_x64.zip)
* [HttpClientUdr_Win_x86.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_Win_x86.zip)

You can download builds for Linux OS using the links:

* [HttpClientUdr_CentOS7_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_CentOS7_x64.zip)

All procedures and functions for working with the HTTP Client library are located in the PSQL package `HTTP_UTILS`.

## Build on Linux

Must be installed before build

On Ubuntu

```bash
sudo apt-get install libcurl4-openssl-dev
```

On CentOS

```bash
sudo yum install libcurl-devel
```

Now you can do the build itself.

```bash
git clone https://github.com/IBSurgeon/http_client_udr.git
cd http_client_udr
mkdir build; cd build
cmake ..
make
sudo make install
```

## Package `HTTP_UTILS`

### Procedure `HTTP_UTILS.HTTP_REQUEST`

The `HTTP_UTILS.HTTP_REQUEST` procedure is designed to send an HTTP request and receive an HTTP response.

```sql
  PROCEDURE HTTP_REQUEST (
    METHOD               D_HTTP_METHOD NOT NULL,
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `METHOD` - HTTP method. Required parameter. Possible values are 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'.
* `URL` - URL address. Required parameter.
* `REQUEST_BODY` - HTTP request body.
* `REQUEST_TYPE` - the content type of the request body. The value of this parameter is passed as the `Content-Type` header.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

The `HTTP_UTILS.HTTP_REQUEST` procedure is the main procedure by which communication with web services takes place.
Procedures `HTTP_UTILS.HTTP_GET`, `HTTP_UTILS.HTTP_HEAD`, `HTTP_UTILS.HTTP_POST`, `HTTP_UTILS.HTTP_PUT`, `HTTP_UTILS.HTTP_PATCH`,
`HTTP_UTILS.HTTP_DELETE`, `HTTP_UTILS.HTTP_OPTIONS`, `HTTP_UTILS.HTTP_TRACE` are derived from `HTTP_UTILS.HTTP_REQUEST`.
Inside, they call `HTTP_UTILS.HTTP_REQUEST` with the `METHOD` parameter filled in, and unnecessary input and output parameters are removed, which
simplifies access to a web resource by a specific HTTP method.

The first two parameters of the `HTTP_UTILS.HTTP_REQUEST` procedure are mandatory.

The `REQUEST_BODY` request body is not allowed for all HTTP methods. If it is, then it is desirable to also specify the `REQUEST_TYPE` parameter, which corresponds to the `Content-Type` header.

In the `HEADERS` parameter, you can pass additional headers as a string. Each heading must be separated by a line break.

In the `OPTIONS` parameter, you can pass additional options for the CURL library in the form `CURLOPT_*=<value>`. Each new parameter must be separated by a newline.

The response body is always returned in binary form, but you can convert it to text with the desired encoding using `CAST(RESPONSE_BODY AS BLOB SUB_TYPE TEXT ...)`.

Examples of using:

```sql
SELECT
  R.STATUS_CODE,
  R.STATUS_TEXT,
  R.RESPONSE_TYPE,
  R.RESPONSE_HEADERS,
  CAST(R.RESPONSE_BODY AS BLOB SUB_TYPE TEXT CHARACTER SET UTF8) AS RESPONSE_BODY
FROM HTTP_UTILS.HTTP_REQUEST (
  'GET',
  'https://www.cbr-xml-daily.ru/latest.js'
) R;


SELECT
  R.STATUS_CODE,
  R.STATUS_TEXT,
  R.RESPONSE_TYPE,
  R.RESPONSE_HEADERS,
  CAST(R.RESPONSE_BODY AS BLOB SUB_TYPE TEXT CHARACTER SET UTF8) AS RESPONSE_BODY
FROM HTTP_UTILS.HTTP_REQUEST (
  -- method
  'POST',
  -- URL
  'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/party',
  -- query body
  trim('
{
    "query": "810702819220",
    "type": "INDIVIDUAL"
}
  '),
  -- content-type
  'application/json',
  -- headers
  q'{
Authorization: Token b81a595753ff53056468a939c034c96b49177db3
  }'
) R;
```

An example of setting CURL parameters:

```sql
SELECT
  R.STATUS_CODE,
  R.STATUS_TEXT,
  R.RESPONSE_TYPE,
  R.RESPONSE_HEADERS,
  CAST(R.RESPONSE_BODY AS BLOB SUB_TYPE TEXT CHARACTER SET UTF8) AS RESPONSE_BODY
FROM HTTP_UTILS.HTTP_REQUEST (
  'GET',
  'https://yandex.ru',
  NULL, 
  NULL, 
  NULL, 
  q'{
CURLOPT_FOLLOWLOCATION=0
CURLOPT_USERAGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 OPR/98.0.0.0
  }'
) R;
```

#### Supported CURL Options

* [CURLOPT_DNS_SERVERS](https://curl.haxx.se/libcurl/c/CURLOPT_DNS_SERVERS.html)
* [CURLOPT_PORT](https://curl.haxx.se/libcurl/c/CURLOPT_PORT.html)
* [CURLOPT_PROXY](https://curl.haxx.se/libcurl/c/CURLOPT_PROXY.html)
* [CURLOPT_PRE_PROXY](https://curl.haxx.se/libcurl/c/CURLOPT_PRE_PROXY.html)
* [CURLOPT_PROXYPORT](https://curl.haxx.se/libcurl/c/CURLOPT_PROXYPORT.html)
* [CURLOPT_PROXYUSERPWD](https://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERPWD.html)
* [CURLOPT_PROXYUSERNAME](https://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERNAME.html)
* [CURLOPT_PROXYPASSWORD](https://curl.haxx.se/libcurl/c/CURLOPT_PROXYPASSWORD.html)
* [CURLOPT_PROXY_TLSAUTH_USERNAME](https://curl.haxx.se/libcurl/c/CURLOPT_PROXY_TLSAUTH_USERNAME.html)
* [CURLOPT_PROXY_TLSAUTH_PASSWORD](https://curl.haxx.se/libcurl/c/CURLOPT_PROXY_TLSAUTH_PASSWORD.html)
* [CURLOPT_PROXY_TLSAUTH_TYPE](https://curl.haxx.se/libcurl/c/CURLOPT_PROXY_TLSAUTH_TYPE.html)
* [CURLOPT_TLSAUTH_USERNAME](https://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_USERNAME.html)
* [CURLOPT_TLSAUTH_PASSWORD](https://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_PASSWORD.html)
* [CURLOPT_TLSAUTH_TYPE](https://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_TYPE.html)
* [CURLOPT_SSL_VERIFYHOST](https://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html)
* [CURLOPT_SSL_VERIFYPEER](https://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYPEER.html)
* [CURLOPT_SSLCERT](https://curl.haxx.se/libcurl/c/CURLOPT_SSLCERT.html)
* [CURLOPT_SSLKEY](https://curl.haxx.se/libcurl/c/CURLOPT_SSLKEY.html)
* [CURLOPT_SSLCERTTYPE](https://curl.haxx.se/libcurl/c/CURLOPT_SSLCERTTYPE.html)
* [CURLOPT_CAINFO](https://curl.haxx.se/libcurl/c/CURLOPT_CAINFO.html)
* [CURLOPT_TIMEOUT](https://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT.html)
* [CURLOPT_TIMEOUT_MS](https://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT_MS.html)
* [CURLOPT_TCP_KEEPALIVE](https://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPALIVE.html)
* [CURLOPT_TCP_KEEPIDLE](https://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPIDLE.html)
* [CURLOPT_TCP_KEEPINTVL](https://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPINTVL.html)
* [CURLOPT_CONNECTTIMEOUT](https://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html)
* [CURLOPT_USERAGENT](https://curl.haxx.se/libcurl/c/CURLOPT_USERAGENT.html)
* [CURLOPT_FOLLOWLOCATION](https://curl.haxx.se/libcurl/c/CURLOPT_FOLLOWLOCATION.html) (default value 1)
* [CURLOPT_MAXREDIRS](https://curl.haxx.se/libcurl/c/CURLOPT_MAXREDIRS.html) (default value 50)

The list of supported options depends on which version of `libcurl` the library was built against.

### Procedure `HTTP_UTILS.HTTP_GET`

The `HTTP_UTILS.HTTP_GET` procedure is designed to send an HTTP request using the GET method.

```sql
  PROCEDURE HTTP_GET (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

Usage example:

```sql
SELECT
  R.STATUS_CODE,
  R.STATUS_TEXT,
  R.RESPONSE_TYPE,
  R.RESPONSE_HEADERS,
  CAST(R.RESPONSE_BODY AS BLOB SUB_TYPE TEXT CHARACTER SET UTF8) AS RESPONSE_BODY
FROM HTTP_UTILS.HTTP_GET('https://www.cbr-xml-daily.ru/latest.js') R;
```

### Procedure `HTTP_UTILS.HTTP_HEAD`

The `HTTP_UTILS.HTTP_HEAD` procedure is designed to send an HTTP request using the HEAD method.

```sql
  PROCEDURE HTTP_HEAD (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_POST`

The `HTTP_UTILS.HTTP_POST` procedure is designed to send an HTTP request using the POST method.

```sql
  PROCEDURE HTTP_POST (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `REQUEST_BODY` - HTTP request body.
* `REQUEST_TYPE` - the content type of the request body. The value of this parameter is passed as the `Content-Type` header.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_PUT`

The `HTTP_UTILS.HTTP_PUT` procedure is designed to send an HTTP request using the PUT method.

```sql
  PROCEDURE HTTP_PUT (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `REQUEST_BODY` - HTTP request body.
* `REQUEST_TYPE` - the content type of the request body. The value of this parameter is passed as the `Content-Type` header.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_PATCH`

The `HTTP_UTILS.HTTP_PATCH` procedure is designed to send an HTTP request using the PATCH method.

```sql
  PROCEDURE HTTP_PATCH (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `REQUEST_BODY` - HTTP request body.
* `REQUEST_TYPE` - the content type of the request body. The value of this parameter is passed as the `Content-Type` header.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_DELETE`

The `HTTP_UTILS.HTTP_DELETE` procedure is designed to send an HTTP request using the DELETE method.

```sql
  PROCEDURE HTTP_DELETE (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `REQUEST_BODY` - HTTP request body.
* `REQUEST_TYPE` - the content type of the request body. The value of this parameter is passed as the `Content-Type` header.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_OPTIONS`

The `HTTP_UTILS.HTTP_OPTIONS` procedure is designed to send an HTTP request using the OPTIONS method.

```sql
  PROCEDURE HTTP_OPTIONS (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Procedure `HTTP_UTILS.HTTP_TRACE`

The `HTTP_UTILS.HTTP_TRACE` procedure is designed to send an HTTP request using the TRACE method.

```sql
  PROCEDURE HTTP_TRACE (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL,
    OPTIONS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

Input parameters:

* `URL` - URL address. Required parameter.
* `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
* `OPTIONS` - CURL library options.

Output parameters:

* `STATUS_CODE` - response status code.
* `STATUS_TEXT` - response status text.
* `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
* `RESPONSE_BODY` - response body.
* `RESPONSE_HEADERS` - response headers.

### Function `HTTP_UTILS.URL_ENCODE`

The `HTTP_UTILS.URL_ENCODE` function is for URL encoding of a string.

```sql
  FUNCTION URL_ENCODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);
```

Usage example:

```sql
SELECT
  HTTP_UTILS.URL_ENCODE('N&N') as encoded
FROM RDB$DATABASE;
```

### Function `HTTP_UTILS.URL_DECODE`

The `HTTP_UTILS.URL_DECODE` function is for URL string decoding.

```sql
  FUNCTION URL_DECODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);
```

Usage example:

```sql
SELECT
  HTTP_UTILS.URL_DECODE('N%26N') as decoded
FROM RDB$DATABASE;
```

### Procedure `HTTP_UTILS.PARSE_URL`

The `HTTP_UTILS.PARSE_URL` procedure is designed to parse a URL into its component parts,
according to the specification [RFC 3986](https://tools.ietf.org/html/rfc3986).

Requirement: minimum version of `libcurl` is 7.62.0.

```sql
  PROCEDURE PARSE_URL (
    URL                  VARCHAR(8191)
  )
  RETURNS (
    URL_SCHEME           VARCHAR(64),
    URL_USER             VARCHAR(64),
    URL_PASSWORD         VARCHAR(64),
    URL_HOST             VARCHAR(256),
    URL_PORT             INTEGER,
    URL_PATH             VARCHAR(8191),
    URL_QUERY            VARCHAR(8191),
    URL_FRAGMENT         VARCHAR(8191)
  );
```

Input parameters:

* `URL` - URL address, in the format `<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`.

Output parameters:

* `URL_SCHEME` is a scheme that defines the protocol.
* `URL_USER` - username.
* `URL_PASSWORD` - password.
* `URL_HOST` - host.
* `URL_PORT` - port number (1-65535) specified in the URL, if the port is not specified, then returns NULL.
* `URL_PATH` - URL path. The path part will be '/' even if no path is specified in the URL. The URL path always starts with a forward slash.
* `URL_QUERY` - query (parameters).
* `URL_FRAGMENT` - fragment (anchor).

Usage example:

```sql
SELECT   
    URL_SCHEME,
    URL_USER,
    URL_PASSWORD,
    URL_HOST,
    URL_PORT,
    URL_PATH,
    URL_QUERY,
    URL_FRAGMENT
FROM HTTP_UTILS.PARSE_URL('https://user:password@server:8080/part/put?a=1&b=2#fragment');
```

### Function `HTTP_UTILS.BUILD_URL`

The `HTTP_UTILS.BUILD_URL` function builds a URL from its component parts, according to the specification [RFC 3986](https://tools.ietf.org/html/rfc3986).

Requirement: The minimum version of `libcurl` is 7.62.0.

```sql
  FUNCTION BUILD_URL (
    URL_SCHEME           VARCHAR(64) NOT NULL,
    URL_USER             VARCHAR(64),
    URL_PASSWORD         VARCHAR(64),
    URL_HOST             VARCHAR(256) NOT NULL,
    URL_PORT             INTEGER DEFAULT NULL,
    URL_PATH             VARCHAR(8191) DEFAULT NULL,
    URL_QUERY            VARCHAR(8191) DEFAULT NULL,
    URL_FRAGMENT         VARCHAR(8191) DEFAULT NULL
  )
  RETURNS VARCHAR(8191);
```

Input parameters:

* `URL_SCHEME` is a scheme that defines the protocol.
* `URL_USER` - username.
* `URL_PASSWORD` - password.
* `URL_HOST` - host.
* `URL_PORT` - port number (1-65535) specified in the URL, if the port is not specified, then returns NULL.
* `URL_PATH` - URL path. The path part will be '/' even if no path is specified in the URL. The URL path always starts with a forward slash.
* `URL_QUERY` - query (parameters).
* `URL_FRAGMENT` - fragment (anchor).

Result: URL string according to the specification [RFC 3986](https://tools.ietf.org/html/rfc3986), i.e. in the format
`<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`.

Usage example:

```sql
SELECT
  HTTP_UTILS.BUILD_URL(
    'https',
    NULL,
    NULL, 
    'localhost',
    8080,
    '/',
    'query=database',
    'DB'
  ) AS URL
FROM RDB$DATABASE;
```

### Function `HTTP_UTILS.URL_APPEND_QUERY`

The `HTTP_UTILS.URL_APPEND_QUERY` function is designed to add parameters to the URL address, while previously
the existing QUERY part of the URL is preserved.

Requirement: The minimum version of `libcurl` is 7.62.0.

```sql
  FUNCTION URL_APPEND_QUERY (
    URL                  VARCHAR(8191) NOT NULL,
    URL_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);
```

Input parameters:

* `URL` - URL address, in the format `<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path> [?<query>][#<fragment>]`.
* `URL_QUERY` - added parameters or parameter.
* `URL_ENCODE` - if `TRUE`, then URL encoding of the added parameter `URL_QUERY` is performed. The part of the string before the first `=` is not encoded.

Result: URL with added parameters.

Usage example:

```sql
EXECUTE BLOCK
RETURNS (
  URL VARCHAR(8191)
)
AS
BEGIN
  URL = 'https://example.com/?shoes=2';
  URL = HTTP_UTILS.URL_APPEND_QUERY(URL, 'hat=1');
  URL = HTTP_UTILS.URL_APPEND_QUERY(URL, 'candy=N&N', TRUE);
  SUSPEND;
END
```

The result will be a URL `https://example.com/?shoes=2&hat=1&candy=N%26N`.

### Function `HTTP_UTILS.APPEND_QUERY`

The `HTTP_UTILS.APPEND_QUERY` function collects parameter values into a single string.
Further, this string can be added to the URL as parameters or passed to the request body if the request is sent using the POST method with
`Content-Type: application/x-www-form-urlencoded`.

Requirement: The minimum version of `libcurl` is 7.62.0.

```sql
  FUNCTION APPEND_QUERY (
    URL_QUERY            VARCHAR(8191),
    NEW_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);
```

Input parameters:

* `URL_QUERY` - existing parameters to which you need to add new ones. If the `URL_QUERY` parameter is `NULL`, then the result will be a string containing only the parameters to be added.
* `NEW_QUERY` - added parameters or parameter.
* `URL_ENCODE` - if `TRUE`, then URL encoding of the added parameter `NEW_QUERY` is performed. The part of the string before the first `=` is not encoded.

Result: string with added parameters.

Usage example:

```sql
EXECUTE BLOCK
RETURNS (
  QUERY VARCHAR(8191)
)
AS
BEGIN
  QUERY = HTTP_UTILS.APPEND_QUERY(NULL, 'shoes=2');
  QUERY = HTTP_UTILS.APPEND_QUERY(QUERY, 'hat=1');
  QUERY = HTTP_UTILS.APPEND_QUERY(QUERY, 'candy=N&N', TRUE);
  SUSPEND;
END
```

The result will be the string `shoes=2&hat=1&candy=N%26N`.

### Procedure `HTTP_UTILS.PARSE_HEADERS`

The `HTTP_UTILS.PARSE_HEADERS` procedure is designed to parse headers returned in an HTTP response.
The procedure returns each header as a separate entry in the `HEADER_LINE` parameter. If the header is of the form `<header name>: <header value>`, 
then the header name is returned in the `HEADER_NAME` parameter, and the value is `HEADER_VALUE`.

```sql
  PROCEDURE PARSE_HEADERS (
    HEADERS              BLOB SUB_TYPE TEXT
  )
  RETURNS (
    HEADER_LINE          VARCHAR(8191),
    HEADER_NAME          VARCHAR(256),
    HEADER_VALUE         VARCHAR(8191)
  );
```  

Input parameters:

* `HEADERS` - HTTP headers.

Output parameters:

* `HEADER_LINE` - HTTP header.
* `HEADER_NAME` - HTTP header name.
* `HEADER_VALUE` - HTTP header value.

Usage example:

```sql
WITH 
  T AS (
    SELECT
      RESPONSE_HEADERS
    FROM HTTP_UTILS.HTTP_GET (
      'https://www.cbr-xml-daily.ru/latest.js'
    )
  )
SELECT
  H.HEADER_LINE,
  H.HEADER_NAME,
  H.HEADER_VALUE
FROM 
  T
  LEFT JOIN HTTP_UTILS.PARSE_HEADERS(T.RESPONSE_HEADERS) H ON TRUE;
```

### Function `HTTP_UTILS.GET_HEADER_VALUE`

The `HTTP_UTILS.GET_HEADER_VALUE` function returns the value of the first found header with the given name. If the header is not found, then `NULL` is returned.

```sql
  FUNCTION GET_HEADER_VALUE (
    HEADERS              BLOB SUB_TYPE TEXT,
    HEADER_NAME          VARCHAR(256)
  )
  RETURNS VARCHAR(8191);
```

Input parameters:

* `HEADERS` - HTTP headers.
* `HEADER_NAME` - HTTP header name.

Result: The value of the first found header with the given name, or `NULL` if no header was found.

Usage example:

```sql
WITH 
  T AS (
    SELECT
      RESPONSE_HEADERS
    FROM HTTP_UTILS.HTTP_GET (
      'https://www.cbr-xml-daily.ru/latest.js'
    )
  )
SELECT
  HTTP_UTILS.GET_HEADER_VALUE(T.RESPONSE_HEADERS, 'age') AS HEADER_VALUE
FROM T;
```

## Examples

### Getting exchange rates

```sql
SELECT
  STATUS_CODE,
  STATUS_TEXT,
  RESPONSE_TYPE,
  RESPONSE_HEADERS,
  RESPONSE_BODY
FROM HTTP_UTILS.HTTP_REQUEST (
  'GET',
  'https://www.cbr-xml-daily.ru/latest.js'
);
```

### Obtaining information about the company by TIN

```sql
SELECT
  STATUS_CODE,
  STATUS_TEXT,
  RESPONSE_TYPE,
  RESPONSE_HEADERS,
  RESPONSE_BODY
FROM HTTP_UTILS.HTTP_REQUEST (
  'POST',
  'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/party',
  trim('
{
    "query": "810712829220",
    "type": "INDIVIDUAL"
}
  '),
  'application/json',
  q'{
Authorization: Token b81a595753ff53056469a939c064c96b49177db3
  }'
)
```

The token has been intentionally changed to non-working. It must be obtained when registering on the [dadata.ru](https://dadata.ru) service.
