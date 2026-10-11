#Requires -Version 7.0
[CmdletBinding()]
param(
  [ValidateSet('Plan', 'Check')]
  [string] $Mode = 'Plan'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

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
