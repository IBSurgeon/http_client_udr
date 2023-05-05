# IBSurgeon HTTP Client UDR

Библиотека IBSurgeon HTTP Client UDR предназначена для работы с HTTP сервисами (получение и отправка данных).
HTTP Client UDR разработана на основе [libcurl](https://curl.se/libcurl/).

## Установка HTTP Client UDR

Для установки HTTP Client UDR необходимо:

1. Распаковать zip архив с динамическими библиотеками в каталог `plugins\udr`
2. Выполнить скрипт `sql\http_client_install.sql` для регистрации процедур и функций в БД. 

Вся процедуры и функции для работы с библиотекой HTTP Client инкапсулированы в PSQL пакете `HTTP_UTILS`.

## Пакет `HTTP_UTILS`

### Функция `HTTP_UTILS.URL_ENCODE`

Функция `HTTP_UTILS.URL_ENCODE` предназначена для URL кодирования строки.

```sql
  FUNCTION URL_ENCODE (
    URL VARCHAR(1024)
  )
  RETURNS VARCHAR(1024);
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
    URL VARCHAR(1024)
  )
  RETURNS VARCHAR(1024);
```

Пример использования:

```sql
SELECT
  HTTP_UTILS.URL_DECODE('%D0%BC%D0%B0%D0%BC%D0%B0') as decoded
FROM RDB$DATABASE;
```

### Процедура `HTTP_UTILS.SEND_REQUEST`

Процедура `HTTP_UTILS.SEND_REQUEST` предназначена для отправки HTTP запросов и получения HTTP ответа. 
Это основная процедура с помощью которой происходит общение с web-сервисами.

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

Входные параметры:

- `METHOD` - HTTP метод. Обязательный параметр. Возможны следующие значения 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'.
- `URL` - URL адрес.
- `REQUEST_BODY` - тело HTTP запроса.
- `REQUEST_TYPE` - тип содержимого тела запроса. Значение этого параметра передаётся в качестве заголовка `Content-Type`.
- `HEADERS` - другие заголовки HTTP запроса. Каждый заголовок должен быть на новой строке, то есть заголовки разделяются символом перевода строки.

Входные параметры:

- `STATUS_CODE` - код статуса ответа.
- `STATUS_TEXT` - текст статуса ответа.
- `RESPONSE_TYPE` - тип содержимого ответа. Содержит значения заголовка `Content-Type`.
- `RESPONSE_BODY` - тело ответа.
- `RESPONSE_HEADERS` - заголовки ответов.

## Примеры

### Получение курсов валют

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

### Получение сведений о компании по ИНН

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

Токен намеренно изменён на нерабочий. Его необходимо получить при регистрации на сервисе dadata.ru.


