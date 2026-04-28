#!/usr/bin/env bash
# Copilot Power Setup — Windows installer (Bash variant)
# Run from Git Bash, WSL, or Cygwin. Equivalent to install.ps1 — pick your shell.
#
# Usage:
#   ./install.sh
#   ./install.sh --project /c/Projects/my-api --template dotnet-api

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH=""
TEMPLATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)  PROJECT_PATH="$2"; shift 2 ;;
    --template) TEMPLATE="$2";     shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--project PATH] [--template NAME]

  --project   Path to the target repo (Git Bash style, e.g. /c/Projects/my-api)
  --template  One of: dotnet-api, react-app, uikit, helm-openshift

Without flags: installs extensions and prints settings-merge instructions.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Resolve VS Code User dir on Windows (Git Bash sets APPDATA automatically).
if [[ -n "${APPDATA:-}" ]]; then
  USER_DIR="$APPDATA/Code/User"
elif [[ -n "${USERPROFILE:-}" ]]; then
  USER_DIR="$USERPROFILE/AppData/Roaming/Code/User"
else
  echo "Cannot resolve VS Code User dir. Run from Git Bash, WSL, or Cygwin." >&2
  exit 1
fi

echo "=== Copilot Power Setup (Windows / Bash) ==="

# ── 1. Extensions ──
echo
echo "[1/3] Installing VS Code extensions…"
if ! command -v code >/dev/null 2>&1; then
  echo "  'code' is not on PATH. In VS Code: Ctrl+Shift+P -> 'Shell Command: Install code in PATH'" >&2
  exit 1
fi

COUNT=0
while IFS= read -r line; do
  ext="${line%%#*}"
  ext="$(echo "$ext" | tr -d '[:space:]')"
  [[ -z "$ext" ]] && continue
  echo "  $ext"
  code --install-extension "$ext" --force >/dev/null 2>&1 || echo "    (failed)"
  COUNT=$((COUNT + 1))
done < "$SCRIPT_DIR/user-level/extensions.txt"
echo "  Done ($COUNT extensions)"

# ── 2. User config ──
echo
echo "[2/3] User config dir: $USER_DIR"
echo "  MERGE manually (do not overwrite the file):"
echo "    $SCRIPT_DIR/user-level/settings.json     -> $USER_DIR/settings.json"
echo "    $SCRIPT_DIR/user-level/keybindings.json  -> $USER_DIR/keybindings.json"
echo "  In VS Code: Ctrl+Shift+P -> 'Open User Settings (JSON)' / 'Open Keyboard Shortcuts (JSON)'"

# ── 3. Project setup ──
if [[ -n "$PROJECT_PATH" && -n "$TEMPLATE" ]]; then
  echo
  echo "[3/3] Setting up project: $PROJECT_PATH (template: $TEMPLATE)"
  TPL_DIR="$SCRIPT_DIR/templates/$TEMPLATE"
  if [[ ! -d "$TPL_DIR" ]]; then
    echo "  Template '$TEMPLATE' not found." >&2
    exit 1
  fi
  mkdir -p "$PROJECT_PATH/.github/agents" "$PROJECT_PATH/.github/prompts"
  cp -R "$TPL_DIR/.github/." "$PROJECT_PATH/.github/"
  if [[ -d "$TPL_DIR/.vscode" ]]; then
    mkdir -p "$PROJECT_PATH/.vscode"
    cp -R "$TPL_DIR/.vscode/." "$PROJECT_PATH/.vscode/"
  fi
  cp "$SCRIPT_DIR/agents-universal/"*.agent.md   "$PROJECT_PATH/.github/agents/"
  cp "$SCRIPT_DIR/prompts-universal/"*.prompt.md "$PROJECT_PATH/.github/prompts/"
  AC=$(ls -1 "$PROJECT_PATH/.github/agents/"*.agent.md   2>/dev/null | wc -l | tr -d ' ')
  PC=$(ls -1 "$PROJECT_PATH/.github/prompts/"*.prompt.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  Copied: $AC agents, $PC prompts, template config"
else
  echo
  echo "[3/3] Skipped project setup (use --project + --template to configure a repo)"
fi

echo
echo "=== Setup complete ==="
echo "Templates: dotnet-api  react-app  uikit  helm-openshift"
echo "Agents:    LogDetective | CodeReviewer | Architect | DBDoctor | DevOpsPilot"
echo "           (pick from agents dropdown in Copilot Chat — extension only, gh copilot CLI is blocked)"
echo "Prompts:   /DebugError  /WriteTests  /ExplainCode  /RefactorCode  /SqlQuery  /HelmDebug"
