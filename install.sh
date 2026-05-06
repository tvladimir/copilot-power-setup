#!/usr/bin/env bash
# Copilot Power Setup — Windows installer (Bash variant)
# Run from Git Bash, WSL, or Cygwin. Equivalent to install.ps1 — pick your shell.
#
# Usage:
#   ./install.sh
#   ./install.sh --project /c/Projects/my-api --template dotnet-api
#   ./install.sh --skip-installed         # don't reinstall extensions already present
#   ./install.sh --skills                 # also copy skills/ to ~/.copilot/skills/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH=""
TEMPLATE=""
SKIP_INSTALLED=0
USER_SKILLS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)        PROJECT_PATH="$2"; shift 2 ;;
    --template)       TEMPLATE="$2";     shift 2 ;;
    --skip-installed) SKIP_INSTALLED=1;  shift ;;
    --skills)         USER_SKILLS=1;     shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--project PATH] [--template NAME] [--skip-installed] [--skills]

  --project          Path to the target repo (Git Bash style, e.g. /c/Projects/my-api)
  --template         One of: dotnet-api, react-app, uikit, helm-openshift
  --skip-installed   Don't reinstall extensions that 'code --list-extensions' already shows
  --skills           Copy skills-universal/ into ~/.copilot/skills/ (user-level)

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

# User-level skills target: ~/.copilot/skills/  (HOME on Git Bash maps to %USERPROFILE%)
USER_SKILLS_DIR="$HOME/.copilot/skills"

echo "=== Copilot Power Setup (Windows / Bash) ==="

# ── 1. Extensions ──
echo
echo "[1/4] Installing VS Code extensions…"
if ! command -v code >/dev/null 2>&1; then
  echo "  'code' is not on PATH. In VS Code: Ctrl+Shift+P -> 'Shell Command: Install code in PATH'" >&2
  exit 1
fi

INSTALLED_LIST=""
if [[ "$SKIP_INSTALLED" -eq 1 ]]; then
  INSTALLED_LIST="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
fi

INSTALL_COUNT=0
SKIP_COUNT=0
while IFS= read -r line; do
  ext="${line%%#*}"
  ext="$(echo "$ext" | tr -d '[:space:]')"
  [[ -z "$ext" ]] && continue
  if [[ "$SKIP_INSTALLED" -eq 1 ]] && echo "$INSTALLED_LIST" | grep -qx "$(echo "$ext" | tr '[:upper:]' '[:lower:]')"; then
    echo "  [skip] $ext (already installed)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi
  echo "  $ext"
  code --install-extension "$ext" --force >/dev/null 2>&1 || echo "    (failed)"
  INSTALL_COUNT=$((INSTALL_COUNT + 1))
done < "$SCRIPT_DIR/user-level/extensions.txt"
echo "  Done: $INSTALL_COUNT installed, $SKIP_COUNT skipped"

# ── 2. User config ──
echo
echo "[2/4] User config dir: $USER_DIR"
echo "  MERGE manually (do not overwrite the file):"
echo "    $SCRIPT_DIR/user-level/settings.json     -> $USER_DIR/settings.json"
echo "    $SCRIPT_DIR/user-level/keybindings.json  -> $USER_DIR/keybindings.json"
echo "  In VS Code: Ctrl+Shift+P -> 'Open User Settings (JSON)' / 'Open Keyboard Shortcuts (JSON)'"

# ── 3. User-level skills (optional) ──
if [[ "$USER_SKILLS" -eq 1 ]]; then
  echo
  echo "[3/4] Installing user-level skills…"
  if [[ -d "$SCRIPT_DIR/skills-universal" ]]; then
    mkdir -p "$USER_SKILLS_DIR"
    cp -R "$SCRIPT_DIR/skills-universal/." "$USER_SKILLS_DIR/"
    SC=$(find "$USER_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    echo "  Installed $SC skills to $USER_SKILLS_DIR"
  else
    echo "  No skills-universal/ folder found, skipping"
  fi
else
  echo
  echo "[3/4] Skipped user-level skills (use --skills to install to ~/.copilot/skills/)"
fi

# ── 4. Project setup ──
if [[ -n "$PROJECT_PATH" && -n "$TEMPLATE" ]]; then
  echo
  echo "[4/4] Setting up project: $PROJECT_PATH (template: $TEMPLATE)"
  TPL_DIR="$SCRIPT_DIR/templates/$TEMPLATE"
  if [[ ! -d "$TPL_DIR" ]]; then
    echo "  Template '$TEMPLATE' not found." >&2
    exit 1
  fi
  mkdir -p "$PROJECT_PATH/.github/agents" "$PROJECT_PATH/.github/prompts" "$PROJECT_PATH/.github/skills"
  cp -R "$TPL_DIR/.github/." "$PROJECT_PATH/.github/"
  if [[ -d "$TPL_DIR/.vscode" ]]; then
    mkdir -p "$PROJECT_PATH/.vscode"
    cp -R "$TPL_DIR/.vscode/." "$PROJECT_PATH/.vscode/"
  fi
  cp "$SCRIPT_DIR/agents-universal/"*.agent.md     "$PROJECT_PATH/.github/agents/"
  cp "$SCRIPT_DIR/prompts-universal/"*.prompt.md   "$PROJECT_PATH/.github/prompts/"
  if [[ -d "$SCRIPT_DIR/skills-universal" ]]; then
    cp -R "$SCRIPT_DIR/skills-universal/." "$PROJECT_PATH/.github/skills/"
  fi
  if [[ -f "$TPL_DIR/.editorconfig" ]]; then
    cp "$TPL_DIR/.editorconfig" "$PROJECT_PATH/.editorconfig"
  fi
  AC=$(ls -1 "$PROJECT_PATH/.github/agents/"*.agent.md     2>/dev/null | wc -l | tr -d ' ')
  PC=$(ls -1 "$PROJECT_PATH/.github/prompts/"*.prompt.md   2>/dev/null | wc -l | tr -d ' ')
  SC=$(find "$PROJECT_PATH/.github/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  HC=$(ls -1 "$PROJECT_PATH/.github/hooks/"*.json          2>/dev/null | wc -l | tr -d ' ')
  echo "  Copied: $AC agents, $PC prompts, $SC skills, $HC hooks, template config"
else
  echo
  echo "[4/4] Skipped project setup (use --project + --template to configure a repo)"
fi

echo
echo "=== Setup complete ==="
echo "Templates: dotnet-api  react-app  uikit  helm-openshift"
echo "Agents:    LogDetective | CodeReviewer | Architect | DBDoctor | DevOpsPilot"
echo "           (pick from agents dropdown in Copilot Chat — extension only, gh copilot CLI is blocked)"
echo "Prompts:   /DebugError  /WriteTests  /ExplainCode  /RefactorCode  /SqlQuery  /HelmDebug"
echo "Skills:    sql-diagnostics  k8s-troubleshooting  log-analysis"
echo "           (auto-discovered by model; or invoke with /skill-name)"
