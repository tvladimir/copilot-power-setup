---
name: log-analysis
description: Parse application logs (Serilog JSON, NLog, log4net, IIS/Kestrel, K8s structured) and walk an exception back to the line of code that caused it. Use when the user pastes a stack trace or points at a log file/pod and wants a root cause + fix.
---

# Log analysis & root-cause walk

A repeatable procedure for turning raw log output into a `file:line` fix. Works with the .NET log formats your stack uses plus generic structured logs.

## When to use this skill

- User pastes a stack trace.
- User points at a log file path or a `kubectl logs` / `oc logs` output.
- Error rate spiked and you need to figure out the dominant cause.
- A test failed in CI and the only signal is the log.

## Procedure

1. **Parse** — identify the log format from the first non-empty line (see "Format cheat-sheet"). Extract: timestamp, level, exception type, exception message, stack trace.
2. **Find the source** — search the codebase (`#codebase`) for the topmost user-frame in the stack trace. Skip framework frames (`System.*`, `Microsoft.*`, `Newtonsoft.*`).
3. **Trace the flow** — walk back through the stack: who calls the failing method? What inputs reach it? Does any caller pass null/empty/0?
4. **Check context** — recent commits to the same file (`git log -p file`), config files (`appsettings*.json`, `values*.yaml`), environment differences.
5. **Propose a fix** — specific code change with `file:line`. Then a **prevention** note: validation, defensive cast, retry policy, contract test.

## Format cheat-sheet

| Format | Recognise by | Key fields |
|---|---|---|
| **Serilog JSON** | `{"@t":"...","@l":"Error","@x":"...","@m":"..."}` | `@t` time, `@l` level, `@x` exception, `@m` message, `RequestId`, `SourceContext` |
| **NLog default** | `2026-01-01 12:00:00.000\|ERROR\|Namespace.Class\|message` | pipe-separated; class is the logger name |
| **log4net** | `2026-01-01 12:00:00,000 [thread] ERROR Logger - message` | thread name in brackets |
| **IIS / Kestrel stdout** | `info: Microsoft.AspNetCore...[0] message` | category and event id in brackets |
| **K8s structured** | JSON lines with `kubernetes.pod_name`, `stream: stdout/stderr` | wraps another format inside `log` field |
| **Plain console** | `[2026-01-01 12:00:00] ERROR: message` | regex-friendly |

## Output template

```
=== LOG ANALYSIS ===

Error:        [Type]: [message]
Source:       [file:line]
Frequency:    [N occurrences in T window]
First seen:   [timestamp]
Correlation:  [request id / trace id if present]

Root cause:
  [why this happens — concrete, not "something about nulls"]

Call chain:
  1. [Entry point]            (e.g. POST /api/orders)
  2. [Controller method]      (file:line)
  3. [Service method]         (file:line)
  4. [Failing call]           (file:line)  ← exception thrown here

Fix:
  [file:line — specific code change, with before/after if non-trivial]

Prevention:
  [validation at boundary / contract test / retry policy / config gate]

Impact:
  [what breaks, who is affected, severity]
```

## Hard rules

- Group multiple stack traces by **root frame** (innermost user code), not by exception type — same root = same fix.
- Don't guess. Read the file. If the stack trace points at a method that doesn't exist anymore, it's a stale build — say so.
- For correlation ID, prefer `RequestId` / `trace_id` / `traceparent` over PID or timestamp.
- Severity ranking: BLOCKING > ERROR > WARNING. Don't lump them.
- If multiple errors share a root cause, show the cause once and list affected sites with counts.
