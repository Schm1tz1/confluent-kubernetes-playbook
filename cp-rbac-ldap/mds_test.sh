#!/usr/bin/env bash

curl -s -u kafka:kafka-secret https://rest.k8s.internal.schmitzi.net/kafka/v3/clusters | jq