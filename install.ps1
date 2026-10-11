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

Write-Output 'dotfiles: foundation phase'
Write-Output "Repository: $repoRoot"
Write-Output '1. Review platform, current configuration and installation ownership.'
Write-Output '2. Prepare Git, mise and chezmoi in a separately authorized bootstrap.'
Write-Output '3. Initialize machine data and review a configuration diff.'
Write-Output '4. Apply only the reviewed migration, then install and verify selected tools.'
Write-Output 'This entry point currently prints a plan or checks prerequisites only.'
