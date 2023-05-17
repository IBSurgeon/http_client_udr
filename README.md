# IBSurgeon HTTP Client UDR

Библиотека IBSurgeon HTTP Client UDR предназначена для работы с HTTP сервисами (REST-API и другие).
HTTP Client UDR разработана на основе [libcurl](https://curl.se/libcurl/).

## Установка HTTP Client UDR

Для установки HTTP Client UDR необходимо:

1. Распаковать zip архив с динамическими библиотеками в каталог `plugins/udr`
2. Выполнить скрипт `sql/http_client_install.sql` для регистрации процедур и функций в БД.

Скачать готовые сборки под ОС Windows можно по ссылкам:

* [HttpClientUdr_Win_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_Win_x64.zip)
* [HttpClientUdr_Win_x86.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_Win_x86.zip)

Скачать готовые сборки под ОС Linux можно по ссылкам:

* [HttpClientUdr_CentOS7_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_CentOS7_x64.zip)

Вся процедуры и функции для работы с библиотекой HTTP Client расположены в PSQL пакете `HTTP_UTILS`.

## Сборка под Linux

Перед сборкой необходимо установить

В Ubuntu

```bash
sudo apt-get install libcurl4-openssl-dev
```

В CentOS

```bash
sudo yum install libcurl-devel
```

Теперь можно производить саму сборку.

```bash
git clone https://github.com/IBSurgeon/http_client_udr.git
cd http_client_udr
mkdir build; cd build
cmake ..
make
sudo make install
```

## Пакет `HTTP_UTILS`

### Процедура `HTTP_UTILS.HTTP_REQUEST`

Процедура `HTTP_UTILS.HTTP_REQUEST` предназначена для отправки HTTP запроса и получения HTTP ответа.

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

Входные параметры:

* `METHOD` - HTTP метод. Обязательный параметр. Возможны следующие значения 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'.
* `URL` - URL адрес. Обязательный параметр.
* `REQUEST_BODY` - тело HTTP запроса.
* `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

Процедура `HTTP_UTILS.HTTP_REQUEST` является основной процедурой с помощью которой происходит общение с web-сервисами.
Процедуры `HTTP_UTILS.HTTP_GET`, `HTTP_UTILS.HTTP_HEAD`, `HTTP_UTILS.HTTP_POST`, `HTTP_UTILS.HTTP_PUT`, `HTTP_UTILS.HTTP_PATCH`,
`HTTP_UTILS.HTTP_DELETE`, `HTTP_UTILS.HTTP_OPTIONS`, `HTTP_UTILS.HTTP_TRACE` являются производными от `HTTP_UTILS.HTTP_REQUEST`.
Внутри они вызывают `HTTP_UTILS.HTTP_REQUEST` с заполненным параметром `METHOD`, а также убираются лишние входные и выходные параметры, что
упрощает обращение к web-ресурсу определённым HTTP методом.

### Процедура `HTTP_UTILS.HTTP_GET`

Процедура `HTTP_UTILS.HTTP_GET` предназначена для отправки HTTP запроса методом GET.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

Пример использования:

```sql
SELECT
  R.STATUS_CODE,
  R.STATUS_TEXT,
  R.RESPONSE_TYPE,
  R.RESPONSE_HEADERS,
  CAST(R.RESPONSE_BODY AS BLOB SUB_TYPE TEXT CHARACTER SET UTF8) AS RESPONSE_BODY
FROM HTTP_UTILS.HTTP_GET('https://www.cbr-xml-daily.ru/latest.js') R;
```

### Процедура `HTTP_UTILS.HTTP_HEAD`

Процедура `HTTP_UTILS.HTTP_HEAD` предназначена для отправки HTTP запроса методом HEAD.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_POST`

Процедура `HTTP_UTILS.HTTP_POST` предназначена для отправки HTTP запроса методом POST.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `REQUEST_BODY` - тело HTTP запроса.
* `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_PUT`

Процедура `HTTP_UTILS.HTTP_PUT` предназначена для отправки HTTP запроса методом PUT.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `REQUEST_BODY` - тело HTTP запроса.
* `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_PATCH`

Процедура `HTTP_UTILS.HTTP_PATCH` предназначена для отправки HTTP запроса методом PATCH.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `REQUEST_BODY` - тело HTTP запроса.
* `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_DELETE`

Процедура `HTTP_UTILS.HTTP_DELETE` предназначена для отправки HTTP запроса методом DELETE.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `REQUEST_BODY` - тело HTTP запроса.
* `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_OPTIONS`

Процедура `HTTP_UTILS.HTTP_OPTIONS` предназначена для отправки HTTP запроса методом OPTIONS.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Процедура `HTTP_UTILS.HTTP_TRACE`

Процедура `HTTP_UTILS.HTTP_TRACE` предназначена для отправки HTTP запроса методом TRACE.

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

Входные параметры:

* `URL` - URL адрес. Обязательный параметр.
* `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
* `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

* `STATUS_CODE` - код статуса ответа.
* `STATUS_TEXT` - текст статуса ответа.
* `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
* `RESPONSE_BODY` - тело ответа.
* `RESPONSE_HEADERS` - заголовки ответа.

### Функция `HTTP_UTILS.URL_ENCODE`

Функция `HTTP_UTILS.URL_ENCODE` предназначена для URL кодирования строки.

```sql
  FUNCTION URL_ENCODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);
