#Requires -Version 5.1
# Exercise the missing-pwsh handoff without downloading or installing anything.
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
foreach ($relative in @('install.ps1','tests/windows-install.ps1')) {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo $relative), [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw "PowerShell 5.1 cannot parse $relative" }
}
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('windows51 contract with spaces ' + [Guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $scratch
try {
    $env:DOTFILES_TEST_ENTRY = Join-Path $repo 'install.ps1'
    $env:DOTFILES_TEST_REPORT = Join-Path $scratch 'handoff.xml'
    $helper = Join-Path $scratch 'helper.ps1'
    @'
$ErrorActionPreference = 'Stop'
$global:prepared = $false
function Get-Command {
    param($Name, $CommandType, $ErrorAction)
    if ($Name -eq 'pwsh') {
        if ($global:prepared) { return @{Source='Invoke-TestPwsh'} }
        return $null
    }
    if ($Name -eq 'winget') { return @{Source='winget'} }
    return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
}
function winget {
    $global:installArguments = @($args)
    $global:prepared = $true
    $global:LASTEXITCODE = 0
}
function Invoke-TestPwsh {
    @{install=@($global:installArguments);handoff=@($args)} | Export-Clixml -LiteralPath $env:DOTFILES_TEST_REPORT
    $global:LASTEXITCODE = 0
}
. $env:DOTFILES_TEST_ENTRY -Mode Apply -ProfilePath 'profile with spaces.json'
'@ | Set-Content -LiteralPath $helper -Encoding UTF8
    & powershell.exe -NoProfile -File $helper
    if ($LASTEXITCODE -ne 0) { throw 'PowerShell 5.1 handoff failed.' }
    $report = Import-Clixml -LiteralPath $env:DOTFILES_TEST_REPORT
    if ($report.install -notcontains 'Microsoft.PowerShell' -or $report.install -notcontains '--exact') { throw 'Wrong bootstrap owner.' }
    if ($report.handoff -notcontains '-ExecutionPolicy' -or $report.handoff -notcontains 'Bypass') { throw 'Restricted native entry cannot continue.' }
    if ($report.handoff -notcontains 'Apply' -or $report.handoff -notcontains 'profile with spaces.json') { throw 'Handoff changed the requested arguments.' }
    Write-Output 'PowerShell 5.1: native parsing, missing-PowerShell WinGet owner and same-argument handoff passed.'
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force
    Remove-Item Env:DOTFILES_TEST_ENTRY, Env:DOTFILES_TEST_REPORT -ErrorAction SilentlyContinue
}
