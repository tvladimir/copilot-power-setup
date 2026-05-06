---
name: "ExplainCode"
description: "Explain code: what it does, why, how, potential issues"
argument-hint: "paste the code (or use #selection to pull from the editor)"
agent: "ask"
tools: ['codebase', 'usages']
---

Explain this code clearly and thoroughly.

```
${input:code:Paste the code to explain}
```

## Provide
1. **Summary** — one sentence: what does this code do?
2. **Step-by-step** — walk through the logic
3. **Key patterns** — design patterns, idioms used
4. **Dependencies** — what external code/services it relies on
5. **Potential issues** — bugs, edge cases, performance concerns
6. **Usage** — how and where this is called (search the codebase)
