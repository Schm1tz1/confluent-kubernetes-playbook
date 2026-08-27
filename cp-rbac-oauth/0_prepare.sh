#!/usr/bin/env bash

set -eo pipefail

kubectl apply -f ../certs/issuer.yaml
kubectl apply -f ../certs/certs.yaml

PRIV_KEY="mds-keypair-priv.pem"
PUB_KEY="mds-keypair-pub.pem"

if [ -f "$PRIV_KEY" ] && [ -f "$PUB_KEY" ]; then
    echo "MDS Keys already exist, skipping generation."
else
    echo "Generating new MDS RSA key pair..."
    openssl genrsa -out "$PRIV_KEY" 2048
    openssl rsa -in "$PRIV_KEY" -outform PEM -pubout -out "$PUB_KEY"
    echo "Keys generated: $PRIV_KEY, $PUB_KEY"
fi

kubectl create secret generic mds-token \
--from-file=mdsPublicKey.pem=mds-keypair-pub.pem \
--from-file=mdsTokenKeyPair.pem=mds-keypair-priv.pem \
-n confluent --dry-run=client -o yaml | kube1 apply -f - 

kubectl create secret generic oidccredential \
--from-file=oidcClientSecret.txt=oidcClientSecret.txt \
-n confluent --dry-run=client -o yaml | kube1 apply -f - 

kubectl create secret generic oauth-jass \
--from-file=oauth.txt=oidcClientSecret.txt \
-n confluent --dry-run=client -o yaml | kube1 apply -f - 

kubectl apply -f keycloak.yaml
kubectl rollout status deployment/keycloak --namespace confluent --timeout=180s
