# IBSurgeon HTTP Client UDR

Библиотека IBSurgeon HTTP Client UDR предназначена для работы с HTTP сервисами, например через REST-API.
Для реализации HTTP клиента используется библиотека с открытыми исходными кодами [libcurl](https://curl.se/libcurl/), которая
обеспечивает взаимодействие c Web-сервисами по протоколу HTTP методами 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'.
Кроме того, предоставляются дополнительные процедуры и функции для разбора HTTP заголовков, а также разбора на составные части URL адресов и их построения.

HTTP Client UDR является 100% бесплатной и с открытым исходным кодом, с лицензией [IDPL](https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/).

Доступны версии для Windows и Linux: для Windows у нас есть готовые к использованию двоичные файлы, а для Linux необходимо собрать UDR из исходных кодов в зависимости от конкретного дистрибутива (у нас есть простая инструкция по сборке).

Библиотека разработана за счет гранта IBSurgeon [www.ib-aid.com](https://www.ib-aid.com).

## Установка HTTP Client UDR

Для установки HTTP Client UDR необходимо:

1. Распаковать zip архив с динамическими библиотеками в каталог `plugins/udr`
2. Выполнить скрипт `sql/http_client_install.sql` для регистрации процедур и функций в БД.

Скачать готовые сборки под ОС Windows можно по ссылкам:

* [HttpClientUdr_Win_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_Win_x64.zip)
* [HttpClientUdr_Win_x86.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_Win_x86.zip)

Скачать готовые сборки под ОС Linux можно по ссылкам:

* [HttpClientUdr_CentOS7_x64.zip](https://github.com/IBSurgeon/http_client_udr/releases/download/1.0/HttpClientUdr_CentOS7_x64.zip)

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

Первые два параметра процедуры `HTTP_UTILS.HTTP_REQUEST` являются обязательными.

Тело запроса `REQUEST_BODY` позволяется не для всех HTTP методов. Если оно, есть то желательно также указывать параметр `REQUEST_TYPE`, который соответствует заголовку `Content-Type`.

В параметре `HEADERS` вы можете передать дополнительные заголовки в виде строки. Каждый заголовок должен быть разделён переводом строки.

В параметре `OPTIONS` вы можете передать дополнительные параметры для библиотеки CURL в виде `CURLOPT_*=<value>`. Каждый новый параметр должен быть отделён переводом строки.

Тело ответа всегда возвращается в двоичном виде, но вы можете преобразовать его в текст с нужной кодировкой с помощью `CAST(RESPONSE_BODY AS BLOB SUB_TYPE TEXT ...)`.

Примеры использования:

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

Пример задания параметров CURL:

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

#### Поддерживаемые CURL опции

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
* [CURLOPT_FOLLOWLOCATION](https://curl.haxx.se/libcurl/c/CURLOPT_FOLLOWLOCATION.html) (значение по умолчанию 1)
* [CURLOPT_MAXREDIRS](https://curl.haxx.se/libcurl/c/CURLOPT_MAXREDIRS.html) (значение по умолчанию 50)

Список поддерживаемых опций зависит от того с какой версий `libcurl` происходила сборка библиотеки.

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
  HTTP_UTILS.URL_ENCODE('N&N') as encoded
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
  HTTP_UTILS.URL_DECODE('N%26N') as decoded
FROM RDB$DATABASE;
```

### Процедура `HTTP_UTILS.PARSE_URL`

Процедура `HTTP_UTILS.PARSE_URL` предназначена для разбора URL на составные части,
согласно спецификации [RFC 3986](https://tools.ietf.org/html/rfc3986).

Требование: минимальная версия `libcurl` 7.62.0.

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

Требование: минимальная версия `libcurl` 7.62.0.

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

Требование: минимальная версия `libcurl` 7.62.0.

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

Требование: минимальная версия libcurl 7.62.0.

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
