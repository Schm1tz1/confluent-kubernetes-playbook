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

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minio-ingress
  namespace: minio
spec:
  tls:
  - hosts:
    - minio.k8s.schmitzi.net
    secretName: tls-schmitzi-ingress
  rules:
  - host: minio.k8s.schmitzi.net
    http:
      paths:
      - path: /api/(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: minio
            port:
              number: 9000
      - path: /console/(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: minio-console
            port:
              number: 9001
EOF
