#Requires -Version 7.0
# Offline failure/idempotency contracts. No real installer or PATH changes.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $repo 'scripts/windows/install.ps1') -LibraryOnly
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('provider contracts with spaces ' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$originalProcessPath = $env:Path
try {
    function Invoke-WebRequest { param($Uri,$OutFile); [IO.File]::WriteAllText($OutFile,'downloaded fixture') }
    $asset = [pscustomobject]@{url='https://publisher.invalid/install.ps1';sha256=('0'*64)}
    $file = Join-Path $scratch 'bad installer.ps1'
    $rejected = $false
    try { Receive-VerifiedFile $asset $file } catch { $rejected = $_.ToString() -match 'Checksum mismatch' }
    if (-not $rejected -or (Test-Path $file)) { throw 'Changed publisher script was accepted or retained.' }
    $asset.sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('downloaded fixture'))).ToLowerInvariant()
    Receive-VerifiedFile $asset $file
    if (-not (Test-Path $file)) { throw 'Verified publisher script was not saved.' }
    try { Receive-VerifiedFile $asset $file; throw 'Overwrite accepted.' } catch { if ($_ -notmatch 'Refusing to overwrite') { throw } }
    function Invoke-VendorInstaller { throw 'An existing CLI must not invoke its installer.' }
    function Receive-VerifiedFile { throw 'An existing CLI must not download.' }
    function Add-UserCommandPath { throw 'An existing provider must not change PATH.' }
    Install-OfficialCli ([pscustomobject]@{tool='codex';command='pwsh';arguments=@()}) $scratch
    $script:publisherBin = Join-Path $scratch 'publisher bin'
    $script:pathPrepared = $false
    $script:installCalls = 0
    function Get-OfficialCommandPath { param($Tool); return $script:publisherBin }
    function Add-UserCommandPath {
        param($Directory)
        $script:pathPrepared = $true
        if ($Directory -notin ($env:Path -split ';')) { $env:Path = $Directory + ';' + $env:Path }
    }
    function Receive-VerifiedFile { param($Asset,$Destination); 'reviewed fixture' | Set-Content $Destination }
    function Invoke-VendorInstaller {
        param($Script,$Arguments,$Log)
        if (-not $script:pathPrepared) { throw 'Pi would prompt for PATH in noninteractive mode.' }
        $script:installCalls++
        '@echo off' | Set-Content (Join-Path $script:publisherBin 'fixture-pi-unittest.cmd')
    }
    $fixture = [pscustomobject]@{tool='pi';command='fixture-pi-unittest';arguments=@()}
    Install-OfficialCli $fixture $scratch
    $firstPath = $env:Path
    Install-OfficialCli $fixture $scratch
    if ($script:installCalls -ne 1 -or $env:Path -ne $firstPath) { throw 'Repeat Pi setup downloaded/reinstalled or duplicated PATH.' }
    Write-Output 'Publisher checksum/overwrite failure, provider preservation and Pi noninteractive PATH/repeat setup: OK'
} finally { $env:Path = $originalProcessPath; Remove-Item -LiteralPath $scratch -Recurse -Force }
