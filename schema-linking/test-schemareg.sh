#!/usr/bin/env bash
set -e

schemareg_test() {
    echo "Schemareg $1 contexts:"
    curl --silent http://$1:$2/contexts | jq .
    echo
    echo "Schemareg $1 subjects:"
    curl --silent http://$1:$2/subjects | jq .
    echo
    echo "Schemareg $1 schemas:"
    curl --silent http://$1:$2/schemas | jq .
    echo
}

# lsit exporters
echo "Exporters in source:"
curl --silent http://10.0.0.22:30200/exporters | jq .
echo

# k8s registry / source
schemareg_test 10.0.0.22 30200
echo "---"

# VM registry / target
schemareg_test 10.0.0.50 8081