#!/usr/bin/env bash

echo -n "license=<paste your key here>" > license.txt
kubectl create secret generic confluent-license \
  --from-file=license.txt=./license.txt \
  --namespace confluent

