# Confluent Tiered Storage

## Set Up S3-Compatible Storage

### MinIO
Quickstart:
```shell
helm repo add minio https://charts.min.io/
helm install minio minio/minio -n minio\
    --set resources.requests.memory=512Mi \
    --set replicas=1 --set persistence.enabled=false \
    --set mode=standalone \
    --set rootUser=rootuser,rootPassword=rootpass123 \
    --create-namespace
```
Create bucket in MinIO pod:
```shell
mc alias set self http://localhost:9000 rootuser rootpass123
mc mb self/cflt-tier
```
or simply `kubectl exec -it deploy/minio -n minio -- bash -c "mc alias set local http://localhost:9000 rootuser rootpass123 && mc mb local/cflt-tier"`

MinIO [region](https://docs.min.io/aistor/reference/cli/mc-mb/#--region) defaults to `us-east-1`, otherwise do `mc admin config get self region` to get the region config.

### SeaweedFS (to be tested)
* Public docs: https://github.com/seaweedfs/seaweedfs
* Examples based on [Blog Post](https://itnext.io/minio-alternative-seaweedfs-41fe42c3f7be):
```yaml 
# custom-values.yaml

master:
  enabled: true
  replicas: 3
  volumeSizeLimitMB: 30000
  data:
    type: "persistentVolumeClaim"
    size: "30G"
    storageClass: "local-path"

volume:
  enabled: true
  replicas: 3
  dataDirs:
    - name: data
      size: 30Gi
      type: "persistentVolumeClaim"
      storageClass: "local-path"
      maxVolumes: 100

filer:
  enabled: true
  replicas: 3
  enablePVC: true
  data:
    type: "persistentVolumeClaim"
    size: "10G"
    storageClass: "local-path"

s3:
  enabled: true
  replicas: 3
  port: 8333
  enableAuth: true

ingress:
  enabled: false

persistence:
  enabled: true
```

```shell
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm install --values=custom-values.yaml seaweedfs seaweedfs/seaweedfs
```

## Configure and Deploy CP
* Configure the secret:
```yaml
kind: Secret
metadata:
  name: tiered-storage-creds
(...)
stringData:
  storage-creds: 2ca3adb6-509e-41fa-b1ef-545eab5893e2
```
* Edit the connection details in Kafka CR:
```yaml
spec:
  (...)
  mountedSecrets:
    - secretRef: tiered-storage-creds
  configOverrides:
    server:
      - confluent.tier.feature=true
      - confluent.tier.enable=true
      - confluent.tier.backend=S3
      - confluent.tier.s3.bucket=my-bucket
      - confluent.tier.s3.region=us-west-2
      - confluent.tier.s3.cred.file.path=/mnt/secrets/tiered-storage-creds/storage-creds
    # For tiering of compact topics, activate below:
      # - confluent.tier.cleaner.feature.enable=true  
      # - confluent.tier.cleaner.enable=true
```
* Deploy:
```shell
kubectl apply -f cp_minio.yaml
```

## Performance Testing

* Create 2 topics for testing hot-cold storage:
```shell
kubectl apply -f topic-performance-cold.yaml
kubectl apply -f topic-performance-hot.yaml
```

* Produce to "cold" topic and wait until all data is in tiered storage (~30s):
```shell
KAFKA_TOPIC=performance-cold envsubst <perf-test-producer.yaml | kubectl apply -f -
```

* Produce to "hot" topic:
```shell
KAFKA_TOPIC=performance-hot envsubst <perf-test-producer.yaml | kubectl apply -f -
```

* Now run consumer tests to test throughput for hot (broker storage) and cold (tiered storage) topics - one job at a time:
```shell
# First as a baseline
KAFKA_TOPIC=performance-hot envsubst <perf-test-consumer.yaml | kubectl apply -f -

# Once finished, run from tired storage "cold" topic
KAFKA_TOPIC=performance-cold envsubst <perf-test-consumer.yaml | kubectl apply -f -
```
