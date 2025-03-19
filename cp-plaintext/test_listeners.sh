#!/usr/bin/env bash
set -x

kubectl exec kafka-0 -it -n confluent -- cat /opt/confluentinc/etc/kafka/kafka.properties | grep advertised

kubectl get kafka kafka -n confluent -o yaml | grep advertisedExternal -A3
