/*
 *	PROGRAM:		Http Client UDR.
 *	MODULE:			http_client_install.sql
 *	DESCRIPTION:	Script to register the Http Client UDR library in the database.
 * 
 *  The contents of this file are subject to the Initial
 *  Developer's Public License Version 1.0 (the "License");
 *  you may not use this file except in compliance with the
 *  License. You may obtain a copy of the License at
 *  http://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/.
 *
 *  Software distributed under the License is distributed AS IS,
 *  WITHOUT WARRANTY OF ANY KIND, either express or implied.
 *  See the License for the specific language governing rights
 *  and limitations under the License.
 *
 *  The Original Code was created by Simonov Denis
 *  for the open source project "IBSurgeon Http Client UDR".
 *
 *  Copyright (c) 2023 Simonov Denis <sim-mail@list.ru>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________.
 */

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
   * <URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]
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

  /**
   * Adds a query to the URL.
   *
   * Input parameters:
   *
   * - `URL` - URL address.
   * - `URL_QUERY` - query to add.
   * - `URL_ENCODE` - if TRUE then the added string can be URL encoded when added,
   *    the encoding process will skip the '=' character. Otherwise no URL encoding will be applied.
   */
  FUNCTION URL_APPEND_QUERY (
    URL                  VARCHAR(8191) NOT NULL,
    URL_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);

  /**
   * Adds a query to the query part of URL.
   *
   * Input parameters:
   *
   * - `URL_QUERY` - old query part.
   * - `NEW_QUERY` - query to add.
   * - `URL_ENCODE` - if TRUE then the added string can be URL encoded when added,
   *    the encoding process will skip the '=' character. Otherwise no URL encoding will be applied.
   */
  FUNCTION APPEND_QUERY (
    URL_QUERY            VARCHAR(8191),
    NEW_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);

  /**
   * Parses HTTP headers.
   *
   * Input parameters:
   *
   * - `HEADERS` - http headers.
   *
   * Output parameters:
   *
   * - `HEADER_LINE` - header line.
   * - `HEADER_NAME` - header name.
   * - `HEADER_VALUE` - header value.
   */
  PROCEDURE PARSE_HEADERS (
    HEADERS              BLOB SUB_TYPE TEXT
  )
  RETURNS (
    HEADER_LINE          VARCHAR(8191),
    HEADER_NAME          VARCHAR(256),
    HEADER_VALUE         VARCHAR(8191)
  );

  /**
   * Returns the header value with the given name.
   *
   * Input parameters:
   *
   * - `HEADERS` - http headers.
   * - `HEADER_NAME` - header name.
   */
  FUNCTION GET_HEADER_VALUE (
    HEADERS              BLOB SUB_TYPE TEXT,
    HEADER_NAME          VARCHAR(256)
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

  FUNCTION URL_APPEND_QUERY (
    URL                  VARCHAR(8191) NOT NULL,
    URL_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!urlAppendQuery'
  ENGINE UDR;

  FUNCTION APPEND_QUERY (
    URL_QUERY            VARCHAR(8191),
    NEW_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!appendQuery'
  ENGINE UDR;

  PROCEDURE PARSE_HEADERS (
    HEADERS              BLOB SUB_TYPE TEXT
  )
  RETURNS (
    HEADER_LINE          VARCHAR(8191),
    HEADER_NAME          VARCHAR(256),
    HEADER_VALUE         VARCHAR(8191)
  )
  EXTERNAL NAME 'http_client_udr!parseHeaders'
  ENGINE UDR;

  FUNCTION GET_HEADER_VALUE (
    HEADERS              BLOB SUB_TYPE TEXT,
    HEADER_NAME          VARCHAR(256)
  )
  RETURNS VARCHAR(8191)
  EXTERNAL NAME 'http_client_udr!getHeaderValue'
  ENGINE UDR;
END
^

SET TERM ; ^
