---
name: k8s-troubleshooting
description: Triage failing OpenShift / Kubernetes pods and deployments — decision tree for Pending / CrashLoopBackOff / ImagePullBackOff / OOMKilled / unreachable services, with the exact oc/kubectl commands to confirm each cause. Use when a deployment is stuck or a pod keeps restarting.
---

# Kubernetes / OpenShift triage

A deterministic decision tree for the five common failure modes. Run the **confirmation command** for the symptom you observe; the output disambiguates the root cause.

## When to use this skill

- A pod is in a non-Ready state and you don't know why yet.
- A service is up but clients can't reach it.
- A Helm release deployed but pods are crashing.
- A user asks DevOpsPilot for help and the diagnosis isn't obvious.

## Decision tree

```
Pod not running?
├─ Status: Pending
│   └─ oc describe pod <name>  → Events
│       ├─ "0/N nodes are available: insufficient memory/cpu" → bump cluster or lower requests
│       ├─ "node selector"                                     → fix nodeSelector / taints
│       ├─ "PersistentVolumeClaim is not bound"                → check PVC + StorageClass
│       └─ "Failed to pull image"                              → see ImagePullBackOff branch
├─ Status: CrashLoopBackOff
│   └─ oc logs <pod> --previous   (logs from the crashed container, not the new one)
│       ├─ Stack trace            → fix code; check config (env, configmaps, secrets)
│       ├─ "Cannot connect to ..."→ dependency not reachable; check NetworkPolicy
│       └─ Exits 0 immediately    → process completes too fast; check command/args
├─ Status: ImagePullBackOff
│   └─ oc describe pod <name>  → Events.Reason
│       ├─ "manifest unknown"     → tag does not exist in registry
│       ├─ "unauthorized"         → registry pull-secret missing or expired
│       └─ "no such host"         → registry URL typo or DNS failure
├─ Status: CreateContainerConfigError
│   └─ oc describe pod <name>  → Events
│       ├─ "secret X not found"     → create the secret
│       └─ "configmap Y not found"  → create the configmap
└─ Status: OOMKilled (Last State: Terminated, Reason: OOMKilled)
    └─ Two fixes (in order):
        1. raise memory limit if app actually needs it
        2. fix the leak — check heap, unbounded caches, large in-memory parses

Service unreachable?
├─ oc get endpoints <svc>           → empty? labels don't match
├─ oc get svc <svc> -o yaml         → port name in svc must match port name in pod
├─ oc get networkpolicy             → policy may be blocking traffic
└─ For Routes: oc get route <name>  → check TLS mode + target port name
```

## Universal first-look commands

```bash
# Pod status across the namespace
oc get pods -o wide

# Recent events sorted (most useful single command for "what just broke?")
oc get events --sort-by=.lastTimestamp | tail -30

# What the scheduler / kubelet said about this pod
oc describe pod <pod-name>

# Logs — current and previous container
oc logs <pod-name> --tail=200
oc logs <pod-name> --previous --tail=200

# Resource pressure on nodes / pods
oc adm top nodes
oc adm top pods

# Live shell inside the pod (or a debug copy if it crashes too fast)
oc rsh <pod-name>
oc debug deployment/<name>

# Helm side
helm list -A
helm history <release>
helm get values <release>
helm template <chart> --values values-dev.yaml --debug
```

## Hard rules

- **Never** suggest removing a resource limit as a fix. Adjust it; don't remove it.
- **Always** set both `requests` and `limits` for memory and CPU. Unset `requests` = bad scheduling. Unset `limits` = noisy neighbour risk.
- Probes: a `livenessProbe` that fails restarts the pod — make sure the probe doesn't depend on a slow dependency, or you create a CrashLoop on a downstream blip. `readinessProbe` is the right place for dependency checks.
- Use `oc` for OpenShift, `kubectl` for vanilla K8s. Both work, but `oc` exposes Routes / SCCs / project commands that `kubectl` doesn't.
- For Helm: validate locally with `helm template ... --debug` before suggesting `helm upgrade`.
