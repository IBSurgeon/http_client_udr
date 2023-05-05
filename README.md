# IBSurgeon HTTP Client UDR

���������� IBSurgeon HTTP Client UDR ������������� ��� ������ � HTTP ��������� (��������� � �������� ������).
HTTP Client UDR ����������� �� ������ [libcurl](https://curl.se/libcurl/).

## ��������� HTTP Client UDR

��� ��������� HTTP Client UDR ����������:

1. ����������� zip ����� � ������������� ������������ � ������� `plugins\udr`
2. ��������� ������ `sql\http_client_install.sql` ��� ����������� �������� � ������� � ��. 

��� ��������� � ������� ��� ������ � ����������� HTTP Client ��������������� � PSQL ������ `HTTP_UTILS`.

## ����� `HTTP_UTILS`

### ������� `HTTP_UTILS.URL_ENCODE`

������� `HTTP_UTILS.URL_ENCODE` ������������� ��� URL ����������� ������.

```sql
  FUNCTION URL_ENCODE (
    URL VARCHAR(1024)
  )
  RETURNS VARCHAR(1024);
```

������ �������������:

```sql
SELECT
  HTTP_UTILS.URL_ENCODE('����') as encoded
FROM RDB$DATABASE;
```

### ������� `HTTP_UTILS.URL_DECODE`

������� `HTTP_UTILS.URL_DECODE` ������������� ��� URL ������������� ������.

```sql
  FUNCTION URL_DECODE (
    URL VARCHAR(1024)
  )
  RETURNS VARCHAR(1024);
```

������ �������������:

```sql
SELECT
  HTTP_UTILS.URL_DECODE('%D0%BC%D0%B0%D0%BC%D0%B0') as decoded
FROM RDB$DATABASE;
```

### ��������� `HTTP_UTILS.SEND_REQUEST`

��������� `HTTP_UTILS.SEND_REQUEST` ������������� ��� �������� HTTP �������� � ��������� HTTP ������. 
��� �������� ��������� � ������� ������� ���������� ������� � web-���������.

```sql
  PROCEDURE SEND_REQUEST (
    METHOD               D_HTTP_METHOD NOT NULL,
    URL                  VARCHAR(1024) NOT NULL,
    REQUEST_BODY         BLOB SUB_TYPE TEXT DEFAULT NULL,
    REQUEST_TYPE         VARCHAR(256) DEFAULT NULL,
    HEADERS              VARCHAR(8191) DEFAULT NULL
  )
  RETURNS (
    STATUS_CODE          SMALLINT,
    STATUS_TEXT          VARCHAR(256),
    RESPONSE_TYPE        VARCHAR(256),
    RESPONSE_BODY        BLOB SUB_TYPE TEXT,
    RESPONSE_HEADERS     BLOB SUB_TYPE TEXT
  );
```

������� ���������:

- `METHOD` - HTTP �����. ������������ ��������. �������� ��������� �������� 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'.
- `URL` - URL �����.
- `REQUEST_BODY` - ���� HTTP �������.
- `REQUEST_TYPE` - ��� ����������� ���� �������. �������� ����� ��������� ��������� � �������� ��������� `Content-Type`.
- `HEADERS` - ������ ��������� HTTP �������. ������ ��������� ������ ���� �� ����� ������, �� ���� ��������� ����������� �������� �������� ������.

������� ���������:

- `STATUS_CODE` - ��� ������� ������.
- `STATUS_TEXT` - ����� ������� ������.
- `RESPONSE_TYPE` - ��� ����������� ������. �������� �������� ��������� `Content-Type`.
- `RESPONSE_BODY` - ���� ������.
- `RESPONSE_HEADERS` - ��������� �������.

## �������

### ��������� ������ �����

```sql
SELECT
  STATUS_CODE,
  STATUS_TEXT,
  RESPONSE_TYPE,
  RESPONSE_HEADERS,
  RESPONSE_BODY
FROM HTTP_UTILS.SEND_REQUEST (
  'GET',
  'https://www.cbr-xml-daily.ru/latest.js'
);
```

### ��������� �������� � �������� �� ���

```sql
SELECT
  STATUS_CODE,
  STATUS_TEXT,
  RESPONSE_TYPE,
  RESPONSE_HEADERS,
  RESPONSE_BODY
FROM HTTP_UTILS.SEND_REQUEST (
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

����� ��������� ������ �� ���������. ��� ���������� �������� ��� ����������� �� ������� dadata.ru.


