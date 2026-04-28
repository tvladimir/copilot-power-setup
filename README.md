# Copilot Power Setup

A friendly, opinionated toolkit that turns VS Code + GitHub Copilot into a near-autonomous coding partner for your Windows dev box. It ships **5 custom agents**, **6 slash-prompts**, **4 per-stack templates**, modern Copilot settings tuned for 2026, and one-shot installers — drop it into any project and Copilot starts pulling its weight.

> **Target environment**
> - **Windows only.** Both **PowerShell** (`install.ps1`) and **Git Bash** (`install.sh`) are supported — pick whichever shell you prefer.
> - **VS Code Copilot extension only** — `gh copilot` CLI is *not* used. Everything is driven through Chat / Agent mode / MCP. The agent's `runCommands` tool is the extension's integrated-terminal access, not the blocked CLI.
> - Built and verified against VS Code **v1.106+** (October 2025) Copilot conventions.

---

## Table of contents

- [What you get](#what-you-get)
- [Quick start](#quick-start)
- [Install — global config](#install--global-config)
- [Install — per project](#install--per-project)
- [Custom agents](#custom-agents)
- [Slash-prompts](#slash-prompts)
- [Templates](#templates)
- [How instructions cascade](#how-instructions-cascade)
- [MCP servers](#mcp-servers)
- [Cheatsheet](#cheatsheet)
- [Make your own](#make-your-own)
- [Project structure](#project-structure)
- [Settings & keybindings](#settings--keybindings)
- [Tips](#tips)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## What you get

| Component | Count | What it is |
|---|---|---|
| Custom agents | 5 | Specialized chat personas with their own toolset (LogDetective, CodeReviewer, Architect, DBDoctor, DevOpsPilot) |
| Slash-prompts | 6 | One-shot reusable prompts (`/DebugError`, `/WriteTests`, `/ExplainCode`, `/RefactorCode`, `/SqlQuery`, `/HelmDebug`) |
| Project templates | 4 | Starter `.github/` + `.vscode/` configs for `dotnet-api`, `react-app`, `uikit`, `helm-openshift` |
| Installers | 2 | `install.ps1` (PowerShell) and `install.sh` (Git Bash) — equivalent functionality |
| User config | 3 files | `settings.json`, `keybindings.json`, `extensions.txt` |
| MCP server configs | 4 | Per-template `.vscode/mcp.json` with verified packages |

Everything is plain Markdown / JSON / Bash / PowerShell. No vendor lock-in beyond GitHub Copilot itself.

---

## Quick start

```powershell
# 1. Clone and install global config (extensions + settings)
git clone git@github.com:tvladimir/copilot-power-setup.git
cd copilot-power-setup
.\install.ps1

# 2. Wire it into a project
.\install.ps1 -ProjectPath C:\Projects\my-api -Template dotnet-api
```

Open the project in VS Code. Open Copilot Chat (`Ctrl+Shift+I`). The five custom agents now appear in the agents dropdown; the six slash-prompts work with `/`.

That's it.

---

## Install — global config

The "global" half installs VS Code extensions and prints settings-merge instructions. Run it once per machine.

### PowerShell
```powershell
.\install.ps1
```

### Git Bash
```bash
chmod +x install.sh
./install.sh
```

### What it does
1. Installs every extension listed in `user-level/extensions.txt` via `code --install-extension`.
2. Tells you where to merge `user-level/settings.json` and `user-level/keybindings.json` (it deliberately does **not** auto-merge — you decide what to keep).

### Manual install (any shell)

Install extensions:
```powershell
# PowerShell
Get-Content .\user-level\extensions.txt |
  Where-Object { $_ -and $_ -notmatch '^#' } |
  ForEach-Object { code --install-extension $_.Trim() --force }
```
```bash
# Git Bash
xargs -L1 code --install-extension --force < user-level/extensions.txt
```

Then in VS Code (`Ctrl+Shift+P`):
- **Open User Settings (JSON)** → MERGE the contents of `user-level/settings.json` (don't replace).
- **Open Keyboard Shortcuts (JSON)** → MERGE the contents of `user-level/keybindings.json`.

VS Code user-config dir on Windows: `%APPDATA%\Code\User\` (Git Bash: `$APPDATA/Code/User`).

---

## Install — per project

Drop a per-stack template into your repo so Copilot follows that stack's conventions.

### Available templates

| Template | For | Includes |
|---|---|---|
| `dotnet-api` | ASP.NET Core / EF Core / SQL Server | C# + SQL-migration rules, `tasks.json` (build/test/migrate), MCP for MSSQL |
| `react-app` | React 19 + TypeScript strict | TS rules, ESLint+Prettier settings, MCP for Playwright |
| `uikit` | Component library + Storybook | Component rules, Story template, MCP for Playwright |
| `helm-openshift` | Helm 3 charts on OpenShift | Helm template rules, K8s probes/security guidelines, MCP basics |

### Options

**PowerShell:**
```powershell
.\install.ps1 -ProjectPath C:\Projects\my-api -Template dotnet-api
```

**Git Bash:**
```bash
./install.sh --project /c/Projects/my-api --template dotnet-api
```

### What it copies

- `templates/<NAME>/.github/*` → `<project>/.github/` (instructions + path-scoped instructions)
- `templates/<NAME>/.vscode/*` → `<project>/.vscode/` (settings, tasks, MCP)
- `agents-universal/*.agent.md` → `<project>/.github/agents/` (5 agents)
- `prompts-universal/*.prompt.md` → `<project>/.github/prompts/` (6 prompts)

### Manual variants

**PowerShell:**
```powershell
$DST = 'C:\Projects\my-api'
New-Item -ItemType Directory -Force -Path "$DST\.github\agents","$DST\.github\prompts","$DST\.vscode" | Out-Null
Copy-Item -Recurse -Force ".\templates\dotnet-api\.github\*"  "$DST\.github\"
Copy-Item -Recurse -Force ".\templates\dotnet-api\.vscode\*"  "$DST\.vscode\"
Copy-Item -Force          ".\agents-universal\*.agent.md"     "$DST\.github\agents\"
Copy-Item -Force          ".\prompts-universal\*.prompt.md"   "$DST\.github\prompts\"
```

**Git Bash:**
```bash
DST=/c/Projects/my-api
mkdir -p "$DST/.github/agents" "$DST/.github/prompts" "$DST/.vscode"
cp -R templates/dotnet-api/.github/.   "$DST/.github/"
cp -R templates/dotnet-api/.vscode/.   "$DST/.vscode/"
cp     agents-universal/*.agent.md     "$DST/.github/agents/"
cp     prompts-universal/*.prompt.md   "$DST/.github/prompts/"
```

---

## Custom agents

Custom agents are specialized chat personas — each has its own role, allowed toolset, and behavior. They appear in the **agents dropdown** in Copilot Chat (the same dropdown where Ask / Edit / Agent live). They are **not** invoked with `@`.

### LogDetective — log analyst
**Pick when** you have logs / a stack trace / a flaky pod and want a root-cause chase.
**Tools:** `runCommands`, `codebase`, `usages`, `terminalLastCommand`, `problems`.
**Behavior:** parses the log, searches the codebase for the failing method, follows the call chain, and proposes a specific code change with `file:line`. Knows Serilog / NLog / log4net / IIS / Kestrel / K8s structured logs.
**Try it:** *"Pod is in CrashLoopBackOff — here are the last 200 lines of `oc logs --previous`. What's the root cause?"*

### CodeReviewer — thorough reviewer
**Pick when** you want a real code review before pushing.
**Tools:** `codebase`, `usages`, `search`, `changes`, `problems`.
**Behavior:** checks correctness (logic, async, leaks), security (OWASP), performance (N+1, allocations), maintainability, and tests. Produces findings tagged with severity: BUG / SECURITY / PERF / STYLE / NIT, plus a verdict (APPROVE / REQUEST CHANGES / DISCUSS).

### Architect — solution designer
**Pick when** you're starting a non-trivial feature and want a plan first.
**Tools:** `codebase`, `usages`, `search`, `fetch`, `githubRepo`.
**Special:** has a one-click **"Implement this plan"** handoff that switches to Agent mode — design first, implementation second, two clicks total.
**Behavior:** surveys existing patterns, proposes a design with rejected alternatives, breaks it into ordered steps with effort estimates, and flags risks + mitigations.

### DBDoctor — SQL Server / EF Core specialist
**Pick when** a query is slow, a migration is risky, or EF is generating odd SQL.
**Tools:** `runCommands`, `codebase`, `search`.
**Behavior:** diagnoses with `SET STATISTICS IO/TIME` + DMVs, finds missing indexes, rewrites slow queries (CTEs, window functions, proper joins), and translates fixes back to LINQ when EF is involved.

### DevOpsPilot — OpenShift / Helm / K8s
**Pick when** a deployment fails, a probe is flapping, or a chart looks wrong.
**Tools:** `runCommands`, `codebase`, `terminalLastCommand`, `problems`.
**Behavior:** drives `oc` / `helm` from the integrated terminal, parses events, and proposes YAML changes with verification commands. Has a built-in decision tree for Pending / CrashLoopBackOff / ImagePullBackOff / OOMKilled.

---

## Slash-prompts

Reusable prompt templates. Type `/` in Copilot Chat and pick one. Inputs use the `${input:name:placeholder}` syntax — Copilot prompts you for them when you invoke the slash command.

| Prompt | Inputs | What it does |
|---|---|---|
| `/DebugError` | `error`, `context` | Parses a stack trace, finds the source, proposes a fix and prevention notes |
| `/WriteTests` | `code`, `framework` | Generates xUnit / NUnit / Jest / Vitest / pytest tests covering happy path, edges, and error handling |
| `/ExplainCode` | `code` | Step-by-step walkthrough: summary, logic, patterns, dependencies, potential issues, where it's called |
| `/RefactorCode` | `code`, `goal` | Refactors without changing external behaviour. Shows before/after diff, explains each change |
| `/SqlQuery` | `task`, `schema` | Writes or optimises T-SQL for MS SQL Server; suggests indexes and provides an EF Core LINQ equivalent |
| `/HelmDebug` | `problem`, `logs` | Diagnoses Helm or OpenShift deployment issues; gives YAML fix and verification commands |

---

## Templates

Each template ships a `.github/copilot-instructions.md` (project-wide rules), zero or more `.github/instructions/*.instructions.md` (path-scoped rules with `applyTo:` glob), and `.vscode/` settings.

### `dotnet-api`
- `.github/copilot-instructions.md` — stack, commands, code standards, EF Core, API conventions, security, Don'ts
- `.github/instructions/csharp.instructions.md` — applies to `**/*.cs`: file-scoped namespaces, async rules, DI, testing
- `.github/instructions/sql-migrations.instructions.md` — applies to `**/Migrations/**/*.cs,**/*.sql`: migration best practices
- `.vscode/settings.json` — workspace settings (rulers, formatOnSave, OmniSharp config)
- `.vscode/tasks.json` — pre-wired `dotnet build`, `dotnet test`, `dotnet test --watch`, EF migrations
- `.vscode/mcp.json` — GitHub HTTP, filesystem, fetch, MSSQL

### `react-app`
- `.github/copilot-instructions.md` — stack, commands, components, hooks, state, testing, a11y, Don'ts
- `.github/instructions/typescript.instructions.md` — applies to `**/*.ts,**/*.tsx`: types, imports, null safety, naming
- `.vscode/settings.json` — Prettier as default formatter, ESLint code-actions on save, TS import preferences
- `.vscode/mcp.json` — GitHub HTTP, filesystem, Playwright, fetch

### `uikit`
- `.github/copilot-instructions.md` — Storybook + component layout, Story template, RTL rules, Don'ts
- `.vscode/mcp.json` — GitHub HTTP, filesystem, Playwright (for visual / interaction tests)

### `helm-openshift`
- `.github/copilot-instructions.md` — chart layout, probes, security context, Don'ts, reference snippets
- `.github/instructions/helm-yaml.instructions.md` — applies to `**/*.yaml,**/*.yml,**/*.tpl`: Helm syntax, security, mistakes-to-avoid
- `.vscode/mcp.json` — GitHub HTTP, filesystem, fetch

---

## How instructions cascade

VS Code Copilot loads multiple instruction sources and concatenates them into the chat context:

```
You open: src/Services/OrderService.cs

Copilot loads:
  1. .github/copilot-instructions.md             (always-on, repo rules)
  2. AGENTS.md (workspace root)                   (always-on, cross-tool rules)
  3. .github/instructions/csharp.instructions.md (matches **/*.cs)
  4. .github/instructions/sql-migrations.instructions.md  (does NOT match — skipped)
```

Priority for conflict resolution: **personal > repo > organization** (per VS Code docs). All matching sources are added to context — priority only governs conflicts.

| File | Auto-loaded? | Purpose |
|---|---|---|
| `.github/copilot-instructions.md` | Always | Project-wide rules |
| `AGENTS.md` (workspace root) | Always (`chat.useAgentsMdFile`) | Cross-tool rules |
| `.github/instructions/*.instructions.md` | By `applyTo:` glob | Path-scoped rules |
| `.github/agents/*.agent.md` | On demand (dropdown) | Custom agents |
| `.github/prompts/*.prompt.md` | On demand (`/`) | Reusable prompts |
| `.vscode/settings.json` | Always | Workspace VS Code settings |
| `.vscode/tasks.json` | Always | Build/test tasks (`Ctrl+Shift+B`) |
| `.vscode/mcp.json` | In Agent mode | MCP server connections |

---

## MCP servers

The Model Context Protocol lets the Copilot agent talk to external tools — databases, browsers, repos, the filesystem. Each template ships a `.vscode/mcp.json` with verified packages.

### Schema

Top-level key is **`servers`** (NOT `mcpServers` — that's Claude Desktop / Cursor).

```jsonc
{
  "inputs": [
    { "type": "promptString", "id": "mssql-conn", "description": "MSSQL connection string", "password": true }
  ],
  "servers": {
    "github":     { "type": "http",  "url": "https://api.githubcopilot.com/mcp" },
    "playwright": { "type": "stdio", "command": "npx", "args": ["-y", "@playwright/mcp@latest"] },
    "filesystem": { "type": "stdio", "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"] },
    "fetch":      { "type": "stdio", "command": "uvx", "args": ["mcp-server-fetch"] },
    "mssql":      { "type": "stdio", "command": "npx", "args": ["-y", "mssql-mcp-server"], "env": { "MSSQL_CONNECTION_STRING": "${input:mssql-conn}" } }
  }
}
```

### Servers in the templates

- **github** (HTTP) — issues / PRs / repo browsing. Hosted by GitHub at `https://api.githubcopilot.com/mcp`. No install needed.
- **filesystem** (stdio) — local file ops scoped to the workspace. Auto-installs via `npx`.
- **playwright** (stdio) — browser automation / interaction tests. Auto-installs via `npx`.
- **mssql** (stdio) — MS SQL Server queries. Third-party `mssql-mcp-server` from npm.
- **fetch** (stdio) — web fetch. Requires `uv` (`winget install astral-sh.uv`). Optional — remove the block if `uv` isn't available.

### Secrets

Use the `inputs` array. VS Code prompts on first server start and stores values in the OS keychain. The `password: true` flag masks the input field. Reference values in env or args via `${input:id}`.

### Workspace vs user-level

- **Workspace:** `.vscode/mcp.json` (commit it to share with the team).
- **User-level:** Command Palette → **MCP: Open User Configuration**.

---

## Cheatsheet

Four different ways Copilot Chat exposes things — easy to confuse.

| Type | Invoked by | Examples | Where defined |
|---|---|---|---|
| Built-in mode | Mode dropdown | Ask, Edit, Agent | Built into VS Code |
| Custom agent | **Agents dropdown** | Architect, CodeReviewer, ... | `.github/agents/*.agent.md` |
| Slash-prompt | `/` (slash) | `/WriteTests`, `/DebugError` | `.github/prompts/*.prompt.md` |
| Chat participant | `@` (mention) | `@workspace`, `@github`, `@terminal`, `@vscode` | Built into the GitHub Copilot extension |

---

## Make your own

### New agent

Create `.github/agents/MyAgent.agent.md`:
```markdown
---
description: "What this agent does (shown in dropdown)"
name: "MyAgent"
tools: ['codebase', 'usages', 'editFiles']
---

You are MyAgent. Your job is to ...

[Detailed behaviour, output format, rules]
```

### New prompt

Create `.github/prompts/MyPrompt.prompt.md`:
```markdown
---
description: "What this prompt does"
tools: ['codebase']
---
## Task
${input:task:Describe what you need}

## Code
${input:code:Paste code}

[Step-by-step instructions for Copilot]
```

### Valid built-in tool IDs

All flat — no slashes:

`codebase`, `usages`, `search`, `fetch`, `githubRepo`, `editFiles`, `runCommands`, `runTasks`, `terminalLastCommand`, `terminalSelection`, `findTestFiles`, `testFailure`, `problems`, `changes`, `todos`, `extensions`, `vscodeAPI`, `think`.

MCP wildcards use `<server>/*` (e.g. `'playwright/*'` to grant the agent every Playwright tool).

---

## Project structure

```
copilot-power-setup/
├─ README.md                       ← you are here
├─ AGENTS.md                       ← cross-tool meta-instructions for this repo
├─ install.ps1                     ← Windows / PowerShell installer
├─ install.sh                      ← Windows / Git Bash installer
├─ docs/
│  └─ lessons.md                   ← captured lessons + decisions
├─ user-level/                     ← global VS Code config (one-time install)
│  ├─ settings.json                ← merge into User Settings JSON
│  ├─ keybindings.json             ← merge into Keyboard Shortcuts JSON
│  └─ extensions.txt               ← extension list, one per line
├─ templates/                      ← per-stack starter configs
│  ├─ dotnet-api/                  ← .github/* + .vscode/{settings,tasks,mcp}.json
│  ├─ react-app/                   ← .github/* + .vscode/{settings,mcp}.json
│  ├─ uikit/                       ← .github/* + .vscode/mcp.json
│  └─ helm-openshift/              ← .github/* + .vscode/mcp.json
├─ agents-universal/               ← copy into any repo's .github/agents/
│  ├─ log-detective.agent.md
│  ├─ code-reviewer.agent.md
│  ├─ architect.agent.md
│  ├─ db-doctor.agent.md
│  └─ devops-pilot.agent.md
└─ prompts-universal/              ← copy into any repo's .github/prompts/
   ├─ DebugError.prompt.md
   ├─ WriteTests.prompt.md
   ├─ ExplainCode.prompt.md
   ├─ RefactorCode.prompt.md
   ├─ SqlQuery.prompt.md
   └─ HelmDebug.prompt.md
```

---

## Settings & keybindings

`user-level/settings.json` ships ~50 settings tuned for power use. Highlights:

- **`chat.agent.maxRequests: 50`** — raises the agent's tool-call budget (default 25). Long agent runs need this.
- **`chat.tools.terminal.autoApprove`** — granular regex/per-command approval. Pre-approves safe ops (`ls`, `git`, `npm test`, `dotnet build`, `helm lint`); blocks risky ones (`rm`, `curl`, `chmod`, `kill`).
- **`chat.tools.global.autoApprove: false`** — never YOLO globally; opt in per category instead.
- **`chat.checkpoints.enabled`** — rollback safety for agent edits.
- **`chat.useAgentsMdFile` + `chat.useClaudeMdFile`** — auto-loads `AGENTS.md` and `CLAUDE.md` from the workspace root.
- **`chat.useCustomizationsInParentRepositories`** — instructions cascade up in monorepos.
- **`chat.mcp.discovery.enabled` + `chat.mcp.autoStart`** — MCP servers start on demand.
- **`github.copilot.nextEditSuggestions.enabled`** + `.fixes` — Next Edit Suggestions: Copilot proposes the next likely edit after each change, and offers fixes for diagnostics.

Plus standard editor / Git / TypeScript / .NET niceties (`formatOnSave`, `editor.rulers: [120]`, `git.autofetch`, `dotnet.defaultSolution: disable`, etc.).

`user-level/keybindings.json` adds:

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+I` | Open Copilot Chat |
| `Ctrl+Shift+A` | Attach context to chat |
| `Ctrl+Shift+T` | Run task |
| `Alt+Shift+F` | Format document |
| `Ctrl+Shift+E` | Show all editors |
| `Alt+Left` / `Alt+Right` | Navigate back / forward |
| `` Ctrl+` `` | Toggle terminal |

---

## Tips

1. **Agent-mode budget** — `chat.agent.maxRequests` (default 25) caps tool calls per turn. The shipped value is 50; raise further for long migrations or refactors.
2. **Attach context** — drag files into chat or use `#file:path`.
3. **Vision** — paste a screenshot for UI debugging. Works with Claude Opus / Sonnet 4.6+, GPT-4o / 5.x, Gemini 2.5+/3.x.
4. **Architect → Agent handoff** — start with the `Architect` agent for design, then click **"Implement this plan"** to switch to Agent mode and execute.
5. **Combine prompts and agents** — use `/WriteTests` first, then switch to Agent mode and ask it to make the failing tests pass.
6. **PR review** — add `copilot` as a reviewer on GitHub for automated PR review.
7. **Checkpoints** — `chat.checkpoints.enabled` lets you roll back a bad agent edit.

---

## Troubleshooting

**Custom agents don't appear in the dropdown.**
Make sure the files are at `.github/agents/*.agent.md` (not the legacy `.github/chatmodes/`). Reload the VS Code window: `Ctrl+Shift+P → Developer: Reload Window`.

**Slash-prompts don't autocomplete.**
Same fix — files at `.github/prompts/*.prompt.md`. Also verify `chat.promptFilesLocations` isn't overridden somewhere.

**`fetch` MCP server fails to start.**
It needs `uv` on PATH. Install with `winget install astral-sh.uv`, or remove the `fetch` block from `.vscode/mcp.json`.

**`code` not found.**
In VS Code: `Ctrl+Shift+P → Shell Command: Install 'code' command in PATH`.

**Settings keys flagged as unknown.**
You may be on an older VS Code release. The toolkit targets v1.106+ (October 2025+). Update VS Code.

**`@AgentName` doesn't work.**
Custom agents are not invoked with `@`. Pick them from the **agents dropdown** in chat. `@` is reserved for built-in chat participants (`@workspace`, `@github`, `@terminal`, `@vscode`).

**MCP server fails with "trust required".**
On the first start of a newly added server, VS Code shows a trust dialog. Decline → server stays disabled. Reset via `Ctrl+Shift+P → MCP: Reset Trust`.

---

## References

- [VS Code Copilot — Custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot — Custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [VS Code Copilot — Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [VS Code Copilot — MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- [VS Code Copilot — Settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings)
- [AGENTS.md spec](https://agents.md/)
- [Awesome Copilot — community catalog](https://github.com/github/awesome-copilot)