```

Пример использования:

```sql
SELECT
  HTTP_UTILS.URL_ENCODE('мама') as encoded
FROM RDB$DATABASE;
```

### Функция `HTTP_UTILS.URL_DECODE`

Функция `HTTP_UTILS.URL_DECODE` предназначена для URL декодирования строки.

```sql
  FUNCTION URL_DECODE (
    STR VARCHAR(8191)
  )
  RETURNS VARCHAR(8191);
```

Пример использования:

```sql
SELECT
  HTTP_UTILS.URL_DECODE('%D0%BC%D0%B0%D0%BC%D0%B0') as decoded
FROM RDB$DATABASE;
```

### Процедура `HTTP_UTILS.PARSE_URL`

Процедура `HTTP_UTILS.PARSE_URL` предназначена для разбора URL на составные части,
согласно спецификации [RFC 3986](https://tools.ietf.org/html/rfc3986).

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

Входные параметры:

* `URL` - URL адрес, в формате `<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`.

Выходные параметры:

* `URL_SCHEME` - схема, определяющая протокол.
* `URL_USER` - имя пользователя.
* `URL_PASSWORD` - пароль.
* `URL_HOST` - хост.
* `URL_PORT` - номер порта (1-65535) указанный в URL, если порт не указан, то возвращает NULL.
* `URL_PATH` - URL путь. Часть пути будет равна '/', даже если в URL-адресе не указан путь. URL-путь всегда начинается с косой черты.
* `URL_QUERY` - запрос (параметры).
* `URL_FRAGMENT` - фрагмент (якорь).

Пример использования:

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

### Функция `HTTP_UTILS.BUILD_URL`

Функция `HTTP_UTILS.BUILD_URL` собирает URL из составных частей, согласно спецификации [RFC 3986](https://tools.ietf.org/html/rfc3986).

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

Входные параметры:

* `URL_SCHEME` - схема, определяющая протокол.
* `URL_USER` - имя пользователя.
* `URL_PASSWORD` - пароль.
* `URL_HOST` - хост.
* `URL_PORT` - номер порта (1-65535) указанный в URL, если порт не указан, то возвращает NULL.
* `URL_PATH` - URL путь. Часть пути будет равна '/', даже если в URL-адресе не указан путь. URL-путь всегда начинается с косой черты.
* `URL_QUERY` - запрос (параметры).
* `URL_FRAGMENT` - фрагмент (якорь).

Результат: URL строка согласно спецификации [RFC 3986](https://tools.ietf.org/html/rfc3986), т.е. в формате
`<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`.

Пример использования:

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

### Функция `HTTP_UTILS.URL_APPEND_QUERY`

Функция `HTTP_UTILS.URL_APPEND_QUERY` предназначена для добавление параметров к URL адресу, при этом ранее
существующая QUERY часть URL адреса сохраняется.

```sql
  FUNCTION URL_APPEND_QUERY (
    URL                  VARCHAR(8191) NOT NULL,
    URL_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);
