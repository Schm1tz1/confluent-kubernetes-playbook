#!/usr/bin/env bash
set +x

schemareg_test() {
    echo "Schemareg $1 contexts:"
    curl --silent http://$1:$2/contexts
    echo
    echo "Schemareg $1 subjects:"
    curl --silent http://$1:$2/subjects
    echo
    echo "Schemareg $1 schemas:"
    curl --silent http://$1:$2/schemas
    echo
}

# list exporters and schema exporter config (if exists)
echo "Exporters in source:"
curl --silent http://schemaregistry.confluent.svc.cluster.local:8081/exporters
echo
echo "Exporter config:"
curl --silent http://schemaregistry.confluent.svc.cluster.local:8081/exporters/schemaexporter
echo

# k8s registry / source
schemareg_test schemaregistry.confluent.svc.cluster.local 8081
echo "---"

# VM registry / target
schemareg_test schemaregistry.confluent-target.svc.cluster.local 8081