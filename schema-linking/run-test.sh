#!/usr/bin/env bash
set +x

kubectl cp test-schema-linking.sh schemaregistry-0:/tmp/test-schema-linking.sh -n confluent
kubectl exec -it schemaregistry-0 -- bash /tmp/test-schema-linking.sh
