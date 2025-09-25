#!/usr/bin/env bash

set -x
kubectl --namespace=confluent exec -it ldap-0 -- ldapsearch -LLL -x -H ldap://ldap.confluent.svc.cluster.local:389 -b 'ou=users,dc=test,dc=com' -D "cn=mds,dc=test,dc=com" -w 'Developer!'
