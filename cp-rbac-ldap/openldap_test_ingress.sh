#!/usr/bin/env bash

set -x
ldapsearch -LLL -x -H ldaps://ldap.k8s.internal.schmitzi.net:443 \
  -b 'DC=confluent,DC=demo,DC=org' -D "uid=kafka,ou=services,dc=confluent,dc=demo,dc=org" -w 'yZvEFM3AV7mj'
