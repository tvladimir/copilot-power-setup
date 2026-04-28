# Copilot Power Setup — Windows Installer
# Run: .\install.ps1
# Or with project setup: .\install.ps1 -ProjectPath "C:\Projects\my-api" -Template "dotnet-api"

param(
    [string]$ProjectPath = "",
    [ValidateSet("dotnet-api", "react-app", "uikit", "helm-openshift", "")]
    [string]$Template = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n=== Copilot Power Setup ===" -ForegroundColor Cyan

# ── Step 1: Install Extensions ──
Write-Host "`n[1/3] Installing VS Code extensions..." -ForegroundColor Yellow
$extensions = Get-Content "$ScriptDir\user-level\extensions.txt" | Where-Object { $_ -and $_ -notmatch '^#' }
foreach ($ext in $extensions) {
    $ext = $ext.Trim()
    if ($ext) {
        Write-Host "  Installing $ext..." -ForegroundColor Gray
        code --install-extension $ext --force 2>$null
    }
}
Write-Host "  Done! ($($extensions.Count) extensions)" -ForegroundColor Green

# ── Step 2: User Settings ──
Write-Host "`n[2/3] User settings..." -ForegroundColor Yellow
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

# ── Step 3: Project Setup ──
if ($ProjectPath -and $Template) {
    Write-Host "`n[3/3] Setting up project: $ProjectPath (template: $Template)" -ForegroundColor Yellow

    $templateDir = "$ScriptDir\templates\$Template"
    if (-not (Test-Path $templateDir)) {
        Write-Host "  Template '$Template' not found!" -ForegroundColor Red
        exit 1
    }

    # Copy template
    $githubDir = "$ProjectPath\.github"
    $vscodeDir = "$ProjectPath\.vscode"

    if (-not (Test-Path $githubDir)) { New-Item -ItemType Directory -Path $githubDir -Force | Out-Null }
    if (-not (Test-Path "$githubDir\agents")) { New-Item -ItemType Directory -Path "$githubDir\agents" -Force | Out-Null }
    if (-not (Test-Path "$githubDir\prompts")) { New-Item -ItemType Directory -Path "$githubDir\prompts" -Force | Out-Null }

    # Copy template files
    Copy-Item -Recurse -Force "$templateDir\.github\*" $githubDir
    if (Test-Path "$templateDir\.vscode") {
        if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }
        Copy-Item -Recurse -Force "$templateDir\.vscode\*" $vscodeDir
    }

    # Copy universal agents + prompts
    Copy-Item -Force "$ScriptDir\agents-universal\*" "$githubDir\agents\"
    Copy-Item -Force "$ScriptDir\prompts-universal\*" "$githubDir\prompts\"

    $agentCount = (Get-ChildItem "$githubDir\agents\*.agent.md").Count
    $promptCount = (Get-ChildItem "$githubDir\prompts\*.prompt.md").Count
    Write-Host "  Copied: $agentCount agents, $promptCount prompts, template config" -ForegroundColor Green
} else {
    Write-Host "`n[3/3] Skipped project setup (no -ProjectPath / -Template specified)" -ForegroundColor Gray
    Write-Host "  To setup a project later:" -ForegroundColor Gray
    Write-Host "  .\install.ps1 -ProjectPath 'C:\Projects\my-api' -Template 'dotnet-api'" -ForegroundColor White
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Available templates: dotnet-api, react-app, uikit, helm-openshift" -ForegroundColor Gray
Write-Host "Available agents:    LogDetective | CodeReviewer | Architect | DBDoctor | DevOpsPilot" -ForegroundColor Gray
Write-Host "                     (pick from agents dropdown in Copilot Chat - NOT @-mention)" -ForegroundColor Gray
Write-Host "Available prompts:   /DebugError /WriteTests /ExplainCode /RefactorCode /SqlQuery /HelmDebug" -ForegroundColor Gray
Write-Host ""
