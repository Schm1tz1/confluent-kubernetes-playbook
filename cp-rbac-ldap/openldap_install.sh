#!/usr/bin/env bash
helm upgrade --install -f ./openldap/ldaps-rbac.yaml test-ldap ./openldap/ --namespace confluent

# LDAP split-setup - not working yet
# helm upgrade --install -f ./openldap/ldaps-rbac.yaml test-ldap ./openldap/ --values ./openldap/values-split.yaml --namespace confluent
