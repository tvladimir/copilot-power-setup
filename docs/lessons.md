# Lessons

Running log of corrections, surprises, and reasoning that informs future work in this repo.

## 2026-04-27 — Initial audit retraction

- **What happened:** First-pass audit incorrectly flagged `.agent.md` / `.github/agents/` as "fictional", `handoffs:` frontmatter as invented, and 7 of 15 settings keys as hallucinated.
- **What was wrong:** Memory of older Copilot conventions; did not verify against current docs (April 2026).
- **Correct approach:** Before claiming "this is fictional" about a Copilot file format, frontmatter field, or settings key, verify against the official references:
  - https://code.visualstudio.com/docs/copilot/customization/custom-agents
  - https://code.visualstudio.com/docs/copilot/reference/copilot-settings
  - https://code.visualstudio.com/docs/copilot/customization/mcp-servers
- The actually broken bits were: tool IDs (slashed `search/codebase` etc.), the README's `@AgentName` invocation claim, and the MCP package names in the README example.

## 2026-04-27 — Tool IDs are flat, not slashed

- **What happened:** Project had `tools: ['cli', 'search/codebase', 'web/fetch']`.
- **What was wrong:** No slashed namespaces in built-in tool IDs; `cli` doesn't exist as a tool name.
- **Correct approach:** Use the canonical flat IDs: `runCommands`, `codebase`, `usages`, `search`, `fetch`, `githubRepo`, `editFiles`, `runTasks`, `terminalLastCommand`, `terminalSelection`, `problems`, `changes`, `todos`, `findTestFiles`, `testFailure`, `extensions`, `vscodeAPI`, `think`. Slashed forms are valid only for MCP wildcards: `<server>/*`.

## 2026-04-27 — Custom agents are picked from a dropdown, not @-mentioned

- **What happened:** README claimed `@LogDetective`, `@Architect`, etc.
- **What was wrong:** `@` in Copilot Chat is reserved for built-in chat participants (workspace / terminal / vscode / github), which come from VS Code extensions — they cannot be added with a markdown file.
- **Correct approach:** Document custom agents as "selected from the agents dropdown in Chat". Reserve `@` examples for built-in participants, `/` for prompt files, and the dropdown for agents.

## 2026-04-27 — MCP package names must be verified against npm

- **What happened:** README example referenced `@modelcontextprotocol/server-mssql` and `@microsoft/mcp-server-playwright`.
- **What was wrong:** Both packages do not exist on npm. The first returns 404; the second is invented.
- **Correct approach:** Verified package names (April 2026):
  - GitHub: hosted HTTP at `https://api.githubcopilot.com/mcp` (`type: "http"`)
  - Playwright: `@playwright/mcp@latest` (Microsoft / Playwright team)
  - Filesystem: `@modelcontextprotocol/server-filesystem`
  - Fetch: Python `uvx mcp-server-fetch` (no npm package exists)
  - MSSQL: third-party `mssql-mcp-server` on npm (no first-party MS npm package; Microsoft has C# `microsoft/SQL-AI-samples/MssqlMcp`)

## 2026-04-27 — `applyTo:` only on `.instructions.md`, not root `copilot-instructions.md`

- **What happened:** Templates had `applyTo: "**"` on the root `copilot-instructions.md`.
- **What was wrong:** Frontmatter on the root file is silently ignored — it's always-on regardless. `applyTo:` is meaningful only on path-scoped `.github/instructions/*.instructions.md`.
- **Correct approach:** Drop the `applyTo` frontmatter from root files (kept here for now since it's harmless; clean up in a future pass if the editor flags it as a warning).

## 2026-05-06 — Verify both directions: not just claims, also your own skepticism

- **What happened:** Reviewing a 15-point improvement plan from Copilot research, I rejected ~7 items as "probably hallucinated" (skills, hooks, `chat.autopilot.enabled`, `chat.permissions.default`, `agents:` subagent frontmatter, `argument-hint`, etc.) without opening the docs.
- **What was wrong:** I applied the "verify before claiming" rule one-sidedly — only against suggestions, not against my own absence of memory. "I don't recall this feature" is a signal to verify, not to dismiss.
- **Correct approach:** Before pushing back on a Copilot/VS Code feature claim, fetch the official reference page (`copilot-settings`, `custom-agents`, `agent-skills`, `hooks`, `prompt-files`) and grep for the term. Empty result → push back. Match → accept. Memory of "I haven't seen this" is unreliable evidence — VS Code Copilot ships features quarterly.
- **Verified real (May 2026)**: Agent Skills (`.github/skills/<name>/SKILL.md`, stable since Jan 2026), Agent Hooks (`.github/hooks/*.json`, 8 lifecycle events), `chat.autopilot.enabled`, `chat.permissions.default`, `chat.tools.terminal.outputLocation`, `chat.promptFilesRecommendations`, `chat.includeReferencedInstructions`, `chat.hookFilesLocations`, `chat.agentSkillsLocations`, `github.copilot.chat.commitMessageGeneration.instructions`, `github.copilot.chat.pullRequestDescriptionGeneration.instructions`, `github.copilot.chat.otel.enabled`. Frontmatter on `*.agent.md`: `agents`, `argument-hint`, `model`, `user-invocable`, `disable-model-invocation`. Frontmatter on `*.prompt.md`: `agent`, `model`, `argument-hint`.
- **Verified false:** `${input:}` syntax is NOT deprecated; `vscode/askQuestion` is an alternative tool, not a replacement.

## 2026-04-27 — Windows-only target; Copilot CLI blocked

- **What happened:** Initial design treated this as a portable Mac↔Windows toolkit; in reality the target environment is Windows only, and the GitHub Copilot CLI (`gh copilot`) is blocked by org policy.
- **What was wrong:**
  - `install.sh` had macOS / Linux branches and `~/Library/...` paths that don't apply.
  - `chat.agent.sandbox.enabled` was set in `user-level/settings.json` — this setting is macOS / Linux only and a no-op on Windows.
  - README claimed "portable" / "works on macOS, Linux, Windows" — misleading for the actual target.
- **Correct approach:**
  - Windows only. Keep both `install.ps1` (PowerShell) and `install.sh` (Git Bash) since both shells exist on Windows; the Bash variant uses `$APPDATA/Code/User`.
  - Drop macOS-only settings (`chat.agent.sandbox.enabled`).
  - Everything runs through the VS Code Copilot **extension**: Chat, Agent mode, MCP. The agent's `runCommands` tool runs in the integrated terminal — it's NOT the blocked `gh copilot` CLI.
  - Don't document or suggest `gh copilot suggest` / `gh copilot explain` workflows.
  - For MCP `fetch` (Python `uvx mcp-server-fetch`): note the `uv` dependency in `.vscode/mcp.json`; offer "remove this block if uv is unavailable" instead of assuming it works.
