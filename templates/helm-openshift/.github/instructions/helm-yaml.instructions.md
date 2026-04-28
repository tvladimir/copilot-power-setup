---
applyTo: "**/*.yaml,**/*.yml,**/*.tpl"
---
# Helm Template Rules

## Syntax
- Use `{{-` and `-}}` to trim whitespace
- Quote strings: `{{ .Values.image.tag | quote }}`
- Default values: `{{ .Values.replicas | default 1 }}`
- Required values: `{{ required "image.repository is required" .Values.image.repository }}`

## Naming
- Template names: `{{ define "chart.labels" }}`
- Use `chart.fullname` for all resource names
- Labels: `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`

## Security
- Never put secrets in values.yaml — use ExternalSecret or SealedSecret
- Set `securityContext.runAsNonRoot: true`
- Drop all capabilities: `drop: ["ALL"]`
- Read-only root filesystem where possible

## Common Mistakes to Avoid
- Missing `---` between multiple documents
- Incorrect indentation (YAML is 2-space)
- Using `{{ .Values.x }}` without default when value might not exist
- Forgetting to quote numeric strings used as labels
