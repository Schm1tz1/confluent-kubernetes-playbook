#!/usr/bin/env bash
set -x

# test the configuration
echo "Kubernetes services:"
kubectl get svc

echo "Kubernetes Pods:"
kubectl get pods

echo "Adding helm repo and installing Confluent Plugin..."
kubectl create ns confluent
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set namespaced=false \
  --set kRaftEnabled=true \
  --namespace confluent
