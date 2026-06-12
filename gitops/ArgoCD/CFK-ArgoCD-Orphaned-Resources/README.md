# CFK KafkaTopics + ArgoCD: Orphaned-Resource Cleanup

ArgoCD v3.0+ does not prune Confluent for Kubernetes (CFK) `KafkaTopic`
resources when they are removed from Git. They become **orphaned** — left in the
cluster, still backed by a topic in the Kafka broker. This repo documents the bug
and ships working cleanup solutions for every rendering style (Kustomize, Helm,
plain directory, single-repo, and multi-repo).

- **New here?** Read [The Problem](#the-problem).
- **Want to deploy?** Jump to [Quick Start](#quick-start) and pick the
  [solution](#the-solutions) that matches how you render manifests.
- **Debugging?** See [Troubleshooting](#troubleshooting).

---

## The Problem

**Confirmed:** ArgoCD v3.4.3 (regression from v2.14.x).
**Upstream:** [argoproj/argo-cd#23687](https://github.com/argoproj/argo-cd/issues/23687).

When a `KafkaTopic` is removed from Git, ArgoCD stops tracking it but **never
sends a delete**:

| Step | Expected | Actual |
|------|----------|--------|
| Detect removal during sync | ✅ | ✅ |
| Remove from `.status.resources[]` | ✅ | ✅ (stops tracking) |
| Create a prune task | ✅ | ❌ **never created** |
| Send DELETE to Kubernetes | ✅ | ❌ never sent |
| Resource removed from cluster | ✅ | ❌ orphaned |
| Report "Synced" | ✅ | ✅ (incorrectly) |

### Why it happens

CFK `KafkaTopic` resources carry two things ArgoCD's v3.0+ sync planner trips on:

- a finalizer: `kafkatopic.finalizers.platform.confluent.io`
- owner references with `blockOwnerDeletion: true` (Kafka → KafkaTopic)

The planner silently **skips creating the prune task** for such resources. Because
no prune task is ever created, `PrunePropagationPolicy=background` and
`prune: true` have nothing to act on — they are not the fix.

### What is NOT broken

Kubernetes deletion, the CFK finalizer, and owner references all work correctly.
Manual deletion succeeds in seconds:

```bash
kubectl delete kafkatopic topic-b -n confluent --cascade=background   # ~2s ✅
```

The problem is 100% that ArgoCD never *attempts* deletion. Every solution below is
just "detect the orphans ArgoCD left behind, and delete them ourselves."

### `ignoreDifferences` is still worth keeping

It does not fix pruning, but it prevents ArgoCD from flapping on the CFK-managed
owner references:

```yaml
ignoreDifferences:
- group: platform.confluent.io
  kind: KafkaTopic
  jsonPointers:
  - /metadata/ownerReferences
```

---

## How the Cleanup Works

A small Job (kubectl + jq) compares two lists and deletes the difference:

1. **Tracked** — what the ArgoCD Application currently lists in
   `.status.resources[]`.
2. **In cluster** — every `KafkaTopic` carrying this app's
   `argocd.argoproj.io/tracking-id` annotation.
3. **Orphans** = in cluster − tracked → `kubectl delete kafkatopic
   --cascade=foreground`.

The same script body is shared by every variant (PostSync hook, CronJob, Helm). It
is POSIX-sh, runs on `alpine/k8s:1.28.13`, and auto-installs `jq` if missing.
RBAC needed: `get/list applications`, `get/list/delete kafkatopics`.

---

## The Solutions

Pick by how you render manifests and where the hook lives. **All four rows are
provided as working examples.**

| Your setup | Solution | Trigger | Example |
|---|---|---|---|
| Kustomize, hook in topics repo | PostSync hook, **fixed name + `HookSucceeded`** | every sync | `examples/kustomize/`, `examples/argocd/cleanup-hook-job.yaml` |
| Kustomize, want it decoupled | **CronJob** (fixed name; controller names the Jobs) | schedule | `examples/argocd/cleanup-cronjob.yaml`, `examples/helm` (cronjob mode) |
| Helm, hook in topics repo | PostSync hook, **`generateName`** | every sync | `examples/helm/` (hook mode) |
| Hook in a **separate** repo | **Multi-source** Application (topics + Helm chart) | every sync | `examples/argocd/application-multisource.yaml` |

### Decision: why these and not the obvious alternatives

**Why not just `generateName` everywhere?**
`generateName` is the cleanest way to make a hook run every sync (each sync gets a
fresh, uniquely-named Job). It works under **Helm** and **plain directory** mode.
It does **not** work under **Kustomize** — `kustomize build` rejects it:

```
error: ... missing metadata.name in object {{batch/v1 Job} ...}; file is not directory
```

Kustomize's resource-identity model requires a fixed `name`. So Kustomize users
need a different trick.

**Why fixed name + `HookSucceeded` (and NOT `BeforeHookCreation`) for Kustomize?**
With a fixed name, the hook Job's name is reused every sync, so ArgoCD must delete
the previous Job before creating the new one. The default `BeforeHookCreation`
delete policy deletes the old Job *asynchronously* and immediately tries to create
the new one → race → `Job already exists`, and the hook appears to "only run once."
`HookSucceeded` deletes the Job right after it succeeds, so the next sync starts
clean. This is the fix for the common "hook runs once" symptom.

**Why offer a CronJob at all?**
A CronJob has a fixed name (Kustomize-friendly) and the controller generates unique
Job names, so it sidesteps both the generateName and the name-collision problems.
It is **decoupled from sync**: it reconciles orphans on a schedule, so it still
cleans up even if a sync is missed or the hook fails. Trade-off: cleanup latency =
the schedule interval (default 5 min).

**Why multi-source instead of copying the hook into the topics repo?**
A [multi-source Application](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
(ArgoCD v2.6+) renders several `spec.sources[]` together. You keep the cleanup
chart in its own repo and ArgoCD still applies its PostSync hook on every sync of
the topics — no duplication into the topics repo. Because the hook source is a Helm
chart, `generateName` works there.

**Note on standalone `helm install` (hook mode):** if you `helm install` the chart
directly (not via an ArgoCD Application), the PostSync hook has no ArgoCD sync to
fire it, so it runs once at install and never again. For standalone use, choose
**cronjob mode** instead.

---

## Quick Start

### 1. Deploy RBAC once (cluster-wide)

```bash
kubectl apply -f examples/argocd/cleanup-hook-rbac.yaml
```

Creates ServiceAccount `argocd-orphan-cleanup` + ClusterRole + binding.

### 2. Choose and deploy a solution

<details>
<summary><b>Kustomize — PostSync hook (hook in your topics repo)</b></summary>

Add the hook to your kustomization (fixed name + `HookSucceeded` is already set in
the example):

```yaml
# kustomization.yaml
resources:
- hooks/cleanup-hook.yaml   # from examples/kustomize/hooks/
- topics/topic-a.yaml
```

Customize `APP_NAME` / `TARGET_NAMESPACE` env in the hook. See
`examples/kustomize/` for a complete, buildable layout
(`kubectl kustomize examples/kustomize` renders clean).
</details>

<details>
<summary><b>Helm — PostSync hook or CronJob</b></summary>

```bash
# Hook mode (default; runs every ArgoCD sync via generateName)
helm install orphan-cleanup ./examples/helm \
  --set config.appName=topic-purge \
  --set config.targetNamespace=confluent

# CronJob mode (decoupled, periodic — good for standalone installs)
helm install orphan-cleanup ./examples/helm \
  --set hook.enabled=false --set cronjob.enabled=true \
  --set config.appName=topic-purge

# Both at once (hook = immediate after sync; CronJob = periodic safety net)
helm install orphan-cleanup ./examples/helm \
  --set hook.enabled=true --set cronjob.enabled=true \
  --set config.appName=topic-purge

# RBAC already in cluster? Don't recreate it:
helm install orphan-cleanup ./examples/helm \
  --set serviceAccount.create=false \
  --set serviceAccount.name=argocd-orphan-cleanup
```

Render locally: `helm template t ./examples/helm` (add
`--set cronjob.enabled=true` for the CronJob).

`helm lint` warns that the hook Job's `metadata.name` is empty — that is the
intentional `generateName`; ignore it.

Key values: `image` (default `alpine/k8s:1.28.13`), `namespace` (`argocd`),
`serviceAccount.{create,name}`, `config.{appName,appNamespace,targetNamespace,dryRun}`,
`hook.{enabled,deletePolicy,ttlSecondsAfterFinished}`,
`cronjob.{enabled,schedule,ttlSecondsAfterFinished}`.
</details>

<details>
<summary><b>CronJob — standalone (no Helm, Kustomize-friendly)</b></summary>

```bash
kubectl apply -f examples/argocd/cleanup-cronjob.yaml   # edit APP_NAME/namespace first
```

Default schedule `*/5 * * * *`, `concurrencyPolicy: Forbid`.
</details>

<details>
<summary><b>Multi-source — hook in a separate repo</b></summary>

Use `examples/argocd/application-multisource.yaml`: one Application with two
`spec.sources[]` (your topics repo + this repo's `examples/helm` chart). Edit the
`repoURL`s and the Helm `values`, then apply it.
</details>

### 3. Verify

```bash
# Find orphans ArgoCD left behind
kubectl get kafkatopic -n confluent -o json | jq -r \
  '.items[] | select(.metadata.annotations."argocd.argoproj.io/tracking-id") | .metadata.name'

# Watch the cleanup Job logs
kubectl logs -n argocd -l app=argocd-orphan-cleanup --tail=100
```

---

## Examples Index

```
examples/
├── argocd/
│   ├── cleanup-hook-rbac.yaml                       # RBAC — deploy once ⭐
│   ├── cleanup-hook-job.yaml                        # Directory/Kustomize hook (fixed name + HookSucceeded)
│   ├── cleanup-cronjob.yaml                         # Standalone CronJob
│   ├── application-multisource.yaml                 # Hook in a separate repo ⭐
│   ├── application-with-cleanup-hook.yaml           # Directory mode Application
│   ├── application-with-cleanup-hook-kustomize.yaml # Kustomize mode Application
│   ├── application.yaml / applicationset.yaml       # Basic references
│   ├── helm-values.yaml                             # Helm values reference
│   └── pre-delete-hook.yaml                         # Does NOT work — reference only (see note below)
├── helm/                                            # Helm chart: hook OR cronjob mode
│   ├── Chart.yaml, values.yaml
│   └── templates/{_helpers.tpl,rbac.yaml,cleanup-hook.yaml,cleanup-cronjob.yaml}
├── kustomize/                                        # Buildable Kustomize layout
│   ├── kustomization.yaml
│   ├── hooks/cleanup-hook.yaml
│   └── topics/topic-a.yaml
└── kafkatopics/                                      # Sample KafkaTopic CRs
    ├── basic-topic.yaml, compacted-topic.yaml, with-restclass.yaml
```

**`pre-delete-hook.yaml` does not work** and is kept only as a reference: a
PreDelete/pre-prune hook never fires, because ArgoCD never creates the prune task
in the first place (that *is* the bug).

---

## Troubleshooting

**Hook only runs on the first sync (Kustomize / fixed name).**
Cause: `hook-delete-policy: BeforeHookCreation` races (async delete + immediate
create → `Job already exists`). Fix: use `HookSucceeded` (already set in the
examples). Do not switch to `generateName` under Kustomize — `kustomize build`
rejects it.

**`kustomize build` fails: `missing metadata.name ... file is not directory`.**
The hook uses `generateName`. Kustomize requires a fixed `name`. Use the fixed-name
hook (`examples/kustomize/hooks/cleanup-hook.yaml`) or switch to Helm/CronJob.

**Topic removed from Git but nothing gets deleted.**
Expected — that is the bug. `prune: true` will not delete CFK topics. Confirm a
cleanup hook/CronJob is actually deployed and that its `APP_NAME` /
`TARGET_NAMESPACE` match your Application and topic namespace.

**Hook runs but finds no orphans.**
Check the `tracking-id` annotation matches your app name, and that RBAC allows
`get/list applications` and `get/list/delete kafkatopics`. Run with `DRY_RUN=true`
to log without deleting.

**Standalone `helm install` hook never re-runs.**
Hook mode needs an ArgoCD sync to fire it. For standalone installs use cronjob
mode.

**Image / shell issues.**
The script is POSIX-sh on `alpine/k8s:1.28.13` (busybox ash). It auto-installs
`jq`. Avoid bash-only syntax if you swap the image.

---

## CFK Operator Notes

For deletion to fully clean up the broker topic, the CFK operator must process the
`kafkatopic.finalizers.platform.confluent.io` finalizer during deletion. The
cleanup Job deletes with `--cascade=foreground --timeout=60s` so the finalizer has
time to run. If the operator is unhealthy, the CR may hang in `Terminating` — check
the operator before assuming the Job failed.

---

## References

- Upstream bug: [argoproj/argo-cd#23687](https://github.com/argoproj/argo-cd/issues/23687)
- [ArgoCD Sync Options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [ArgoCD Multiple Sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
- [Kubernetes Garbage Collection](https://kubernetes.io/docs/concepts/architecture/garbage-collection/)
