#!/usr/bin/env bash
set -euo pipefail

kubectl create configmap "grafana-kafka-txn" -n "monitoring" --from-file="DashboardTxn.json" --dry-run=client -o yaml \
    | kubectl apply --server-side --force-conflicts -f -

kubectl label configmap "grafana-kafka-txn" -n "monitoring" grafana_dashboard=1 --overwrite
