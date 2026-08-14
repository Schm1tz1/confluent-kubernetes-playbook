#!/usr/bin/env bash
set -euo pipefail

kubectl exec kcat -- bash -c '
for i in $(seq 1 100); do
  cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 128 | head -n 500 | \
    kcat -b kafka.source:9092 -t test-topic -P -X transactional.id=testproducerapp1
  sleep 1
done
'
