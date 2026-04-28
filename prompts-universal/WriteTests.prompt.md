---
name: "WriteTests"
description: "Generate comprehensive tests for a function or class"
tools: ['codebase', 'editFiles', 'findTestFiles']
---

Generate tests for this code.

## Code to Test
```
${input:code:Paste the function or class to test}
```

## Framework
${input:framework:Test framework (xUnit, NUnit, Jest, Vitest, pytest)}

## Requirements
- Cover: happy path, edge cases, error handling
- Descriptive test names that explain what is being tested
- Arrange / Act / Assert pattern
- Mock external dependencies (DB, HTTP, file system)
- Each test independent — no shared mutable state
- Include boundary values: empty, null, zero, max, negative
