---
name: "DebugError"
description: "Paste an error/stack trace — get root cause and fix"
argument-hint: "stack trace + where it happened (API call, test, deployment)"
agent: "ask"
tools: ['codebase', 'usages', 'problems']
---

Debug this error and find the fix.

## Error
```
${input:error:Paste the full error message or stack trace}
```

## Context
${input:context:Where did this happen? (API call, unit test, deployment, etc.)}

## Instructions
1. Parse the stack trace — identify the exception type, message, and source location
2. Search the codebase for the failing method/class
3. Trace the call chain to find the root cause
4. Check for common patterns: null reference, missing config, async issues, DB errors
5. Propose a specific fix with code

## Output Format
- **Error**: [type]: [message]
- **Source**: [file:line]
- **Root Cause**: [why this happens]
- **Fix**: [exact code change]
- **Prevention**: [how to avoid in the future]
