#!/usr/bin/env bash
set -x

openssl genrsa -out ./ca-key.pem 2048

openssl req -new -key ./ca-key.pem -x509 \
  -days 1000 \
  -out ./ca.pem \
  -subj "/C=US/ST=CA/L=MountainView/O=Confluent/OU=Operator/CN=TestCA"

kubectl create secret tls ca-pair-sslcerts \
  --cert=./ca.pem \
  --key=./ca-key.pem -n confluent

# kubectl create -n confluent secret generic kraft-credential \
#     --from-file=plain.txt=./plain.txt \
#     --from-file=plain-users.json=./plain-users.json \
#     --from-file=basic.txt=./basic.txt
