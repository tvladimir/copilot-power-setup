# Helm / OpenShift Deployment

## Stack
- Helm 3 charts
- OpenShift 4.x (OKD / OCP)
- Container images: Docker / Podman

## Commands
- Lint: `helm lint chart/`
- Render: `helm template chart/ -f chart/values-dev.yaml`
- Diff: `helm diff upgrade <release> chart/ -f chart/values-prod.yaml`
- Validate K8s schema: `kubeconform -strict chart/`
- OpenShift logs: `oc logs <pod>` / `oc logs <pod> --previous`
- OpenShift events: `oc get events --sort-by=.lastTimestamp`

## Chart layout
```
chart/
  Chart.yaml
  values.yaml
  values-dev.yaml
  values-staging.yaml
  values-prod.yaml
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    route.yaml
    configmap.yaml
    hpa.yaml
```

## Rules
- Always set BOTH resource requests AND limits (Why: missing limits cause noisy-neighbour cluster issues)
- Always include readiness AND liveness probes
- Use `_helpers.tpl` for `chart.fullname`, `chart.labels`
- Env-specific values live in `values-{env}.yaml` — NOT in templates
- Reference secrets via ExternalSecrets / SealedSecrets — never plaintext in `values.yaml`
- Guard optional resources with `{{- if .Values.feature.enabled }}`
- Quote numeric strings used as labels

## Reference snippets
```yaml
resources:
  requests: { cpu: 100m, memory: 256Mi }
  limits:   { cpu: 500m, memory: 512Mi }

readinessProbe:
  httpGet: { path: /health/ready, port: 8080 }
  initialDelaySeconds: 10
  periodSeconds: 5

livenessProbe:
  httpGet: { path: /health/live, port: 8080 }
  initialDelaySeconds: 30
  periodSeconds: 10

securityContext:
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

## Don'ts
- Don't hardcode image tags — pass via `--set image.tag=...` or values overlay
- Don't omit `securityContext.runAsNonRoot: true`
- Don't skip `helm lint` / `helm template --debug` before deploying
- Don't disable resource limits as a "fix" for OOMKilled — increase the limit (Why: removing limits hides the real memory leak)
- Don't put cluster-specific URLs / paths in templates — keep them in env values
- Don't use `latest` image tag in any environment
