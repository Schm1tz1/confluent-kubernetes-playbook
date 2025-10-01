#!/usr/bin/env bash
set -x

# clean up
kubectl -n confluent delete secret credentials
kubectl -n confluent delete secret mds-token
kubectl -n confluent delete secret mds-client
kubectl -n confluent delete secret mds-client-c3
kubectl -n confluent delete secret mds-client-connect
kubectl -n confluent delete secret mds-client-sr
kubectl -n confluent delete secret mds-client-ksql
kubectl -n confluent delete secret mds-client-krp
kubectl -n confluent delete rest-credential

# Issuer and Certificates via CertBot
kubectl apply -f ../certs/issuer.yaml
kubectl apply -f ../certs/certs.yaml

# MDS keys and token
openssl genrsa -out mds-keypair-priv.pem 2048
openssl rsa -in mds-keypair-priv.pem -outform PEM -pubout -out mds-keypair-pub.pem
kubectl create secret generic mds-token \
--from-file=mdsPublicKey.pem=mds-keypair-pub.pem \
--from-file=mdsTokenKeyPair.pem=mds-keypair-priv.pem \
-n confluent

# CP servers and clients
kubectl create secret generic credentials \
  -n confluent \
  --from-file=plain-users.json=./credentials/creds-kafka-sasl-users.json \
  --from-file=digest-users.json=./credentials/creds-zookeeper-sasl-digest-users.json \
  --from-file=digest.txt=./credentials/creds-kafka-zookeeper-credentials.txt \
  --from-file=plain.txt=./credentials/creds-client-kafka-sasl-user.txt \
  --from-file=basic.txt=./credentials/creds-control-center-users.txt \
  --from-file=plain-interbroker.txt=./credentials/creds-client-kafka-sasl-user.txt \
  --from-file=ldap.txt=./credentials/ldap.txt \
    --save-config --dry-run=client -oyaml | kubectl apply -f -

# C3 Monitoring Services
kubectl -n confluent create secret generic prometheus-credentials --from-file=basic.txt=./credentials/prometheus-credentials-secret.txt
kubectl -n confluent create secret generic alertmanager-credentials --from-file=basic.txt=./credentials/alertmanager-credentials-secret.txt

kubectl -n confluent create secret generic prometheus-client-creds --from-file=basic.txt=./credentials/prometheus-client-credentials-secret.txt
kubectl -n confluent create secret generic alertmanager-client-creds --from-file=basic.txt=./credentials/alertmanager-client-credentials-secret.txt

# MDS
kubectl create secret generic mds-token \
  --from-file=mdsPublicKey.pem=./mdsPublicKey.pem \
  --from-file=mdsTokenKeyPair.pem=./mdsTokenKeyPair.pem \
  -n confluent

# Kafka RBAC credential
kubectl create secret generic mds-client \
  --from-file=bearer.txt=./credentials/bearer.txt \
  --namespace confluent
# Control Center RBAC credential
kubectl create secret generic mds-client-c3 \
  --from-file=bearer.txt=./credentials/c3-mds-client.txt \
  --namespace confluent
# Connect RBAC credential
kubectl create secret generic mds-client-connect \
  --from-file=bearer.txt=./credentials/connect-mds-client.txt \
  --namespace confluent
# Schema Registry RBAC credential
kubectl create secret generic mds-client-sr \
  --from-file=bearer.txt=./credentials/sr-mds-client.txt \
  --namespace confluent
# ksqlDB RBAC credential
kubectl create secret generic mds-client-ksql \
  --from-file=bearer.txt=./credentials/ksqldb-mds-client.txt \
  --namespace confluent
# Kafka Rest Proxy RBAC credential
kubectl create secret generic mds-client-krp \
  --from-file=bearer.txt=./credentials/krp-mds-client.txt \
  --namespace confluent
# Kafka REST credential
kubectl create secret generic rest-credential \
  --from-file=bearer.txt=./credentials/bearer.txt \
  --from-file=basic.txt=./credentials/bearer.txt \
  --namespace confluent