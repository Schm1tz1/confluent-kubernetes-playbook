#!/usr/bin/env bash
set -x

helm repo add minio https://charts.min.io/
helm install minio minio/minio -n minio\
    --set resources.requests.memory=512Mi \
    --set replicas=1 --set persistence.enabled=false \
    --set mode=standalone \
    --set rootUser=rootuser,rootPassword=rootpass123 \
    --create-namespace

kubectl exec -it deploy/minio -n minio -- bash -c "mc alias set local http://localhost:9000 rootuser rootpass123 && mc mb local/cflt-tier"
