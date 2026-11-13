<#
.SYNOPSIS
  Install or update WezTerm to the latest nightly build from GitHub.

.DESCRIPTION
  Compares the SHA-256 digest GitHub publishes for the nightly installer with the one recorded at the last install
  (%LOCALAPPDATA%\wezterm-setup\nightly.sha256) and installs only when they differ. The download is checked against
  that digest. Run from inside WezTerm, it opens a separate window that waits until WezTerm is closed, updates it and
  starts it again (the installer can't replace files of a running WezTerm).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\update-wezterm.ps1
#>
[CmdletBinding()]
param(
  [switch]$Force,           # reinstall even when the recorded digest matches
  [switch]$AfterWezTerm     # internal: wait for WezTerm to exit, then install and restart it
)

$ErrorActionPreference = 'Stop'
$Name = 'WezTerm-nightly-setup.exe'
$Gui = 'C:\Program Files\WezTerm\wezterm-gui.exe'
$State = Join-Path $env:LOCALAPPDATA 'wezterm-setup\nightly.sha256'

function Ok($msg)   { Write-Host "    [ok] $msg" -ForegroundColor Green }
function Info($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "    [!] $msg" -ForegroundColor Yellow }

$asset = (Invoke-RestMethod 'https://api.github.com/repos/wezterm/wezterm/releases/tags/nightly').assets |
  Where-Object name -eq $Name
if (-not $asset) { throw "$Name not found in the GitHub nightly release" }

$installed = if (Test-Path $State) { (Get-Content $State -Raw).Trim() } else { '' }
if (-not $Force -and (Test-Path $Gui) -and $installed -eq $asset.digest) {
  Ok "WezTerm nightly is up to date (built $($asset.updated_at))"
  return
}

if (-not $AfterWezTerm -and (Get-Process wezterm-gui -ErrorAction SilentlyContinue)) {
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-AfterWezTerm')
  if ($Force) { $argList += '-Force' }
  Start-Process powershell -ArgumentList $argList
  Warn "WezTerm is running. Close all WezTerm windows; a separate window then updates it and starts it again."
  return
}

if ($AfterWezTerm) {
  Info 'waiting for WezTerm to close...'
  while (Get-Process wezterm-gui -ErrorAction SilentlyContinue) { Start-Sleep 2 }
}

Info "downloading the nightly built $($asset.updated_at)..."
$dir = Join-Path $env:TEMP ('wezterm-nightly-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $dir | Out-Null
try {
  $setup = Join-Path $dir $Name
  Invoke-WebRequest $asset.browser_download_url -OutFile $setup -UseBasicParsing
  $digest = 'sha256:' + (Get-FileHash $setup -Algorithm SHA256).Hash.ToLower()
  if ($digest -ne $asset.digest) { throw 'download does not match the GitHub digest; not installed' }

  Info 'installing (Windows asks for admin rights)...'
  $p = Start-Process $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Verb RunAs -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "installer exit code $($p.ExitCode)" }

  New-Item -ItemType Directory -Force (Split-Path $State) | Out-Null
  Set-Content -Path $State -Value $asset.digest -Encoding ascii
  Ok "WezTerm $((& 'C:\Program Files\WezTerm\wezterm.exe' --version) -replace '^wezterm ', '')"
} catch {
  Warn "WezTerm update failed: $_"
  if ($AfterWezTerm) { Read-Host 'Enter to close' }
  exit 1
} finally {
  Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($AfterWezTerm) { Start-Process $Gui }
