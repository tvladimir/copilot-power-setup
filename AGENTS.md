# AGENTS.md — Copilot Power Setup

Cross-tool instructions for AI agents (Copilot, Claude Code, Cursor) working in **this** repo.
Auto-loaded by VS Code Copilot via `chat.useAgentsMdFile`.

## What this repo is

A personal toolkit for configuring GitHub Copilot in VS Code on **Windows** (work environment). It is **not** a runnable app — it ships installable artifacts: custom agents, prompt files, instruction files, settings, per-stack templates, and installers (PowerShell + Git Bash).

## Layout

- `agents-universal/` — `*.agent.md` files copied into any project's `.github/agents/`
- `prompts-universal/` — `*.prompt.md` files copied into any project's `.github/prompts/`
- `templates/<stack>/` — per-stack starter `.github/` and `.vscode/` configs (dotnet-api, react-app, uikit, helm-openshift)
- `user-level/` — global VS Code config (`settings.json`, `keybindings.json`, `extensions.txt`) to merge into the user profile
- `install.ps1` — Windows / PowerShell installer
- `install.sh` — Windows / Git Bash installer (equivalent functionality, different shell)
- `docs/lessons.md` — running log of corrections and decisions

## Conventions when editing this repo

- **Tool IDs in agent / prompt frontmatter are FLAT** (no slashes): `codebase`, `usages`, `editFiles`, `runCommands`, `runTasks`, `terminalLastCommand`, `terminalSelection`, `fetch`, `githubRepo`, `search`, `problems`, `changes`, `todos`, `findTestFiles`, `testFailure`, `extensions`, `vscodeAPI`, `think`. MCP wildcard: `<server>/*` (e.g. `playwright/*`).
- **Custom agents** live in `.github/agents/*.agent.md` (canonical since VS Code v1.106, Oct 2025). Old `.chatmode.md` form still works for back-compat but new files use `.agent.md`.
- **Prompt files** use `${input:name:placeholder}` for user-provided variables; `${selection}` for current editor selection.
- `applyTo:` frontmatter is meaningful only on `.github/instructions/*.instructions.md`. On the root `copilot-instructions.md` it is ignored (root file is always-on).
- Top-level key in `.vscode/mcp.json` is **`servers`** (NOT `mcpServers`).
- Custom agents are picked from the **agents dropdown** in chat — never claim `@AgentName` invocation.

## When changing this repo

- Verify any new settings key against the [Copilot Settings Reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings) before adding to `user-level/settings.json`.
- Verify any MCP package name against npmjs.org (or the relevant registry) before referencing in templates / README.
- Keep both PowerShell and Git Bash variants when adding install steps — both shells are used on Windows.
- Append a new entry to `docs/lessons.md` whenever the user corrects an assumption — include date, what happened, what was wrong, correct approach.

## Don'ts

- Don't invent tool IDs — VS Code silently ignores unknown ones, so the agent fails open without the intended capability.
- Don't claim `@AgentName` invocation for custom agents.
- Don't ship MCP package names without verifying they exist on npm / PyPI.
- Don't add `applyTo:` frontmatter to the root `copilot-instructions.md`.
- Don't replace cross-platform `.sh` / `.ps1` pairs with a single OS-specific installer.

## Constraints (target environment)

- **Windows only.** All paths and installers target Windows. Both PowerShell (`install.ps1`) and Git Bash (`install.sh`) are supported — pick whichever shell is preferred.
- **Extension only — Copilot CLI is blocked.** `gh copilot` is unavailable in this environment. Everything must work through the VS Code Copilot extension (Chat / Agent mode / MCP). Don't document `gh copilot suggest` / `gh copilot explain` workflows.
- The agent's `runCommands` / `terminalLastCommand` tools are extension features running in the integrated terminal — they are NOT the blocked Copilot CLI, so they work fine.
- `chat.agent.sandbox.*` settings are macOS / Linux only — do NOT add them to `user-level/settings.json`.
- The `fetch` MCP server requires `uv` (`winget install astral-sh.uv`). Remove the `fetch` block from any `.vscode/mcp.json` if `uv` is unavailable.

## References

- [Custom agents (VS Code docs)](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [Custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- [Settings reference](https://code.visualstudio.com/docs/copilot/reference/copilot-settings)
- [AGENTS.md spec](https://agents.md/)
- [Awesome Copilot (community catalog)](https://github.com/github/awesome-copilot)
