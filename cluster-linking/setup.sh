#!/usr/bin/env bash

kubectl apply -f cp-source.yaml
kubectl apply -f cp-dest.yaml
kubectl apply -f topic.yaml
kubectl exec kcat -it -n confluent -- bash -c "cat /dev/urandom | \
  tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 666 | \
  kcat -b kafka:9071 -t test-topic -P"