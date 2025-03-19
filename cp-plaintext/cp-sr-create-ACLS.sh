#!/usr/bin/env bash
set -x

# List ACLs
kubectl exec -it -n confluent schemaregistry-0 -- \
sr-acl-cli --config /opt/confluentinc/etc/schemaregistry/schemaregistry.properties \
--list

# Admin User
kubectl exec -it -n confluent schemaregistry-0 -- \
sr-acl-cli --config /opt/confluentinc/etc/schemaregistry/schemaregistry.properties \
--add --subject '*' --principal sr-admin --operation '*'
