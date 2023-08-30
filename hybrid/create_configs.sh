#!/usr/bin/env bash

#
# re-create all secrets
#

kubectl create secret tls ca-pair-sslcerts \
  --namespace=confluent \
  --cert=../../cp-proxmox-playbook/certs/ca.crt \
  --key=../../cp-proxmox-playbook/certs/ca.key \
  -o yaml --dry-run=client | kubectl apply -f -

kubectl create secret generic ccloud-credentials \
    --namespace=confluent \
    --from-file=plain.txt=ccloud-credentials.txt \
    -o yaml --dry-run=client | kubectl apply -f -

kubectl create secret generic ccloud-sr-credentials \
    --namespace=confluent \
    --from-file=basic.txt=ccloud-sr-credentials.txt \
    -o yaml --dry-run=client | kubectl apply -f -

kubectl create secret generic csm-sidecar-properties \
    --namespace=confluent \
    --from-file=csm.properties=csm-sidecar-azure-ple-wrapper-asymm-AES_GCM.properties \
    -o yaml --dry-run=client | kubectl apply -f -

kubectl create configmap csm-enabled \
    --namespace=confluent \
    --from-file=pod-template.yaml=csm-enabled-template.yaml \
    -o yaml --dry-run=client | kubectl apply -f -
