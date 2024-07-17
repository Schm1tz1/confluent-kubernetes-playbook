# Cluster Linking
Official Docs: https://docs.confluent.io/operator/current/co-link-clusters.html
This example convers a somewhat unusual setup of 2 CP cluster in the same namespace showing the possibilities of a topic mirroring/migration.

## General Setup
* Execute `./setup.sh` or follow steps below.

* Deploy clusters:
```shell
kubectl apply -f cp-source.yaml
kubectl apply -f cp-dest.yaml
```

* Create topic via CR:
```shell
kubectl apply -f topic.yaml
```
* Produce random data:
```shell
kubectl exec kcat -it -n confluent -- bash -c "cat /dev/urandom | \
  tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 666 | \
  kcat -b kafka:9071 -t test-topic -P"
```
## ClusterLink Setup with 2 Clusters in same namespace using ClusterLink-CR
* Start cluster link:
```shell
kubectl apply -f cluster-link.yaml
```

* Check topics in destination cluster:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-topics --bootstrap-server localhost:9071 --list
kubectl get kafkatopics -A -o wide
```

* Check mirror topic status:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-replica-status --topics test-topic --include-mirror --bootstrap-server localhost:9071
```
If there is no lag, promote the topic!

* Promote mirror topic:
```shell
kubectl apply -f cluster-link-promote.yaml
```

* Check topics:
```shell
$ kubectl get kafkatopics -A -o wide                                                           ~
NAMESPACE   NAME                        REPLICAS   PARTITION   STATUS    CLUSTERID                AGE     KAFKACLUSTER
confluent   clink-test-topic-5ede0ef2   1          6           CREATED   yGfY2iW8R4ysMkMJLN2hpw   3m31s
confluent   test-topic                  1          6           CREATED   ebAE9XJGS5-iVrJKvJX1-g   52m     confluent/kafka
```
Check details with `kubectl describe` or `kubectl get -o yaml`. Note the difference between CR name and topic name:
```yaml
apiVersion: platform.confluent.io/v1beta1
kind: KafkaTopic
metadata:
  ...
  name: clink-test-topic-5ede0ef2
  namespace: confluent
  ...
spec:
  configs:
    cleanup.policy: delete
    delete.retention.ms: "86400000"
    ...
  kafkaRestClassRef:
    name: kafka-new-rest
    namespace: confluent
  name: test-topic
  partitionCount: 6
  replicas: 1
status:
  ...
```

* Consume from old topic, then delete old topic, consume from new topic, verify deletion and compare:
```shell
$ kubectl exec kcat -n confluent -it -- kcat -b kafka:9092 -t test-topic -C -e >old.txt
$ kubectl delete -f topic.yaml
kafkatopic.platform.confluent.io "test-topic" deleted
$ kubectl get kafkatopics -A -o wide
NAMESPACE   NAME                        REPLICAS   PARTITION   STATUS    CLUSTERID                AGE   KAFKACLUSTER
confluent   clink-test-topic-5ede0ef2   1          6           CREATED   yGfY2iW8R4ysMkMJLN2hpw   12m
$ kubectl exec kcat -n confluent -it -- kcat -b kafka-new:9092 -t test-topic -C -e >new.txt
$ diff old.txt new.txt
```

## ClusterLink Setup with 2 Clusters in same namespace using ClusterLink-CLI
* Create manual Cluster Link and mirror topics:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-cluster-links --bootstrap-server localhost:9071 --create --link manual-link --config bootstrap.servers=kafka.confluent.svc.cluster.local:9071

kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-mirrors --create --mirror-topic test-topic --link manual-link --bootstrap-server localhost:9071
```
* List and check topics in destination cluster:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-topics --bootstrap-server localhost:9071 --list
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-topics --bootstrap-server localhost:9071 --describe --topic test-topic
```
* Check mirror topic status:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-replica-status --topics test-topic --include-mirror --bootstrap-server localhost:9071
```
If there is no lag, promote the topic!

* Promote mirror topic and check status:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-mirrors --promote --topics test-topic --bootstrap-server localhost:9071

kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-mirrors --describe --topics test-topic --pending-stopped-only --bootstrap-server localhost:9071
```

## Other helpful commands

* Create topic via CR:
```shell
kubectl apply -f topic.yaml
```

* Create topic manually:
```shell
kubectl exec kafka-0 -n confluent -it \
  -- kafka-topics --bootstrap-server localhost:9071 --create --topic test-topic
```
Note: (Re-)Creating an existing topic via CR apply will "import" it to the tracked CRs of the operator and won't delete ay existing topic.

* Check cluster links:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-cluster-links --list --bootstrap-server localhost:9071
```

* Check mirrors:
```shell
kubectl exec kafka-new-0 -n confluent -it \
  -- kafka-mirrors --list --bootstrap-server localhost:9071
```
