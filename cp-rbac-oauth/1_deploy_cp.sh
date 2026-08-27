#!/usr/bin/env bash

set -eo pipefail

kubectl apply -f cp-v8.yaml
kubectl rollout status statefulset/kafka -n confluent --timeout=600s

kubectl apply -f rolebindings.yaml

# ORDERING NOTE (RBAC startup race):
# cp-v8.yaml creates the ControlCenter CR, but its User:c3 SystemAdmin binding
# lives in rolebindings.yaml, applied afterwards. C3's exactly-once "command"
# Kafka Streams app can start producing BEFORE that binding has propagated to
# MDS/brokers, hit "Cluster authorization failed", and wedge without ever
# binding its web port 9021 (pod stays 2/3, controlcenter container not Ready).
# The rolebinding must be live before C3 first produces. If C3 comes up stuck,
# it needs a restart once the bindings are CREATED. The check below does this
# automatically.
if ! kubectl rollout status statefulset/controlcenter -n confluent --timeout=300s; then
  echo "controlcenter not ready after 300s; likely the RBAC startup race — recovering..."
  kubectl wait --for=jsonpath='{.status.state}'=CREATED confluentrolebinding/c3-admin -n confluent --timeout=300s
  kubectl delete pod controlcenter-0 -n confluent
  kubectl rollout status statefulset/controlcenter -n confluent --timeout=300s
fi
