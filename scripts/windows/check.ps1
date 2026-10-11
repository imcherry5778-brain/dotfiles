#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

foreach ($relative in @('.chezmoiroot', 'home/.chezmoi.toml.tmpl', 'home/.chezmoidata.toml', 'home/.chezmoiignore', 'mise.toml')) {
  if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relative) -PathType Leaf)) {
    throw "Missing file: $relative"
  }
}
if ((Get-Content -LiteralPath (Join-Path $repoRoot '.chezmoiroot') -Raw).Trim() -ne 'home') {
  throw 'Invalid chezmoi source root.'
}
if (@(Get-Content -LiteralPath (Join-Path $repoRoot 'home/.chezmoiignore')) -notcontains '**') {
  throw 'Foundation deployment boundary is missing.'
}

foreach ($file in @('install.ps1', 'scripts/windows/check.ps1')) {
  $tokens = $null
  $parseErrors = $null
  $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $file), [ref] $tokens, [ref] $parseErrors)
  if ($parseErrors.Count -gt 0) { throw "Invalid PowerShell syntax: $file" }
}
Write-Output 'Repository structure and PowerShell syntax: OK'

foreach ($tool in @('git', 'mise', 'chezmoi')) {
  if (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue) {
    Write-Output "Available prerequisite: $tool"
  } else {
    Write-Output "Missing future bootstrap prerequisite: $tool (not installed by this check)"
  }
}
Write-Output 'No user configuration or packages were changed.'
exit 0
