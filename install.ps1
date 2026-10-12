<#
.SYNOPSIS
  One-shot setup: WezTerm + Git Bash + Starship + fzf + zoxide + Nerd Font + GitHub CLI + Claude Code.

.EXAMPLE
  # from a clone
  powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
  # straight from GitHub (public repo only)
  irm https://raw.githubusercontent.com/__REPO__/main/install.ps1 | iex
#>
[CmdletBinding()]
param(
  [switch]$SkipApps,     # only (re)deploy config files
  [switch]$NoBackup      # overwrite existing configs without .bak copies
)

$ErrorActionPreference = 'Stop'
$Repo = '__REPO__'
$Branch = 'main'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Magenta }
function Ok($msg)   { Write-Host "    [ok] $msg" -ForegroundColor Green }
function Info($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "    [!] $msg" -ForegroundColor Yellow }

function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
}

# ------------------------------------------------------------------ locate config files
$Root = $PSScriptRoot
if (-not $Root -or -not (Test-Path (Join-Path $Root 'config\.wezterm.lua'))) {
  Step "Downloading $Repo"
  $tmp = Join-Path $env:TEMP ("wezterm-setup-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $zip = Join-Path $tmp 'repo.zip'
  Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/$Branch.zip" -OutFile $zip -UseBasicParsing
  Expand-Archive $zip -DestinationPath $tmp -Force
  $Root = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName
  Ok "downloaded to $Root"
}
$Cfg = Join-Path $Root 'config'

# ------------------------------------------------------------------ apps
$Apps = @(
  @{ Id = 'wez.wezterm';                  Name = 'WezTerm' },
  @{ Id = 'Git.Git';                      Name = 'Git for Windows (Git Bash)' },
  @{ Id = 'Starship.Starship';            Name = 'Starship prompt' },
  @{ Id = 'junegunn.fzf';                 Name = 'fzf' },
  @{ Id = 'ajeetdsouza.zoxide';           Name = 'zoxide' },
  @{ Id = 'DEVCOM.JetBrainsMonoNerdFont'; Name = 'JetBrainsMono Nerd Font' },
  @{ Id = 'GitHub.cli';                   Name = 'GitHub CLI' },
  @{ Id = 'Anthropic.ClaudeCode';         Name = 'Claude Code' }
)

if (-not $SkipApps) {
  Step 'Installing apps with winget'
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store and re-run.'
  }
  foreach ($a in $Apps) {
    winget list --id $a.Id -e --accept-source-agreements --disable-interactivity *> $null
    if ($LASTEXITCODE -eq 0) { Ok "$($a.Name) already installed"; continue }
    Info "installing $($a.Name)..."
    winget install --id $a.Id -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok $a.Name } else { Warn "$($a.Name) failed (winget exit $LASTEXITCODE)" }
  }
  Refresh-Path
}

# ------------------------------------------------------------------ config files
Step 'Deploying config files'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Targets = @(
  @{ Src = '.wezterm.lua';  Dst = Join-Path $HOME '.wezterm.lua' },
  @{ Src = '.bashrc';       Dst = Join-Path $HOME '.bashrc' },
  @{ Src = '.bash_profile'; Dst = Join-Path $HOME '.bash_profile' },
  @{ Src = '.inputrc';      Dst = Join-Path $HOME '.inputrc' },
  @{ Src = 'starship.toml'; Dst = Join-Path $HOME '.config\starship.toml' }
)
foreach ($t in $Targets) {
  $src = Join-Path $Cfg $t.Src
  New-Item -ItemType Directory -Force (Split-Path $t.Dst) | Out-Null
  if ((Test-Path $t.Dst) -and -not $NoBackup) {
    if ((Get-FileHash $src).Hash -eq (Get-FileHash $t.Dst).Hash) { Ok "$($t.Dst) (unchanged)"; continue }
    Copy-Item $t.Dst "$($t.Dst).bak-$stamp"
    Info "backed up $($t.Dst) -> .bak-$stamp"
  }
  Copy-Item $src $t.Dst -Force   # byte copy keeps LF endings
  Ok $t.Dst
}

# ------------------------------------------------------------------ git defaults
Step 'Configuring git'
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { $git = 'C:\Program Files\Git\cmd\git.exe' } else { $git = $git.Source }
if (Test-Path $git) {
  $defaults = [ordered]@{
    'init.defaultBranch'   = 'main'
    'pull.rebase'          = 'true'
    'fetch.prune'          = 'true'
    'rebase.autoStash'     = 'true'
    'push.autoSetupRemote' = 'true'
    'core.autocrlf'        = 'true'
    'color.ui'             = 'auto'
    'diff.colorMoved'      = 'zebra'
    'merge.conflictstyle'  = 'zdiff3'
    'rerere.enabled'       = 'true'
    'branch.sort'          = '-committerdate'
  }
  foreach ($k in $defaults.Keys) { & $git config --global $k $defaults[$k] }
  if (-not (& $git config --global core.editor)) { & $git config --global core.editor notepad }
  Ok 'defaults applied'

  foreach ($k in 'user.name', 'user.email') {
    if (-not (& $git config --global $k)) {
      $v = Read-Host "    git $k"
      if ($v) { & $git config --global $k $v; Ok "$k set" } else { Warn "$k not set" }
    }
  }
} else {
  Warn 'git not found, skipped'
}

# ------------------------------------------------------------------ done
Step 'Done'
Write-Host @'
    Open WezTerm (close any running instance first).
    Next steps:
      gh auth login      # GitHub CLI
      claude             # Claude Code (log in on first run)
    Cheatsheet: see README.md
'@ -ForegroundColor Cyan