```

Входные параметры:

* `URL` - URL адрес, в формате `<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`.
* `URL_QUERY` - добавляемые параметры или параметр.
* `URL_ENCODE` - если `TRUE`, то производиться URL кодирования добавляемого параметра `URL_QUERY`. Часть строки до первого знака `=` не кодируется.

Результат: URL адрес с добавленными параметрами.

Пример использования:

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

Результатом будет URL `https://example.com/?shoes=2&hat=1&candy=N%26N`.

### Функция `HTTP_UTILS.APPEND_QUERY`

Функция `HTTP_UTILS.APPEND_QUERY` сборки значений параметров в единую строку.
Далее эта строка может быть добавлена в URL адрес как параметры или передана в тело запроса, если запрос отправляется методом POST с
`Content-Type: application/x-www-form-urlencoded`.

```sql
  FUNCTION APPEND_QUERY (
    URL_QUERY            VARCHAR(8191),
    NEW_QUERY            VARCHAR(8191),
    URL_ENCODE           BOOLEAN NOT NULL DEFAULT FALSE
  )
  RETURNS VARCHAR(8191);
```

Входные параметры:

* `URL_QUERY` - существующие параметры к которым необходимо добавить новые. Если параметр `URL_QUERY` равен `NULL`, то результатом будет строка содержащая только добавляемые параметры.
* `NEW_QUERY` - добавляемые параметры или параметр.
* `URL_ENCODE` - если `TRUE`, то производиться URL кодирования добавляемого параметра `NEW_QUERY`. Часть строки до первого знака `=` не кодируется.

Результат: строка с добавленными параметрами.

Пример использования:

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

Результатом будет строка `shoes=2&hat=1&candy=N%26N`.

### Процедура `HTTP_UTILS.PARSE_HEADERS`

Процедура `HTTP_UTILS.PARSE_HEADERS` предназначена для анализа заголовков возвращаемых в HTTP ответе.
Каждый заголовок процедура возвращает отдельной записью в параметре `HEADER_LINE`. Если заголовок имеет вид `<header name>: <header value>`, то
наименование заголовка возвращается в параметре `HEADER_NAME`, а значение - `HEADER_VALUE`.

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

Входные параметры:

* `HEADERS` - HTTP заголовки.

Выходные параметры:

* `HEADER_LINE` - HTTP заголовок.
* `HEADER_NAME` - имя HTTP заголовка.
* `HEADER_VALUE` - значение HTTP заголовка.

Пример использования:

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

### Функция `HTTP_UTILS.GET_HEADER_VALUE`

Функция `HTTP_UTILS.GET_HEADER_VALUE` возвращает значение первого найденного заголовка с заданным именем. Если заголовок не найден, то возвращается `NULL`.

```sql
  FUNCTION GET_HEADER_VALUE (
    HEADERS              BLOB SUB_TYPE TEXT,
    HEADER_NAME          VARCHAR(256)
  )
  RETURNS VARCHAR(8191);
```

Входные параметры:

* `HEADERS` - HTTP заголовки.
* `HEADER_NAME` - имя HTTP заголовка.

Результат: значение первого найденного заголовка с заданным именем или `NULL`, если заголовок не найден.

Пример использования:

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

## Примеры

### Получение курсов валют

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

### Получение сведений о компании по ИНН

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

Токен намеренно изменён на нерабочий. Его необходимо получить при регистрации на сервисе [dadata.ru](https://dadata.ru).
