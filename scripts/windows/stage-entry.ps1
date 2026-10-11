#Requires -Version 5.1
[CmdletBinding()]
param([ValidateSet('Before','After')][string] $Stage, [string] $ContextJson)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
if (-not $pwsh) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'install.ps1') -Mode Bootstrap
    if ($LASTEXITCODE -ne 0) { throw 'PowerShell 7 bootstrap failed.' }
    $env:Path = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'))
    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
    if (-not $pwsh) { throw 'PowerShell 7 unavailable after bootstrap.' }
}
# Avoid PowerShell 5.1 native quoting of JSON and command-line length limits.
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-context-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $scratch
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
& icacls $scratch /inheritance:r /grant:r "*${sid}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Cannot protect installation context.' }
try {
    $contextFile = Join-Path $scratch 'context.json'
    [IO.File]::WriteAllText($contextFile,$ContextJson,[Text.UTF8Encoding]::new($false))
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'scripts/windows/install.ps1') -Stage $Stage -ContextPath $contextFile
    $stageExitCode = $LASTEXITCODE
} finally { Remove-Item -LiteralPath $scratch -Recurse -Force }
exit $stageExitCode
