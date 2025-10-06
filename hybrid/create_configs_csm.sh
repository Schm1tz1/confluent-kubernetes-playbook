#!/usr/bin/env bash

#
# re-create all secrets
#

kubectl create secret generic csm-sidecar-properties \
    --namespace=confluent \
    --from-file=csm.properties=csm-sidecar-azure-ple-wrapper-asymm-AES_GCM.properties \
    -o yaml --dry-run=client | kubectl apply -f -

kubectl create configmap csm-enabled \
    --namespace=confluent \
    --from-file=pod-template.yaml=csm-enabled-template.yaml \
    -o yaml --dry-run=client | kubectl apply -f -
