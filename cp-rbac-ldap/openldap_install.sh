#!/usr/bin/env bash
kubectl apply -f openldap-certs.yaml
kubectl apply -n confluent -f openldap.yaml
