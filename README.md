# Copilot Power Setup

A friendly, opinionated toolkit that turns VS Code + GitHub Copilot into a near-autonomous coding partner for your Windows dev box. It ships **5 custom agents**, **6 slash-prompts**, **3 portable agent skills**, **2 hook bundles**, **4 per-stack templates**, modern Copilot settings tuned for May 2026, and one-shot installers — drop it into any project and Copilot starts pulling its weight.

> **Target environment**
> - **Windows only.** Both **PowerShell** (`install.ps1`) and **Git Bash** (`install.sh`) are supported — pick whichever shell you prefer.
> - **VS Code Copilot extension only** — `gh copilot` CLI is *not* used. Everything is driven through Chat / Agent mode / MCP. The agent's `runCommands` tool is the extension's integrated-terminal access, not the blocked CLI.
> - Built and verified against VS Code **v1.106+** (October 2025) Copilot conventions, refreshed against the May 2026 settings reference.

---

## Table of contents

- [What you get](#what-you-get)
- [Quick start](#quick-start)
- [Install — global config](#install--global-config)
- [Install — per project](#install--per-project)
- [Custom agents](#custom-agents)
- [Slash-prompts](#slash-prompts)
- [Agent skills](#agent-skills)
- [Agent hooks](#agent-hooks)
- [Templates](#templates)
- [How instructions, skills, and hooks cascade](#how-instructions-skills-and-hooks-cascade)
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
| Custom agents | 5 | Specialised chat personas with their own toolset (LogDetective, CodeReviewer, Architect, DBDoctor, DevOpsPilot) |
| Slash-prompts | 6 | One-shot reusable prompts (`/DebugError`, `/WriteTests`, `/ExplainCode`, `/RefactorCode`, `/SqlQuery`, `/HelmDebug`) |
| Agent skills | 3 | Portable, model-discoverable knowledge packs (`sql-diagnostics`, `k8s-troubleshooting`, `log-analysis`) |
| Hook bundles | 2 | Auto-format on edit for `dotnet-api` (`dotnet format`) and `react-app` (`eslint --fix` + `prettier`) |
| Project templates | 4 | Starter `.github/` + `.vscode/` configs for `dotnet-api`, `react-app`, `uikit`, `helm-openshift` |
| Installers | 2 | `install.ps1` (PowerShell) and `install.sh` (Git Bash) — equivalent functionality |
| User config | 3 files | `settings.json` (60+ keys), `keybindings.json`, `extensions.txt` |
| MCP server configs | 4 | Per-template `.vscode/mcp.json` with verified packages |

Everything is plain Markdown / JSON / Bash / PowerShell. No vendor lock-in beyond GitHub Copilot itself.

---

## Quick start

```powershell
# 1. Clone and install global config (extensions + settings + skills)
git clone git@github.com:tvladimir/copilot-power-setup.git
cd copilot-power-setup
.\install.ps1 -SkipInstalled -Skills

# 2. Wire it into a project
.\install.ps1 -ProjectPath C:\Projects\my-api -Template dotnet-api
```

Open the project in VS Code. Open Copilot Chat (`Ctrl+Shift+I`). The five custom agents appear in the agents dropdown; the six slash-prompts work with `/`; skills are auto-discovered by the model based on the user's question (or you can invoke them explicitly with `/sql-diagnostics` etc.).

That's it.

---

## Install — global config

The "global" half installs VS Code extensions, prints settings-merge instructions, and (optionally) drops the universal skills into your user profile. Run it once per machine.

### PowerShell
```powershell
.\install.ps1                       # extensions + settings prompt
.\install.ps1 -SkipInstalled        # skip extensions already installed
.\install.ps1 -Skills               # also copy skills/ to %USERPROFILE%\.copilot\skills\
.\install.ps1 -SkipInstalled -Skills
```

### Git Bash
```bash
chmod +x install.sh
./install.sh                        # extensions + settings prompt
./install.sh --skip-installed       # skip extensions already installed
./install.sh --skills               # also copy skills/ to ~/.copilot/skills/
./install.sh --skip-installed --skills
```

### What it does

1. Installs every extension listed in `user-level/extensions.txt` via `code --install-extension`. With `--skip-installed` (or `-SkipInstalled`) it queries `code --list-extensions` first and skips anything already present — useful for re-runs.
2. Tells you where to merge `user-level/settings.json` and `user-level/keybindings.json` (it deliberately does **not** auto-merge — you decide what to keep).
3. With `--skills` (or `-Skills`), copies the universal skills into your user-level skills folder so they're available in **every** workspace, not just per-project.

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

Drop a per-stack template into your repo so Copilot follows that stack's conventions, plus the universal agents / prompts / skills.

### Available templates

| Template | For | Includes |
|---|---|---|
| `dotnet-api` | ASP.NET Core / EF Core / SQL Server | C# + SQL-migration rules, `tasks.json` (build/test/migrate), MCP for MSSQL, `dotnet format` hook |
| `react-app` | React 19 + TypeScript strict | TS rules, ESLint+Prettier settings, MCP for Playwright, `eslint --fix` + `prettier` hook |
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

- `templates/<NAME>/.github/*` → `<project>/.github/` (instructions, hooks, anything else)
- `templates/<NAME>/.vscode/*` → `<project>/.vscode/` (settings, tasks, MCP)
- `templates/<NAME>/.editorconfig` → `<project>/.editorconfig` (cross-editor formatting)
- `agents-universal/*.agent.md` → `<project>/.github/agents/` (5 agents)
- `prompts-universal/*.prompt.md` → `<project>/.github/prompts/` (6 prompts)
- `skills-universal/*` → `<project>/.github/skills/` (3 skills)

### Manual variants

**PowerShell:**
```powershell
$DST = 'C:\Projects\my-api'
New-Item -ItemType Directory -Force -Path "$DST\.github\agents","$DST\.github\prompts","$DST\.github\skills","$DST\.vscode" | Out-Null
Copy-Item -Recurse -Force ".\templates\dotnet-api\.github\*"  "$DST\.github\"
Copy-Item -Recurse -Force ".\templates\dotnet-api\.vscode\*"  "$DST\.vscode\"
Copy-Item -Force          ".\templates\dotnet-api\.editorconfig" "$DST\.editorconfig"
Copy-Item -Force          ".\agents-universal\*.agent.md"     "$DST\.github\agents\"
Copy-Item -Force          ".\prompts-universal\*.prompt.md"   "$DST\.github\prompts\"
Copy-Item -Recurse -Force ".\skills-universal\*"              "$DST\.github\skills\"
```

**Git Bash:**
```bash
DST=/c/Projects/my-api
mkdir -p "$DST/.github/agents" "$DST/.github/prompts" "$DST/.github/skills" "$DST/.vscode"
cp -R templates/dotnet-api/.github/.   "$DST/.github/"
cp -R templates/dotnet-api/.vscode/.   "$DST/.vscode/"
cp     templates/dotnet-api/.editorconfig "$DST/.editorconfig"
cp     agents-universal/*.agent.md     "$DST/.github/agents/"
cp     prompts-universal/*.prompt.md   "$DST/.github/prompts/"
cp -R  skills-universal/.              "$DST/.github/skills/"
```

---

## Custom agents

Custom agents are specialised chat personas — each has its own role, allowed toolset, and behaviour. They appear in the **agents dropdown** in Copilot Chat (the same dropdown where Ask / Edit / Agent live). They are **not** invoked with `@`.

Each shipped agent now carries an `argument-hint` (placeholder shown in the chat input field when the agent is active), so you'll see a contextual hint like *"paste the slow query / migration / schema"* the moment you pick DBDoctor.

### LogDetective — log analyst
**Pick when** you have logs / a stack trace / a flaky pod and want a root-cause chase.
**Tools:** `runCommands`, `codebase`, `usages`, `terminalLastCommand`, `problems`.
**Behaviour:** parses the log, searches the codebase for the failing method, follows the call chain, and proposes a specific code change with `file:line`. Knows Serilog / NLog / log4net / IIS / Kestrel / K8s structured logs. Pairs naturally with the **`log-analysis`** skill.
**Try it:** *"Pod is in CrashLoopBackOff — here are the last 200 lines of `oc logs --previous`. What's the root cause?"*

### CodeReviewer — thorough reviewer
**Pick when** you want a real code review before pushing.
**Tools:** `codebase`, `usages`, `search`, `changes`, `problems`.
**Behaviour:** checks correctness (logic, async, leaks), security (OWASP), performance (N+1, allocations), maintainability, and tests. Produces findings tagged with severity: BUG / SECURITY / PERF / STYLE / NIT, plus a verdict (APPROVE / REQUEST CHANGES / DISCUSS). Can be invoked as a sub-agent by Architect.

### Architect — solution designer
**Pick when** you're starting a non-trivial feature and want a plan first.
**Tools:** `codebase`, `usages`, `search`, `fetch`, `githubRepo`.
**Sub-agents:** Architect can call **CodeReviewer** as a sub-step (`agents: ['CodeReviewer']`).
**Handoffs:** two one-click buttons — **"Implement this plan"** (switches to Agent mode) and **"Review the plan"** (hands off to CodeReviewer for a pre-implementation sanity check).
**Behaviour:** surveys existing patterns, proposes a design with rejected alternatives, breaks it into ordered steps with effort estimates, and flags risks + mitigations.

### DBDoctor — SQL Server / EF Core specialist
**Pick when** a query is slow, a migration is risky, or EF is generating odd SQL.
**Tools:** `runCommands`, `codebase`, `search`.
**Behaviour:** diagnoses with `SET STATISTICS IO/TIME` + DMVs, finds missing indexes, rewrites slow queries (CTEs, window functions, proper joins), and translates fixes back to LINQ when EF is involved. Pairs with the **`sql-diagnostics`** skill for a one-shot health snapshot.

### DevOpsPilot — OpenShift / Helm / K8s
**Pick when** a deployment fails, a probe is flapping, or a chart looks wrong.
**Tools:** `runCommands`, `codebase`, `terminalLastCommand`, `problems`.
**Behaviour:** drives `oc` / `helm` from the integrated terminal, parses events, and proposes YAML changes with verification commands. Has a built-in decision tree for Pending / CrashLoopBackOff / ImagePullBackOff / OOMKilled — duplicated as the **`k8s-troubleshooting`** skill so other agents can reach for the same checklist.

---

## Slash-prompts

Reusable prompt templates. Type `/` in Copilot Chat and pick one. Inputs use the `${input:name:placeholder}` syntax — Copilot prompts you for them when you invoke the slash command. Each prompt also declares an `agent:` (`ask` for read-only Q&A, `agent` for editing) and an `argument-hint:` so you see what to paste in.

| Prompt | Agent | Inputs | What it does |
|---|---|---|---|
| `/DebugError` | `ask` | `error`, `context` | Parses a stack trace, finds the source, proposes a fix and prevention notes |
| `/WriteTests` | `agent` | `code`, `framework` | Generates xUnit / NUnit / Jest / Vitest / pytest tests covering happy path, edges, and error handling |
| `/ExplainCode` | `ask` | `code` | Step-by-step walkthrough: summary, logic, patterns, dependencies, potential issues, where it's called |
| `/RefactorCode` | `agent` | `code`, `goal` | Refactors without changing external behaviour. Shows before/after diff, explains each change |
| `/SqlQuery` | `ask` | `task`, `schema` | Writes or optimises T-SQL for MS SQL Server; suggests indexes and provides an EF Core LINQ equivalent |
| `/HelmDebug` | `agent` | `problem`, `logs` | Diagnoses Helm or OpenShift deployment issues; gives YAML fix and verification commands |

---

## Agent skills

**Skills** (stable in VS Code since January 2026) are portable, model-discoverable knowledge packs. Unlike custom agents, skills can bundle scripts and resources, and they're cross-tool — the same `SKILL.md` works in VS Code Copilot, Claude Code, and any agent runner that follows the spec.

A skill is a folder containing a `SKILL.md` whose YAML frontmatter has just two required fields:

```yaml
---
name: short-name              # lowercase + hyphens, max 64 chars
description: One sentence...  # what it does AND when to use it (max 1024 chars)
---
```

The model auto-loads a skill when the user's request matches its `description`. Users can also invoke a skill directly with `/skill-name`.

### Where skills live

| Scope | Location | When to use |
|---|---|---|
| **Workspace** | `.github/skills/<name>/SKILL.md` | Project-specific knowledge — commit it with the repo |
| **User** | `%USERPROFILE%\.copilot\skills\<name>\SKILL.md` (Bash: `~/.copilot/skills/<name>/SKILL.md`) | Personal toolkit available everywhere — install with `--skills` / `-Skills` |
| **Custom** | Any path listed in `chat.agentSkillsLocations` | If you want skills outside `.github/skills` |

### Shipped skills

| Skill | What it knows | Pairs with |
|---|---|---|
| `sql-diagnostics` | DMV queries for top-expensive queries, missing indexes, table sizes, unused indexes — read-only, safe in prod | DBDoctor |
| `k8s-troubleshooting` | Decision tree for Pending / CrashLoopBackOff / ImagePullBackOff / OOMKilled / unreachable services with the exact `oc`/`kubectl` confirmation commands | DevOpsPilot |
| `log-analysis` | Format cheat-sheet (Serilog JSON / NLog / log4net / IIS / K8s) + 5-step procedure for walking a stack trace to a `file:line` fix | LogDetective |

### Using a skill

Auto-discovery (recommended):
> *"This stored proc became slow last week — what's going on?"*
> Copilot reads the active skills' descriptions, matches `sql-diagnostics`, and runs through its DMV checks.

Explicit invocation:
> `/sql-diagnostics`
> Copilot loads the skill body verbatim into the chat context.

---

## Agent hooks

**Hooks** let you run shell commands at fixed lifecycle points during a Copilot agent session. They live in `.github/hooks/*.json` (workspace) or in your user-level config; **workspace hooks take precedence** over user-level for the same event.

### Lifecycle events (8)

| Event | When it fires |
|---|---|
| `SessionStart` | New chat session begins |
| `UserPromptSubmit` | After the user submits a message, before the agent runs |
| `PreToolUse` | Before the agent calls a tool |
| `PostToolUse` | After a tool returns (the most useful one — auto-format on edit, etc.) |
| `PreCompact` | Before history compaction |
| `SubagentStart` / `SubagentStop` | Wrapping a subagent invocation |
| `Stop` | Session ends |

### Schema

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "default cross-platform command",
        "windows": "windows-specific override (optional)",
        "linux":   "linux override (optional)",
        "osx":     "macOS override (optional)",
        "cwd":     "working directory (optional)",
        "env":     { "MY_VAR": "value" },
        "timeout": 30
      }
    ]
  }
}
```

**Accessing event data inside a hook command.** The official VS Code example uses one shell-expanded variable:

- `$TOOL_INPUT_FILE_PATH` — path of the file the tool just touched (used in the shipped `format-on-edit` hooks)

For richer event data, VS Code pipes a JSON payload to the hook on **stdin** with fields like `tool_name`, `tool_input`, `cwd`, `sessionId`, `timestamp`, `hookEventName`. Read with `jq` (or PowerShell `ConvertFrom-Json`):

```bash
"command": "EVT=$(jq -r '.tool_name'); echo \"hook fired by tool: $EVT\""
```

### Shipped hooks

| Template | File | What it does |
|---|---|---|
| `dotnet-api` | `.github/hooks/format-on-edit.json` | After Copilot edits a file, runs `dotnet format --include "$TOOL_INPUT_FILE_PATH"` |
| `react-app` | `.github/hooks/format-on-edit.json` | After Copilot edits a file, runs `eslint --fix` then `prettier --write` (silent if not a JS/TS source) |

### Verifying hooks load

`Ctrl+Shift+P → Output → "GitHub Copilot Chat"` and look for `Load Hooks` lines. Each loaded hook is logged with its source location.

---

## Templates

Each template ships:

- `.github/copilot-instructions.md` — project-wide rules
- zero or more `.github/instructions/*.instructions.md` — path-scoped rules with `applyTo:` glob
- optional `.github/hooks/*.json` — automation hooks
- `.vscode/` — workspace settings, tasks, MCP servers
- `.editorconfig` — cross-editor formatting baseline

### `dotnet-api`
- `.github/copilot-instructions.md` — stack, commands, code standards, EF Core, API conventions, security, Don'ts
- `.github/instructions/csharp.instructions.md` — applies to `**/*.cs`: file-scoped namespaces, async rules, DI, testing
- `.github/instructions/sql-migrations.instructions.md` — applies to `**/Migrations/**/*.cs,**/*.sql`: migration best practices
- `.github/hooks/format-on-edit.json` — auto-format C# after every edit
- `.vscode/settings.json` — workspace settings (rulers, formatOnSave, OmniSharp config)
- `.vscode/tasks.json` — pre-wired `dotnet build`, `dotnet test`, `dotnet test --watch`, EF migrations
- `.vscode/mcp.json` — GitHub HTTP, filesystem, fetch, MSSQL
- `.editorconfig` — 4-space C#, 2-space JSON/YAML, Allman braces

### `react-app`
- `.github/copilot-instructions.md` — stack, commands, components, hooks, state, testing, a11y, Don'ts
- `.github/instructions/typescript.instructions.md` — applies to `**/*.ts,**/*.tsx`: types, imports, null safety, naming
- `.github/hooks/format-on-edit.json` — auto-fix lint + format on every edit
- `.vscode/settings.json` — Prettier as default formatter, ESLint code-actions on save, TS import preferences
- `.vscode/mcp.json` — GitHub HTTP, filesystem, Playwright, fetch
- `.editorconfig` — 2-space indent, LF, final newline

### `uikit`
- `.github/copilot-instructions.md` — Storybook + component layout, Story template, RTL rules, Don'ts
- `.vscode/mcp.json` — GitHub HTTP, filesystem, Playwright (for visual / interaction tests)
- `.editorconfig` — 2-space indent, LF, final newline

### `helm-openshift`
- `.github/copilot-instructions.md` — chart layout, probes, security context, Don'ts, reference snippets
- `.github/instructions/helm-yaml.instructions.md` — applies to `**/*.yaml,**/*.yml,**/*.tpl`: Helm syntax, security, mistakes-to-avoid
- `.vscode/mcp.json` — GitHub HTTP, filesystem, fetch
- `.editorconfig` — 2-space YAML/TPL indent

---

## How instructions, skills, and hooks cascade

VS Code Copilot loads multiple sources and concatenates them into context (or runs them at lifecycle points):

```
You open: src/Services/OrderService.cs

Copilot loads (always-on):
  1. .github/copilot-instructions.md                          (repo rules)
  2. AGENTS.md (workspace root)                                (cross-tool rules; chat.useAgentsMdFile)
  3. .github/instructions/csharp.instructions.md               (matches **/*.cs)
  4. .github/instructions/sql-migrations.instructions.md       (does NOT match — skipped)

Copilot loads on demand:
  5. .github/agents/*.agent.md                                 (when picked from agents dropdown)
  6. .github/prompts/*.prompt.md                               (when invoked with /name)
  7. .github/skills/*/SKILL.md                                 (auto-matched by description, or /skill-name)
  8. .github/hooks/*.json                                      (fires at lifecycle events)
```

Priority for **conflict** resolution: **personal > repo > organisation** (per VS Code docs). All matching sources are added to context — priority only governs conflicts. **Hooks**: workspace > user-level for the same event.

| File | Auto-loaded? | Purpose |
|---|---|---|
| `.github/copilot-instructions.md` | Always | Project-wide rules |
| `AGENTS.md` (workspace root) | Always (`chat.useAgentsMdFile`) | Cross-tool rules |
| `.github/instructions/*.instructions.md` | By `applyTo:` glob | Path-scoped rules |
| `.github/agents/*.agent.md` | On demand (dropdown) | Custom agents |
| `.github/prompts/*.prompt.md` | On demand (`/`) | Reusable prompts |
| `.github/skills/<name>/SKILL.md` | Auto-matched by `description`, or `/skill-name` | Portable knowledge packs |
| `.github/hooks/*.json` | At lifecycle events | Automation (format, lint, scan) |
| `.vscode/settings.json` | Always | Workspace VS Code settings |
| `.vscode/tasks.json` | Always | Build/test tasks (`Ctrl+Shift+B`) |
| `.vscode/mcp.json` | In Agent mode | MCP server connections |
| `.editorconfig` | Always (any IDE) | Cross-editor formatting |

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

Five different ways Copilot Chat exposes things — easy to confuse.

| Type | Invoked by | Examples | Where defined |
|---|---|---|---|
| Built-in mode | Mode dropdown | Ask, Edit, Agent | Built into VS Code |
| Custom agent | **Agents dropdown** | Architect, CodeReviewer, … | `.github/agents/*.agent.md` |
| Slash-prompt | `/` (slash) | `/WriteTests`, `/DebugError` | `.github/prompts/*.prompt.md` |
| Skill | Auto-matched by description, or `/skill-name` | `/sql-diagnostics`, `/k8s-troubleshooting` | `.github/skills/<name>/SKILL.md` |
| Chat participant | `@` (mention) | `@workspace`, `@github`, `@terminal`, `@vscode` | Built into the GitHub Copilot extension |

---

## Make your own

VS Code Copilot ships built-in slash commands to scaffold each artefact. Type any of these in Copilot Chat and pick the file location:

| Command | Creates |
|---|---|
| `/init` | `.github/copilot-instructions.md` tailored to the current codebase |
| `/create-agent` | `.github/agents/<Name>.agent.md` with frontmatter scaffold |
| `/create-instruction` | `.github/instructions/<name>.instructions.md` with `applyTo:` scaffold |
| `/create-prompt` | `.github/prompts/<Name>.prompt.md` with input scaffold |
| `/create-skill` | `.github/skills/<name>/SKILL.md` with frontmatter scaffold |
| `/create-hook` | `.github/hooks/<name>.json` with lifecycle-event scaffold |

Or do it by hand:

### New agent

Create `.github/agents/MyAgent.agent.md`:
```markdown
---
description: "What this agent does (shown in dropdown)"
name: "MyAgent"
argument-hint: "what to paste / mention when invoking this agent"
tools: ['codebase', 'usages', 'editFiles']
agents: ['CodeReviewer']        # optional — sub-agents this agent can call
---

You are MyAgent. Your job is to …

[Detailed behaviour, output format, rules]
```

### New prompt

Create `.github/prompts/MyPrompt.prompt.md`:
```markdown
---
description: "What this prompt does"
argument-hint: "what to paste"
agent: "ask"                    # ask | agent | plan | <custom-agent-name>
tools: ['codebase']
---
## Task
${input:task:Describe what you need}

## Code
${input:code:Paste code}

[Step-by-step instructions for Copilot]
```

### New skill

Create `.github/skills/my-skill/SKILL.md`:
```markdown
---
name: my-skill
description: One sentence describing what the skill knows and when to reach for it. Be specific — the model uses this to decide when to load the skill.
---

# Skill body

[Procedure, decision tree, code snippets, references — whatever the skill needs.]
```

You can put scripts and other resources next to `SKILL.md` (any file in the same folder) and reference them from the body via relative Markdown links.

### New hook

Create `.github/hooks/my-hook.json`:
```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "type": "command",
        "command": "your shell command — $TOOL_INPUT_FILE_PATH expands to the touched file; richer event data is on stdin as JSON (use jq)",
        "windows": "windows-specific variant (optional)",
        "timeout": 30
      }
    ]
  }
}
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
│  ├─ dotnet-api/                  ← .github/{copilot-instructions,instructions/*,hooks/*} + .vscode/{settings,tasks,mcp}.json + .editorconfig
│  ├─ react-app/                   ← .github/{copilot-instructions,instructions/*,hooks/*} + .vscode/{settings,mcp}.json + .editorconfig
│  ├─ uikit/                       ← .github/copilot-instructions + .vscode/mcp.json + .editorconfig
│  └─ helm-openshift/              ← .github/{copilot-instructions,instructions/*} + .vscode/mcp.json + .editorconfig
├─ agents-universal/               ← copy into any repo's .github/agents/
│  ├─ log-detective.agent.md
│  ├─ code-reviewer.agent.md
│  ├─ architect.agent.md           ← has agents:[CodeReviewer] sub-agent + 2 handoffs
│  ├─ db-doctor.agent.md
│  └─ devops-pilot.agent.md
├─ prompts-universal/              ← copy into any repo's .github/prompts/
│  ├─ DebugError.prompt.md
│  ├─ WriteTests.prompt.md
│  ├─ ExplainCode.prompt.md
│  ├─ RefactorCode.prompt.md
│  ├─ SqlQuery.prompt.md
│  └─ HelmDebug.prompt.md
└─ skills-universal/               ← copy into any repo's .github/skills/ or ~/.copilot/skills/
   ├─ sql-diagnostics/
   │  └─ SKILL.md
   ├─ k8s-troubleshooting/
   │  └─ SKILL.md
   └─ log-analysis/
      └─ SKILL.md
```

---

## Settings & keybindings

`user-level/settings.json` ships ~60 settings tuned for power use. Highlights below — the file itself is fully commented.

### Permissions, autopilot, auto-approval

- **`chat.permissions.default: "default"`** — confirm-each-tool baseline. Switch to `"autoApprove"` for the auto-approve list, or `"autopilot"` once you trust your auto-approve rules end-to-end.
- **`chat.autopilot.enabled: true`** — makes the Autopilot permission level available (still off by default; you opt in per session).
- **`chat.tools.terminal.autoApprove`** — granular regex/per-command approval. Pre-approves safe ops (`ls`, `git`, `npm test`, `dotnet build`, `helm lint`); blocks risky ones (`rm`, `curl`, `chmod`, `kill`).
- **`chat.tools.global.autoApprove: false`** — never YOLO globally; opt in per category instead.
- **`chat.tools.edits.autoApprove: false`** — review every edit by default.
- **`chat.tools.terminal.outputLocation: "chat"`** — show terminal command output inline in chat (vs in the integrated terminal panel).

### Customisations & cross-tool

- **`chat.useAgentsMdFile` + `chat.useClaudeMdFile`** — auto-loads `AGENTS.md` and `CLAUDE.md` from the workspace root.
- **`chat.useCustomizationsInParentRepositories: true`** — instructions cascade up in monorepos / nested repos.
- **`chat.useNestedAgentsMdFiles: false`** — only the workspace-root AGENTS.md is loaded (turn on if subprojects need their own).
- **`chat.includeReferencedInstructions: true`** — auto-pull instruction files referenced via Markdown links.

### Skills & hooks

- **`chat.useAgentSkills: true`** — turn skill discovery on globally.
- **`chat.agentSkillsLocations: { ".github/skills": true }`** — workspace skills folder.
- **`chat.hookFilesLocations: { ".github/hooks": true }`** — workspace hooks folder.
- **`chat.promptFilesRecommendations: true`** — recommends installed prompts when starting a new chat session.

### Agent runtime

- **`chat.agent.maxRequests: 50`** — raises the agent's tool-call budget (default 25). Long agent runs need this.
- **`chat.checkpoints.enabled: true`** — rollback safety for agent edits.
- **`chat.mcp.discovery.enabled` + `chat.mcp.autoStart`** — MCP servers start on demand.

### Code generation & helpers

- **`github.copilot.nextEditSuggestions.enabled` + `.fixes`** — Next Edit Suggestions: Copilot proposes the next likely edit after each change, and offers fixes for diagnostics.
- **`github.copilot.chat.commitMessageGeneration.instructions`** — Conventional Commits rules baked in (subject ≤72 chars, body explains WHY, etc.).
- **`github.copilot.chat.pullRequestDescriptionGeneration.instructions`** — Summary / Changes / Test plan template, breaking-change callouts.
- **`github.copilot.chat.terminalChatLocation: "chatView"`** — terminal-side chat goes into the chat view, not floating.

### Telemetry (optional)

- **`github.copilot.chat.otel.enabled: false`** — off by default. Set to `true` and set `otel.exporterType` + `otel.otlpEndpoint` if you have an OTLP collector running locally.

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
4. **Architect → Agent handoff** — start with the `Architect` agent for design, click **"Review the plan"** for a CodeReviewer pass, then **"Implement this plan"** to switch to Agent mode and execute.
5. **Combine prompts and agents** — use `/WriteTests` first, then switch to Agent mode and ask it to make the failing tests pass.
6. **Skill discovery** — give your skills' `description` field a clear "use when …" clause; that string is what the model matches against.
7. **PR review** — add `copilot` as a reviewer on GitHub for automated PR review.
8. **Checkpoints** — `chat.checkpoints.enabled` lets you roll back a bad agent edit.
9. **Autopilot tier** — for trusted repos, switch `chat.permissions.default` to `"autopilot"`. Keep auto-approve regex tight; never auto-approve `curl`/`rm`.

---

## Troubleshooting

**Custom agents don't appear in the dropdown.**
Make sure the files are at `.github/agents/*.agent.md` (not the legacy `.github/chatmodes/`). Reload the VS Code window: `Ctrl+Shift+P → Developer: Reload Window`.

**Slash-prompts don't autocomplete.**
Same fix — files at `.github/prompts/*.prompt.md`. Also verify `chat.promptFilesLocations` isn't overridden somewhere.

**Skills aren't being discovered.**
1. Confirm the file is at `.github/skills/<name>/SKILL.md` (one folder per skill).
2. Ensure frontmatter has both `name` and `description`.
3. Check `chat.useAgentSkills: true` in settings.
4. Reload the window. Skill loading is logged in the Copilot Chat output channel.
5. Make the `description` more specific — vague descriptions get skipped because the model can't decide when to use them.

**Hooks don't fire.**
1. `Ctrl+Shift+P → Output → "GitHub Copilot Chat"` and look for `Load Hooks` lines on session start.
2. Validate JSON (commas, quotes — VS Code's Problems panel will flag bad JSON).
3. Confirm the lifecycle event name is spelled exactly (`PostToolUse`, not `PostTool`).
4. On Windows, use the `windows` override for shell-specific syntax.

**`fetch` MCP server fails to start.**
It needs `uv` on PATH. Install with `winget install astral-sh.uv`, or remove the `fetch` block from `.vscode/mcp.json`.

**`code` not found.**
In VS Code: `Ctrl+Shift+P → Shell Command: Install 'code' command in PATH`.

**Settings keys flagged as unknown.**
You may be on an older VS Code release. The toolkit targets v1.106+ (October 2025+), and uses settings refreshed against the May 2026 reference (skills, hooks, autopilot). Update VS Code.

**`@AgentName` doesn't work.**
Custom agents are not invoked with `@`. Pick them from the **agents dropdown** in chat. `@` is reserved for built-in chat participants (`@workspace`, `@github`, `@terminal`, `@vscode`).

**MCP server fails with "trust required".**
On the first start of a newly added server, VS Code shows a trust dialog. Decline → server stays disabled. Reset via `Ctrl+Shift+P → MCP: Reset Trust`.

**Architect's "Review the plan" handoff is greyed out.**
The handoff targets the `CodeReviewer` agent — make sure `code-reviewer.agent.md` is present in `.github/agents/`. If you only copied a subset of agents, restore CodeReviewer or remove the handoff line from `architect.agent.md`.

---

## References

- [VS Code Copilot — Custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Copilot — Custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [VS Code Copilot — Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [VS Code Copilot — Agent skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [VS Code Copilot — Agent hooks](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [VS Code Copilot — MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- [VS Code Copilot — Settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings)
- [AGENTS.md spec](https://agents.md/)
- [Awesome Copilot — community catalog](https://github.com/github/awesome-copilot)
