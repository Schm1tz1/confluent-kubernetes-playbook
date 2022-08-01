# Example Setup for Schema Linking

## Setup your clusters

### Option 1: Have a source cluster running and add a minimal target cluster
* crerate namespace: `kubectl create namespace confluent-target`
* (maybe) upgrade CFK to also deploy on new namespace `confluent-target` if not alredy done or using `namespaced=false` already:
```
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set namespaceList="{confluent,confluent-target}" \
  --namespace confluent \
  --set namespaced=true
```
* deploy minimal cluster: `kubectl apply -f confluent-platform-target.yaml`

### Option 2: Deploy both minimal source and target clusters
* crerate namespaces: 
```
kubectl create namespace confluent
kubectl create namespace confluent-target
```
* deploy operator if not yet done:
```
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set namespaced=false \
  --namespace confluent
```
* deploy clusters:
```
kubectl apply -f confluent-platform-schemalink.yaml
```

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
