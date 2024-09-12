# Kafka-Performance Tests on k8s
* Adapt client configmap to your needs (brokers)
* Adapt testing script in configmap to your needs (records, size, grid scan step etc.)
* Adapta name/namespace to your needs
* Change job parametes e.g. number of tests to be run and parallelity of execution (see https://kubernetes.io/docs/concepts/workloads/controllers/job/):
```yaml
spec:
  completions: 1
  parallelism: 1
```
* Make sure that the topic is created
* Deploy job and watch logs:
```shell
kubectl apply -f producer-perf-test.yaml
kubectl logs jobs/producer-perf-test-job -n confluent
```
