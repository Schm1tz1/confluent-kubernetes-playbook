#!/usr/bin/env bash
set -x

kubectl delete secret roles-sr --namespace confluent
kubectl delete secret sr-client-basic --namespace confluent

kubectl create secret generic roles-sr \
 --from-file=basic.txt=./rolesSR.txt \
 --namespace confluent

 kubectl create secret generic sr-client-basic \
 --from-file=basic.txt=./clientSR.txt \
  --namespace confluent
