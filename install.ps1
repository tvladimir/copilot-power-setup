# Copilot Power Setup — Windows Installer
# Run: .\install.ps1
# Or with project setup: .\install.ps1 -ProjectPath "C:\Projects\my-api" -Template "dotnet-api"

param(
    [string]$ProjectPath = "",
    [ValidateSet("dotnet-api", "react-app", "uikit", "helm-openshift", "")]
    [string]$Template = "",
    [switch]$SkipInstalled,
    [switch]$Skills
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n=== Copilot Power Setup ===" -ForegroundColor Cyan

# ── Step 1: Install Extensions ──
Write-Host "`n[1/4] Installing VS Code extensions..." -ForegroundColor Yellow
$extensions = Get-Content "$ScriptDir\user-level\extensions.txt" | Where-Object { $_ -and $_ -notmatch '^#' }

$installed = @()
if ($SkipInstalled) {
    try { $installed = (& code --list-extensions) | ForEach-Object { $_.Trim().ToLower() } } catch { $installed = @() }
}

$installCount = 0; $skipCount = 0
foreach ($ext in $extensions) {
    $ext = $ext.Trim()
    if (-not $ext) { continue }
    if ($SkipInstalled -and ($installed -contains $ext.ToLower())) {
        Write-Host "  [skip] $ext (already installed)" -ForegroundColor DarkGray
        $skipCount++
        continue
    }
    Write-Host "  Installing $ext..." -ForegroundColor Gray
    code --install-extension $ext --force 2>$null
    $installCount++
}
Write-Host "  Done: $installCount installed, $skipCount skipped" -ForegroundColor Green

# ── Step 2: User Settings ──
Write-Host "`n[2/4] User settings..." -ForegroundColor Yellow
$userSettingsDir = "$env:APPDATA\Code\User"
if (Test-Path $userSettingsDir) {
    Write-Host "  VS Code user settings dir: $userSettingsDir" -ForegroundColor Gray
    Write-Host "  NOTE: Merge user-level\settings.json manually into your existing settings" -ForegroundColor Yellow
    Write-Host "        Ctrl+Shift+P -> 'Open User Settings (JSON)'" -ForegroundColor Yellow
    Write-Host "  NOTE: Merge user-level\keybindings.json into your keybindings" -ForegroundColor Yellow
    Write-Host "        Ctrl+Shift+P -> 'Open Keyboard Shortcuts (JSON)'" -ForegroundColor Yellow
} else {
    Write-Host "  VS Code settings dir not found at $userSettingsDir" -ForegroundColor Red
}

# ── Step 3: User-level Skills (optional) ──
if ($Skills) {
    Write-Host "`n[3/4] Installing user-level skills..." -ForegroundColor Yellow
    $userSkillsDir = "$env:USERPROFILE\.copilot\skills"
    if (-not (Test-Path $userSkillsDir)) { New-Item -ItemType Directory -Path $userSkillsDir -Force | Out-Null }
    $srcSkills = "$ScriptDir\skills-universal"
    if (Test-Path $srcSkills) {
        Copy-Item -Recurse -Force "$srcSkills\*" $userSkillsDir
        $skillCount = (Get-ChildItem $userSkillsDir -Directory).Count
        Write-Host "  Installed $skillCount skills to $userSkillsDir" -ForegroundColor Green
    } else {
        Write-Host "  No skills-universal/ folder found, skipping" -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n[3/4] Skipped user-level skills (use -Skills to install to ~/.copilot/skills/)" -ForegroundColor Gray
}

# ── Step 4: Project Setup ──
if ($ProjectPath -and $Template) {
    Write-Host "`n[4/4] Setting up project: $ProjectPath (template: $Template)" -ForegroundColor Yellow

    $templateDir = "$ScriptDir\templates\$Template"
    if (-not (Test-Path $templateDir)) {
        Write-Host "  Template '$Template' not found!" -ForegroundColor Red
        exit 1
    }

    # Copy template
    $githubDir = "$ProjectPath\.github"
    $vscodeDir = "$ProjectPath\.vscode"

    if (-not (Test-Path $githubDir)) { New-Item -ItemType Directory -Path $githubDir -Force | Out-Null }
    if (-not (Test-Path "$githubDir\agents"))  { New-Item -ItemType Directory -Path "$githubDir\agents"  -Force | Out-Null }
    if (-not (Test-Path "$githubDir\prompts")) { New-Item -ItemType Directory -Path "$githubDir\prompts" -Force | Out-Null }
    if (-not (Test-Path "$githubDir\skills"))  { New-Item -ItemType Directory -Path "$githubDir\skills"  -Force | Out-Null }

    # Copy template files (root .github contents — instructions, hooks, anything else)
    Copy-Item -Recurse -Force "$templateDir\.github\*" $githubDir
    if (Test-Path "$templateDir\.vscode") {
        if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }
        Copy-Item -Recurse -Force "$templateDir\.vscode\*" $vscodeDir
    }

    # Copy universal agents + prompts + skills
    Copy-Item -Force     "$ScriptDir\agents-universal\*"  "$githubDir\agents\"
    Copy-Item -Force     "$ScriptDir\prompts-universal\*" "$githubDir\prompts\"
    if (Test-Path "$ScriptDir\skills-universal") {
        Copy-Item -Recurse -Force "$ScriptDir\skills-universal\*" "$githubDir\skills\"
    }

    # Copy .editorconfig if the template ships one
    if (Test-Path "$templateDir\.editorconfig") {
        Copy-Item -Force "$templateDir\.editorconfig" "$ProjectPath\.editorconfig"
    }

    $agentCount  = (Get-ChildItem "$githubDir\agents\*.agent.md").Count
    $promptCount = (Get-ChildItem "$githubDir\prompts\*.prompt.md").Count
    $skillCount  = (Get-ChildItem "$githubDir\skills" -Directory -ErrorAction SilentlyContinue).Count
    $hookCount   = (Get-ChildItem "$githubDir\hooks\*.json" -ErrorAction SilentlyContinue).Count
    Write-Host "  Copied: $agentCount agents, $promptCount prompts, $skillCount skills, $hookCount hooks, template config" -ForegroundColor Green
} else {
    Write-Host "`n[4/4] Skipped project setup (no -ProjectPath / -Template specified)" -ForegroundColor Gray
    Write-Host "  To setup a project later:" -ForegroundColor Gray
    Write-Host "  .\install.ps1 -ProjectPath 'C:\Projects\my-api' -Template 'dotnet-api'" -ForegroundColor White
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Available templates: dotnet-api, react-app, uikit, helm-openshift" -ForegroundColor Gray
Write-Host "Available agents:    LogDetective | CodeReviewer | Architect | DBDoctor | DevOpsPilot" -ForegroundColor Gray
Write-Host "                     (pick from agents dropdown in Copilot Chat - NOT @-mention)" -ForegroundColor Gray
Write-Host "Available prompts:   /DebugError /WriteTests /ExplainCode /RefactorCode /SqlQuery /HelmDebug" -ForegroundColor Gray
Write-Host "Available skills:    sql-diagnostics, k8s-troubleshooting, log-analysis" -ForegroundColor Gray
Write-Host "                     (auto-discovered by model; or invoke with /skill-name)" -ForegroundColor Gray
Write-Host ""
Write-Host "Flags:" -ForegroundColor DarkGray
Write-Host "  -SkipInstalled    don't reinstall extensions that are already present" -ForegroundColor DarkGray
Write-Host "  -Skills           also copy skills/ to user-level (~\.copilot\skills\)" -ForegroundColor DarkGray
Write-Host ""
