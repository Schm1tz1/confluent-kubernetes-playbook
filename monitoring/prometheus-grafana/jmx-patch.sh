#!/usr/bin/env bash
set -uo pipefail

DEFAULT_CR_TYPES="kafkas,kraftcontrollers"
PATCH_FILE="${PATCH_FILE:-jmx-cp-patch.yaml}"

usage() {
    cat <<EOF
Usage: $0 <namespace> [cr_types]

  namespace   Kubernetes namespace
  cr_types    Comma-separated list of CR types, for example: kafkas,connects
              Use a comma as separator, not a space.
              Default: ${DEFAULT_CR_TYPES}

Environment:
  PATCH_FILE  Patch file to apply (default: jmx-kafka-patch.yaml)

Examples:
  $0 my-ns
  $0 my-ns kafkas,kraftcontrollers,connects
  PATCH_FILE=other.yaml $0 my-ns kafkas
EOF
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 1
fi

NAMESPACE="$1"
CR_TYPES_RAW="${2:-$DEFAULT_CR_TYPES}"

if [ ! -f "${PATCH_FILE}" ]; then
    echo "Patch file not found: ${PATCH_FILE}" >&2
    exit 1
fi

# Split on comma, trim spaces, skip empty entries
IFS=',' read -r -a RAW_TYPES <<< "${CR_TYPES_RAW}"
CR_TYPES=()
for t in "${RAW_TYPES[@]}"; do
    t="${t//[[:space:]]/}"
    [ -n "${t}" ] && CR_TYPES+=("${t}")
done

if [ "${#CR_TYPES[@]}" -eq 0 ]; then
    echo "No CR types given." >&2
    usage
    exit 1
fi

rc=0

for cr_type in "${CR_TYPES[@]}"; do
    echo "Patching ${cr_type}..."

    if ! names=$(kubectl get "${cr_type}" -n "${NAMESPACE}" -o json | jq -r '.items[].metadata.name'); then
        echo "  Failed to list ${cr_type} in ${NAMESPACE}" >&2
        rc=1
        continue
    fi

    if [ -z "${names}" ]; then
        echo "  No ${cr_type} found in namespace ${NAMESPACE}, skipping."
        continue
    fi

    while IFS= read -r name; do
        echo "  ${cr_type}/${name}"
        if ! kubectl patch "${cr_type}" "${name}" -n "${NAMESPACE}" \
                --patch-file "${PATCH_FILE}" --type=merge; then
            echo "  Failed to patch ${cr_type}/${name}" >&2
            rc=1
        fi
    done <<< "${names}"
done

exit "${rc}"

