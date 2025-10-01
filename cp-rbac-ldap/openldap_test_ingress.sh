#!/usr/bin/env bash

set -x
ldapsearch -LLL -x -H ldaps://ldap.k8s.internal.schmitzi.net:443 -b 'ou=users,dc=test,dc=com' -D "cn=mds,dc=test,dc=com" -w 'Developer!'
