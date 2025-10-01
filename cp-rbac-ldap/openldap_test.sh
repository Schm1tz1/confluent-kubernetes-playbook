#!/usr/bin/env bash

set -x
kubectl --namespace=confluent exec -it ldap-0 -- ldapsearch -LLL -x -H ldap://ldap.confluent.svc.cluster.local:389 -b 'DC=confluent,DC=demo,DC=org' -D "uid=kafka,ou=services,dc=confluent,dc=demo,dc=org" -w 'yZvEFM3AV7mj'
