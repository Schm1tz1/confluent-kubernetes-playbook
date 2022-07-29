#!/usr/bin/env bash
set -e

# list exporters
echo "Exporters in source:"
curl --silent http://10.0.0.22:30200/exporters | jq .
echo "Config:"
curl --silent http://10.0.0.22:30200/exporters/schemaexporter | jq .
echo