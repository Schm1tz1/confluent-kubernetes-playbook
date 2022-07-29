# Confluent for Kubernetes (CFK) Examples Playbook

* lots of general examples: https://github.com/vdesabou/kafka-docker-playground


## Example Directories
* **cp-plaintext** - minimalistic setup of plaintext CP on k8s
* **schema-linking** - schema exporter tests
* **connect** - connector examples
* **ksqldb** - ksqldb examples
* **datadog** - datadog integration

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
