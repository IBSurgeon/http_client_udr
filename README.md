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

В ubuntu
```
sudo apt-get install libcurl4-openssl-dev
```

В CentOS
```
sudo yum install libcurl-devel
```

Теперь можно производить саму сборку.

```
$ git clone https://github.com/IBSurgeon/http_client_udr.git
$ cd http_client_udr
$ mkdir build; cd build
$ cmake ..
$ make
$ sudo make install
```


## Пакет `HTTP_UTILS`

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

### Процедура `HTTP_UTILS.HTTP_REQUEST`

Процедура `HTTP_UTILS.HTTP_REQUEST` предназначена для отправки HTTP запросов и получения HTTP ответа. 
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

- `METHOD` - HTTP метод. Обязательный параметр. Возможны следующие значения 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'TRACE'.
- `URL` - URL адрес. Обязательный параметр.
- `REQUEST_BODY` - тело HTTP запроса.
- `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
- `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.
- `OPTIONS` - опции библиотеки CURL.

Входные параметры:

- `STATUS_CODE` - код статуса ответа.
- `STATUS_TEXT` - текст статуса ответа.
- `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
- `RESPONSE_BODY` - тело ответа.
- `RESPONSE_HEADERS` - заголовки ответа.

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


