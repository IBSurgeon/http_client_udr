CREATE DOMAIN D_HTTP_METHOD
AS VARCHAR(7)
CHECK (VALUE IN ('GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'));

SET TERM ^ ;

CREATE OR ALTER PACKAGE HTTP_UTILS
AS
BEGIN
  /**
   * Sends an HTTP request and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `METHOD` - HTTP method. Possible values are 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'.
   * - `URL` - URL address.
   * - `REQUEST_BODY` - HTTP request body.
   * - `REQUEST_TYPE` - request body content type. The value of this parameter is passed as the `Content-Type` header.
   * - `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the GET method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `HEADERS` - HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the HEAD method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `HEADERS` - HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the POST method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `REQUEST_BODY` - HTTP request body.
   * - `REQUEST_TYPE` - request body content type. The value of this parameter is passed as the `Content-Type` header.
   * - `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the PUT method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `REQUEST_BODY` - HTTP request body.
   * - `REQUEST_TYPE` - request body content type. The value of this parameter is passed as the `Content-Type` header.
   * - `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the PATCH method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `REQUEST_BODY` - HTTP request body.
   * - `REQUEST_TYPE` - request body content type. The value of this parameter is passed as the `Content-Type` header.
   * - `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the DELETE method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `REQUEST_BODY` - HTTP request body.
   * - `REQUEST_TYPE` - request body content type. The value of this parameter is passed as the `Content-Type` header.
   * - `HEADERS` - other HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the OPTIONS method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `HEADERS` - HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * Sends an HTTP request using the TRACE method and receives an HTTP response.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `HEADERS` - HTTP request headers. Each heading must be on a new line, that is, headings are separated by a newline character.
   * - `OPTIONS` - CURL library options.
   *
   * Output parameters:
   *
   * - `STATUS_CODE` - response status code.
   * - `STATUS_TEXT` - response status text.
   * - `RESPONSE_TYPE` - response content type. Contains the values of the `Content-Type` header.
   * - `RESPONSE_BODY` - response body.
   * - `RESPONSE_HEADERS` - response headers.
   */
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

  /**
   * URL encodes the given string.
   */
  FUNCTION URL_ENCODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);

  /**
   * URL decodes the given string.
   */
  FUNCTION URL_DECODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);

  /**
   * Parse the URL and return parts of it.
   *
   * <URL> = <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]
   *
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   *
   * Output parameters:
   *
   * - `URL_SCHEME` - scheme specifies the protocol to use.
   * - `URL_USER` - user part of the URL.
   * - `URL_PASSWORD` - password part of the URL.
   * - `URL_HOST` - hostname part of the URL.
   * - `URL_PORT` - port number (1-65535) specified in the URL, if the port is not present then returns NULL.
   * - `URL_PATH` - path part of the URL. The part will be '/' even if no path is supplied in the URL. A URL path always starts with a slash.
   * - `URL_QUERY` - query part of the URL.
   * - `URL_FRAGMENT` - fragment part of the URL.
   */
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

  /**
   * Building a URL from parts.
   *
   * Input parameters:
   *
   * - `URL_SCHEME` - scheme specifies the protocol to use.
   * - `URL_USER` - user part of the URL.
   * - `URL_PASSWORD` - password part of the URL.
   * - `URL_HOST` - hostname part of the URL.
   * - `URL_PORT` - port number (1-65535) specified in the URL or NULL.
   * - `URL_PATH` - path part of the URL. The part will be '/' even if no path is supplied in the URL. A URL path always starts with a slash.
   * - `URL_QUERY` - query part of the URL.
   * - `URL_FRAGMENT` - fragment part of the URL.
   */
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
END^

RECREATE PACKAGE BODY HTTP_UTILS
AS
BEGIN
  PROCEDURE HTTP_REQUEST (
    METHOD               D_HTTP_METHOD NOT NULL,
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  EXTERNAL NAME 'http_client_udr!sendHttpRequest'
  ENGINE UDR;

  PROCEDURE HTTP_GET (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'GET',
        :URL,
        NULL,
        NULL,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_HEAD (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'HEAD',
        :URL,
        NULL,
        NULL,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_POST (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'POST',
        :URL,
        :REQUEST_BODY,
        :REQUEST_TYPE,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_PUT (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'PUT',
        :URL,
        :REQUEST_BODY,
        :REQUEST_TYPE,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_PATCH (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'PATCH',
        :URL,
        :REQUEST_BODY,
        :REQUEST_TYPE,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_DELETE (
    URL                  VARCHAR(8191) NOT NULL,
    REQUEST_BODY         BLOB,
    REQUEST_TYPE         VARCHAR(256),
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'DELETE',
        :URL,
        :REQUEST_BODY,
        :REQUEST_TYPE,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_OPTIONS (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'OPTIONS',
        :URL,
        NULL,
        NULL,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  PROCEDURE HTTP_TRACE (
    URL                  VARCHAR(8191) NOT NULL,
    HEADERS              VARCHAR(8191),
    OPTIONS              VARCHAR(8191)
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  )
  AS
  BEGIN
    FOR
      SELECT
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
      FROM HTTP_UTILS.HTTP_REQUEST (
        'TRACE',
        :URL,
        NULL,
        NULL,
        :HEADERS,
        :OPTIONS
      )
      INTO
        STATUS_CODE,
        STATUS_TEXT,
        RESPONSE_TYPE,
        RESPONSE_BODY,
        RESPONSE_HEADERS
    DO
      SUSPEND;
  END

  FUNCTION URL_ENCODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!urlEncode'
  ENGINE UDR;

  FUNCTION URL_DECODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!urlDecode'
  ENGINE UDR;

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
  )
  EXTERNAL NAME 'http_client_udr!parseUrl'
  ENGINE UDR;

  FUNCTION BUILD_URL (
    URL_SCHEME           VARCHAR(64) NOT NULL,
    URL_USER             VARCHAR(64),
    URL_PASSWORD         VARCHAR(64),
    URL_HOST             VARCHAR(256) NOT NULL,
    URL_PORT             INTEGER,
    URL_PATH             VARCHAR(8191),
    URL_QUERY            VARCHAR(8191),
    URL_FRAGMENT         VARCHAR(8191)
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!buildUrl'
  ENGINE UDR;
END^

SET TERM ; ^
