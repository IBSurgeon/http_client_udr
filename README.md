# IBSurgeon HTTP Client UDR

Библиотека IBSurgeon HTTP Client UDR предназначена для работы с HTTP сервисами (REST-API и другие).
HTTP Client UDR разработана на основе [libcurl](https://curl.se/libcurl/).

## Установка HTTP Client UDR

Для установки HTTP Client UDR необходимо:

1. Распаковать zip архив с динамическими библиотеками в каталог `plugins\udr`
2. Выполнить скрипт `sql\http_client_install.sql` для регистрации процедур и функций в БД. 

Скачать готовые сборки под ОС Windows можно по ссылкам:

* [HttpClientUdr_Win_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_Win_x64.zip)
* [HttpClientUdr_Win_x86.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_Win_x86.zip)

Скачать готовые сборки под ОС Linux можно по ссылкам:

* [HttpClientUdr_CentOS7_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/0.9_Beta/HttpClientUdr_CentOS7_x64.zip)

Вся процедуры и функции для работы с библиотекой HTTP Client инкапсулированы в PSQL пакете `HTTP_UTILS`.

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
Это основная процедура с помощью которой происходит общение с web-сервисами.

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

- `URL` - URL адрес. Обязательный параметр.
- `REQUEST_BODY` - тело HTTP запроса.
- `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
- `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
- `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

- `STATUS_CODE` - код статуса ответа.
- `STATUS_TEXT` - текст статуса ответа.
- `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
- `RESPONSE_BODY` - тело ответа.
- `RESPONSE_HEADERS` - заголовки ответа.


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

- `URL` - URL адрес. Обязательный параметр.
- `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
- `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

- `STATUS_CODE` - код статуса ответа.
- `STATUS_TEXT` - текст статуса ответа.
- `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
- `RESPONSE_BODY` - тело ответа.
- `RESPONSE_HEADERS` - заголовки ответа.


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

- `URL` - URL адрес. Обязательный параметр.
- `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
- `OPTIONS` - опции библиотеки CURL.

Выходные параметры:

- `STATUS_CODE` - код статуса ответа.
- `STATUS_TEXT` - текст статуса ответа.
- `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
- `RESPONSE_BODY` - тело ответа.
- `RESPONSE_HEADERS` - заголовки ответа.


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

* `URL` - URL адрес, в формате `<URL> ::= <scheme>:[//[<user>:<password>@]<host>[:<port>]][/]<path>[?<query>][#<fragment>]`

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

Функция `HTTP_UTILS.BUILD_URL` собирает URL из составных частей

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

Токен намеренно изменён на нерабочий. Его необходимо получить при регистрации на сервисе dadata.ru.
