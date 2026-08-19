#!/bin/bash
OUTPUT_DIR=dashboards
INPUT_JMX_BASE=${HOME}/workspace/jmx-monitoring-stacks/jmxexporter-prometheus-grafana

mkdir -p $OUTPUT_DIR
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/zookeeper-cluster.json > $OUTPUT_DIR/zookeeper-cluster.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/Instance/Pod/g;s/instance/pod/g;s/kafka-broker/kafka/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-cluster.json > $OUTPUT_DIR/kafka-cluster.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/instance/pod/g;s/kafka-broker/kafka/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-topics.json > $OUTPUT_DIR/kafka-topics.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/Instance/Pod/g;s/instance/pod/g;s/kafka-broker/kafka/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-quotas.json > $OUTPUT_DIR/kafka-quotas.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/instance/pod/g;s/schema-registry/schemaregistry/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/schema-registry-cluster.json > $OUTPUT_DIR/schema-registry-cluster.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/Instance/Pod/g;s/instance/pod/g;s/kafka-connect/connect/g;s/kafka_connect_cluster_id/container/g;s/label_values(container)/label_values(kafka_connect_app, container)/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-connect-cluster.json > $OUTPUT_DIR/kafka-connect-cluster.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/Instance/Pod/g;s/instance/pod/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/ksqldb-cluster.json > $OUTPUT_DIR/ksqldb-cluster.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/instance/pod/g;s/Hostname/Pod/g;s/hostname/pod/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-producer.json > $OUTPUT_DIR/kafka-producer.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/instance/pod/g;s/Hostname/Pod/g;s/hostname/pod/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kafka-consumer.json > $OUTPUT_DIR/kafka-consumer.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/Instance/Pod/g;s/instance/pod/g;s/kafka-broker/kafka/g;s/schema-registry/schemaregistry/g;s/kafka-connect/connect/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/confluent-platform.json > $OUTPUT_DIR/confluent-platform.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/instance/pod/g;s/kafka-broker/kafka/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/cluster-linking.json > $OUTPUT_DIR/cluster-linking.json
sed 's/\${Prometheus}//g;s/Environment/Namespace/g;s/env/namespace/g;s/label_values(namespace)/label_values(jmx_exporter_build_info, namespace)/g;s/Instance/Pod/g;s/instance/pod/g;s/kafka-broker/kafka/g;s/kafka-controller/kraftcontroller/g' ${INPUT_JMX_BASE}/assets/grafana/provisioning/dashboards/kraft.json > $OUTPUT_DIR/kraft.json

# Tag all generated dashboards as "CP"
for f in $OUTPUT_DIR/*.json; do
  jq '.tags = ((.tags // []) + ["CP"] | unique)' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
