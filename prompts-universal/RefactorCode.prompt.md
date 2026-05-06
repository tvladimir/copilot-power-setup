---
name: "RefactorCode"
description: "Refactor code: improve quality without changing behavior"
argument-hint: "code to refactor + goal (readability / perf / testability / DRY)"
agent: "agent"
tools: ['codebase', 'usages', 'editFiles']
---

Refactor this code to improve quality.

## Code
```
${input:code:Paste code to refactor}
```

## Goal
${input:goal:What to improve (readability, performance, testability, DRY, etc.)}

## Rules
- Do NOT change external behavior
- Search for all usages before renaming
- Keep the same public API unless explicitly asked to change it
- Show before/after diff
- Explain each change and WHY it improves the code
