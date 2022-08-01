# Example Setup for Schema Linking

## Setup minimal target cluster
* crerate namespace: `kubectl create namespace confluent-target`
* install CFK on new namespace `confluent-target`:
```
helm upgrade --install confluent-operator \
    confluentinc/confluent-for-kubernetes \
    --namespace confluent-target
```
* deploy minimal cluster: `kubectl apply -f cp-schemareg-target.yaml`

## Simple schema linking test
* Install the schema exporter or source schema registry: `kubectl apply -f schemaExporter.yaml`
* Run test script on schemareg container to display exporters and schemas: `./run-test.sh`. You will see the exporter and its configuration and no subjects/schemas in target registry:
```
Exporters in source:
["schemaexporter"]
Exporter config:
{"name":"schemaexporter","subjects":[":*:"],"contextType":"CUSTOM","context":"exported","config":{"schema.registry.url":"http://schemaregistry.confluent-target.svc.cluster.local:8081"}}
Schemareg schemaregistry.confluent.svc.cluster.local contexts:
["."]
Schemareg schemaregistry.confluent.svc.cluster.local subjects:
[]
Schemareg schemaregistry.confluent.svc.cluster.local schemas:
[]
---
Schemareg schemaregistry.confluent-target.svc.cluster.local contexts:
["."]
Schemareg schemaregistry.confluent-target.svc.cluster.local subjects:
[]
Schemareg schemaregistry.confluent-target.svc.cluster.local schemas:
[]
```
* Create a schema in source schemaregistry: `kubectl apply -f createSchema.yaml`
* Re-run the test script `./run-test.sh` and find the new and also linked schema:
```
Exporters in source:
["schemaexporter"]
Exporter config:
{"name":"schemaexporter","subjects":[":*:"],"contextType":"CUSTOM","context":"exported","config":{"schema.registry.url":"http://schemaregistry.confluent-target.svc.cluster.local:8081"}}
Schemareg schemaregistry.confluent.svc.cluster.local contexts:
["."]
Schemareg schemaregistry.confluent.svc.cluster.local subjects:
["schema-example"]
Schemareg schemaregistry.confluent.svc.cluster.local schemas:
[{"subject":"schema-example","version":1,"id":1,"schema":"{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"}]}"}]
---
Schemareg schemaregistry.confluent-target.svc.cluster.local contexts:
[".",".exported"]
Schemareg schemaregistry.confluent-target.svc.cluster.local subjects:
[":.exported:schema-example"]
Schemareg schemaregistry.confluent-target.svc.cluster.local schemas:
[]
```
