#Requires -Version 7.0
[CmdletBinding()]
param(
  [ValidateSet('Plan', 'Check', 'Bootstrap', 'Diff', 'Apply', 'Verify', 'DesktopPlan', 'DesktopApply')]
  [string] $Mode = 'Plan',
  [string] $ProfilePath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if ($IsWindows -and $Mode -ne 'Check') {
  & (Join-Path $repoRoot 'scripts/windows/install.ps1') -Mode $Mode -ProfilePath $ProfilePath
  exit $LASTEXITCODE
}

if ($Mode -in @('DesktopPlan', 'DesktopApply')) {
  $python = Get-Command python3, python -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $python) { throw 'Python 3.11+ is required for native application installation.' }
  $stage = if ($Mode -eq 'DesktopPlan') { '--desktop-plan' } else { '--desktop-only' }
  & $python.Source (Join-Path $repoRoot 'scripts/unix/install.py') $stage
  exit $LASTEXITCODE
}

if ($Mode -eq 'Check') {
  & (Join-Path $repoRoot 'scripts/windows/check.ps1')
  exit $LASTEXITCODE
}

Write-Output 'dotfiles: Fedora configuration draft; deployment disabled'
Write-Output "Repository: $repoRoot"
Write-Output '1. Review platform, current configuration and installation ownership.'
Write-Output '2. Prepare Git, mise and chezmoi in a separately authorized bootstrap.'
Write-Output '3. Initialize machine data and review a configuration diff.'
Write-Output '4. Prepare selected tool prerequisites, then apply only the separately reviewed migration.'
Write-Output 'This entry point currently prints a plan or checks prerequisites only.'
