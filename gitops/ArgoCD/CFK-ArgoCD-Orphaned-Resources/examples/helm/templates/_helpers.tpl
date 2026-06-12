{{/*
Shared pod spec for both the PostSync hook Job and the CronJob.
Included with `nindent` so the same container/script is reused in both modes.
*/}}
{{- define "cleanup.podSpec" -}}
serviceAccountName: {{ .Values.serviceAccount.name | quote }}
restartPolicy: Never
containers:
- name: cleanup-orphans
  image: {{ .Values.image | quote }}
  imagePullPolicy: {{ .Values.imagePullPolicy }}
  env:
  - name: APP_NAME
    value: {{ .Values.config.appName | quote }}
  - name: APP_NAMESPACE
    value: {{ .Values.config.appNamespace | quote }}
  - name: TARGET_NAMESPACE
    value: {{ .Values.config.targetNamespace | quote }}
  - name: RESOURCE_KIND
    value: {{ .Values.config.resourceKind | quote }}
  - name: DRY_RUN
    value: {{ .Values.config.dryRun | quote }}
  - name: LOG_TIMESTAMPS
    value: {{ .Values.config.logTimestamps | quote }}
  command:
  - /bin/sh
  - -c
  - |
    #!/bin/sh
    set -e

    log() {
      if [ "$LOG_TIMESTAMPS" = "true" ]; then
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*"
      else
        echo "$*"
      fi
    }

    log "=================================================="
    log "ArgoCD Orphan Cleanup"
    log "=================================================="
    log "Application: $APP_NAME (namespace: $APP_NAMESPACE)"
    log "Target: $RESOURCE_KIND resources in namespace: $TARGET_NAMESPACE"
    log "Dry Run: $DRY_RUN"
    log ""

    if ! command -v jq >/dev/null 2>&1; then
      log "Installing jq..."
      if ! apk add --no-cache jq >/dev/null 2>&1; then
        log "ERROR: Failed to install jq"
        exit 1
      fi
    fi

    log "Waiting 10 seconds for ArgoCD to update status..."
    sleep 10

    log "Fetching ArgoCD Application status..."
    APP_JSON=$(kubectl get application "$APP_NAME" -n "$APP_NAMESPACE" -o json 2>/dev/null || echo "")
    if [ -z "$APP_JSON" ]; then
      log "ERROR: Application $APP_NAME not found in namespace $APP_NAMESPACE"
      exit 1
    fi

    log "Extracting tracked resources..."
    TRACKED=$(echo "$APP_JSON" | jq -r \
      --arg kind "$RESOURCE_KIND" \
      '.status.resources[]? | select(.kind==$kind) | .name' | sort || echo "")

    if [ -z "$TRACKED" ]; then
      log "No $RESOURCE_KIND resources tracked by ArgoCD"
      TRACKED_COUNT=0
    else
      TRACKED_COUNT=$(echo "$TRACKED" | wc -l | tr -d ' ')
      log "ArgoCD is tracking $TRACKED_COUNT $RESOURCE_KIND resource(s):"
      echo "$TRACKED" | sed 's/^/  - /'
    fi
    log ""

    TRACKING_ID_PATTERN="$APP_NAME:"
    log "Fetching $RESOURCE_KIND resources from cluster..."
    ANNOTATED=$(kubectl get kafkatopic -n "$TARGET_NAMESPACE" -o json 2>/dev/null | \
      jq -r --arg pattern "$TRACKING_ID_PATTERN" \
      '.items[]? | select(.metadata.annotations."argocd.argoproj.io/tracking-id"? | contains($pattern)) | .metadata.name' | sort || echo "")

    if [ -z "$ANNOTATED" ]; then
      log "No $RESOURCE_KIND resources found with ArgoCD tracking annotation"
      log "Nothing to clean up"
      exit 0
    fi

    ANNOTATED_COUNT=$(echo "$ANNOTATED" | wc -l | tr -d ' ')
    log "Found $ANNOTATED_COUNT $RESOURCE_KIND resource(s) with ArgoCD tracking annotation:"
    echo "$ANNOTATED" | sed 's/^/  - /'
    log ""

    if [ -z "$TRACKED" ]; then
      ORPHANS="$ANNOTATED"
    else
      ORPHANS=$(comm -13 <(echo "$TRACKED") <(echo "$ANNOTATED") || echo "")
    fi

    if [ -z "$ORPHANS" ]; then
      log "✅ No orphaned resources found - all annotated resources are tracked by ArgoCD"
      exit 0
    fi

    ORPHAN_COUNT=$(echo "$ORPHANS" | wc -l | tr -d ' ')
    log "=================================================="
    log "⚠️  Found $ORPHAN_COUNT orphaned $RESOURCE_KIND resource(s):"
    log "=================================================="
    echo "$ORPHANS" | sed 's/^/  - /'
    log ""

    if [ "$DRY_RUN" = "true" ]; then
      log "DRY RUN MODE - Would delete the above resources"
      log "Set DRY_RUN=false to actually delete orphans"
      exit 0
    fi

    log "Deleting orphaned resources..."
    DELETED=0
    FAILED=0
    for topic in $ORPHANS; do
      log "Deleting: $topic"
      OUTPUT=$(kubectl delete kafkatopic "$topic" -n "$TARGET_NAMESPACE" \
        --cascade=foreground --timeout=60s 2>&1)
      EXIT_CODE=$?
      echo "$OUTPUT" | grep -v "reflector.go" | grep -v "Failed to watch" || true
      if [ $EXIT_CODE -eq 0 ]; then
        log "  ✅ Deleted successfully"
        DELETED=$((DELETED + 1))
      elif echo "$OUTPUT" | grep -q "timed out waiting"; then
        log "  ❌ Deletion timed out after 60s - CFK operator not processing finalizer!"
        log "     Check: kubectl logs -n confluent -l app=confluent-operator"
        FAILED=$((FAILED + 1))
      elif echo "$OUTPUT" | grep -q "not found"; then
        log "  ✅ Already deleted"
        DELETED=$((DELETED + 1))
      else
        log "  ❌ Failed to delete: $OUTPUT"
        FAILED=$((FAILED + 1))
      fi
    done

    log ""
    log "=================================================="
    log "Cleanup Summary"
    log "=================================================="
    log "Tracked by ArgoCD: $TRACKED_COUNT"
    log "Found in cluster:  $ANNOTATED_COUNT"
    log "Orphans detected:  $ORPHAN_COUNT"
    log "Successfully deleted: $DELETED"
    log "Failed to delete:     $FAILED"
    log "=================================================="

    if [ $FAILED -gt 0 ]; then
      log "⚠️  Some deletions failed - manual intervention may be required"
      exit 1
    fi
    log "✅ Cleanup completed"
{{- end -}}
