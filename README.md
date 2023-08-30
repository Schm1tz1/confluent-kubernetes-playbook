# Confluent for Kubernetes (CFK) Examples Playbook

* lots of general examples: https://github.com/vdesabou/kafka-docker-playground


## Example Directories
* **cp-plaintext** - Minimalistic setup of plaintext CP on k8s
* **cp-sasl-ldap*** - LDAP AuthN callback example
* **hybrid** - (Cloud-)hybrid setups, e.g. self-managed connect
* **kraft** - KRaft-based examples
* **cluster-linking** - Cluster linking
* **schema-linking** - Schema exporter tests

* **connect** - Connector examples
* **ksqldb** - ksqldb examples
* **clients** - Example client applications
* **datadog** - Datadog integration
* **tools** - Tools for testing, e.g. containers with kcat and networking tools

## Adding your license

* Option 1 - Add license as a kubernetes secret
```
echo -n "license=<paste your key here>" > license.txt
kubectl create secret generic confluent-license \
  --from-file=license.txt=./license.txt \
  --namespace confluent
```
and reference in spec.license for each relevant component:
```
license:
  secretRef: confluent-license
```
* Option 2 - Add a global license   
```
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --namespace confluent \
  --set licenseKey=<paste your key here>
```
and reference in spec.license:
```
license:
    globalLicense: true
```
