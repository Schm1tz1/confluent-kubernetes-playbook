#!/usr/bin/env bash

echo "Producing AVRO record..."
curl --request POST \
  --url https://rest.k8s.internal.schmitzi.net/topics/testdata \
  --header 'accept: application/vnd.kafka.v2+json' \
  --header 'content-type: application/vnd.kafka.avro.v2+json' \
  --data '{
  "value_schema_id": 100078,
  "records": [
    {
      "value": {
        "my_field1": 1,
        "my_field2": 123.4,
        "my_field3": "First record - AVRO!"
      }
    }
  ]
}'
echo

echo "Producing JSONSR record..."
curl --request POST \
  --url https://rest.k8s.internal.schmitzi.net/topics/testdata \
  --header 'accept: application/vnd.kafka.v2+json' \
  --header 'content-type: application/vnd.kafka.jsonschema.v2+json' \
  --data '{
  "value_schema_id": 100078,
  "records": [
    {
      "value": {
        "my_field1": 2,
        "my_field2": 123.4,
        "my_field3": "Second record - JSONSR!"
      }
    }
  ]
}'
echo

echo "Producing JSON record..."
curl --request POST \
  --url https://rest.k8s.internal.schmitzi.net/topics/testdata \
  --header 'accept: application/vnd.kafka.v2+json' \
  --header 'content-type: application/vnd.kafka.json.v2+json' \
  --data '{
  "value_schema_id": 100078,
  "records": [
    {
      "value": {
        "my_field1": 3,
        "my_field2": 123.4,
        "my_field3": "Third record - JSON!"
      }
    }
  ]
}'
echo
