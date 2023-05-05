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

SELECT
  HTTP_UTILS.URL_ENCODE('мама') as encoded,
  HTTP_UTILS.URL_DECODE('%D0%BC%D0%B0%D0%BC%D0%B0') as decoded
FROM RDB$DATABASE;

SELECT
  STATUS_CODE,
  STATUS_TEXT,
  RESPONSE_TYPE,
  RESPONSE_HEADERS,
  RESPONSE_BODY
FROM HTTP_UTILS.SEND_REQUEST (
  -- method
  'HEAD',
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
);
