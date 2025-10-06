#!/usr/bin/env bash

#
# re-create all secrets
#

kubectl create secret generic ccloud-credentials \
    --namespace=confluent \
    --from-file=plain.txt=ccloud-credentials.txt \
    -o yaml --dry-run=client | kubectl apply -f -

kubectl create secret generic ccloud-sr-credentials \
    --namespace=confluent \
    --from-file=basic.txt=ccloud-sr-credentials.txt \
    -o yaml --dry-run=client | kubectl apply -f -
