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
    $fixtureHome = Join-Path $scratch 'fixture home'
    $review = Join-Path $scratch 'review'
    $null = New-Item -ItemType Directory -Path $fixtureHome,$review
    '[acceptance]' | Set-Content (Join-Path $fixtureHome '.gitconfig')
    'reviewed fixture diff' | Set-Content (Join-Path $review 'config.diff')
    $snapshot = @(New-ConfigurationBackup -Managed @('.gitconfig') -Review $review -UserHome $fixtureHome)
    if ($snapshot.Count -ne 1 -or -not (Test-Path -LiteralPath $snapshot[0] -PathType Container)) { throw 'Backup logging contaminated its returned path.' }
    $manifest = Get-Content (Join-Path $snapshot[0] 'manifest.json') -Raw | ConvertFrom-Json
    $savedFile = $manifest.files | Where-Object path -eq '.gitconfig'
    if (-not $savedFile.acl -or $savedFile.acl -ne (Get-Acl (Join-Path $fixtureHome '.gitconfig')).Sddl) { throw 'Backup omitted the original file ACL.' }
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
    # Re-signing reviewed code is allowed; new code or an untrusted publisher is not.
    $script:fixtureCode = "Write-Output 'reviewed fixture'`r`n"
    $script:fixtureSignature = 'YWJj'
    $script:signatureStatus = 'Valid'
    $script:signerName = 'OpenAI OpCo, LLC'
    $certificate = [pscustomobject]@{}
    $certificate | Add-Member -MemberType ScriptMethod -Name GetNameInfo -Value { param($Type,$Issuer); $script:signerName }
    function Get-AuthenticodeSignature {
        param($LiteralPath)
        [pscustomobject]@{Status=$script:signatureStatus;SignerCertificate=$certificate}
    }
    function Invoke-WebRequest {
        param($Uri,$OutFile)
        [IO.File]::WriteAllText($OutFile, ($script:fixtureCode + "# SIG # Begin signature block`r`n# $script:fixtureSignature`r`n# SIG # End signature block`r`n"), [Text.UTF8Encoding]::new($false))
    }
    $signed = [pscustomobject]@{
        url='https://publisher.invalid/signed.ps1'; signerName=$script:signerName
        codeSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($script:fixtureCode))).ToLowerInvariant()
    }
    $signedFile = Join-Path $scratch 'signed installer.ps1'
    Receive-VerifiedFile $signed $signedFile
    Remove-Item $signedFile
    $script:fixtureSignature = 'ZGVm'
    Receive-VerifiedFile $signed $signedFile
    Remove-Item $signedFile
    foreach ($failure in @('code','signature','publisher','block')) {
        $script:fixtureCode = "Write-Output 'reviewed fixture'`r`n"
        $script:fixtureSignature = 'YWJj'
        $script:signatureStatus = 'Valid'
        $script:signerName = 'OpenAI OpCo, LLC'
        switch ($failure) {
            code { $script:fixtureCode += "Write-Output 'unreviewed code'`r`n" }
            signature { $script:signatureStatus = 'HashMismatch' }
            publisher { $script:signerName = 'Other Publisher' }
            block { $script:fixtureSignature = "YWJj`r`nWrite-Output 'hidden code'" }
        }
        $rejected = $false
        try { Receive-VerifiedFile $signed $signedFile } catch { $rejected = $true }
        if (-not $rejected -or (Test-Path $signedFile)) { throw "Unsafe signed script was accepted or retained: $failure" }
    }
    Remove-Item Function:Get-AuthenticodeSignature
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
    $loader = Join-Path $fixtureHome 'Documents/PowerShell/profile.ps1'
    $null = New-Item -ItemType Directory -Path (Split-Path $loader) -Force
    [IO.File]::WriteAllText($loader, '# existing loader')
    [IO.File]::SetLastWriteTimeUtc($loader, [DateTime]::UtcNow.AddMinutes(-5))
    $loaderAcl = (Get-Acl -LiteralPath $loader).Sddl
    $loaderTime = (Get-Item -LiteralPath $loader).LastWriteTimeUtc.Ticks
    Invoke-ProtectedVendors -Plan @{official=@()} -Backup $scratch -Managed @('Documents/PowerShell/profile.ps1') -UserHome $fixtureHome
    if ((Get-Acl -LiteralPath $loader).Sddl -cne $loaderAcl -or (Get-Item -LiteralPath $loader).LastWriteTimeUtc.Ticks -ne $loaderTime -or [IO.File]::ReadAllText($loader) -cne '# existing loader') {
        throw 'No-op provider stage changed an existing loader, timestamp or ACL.'
    }
    Write-Output 'Publisher checksum/overwrite failure, provider preservation and Pi noninteractive PATH/repeat setup: OK'
} finally { $env:Path = $originalProcessPath; Remove-Item -LiteralPath $scratch -Recurse -Force }
