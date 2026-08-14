#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-confluent}"
LABEL_SELECTOR="app=kafka"
EXEC_POD="kafka-0"
BOOTSTRAP="localhost:9092"

DEBUG_LOGGERS="kafka.coordinator.transaction.TransactionCoordinator=DEBUG,kafka.coordinator.transaction.TransactionStateManager=DEBUG,kafka.server.KafkaApis=DEBUG,kafka.request.logger=INFO,kafka.coordinator.group.GroupCoordinator=DEBUG"
LOGGER_NAMES="kafka.coordinator.transaction.TransactionCoordinator,kafka.coordinator.transaction.TransactionStateManager,kafka.server.KafkaApis,kafka.request.logger,kafka.coordinator.group.GroupCoordinator"

SNAPSHOT_DIR="./broker-logger-snapshots"
mkdir -p "$SNAPSHOT_DIR"

get_broker_ids() {
  kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath='{.items[*].metadata.name}' \
    | tr ' ' '\n' \
    | sed 's/.*-//'
}

run_admin() {
  local cmd="$1"
  kubectl exec -n "$NAMESPACE" "$EXEC_POD" -- bash -c "$cmd"
}

snapshot() {
  echo "Snapshotting current broker-logger levels..."
  for broker_id in $(get_broker_ids); do
    echo "  broker-id=$broker_id"
    run_admin "kafka-configs --bootstrap-server $BOOTSTRAP \
      --describe --entity-type broker-loggers --entity-name $broker_id" \
      > "$SNAPSHOT_DIR/broker-${broker_id}.before"
  done
  echo "Snapshots saved to $SNAPSHOT_DIR/"
}

apply_debug() {
  echo "Applying DEBUG logger levels to all brokers..."
  for broker_id in $(get_broker_ids); do
    echo "  broker-id=$broker_id"
    run_admin "kafka-configs --bootstrap-server $BOOTSTRAP \
      --alter --entity-type broker-loggers --entity-name $broker_id \
      --add-config '$DEBUG_LOGGERS'"
  done
}

revert() {
  echo "Reverting broker-logger levels from snapshot..."
  for broker_id in $(get_broker_ids); do
    local snap_file="$SNAPSHOT_DIR/broker-${broker_id}.before"
    if [[ ! -f "$snap_file" ]]; then
      echo "  broker-id=$broker_id: no snapshot found, skipping (delete-config instead)"
      run_admin "kafka-configs --bootstrap-server $BOOTSTRAP \
        --alter --entity-type broker-loggers --entity-name $broker_id \
        --delete-config '$LOGGER_NAMES'"
      continue
    fi

    echo "  broker-id=$broker_id"
    local restore_pairs=()
    local delete_names=()

    IFS=',' read -ra loggers <<< "$LOGGER_NAMES"
    for logger in "${loggers[@]}"; do
      local prior_val
      prior_val=$(grep -oP "(?<=${logger}=)[A-Z]+" "$snap_file" || true)
      if [[ -n "$prior_val" ]]; then
        restore_pairs+=("${logger}=${prior_val}")
      else
        delete_names+=("$logger")
      fi
    done

    if [[ ${#restore_pairs[@]} -gt 0 ]]; then
      local add_str
      add_str=$(IFS=,; echo "${restore_pairs[*]}")
      run_admin "kafka-configs --bootstrap-server $BOOTSTRAP \
        --alter --entity-type broker-loggers --entity-name $broker_id \
        --add-config '$add_str'"
    fi

    if [[ ${#delete_names[@]} -gt 0 ]]; then
      local del_str
      del_str=$(IFS=,; echo "${delete_names[*]}")
      run_admin "kafka-configs --bootstrap-server $BOOTSTRAP \
        --alter --entity-type broker-loggers --entity-name $broker_id \
        --delete-config '$del_str'"
    fi
  done
}

case "${1:-}" in
  snapshot) snapshot ;;
  apply)    apply_debug ;;
  revert)   revert ;;
  all)      snapshot; apply_debug ;;
  *)
    echo "Usage: NAMESPACE=<namespace> $0 {snapshot|apply|revert|all}"
    echo "  NAMESPACE defaults to 'confluent' if not set"
    exit 1
    ;;
esac
