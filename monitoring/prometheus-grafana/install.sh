#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_DIR="${1:-./dashboards}"
NAMESPACE="${NAMESPACE:-monitoring}"

# Helm Repo Setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create Namespace and deploy Prometheus and Grafana
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Update and create dashbaords from JMX monitoring stacks
./update-dashboards.sh

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --values values-prometheus.yaml \
  --namespace ${NAMESPACE} \
  --wait

echo "---"
echo "Installing PodMonitor..."
kubectl apply -f podmonitor-confluent.yaml

echo "---"
echo "Creating Grafana dashboards:"
for f in ${DASHBOARD_DIR}/*.json; do
  name="grafana-$(jq -r '.title' "$f" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  kubectl create configmap "$name" -n "$NAMESPACE" --from-file="$f" --dry-run=client -o yaml \
    | kubectl apply --server-side --force-conflicts -f -
  kubectl label configmap "$name" -n ${NAMESPACE} grafana_dashboard=1 --overwrite
done

echo "---"
echo "Grafana credentials:"
kubectl get secret prometheus-grafana -n ${NAMESPACE} -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl get secret prometheus-grafana -n ${NAMESPACE} -o jsonpath='{.data.admin-password}' | base64 -d; echo
