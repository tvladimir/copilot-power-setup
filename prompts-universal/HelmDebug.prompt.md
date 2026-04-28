---
name: "HelmDebug"
description: "Debug Helm chart or OpenShift deployment issue"
tools: ['runCommands', 'codebase', 'terminalLastCommand']
---

## Problem
${input:problem:Describe the deployment issue (pod crash, config error, etc.)}

## Error / Logs
```
${input:logs:Paste error messages, oc describe output, or helm output}
```

## Instructions
1. Parse the error to identify the root cause
2. Check Helm values, templates, and K8s manifests
3. Identify misconfiguration (resources, probes, secrets, configmaps)
4. Suggest fix with exact YAML changes
5. Provide verification commands
