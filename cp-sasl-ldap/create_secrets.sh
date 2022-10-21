#!/usr/bin/env bash
set -x

# clean up
# kubectl -n confluent delete secret credentials
# kubectl -n confluent delete secret kcat-config

kubectl create secret generic credentials \
    --from-file=ldap.txt=./credentials/ldap.txt \
    -n confluent

kubectl create secret generic kcat-config \
    --from-file=kcat.conf=./kcat.conf \
    -n confluent
