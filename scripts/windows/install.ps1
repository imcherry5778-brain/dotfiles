#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Plan','Bootstrap','Diff','Apply','Verify','DesktopPlan','DesktopApply')]
    [string] $Mode = 'Plan',
    [string] $ProfilePath = '',
    [switch] $LibraryOnly,
    [ValidateSet('Before','After')][string] $Stage,
    [string] $ContextPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($IsWindows) { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) }
$PSNativeCommandUseErrorActionPreference = $false
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$catalog = (Get-Content -LiteralPath (Join-Path $repo 'home/.chezmoidata/windows.json') -Raw | ConvertFrom-Json).windows

function Invoke-Checked {
    param([string] $Command, [string[]] $Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE)." }
}
function Update-SessionPath {
    $combined = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    $env:Path = [Environment]::ExpandEnvironmentVariables($combined)
}
function Get-UserPortablePackage {
    param([string] $PackageId)
    $directory = Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages'
    return @(Get-ChildItem -LiteralPath $directory -Directory -Filter "${PackageId}_*" -ErrorAction SilentlyContinue)
}
function Install-WinGetPackage {
    param($Package)
    if (Get-Command $Package.command -CommandType Application -ErrorAction SilentlyContinue) {
        Write-Output "$($Package.id): existing provider preserved."
        return
    }
    $arguments = @('install','--id',$Package.id,'--exact','--version',$Package.version,'--source','winget',
        '--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if (@(Get-UserPortablePackage $Package.id).Count -eq 0) {
        Invoke-Checked 'winget' $arguments
        Update-SessionPath
        if (Get-Command $Package.command -CommandType Application -ErrorAction SilentlyContinue) { return }
    }
    if (@(Get-UserPortablePackage $Package.id).Count -gt 0) {
        # WinGet 1.11 cannot create some portable aliases from a normal user shell.
        # Reinstall through WinGet's normal UAC flow, keeping user scope. No security policy changes.
        Write-Output "$($Package.id): repair the missing portable command alias through WinGet."
        $install = @{
            FilePath = (Get-Command winget -CommandType Application).Source
            Verb = 'RunAs'; Wait = $true; PassThru = $true
            ArgumentList = $arguments + @('--force','--scope','user')
        }
        $process = Start-Process @install
        if ($process.ExitCode -ne 0) { throw "$($Package.id) alias repair failed (exit $($process.ExitCode))." }
        Update-SessionPath
    }
    if (-not (Get-Command $Package.command -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "$($Package.id) installed without a discoverable $($Package.command) command."
    }
}
function New-PrivateDirectory {
    param([string] $Path)
    $null = New-Item -ItemType Directory -Path $Path -Force
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $null = Invoke-Checked 'icacls' @($Path,'/inheritance:r','/grant:r',"*${sid}:(OI)(CI)F",'*S-1-5-18:(OI)(CI)F')
    return $Path
}
function Receive-VerifiedFile {
    param($Asset, [string] $Destination)
    if ($Asset.url -notmatch '^https://' -or $Asset.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Invalid publisher asset metadata.' }
    if (Test-Path -LiteralPath $Destination) { throw "Refusing to overwrite $Destination" }
    try {
        Invoke-WebRequest -Uri $Asset.url -OutFile $Destination
        if ((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Asset.sha256) {
            throw "Checksum mismatch: $Destination"
        }
    } catch {
        if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination }
        throw
    }
}
. (Join-Path $PSScriptRoot 'providers.ps1')
function Get-Selection {
    param([string] $Path)
    $selection = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $expected = Get-Content -LiteralPath (Join-Path $repo 'tests/profiles/windows-full.json') -Raw | ConvertFrom-Json
    if ($selection.features.desktop -isnot [bool]) { throw 'desktop must be a Boolean.' }
    $expected.features.desktop = $selection.features.desktop
    Assert-ExistingSelection $selection $expected
    return $selection
}
function Assert-ExistingSelection {
    param($Existing, $Requested)
    if ($Existing.platform -ne $Requested.platform) { throw 'Existing chezmoi platform differs; review before replacing it.' }
    foreach ($section in @('features','deployment')) {
        $actual = $Existing.$section.PSObject.Properties
        $wanted = $Requested.$section.PSObject.Properties
        if (@($actual).Count -ne @($wanted).Count) { throw "Existing $section selection differs; no replacement performed." }
        foreach ($property in $wanted) {
            if ($section -eq 'features' -and $Existing.features.($property.Name) -isnot [bool]) { throw 'Feature flags must be Booleans.' }
            if ($property.Name -notin $actual.Name -or $Existing.$section.($property.Name) -ne $property.Value) {
                throw "Existing $section selection differs; no replacement performed."
            }
        }
    }
}
function Get-MachineData {
    param($Selection)
    $documents = [Environment]::GetFolderPath('MyDocuments', [Environment+SpecialFolderOption]::DoNotVerify)
    if ([IO.Path]::GetFullPath($documents) -ne [IO.Path]::GetFullPath((Join-Path $HOME 'Documents'))) {
        throw 'Redirected Documents requires a separate PowerShell profile destination review.'
    }
    foreach ($location in @(@($env:LOCALAPPDATA,'AppData/Local'),@($env:APPDATA,'AppData/Roaming'))) {
        if ([IO.Path]::GetFullPath($location[0]) -ne [IO.Path]::GetFullPath((Join-Path $HOME $location[1]))) {
            throw 'Redirected AppData requires a separate native destination review.'
        }
    }
    return $Selection
}
function Get-ChezmoiOutput {
    param([string[]] $Arguments)
    $output = & chezmoi @Arguments
    if ($LASTEXITCODE -ne 0) { throw "chezmoi failed: $($Arguments -join ' ')" }
    return ($output -join "`n")
}
function Get-OrcaExecutable {
    # Electron's actual publisher application name, independent of display labels.
    foreach ($directory in @((Join-Path $env:LOCALAPPDATA 'Programs/orca-ide'),(Join-Path $env:LOCALAPPDATA 'Programs/Orca'),(Join-Path $env:ProgramFiles 'Orca'))) {
        foreach ($name in @('Orca.exe','orca-ide.exe','orca.exe')) {
            $candidate = Join-Path $directory $name
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
        }
    }
    return $null
}
function Register-OrcaCli {
    param([string] $Executable)
    # Use the publisher's native launcher, including its companion runtime files.
    Add-UserCommandPath (Join-Path (Split-Path $Executable) 'resources/bin')
    $null = Invoke-Checked 'orca' @('--version')
    $null = Invoke-Checked 'orca' @('--help')
}
function Install-NativeDesktop {
    Write-Output 'Ghostty: official native Windows release is unavailable; existing Windows Terminal is preserved.'
    $existing = Get-OrcaExecutable
    if ($existing) {
        Register-OrcaCli $existing
        Write-Output 'Orca: existing installation and bundled CLI preserved.'
        return
    }
    $release = Get-Content -LiteralPath (Join-Path $repo 'scripts/desktop-release.json') -Raw | ConvertFrom-Json
    $asset = $release.orca.assets.'windows-x64'
    $scratch = New-PrivateDirectory (Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-orca-' + [Guid]::NewGuid().ToString('N')))
    try {
        $installer = Join-Path $scratch $asset.name
        Receive-VerifiedFile $asset $installer
        # Publisher UI is intentional: no undocumented silent installer flags.
        $process = Start-Process -FilePath $installer -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Orca installer exit $($process.ExitCode)" }
        $installed = Get-OrcaExecutable
        if (-not $installed) { throw 'Orca installer finished without a detectable native installation.' }
        Register-OrcaCli $installed
    } finally { Remove-Item -LiteralPath $scratch -Recurse -Force }
}
function Read-Review {
    param($Context, [string] $State, [string[]] $Arguments)
    # Separate disposable state for read-only queries while parent apply owns its lock.
    if ($Arguments[0] -notin @('managed','diff','status','verify')) { throw 'Only read-only review commands are allowed.' }
    $output = & $Context.chezmoi --source $repo --config $Context.config --destination $HOME --persistent-state $State --no-tty --no-pager @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Read-only review failed: $($Arguments[0])" }
    return ($output -join "`n")
}
function New-ConfigurationBackup {
    param($Managed, [string] $Review, [string] $UserHome = $HOME)
# Capture only managed destinations plus the registry values changed by this workflow.
$backup = New-PrivateDirectory (Join-Path $UserHome ('.local/state/dotfiles/backups/' + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffffffZ') + '-windows'))
$manifest = @()
$extraBackups = @('.config/chezmoi/chezmoi.toml',
    'Documents/PowerShell/Microsoft.PowerShell_profile.ps1',
    'Documents/PowerShell/powershell.config.json',
    'Documents/WindowsPowerShell/profile.ps1',
    'Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1',
    '.pi/agent/settings.json', '.grok/config.toml')
foreach ($relative in @($managed + $extraBackups | Select-Object -Unique)) {
    $target = [IO.Path]::GetFullPath((Join-Path $UserHome $relative))
    if (-not $target.StartsWith($UserHome + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw "Target outside actual home: $relative" }
    $entry = @{path=$relative;exists=(Test-Path -LiteralPath $target -PathType Leaf)}
    if ($entry.exists) {
        $destination = Join-Path $backup ('files/' + $relative)
        $null = New-Item -ItemType Directory -Path (Split-Path $destination) -Force
        Copy-Item -LiteralPath $target -Destination $destination
        $entry.acl = (Get-Acl -LiteralPath $target).Sddl
        $entry.hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    }
    $manifest += $entry
}
@{files=$manifest;userPath=[Environment]::GetEnvironmentVariable('Path','User');policy=[Environment]::GetEnvironmentVariable('PSExecutionPolicyPreference');currentUserPolicy=(Get-ExecutionPolicy -Scope CurrentUser).ToString()} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding utf8NoBOM
Copy-Item -LiteralPath (Join-Path $review 'config.diff') -Destination (Join-Path $backup 'before.diff')
Write-Host "Private targeted backup: $backup"
return $backup
}
function Enable-ProfilePolicy {
$currentProfilePolicy = Get-ExecutionPolicy -Scope CurrentUser
$profilePolicyNeeded = $currentProfilePolicy -eq 'Restricted' -or
    ($currentProfilePolicy -eq 'Undefined' -and (Get-ExecutionPolicy -Scope LocalMachine) -in @('Undefined','Restricted'))
if ($profilePolicyNeeded) {
    foreach ($scope in @('MachinePolicy','UserPolicy')) {
        if ((Get-ExecutionPolicy -Scope $scope) -ne 'Undefined') { throw 'PowerShell execution group policy requires administrator review.' }
    }
    # Set-ExecutionPolicy rejects a successful persistent write while a more
    # specific Process Bypass is active. Suspend only that process preference.
    $entryProcessPolicy = Get-ExecutionPolicy -Scope Process
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined -Force
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    } finally {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy $entryProcessPolicy -Force
    }
}
}
function Repair-MiseCommands {
    param($Plan)
    $installed = (& mise ls --current --json | Out-String | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect selected mise tools.' }
    foreach ($property in $Plan.mise.PSObject.Properties) {
        $tool = $property.Name
        $version = if ($property.Value -is [string]) { $property.Value } else { $property.Value.version }
        $entries = $installed.PSObject.Properties | Where-Object Name -eq $tool
        if (-not $entries) { continue }
        $selected = @($entries.Value | Where-Object { $_.installed -and $_.version -eq $version })
        if (-not $selected.Count) { continue }
        $catalogEntry = @($catalog.mise.PSObject.Properties.Value | Where-Object backend -eq $tool)
        $command = if ($catalogEntry.Count) { $catalogEntry[0].command } else {
            switch ($tool) { 'github:anomalyco/opencode' {'opencode'} 'pypi:aider-chat' {'aider'} default {$tool} }
        }
        $executable = & mise which $command 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -or -not $executable -or -not (Test-Path -LiteralPath $executable -PathType Leaf)) {
            Invoke-Checked 'mise' @('uninstall','--yes',"${tool}@${version}")
        }
    }
    Invoke-Checked 'mise' @('install','--yes')
}
function Invoke-ProtectedVendors {
    param($Plan, [string] $Backup, $Managed, [string] $UserHome = $HOME)
    $saved = @()
    foreach ($relative in @('Documents/PowerShell/profile.ps1','Documents/PowerShell/Microsoft.PowerShell_profile.ps1')) {
        $path = Join-Path $UserHome $relative
        if ($relative -in $Managed -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            if ((Get-Item -LiteralPath $path).LinkType) { throw "Vendor loader is a symlink: $path" }
            $saved += @{path=$path;content=[IO.File]::ReadAllBytes($path);acl=(Get-Acl -LiteralPath $path)}
        }
    }
    try {
        foreach ($installer in $Plan.official) { Install-OfficialCli $installer $Backup }
    } finally {
        foreach ($entry in $saved) {
            # Existing providers normally leave loaders untouched. Avoid rewriting
            # their timestamps or canonicalizing an unchanged Windows ACL.
            $exists = Test-Path -LiteralPath $entry.path -PathType Leaf
            if (-not $exists -or [Convert]::ToBase64String([IO.File]::ReadAllBytes($entry.path)) -cne [Convert]::ToBase64String($entry.content)) {
                [IO.File]::WriteAllBytes($entry.path,$entry.content)
            }
            if ((Get-Acl -LiteralPath $entry.path).Sddl -cne $entry.acl.Sddl) {
                Set-Acl -LiteralPath $entry.path -AclObject $entry.acl
            }
        }
    }
}
if ($LibraryOnly) { return }
if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') { throw 'Reviewed Windows 11 x64 environment required.' }
if ($HOME -ne $env:USERPROFILE) { throw 'Run with the actual Windows user home.' }
foreach ($name in @('XDG_CONFIG_HOME','XDG_DATA_HOME','MISE_CONFIG_DIR','MISE_DATA_DIR','MISE_GLOBAL_CONFIG_FILE','GH_CONFIG_DIR')) {
    if ([Environment]::GetEnvironmentVariable($name)) { throw "$name redirects the native environment; review it first." }
}
if ($env:MISE_ENV -and $env:MISE_ENV -ne 'windows') { throw 'MISE_ENV selects an unreviewed Windows environment.' }

if ($Stage) {
    $context = Get-Content -LiteralPath $ContextPath -Raw | ConvertFrom-Json
    if ($context.automation -ne $true -or [IO.Path]::GetFullPath($context.source) -ne $repo -or [IO.Path]::GetFullPath($context.destination) -ne $HOME) { throw 'Native login home and explicit automation required.' }
    $selection = Get-MachineData $context.profile
    $expected = Get-Content (Join-Path $repo 'tests/profiles/windows-full.json') -Raw | ConvertFrom-Json
    $expected.features.desktop = $selection.features.desktop
    Assert-ExistingSelection $selection $expected
    $review = New-PrivateDirectory (Join-Path $HOME '.local/state/dotfiles/review/windows')
    $scratch = New-PrivateDirectory (Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-review-' + [Guid]::NewGuid().ToString('N')))
    try {
        $state = Join-Path $scratch 'query.boltdb'
        $managed = @((Read-Review $context $state @('managed','--include=files,symlinks','--path-style=relative')) -split "`n" | Where-Object { $_ } | ForEach-Object { $_.Trim().Replace('\','/') })
        if ($managed.Count -lt 15 -or '.zshrc' -in $managed) { throw 'Invalid Windows deployment targets.' }
        if ($Stage -eq 'Before') {
            $diff = Read-Review $context $state @('diff','--exclude=scripts')
            $diff | Set-Content (Join-Path $review 'config.diff') -Encoding utf8NoBOM
            $backup = New-ConfigurationBackup $managed $review
            $backup | Set-Content (Join-Path $review 'last-backup.txt') -Encoding utf8NoBOM
            foreach ($package in $catalog.bootstrap) { Install-WinGetPackage $package }
            Enable-ProfilePolicy
            return
        }
        $plan = $context.plan
        $plan | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $review 'packages.json') -Encoding utf8NoBOM
        $backup = (Get-Content (Join-Path $review 'last-backup.txt') -Raw).Trim()
        Push-Location $HOME
        try { Repair-MiseCommands $plan } finally { Pop-Location }
        foreach ($package in $plan.editor) { Install-WinGetPackage $package }
        Invoke-ProtectedVendors $plan $backup $managed
        if ($selection.features.desktop) { Install-NativeDesktop }
        Test-WindowsTools $review
        $null = Read-Review $context $state @('verify','--exclude=scripts')
        if ((Read-Review $context $state @('diff','--exclude=scripts')).Trim()) { throw 'Configuration differs after installation.' }
        Write-Output 'Windows configuration and CLI execution verified; authentication/GUI remain separate.'
        return
    } finally { Remove-Item -LiteralPath $scratch -Recurse -Force }
}
if ($Mode -eq 'Plan') { Write-Output 'Prepare chezmoi, then init --apply. Existing providers and authentication are preserved.'; return }
if ($Mode -eq 'DesktopPlan') { @{ghostty='unsupported: native Windows release unavailable';orca='checksum-pinned official installer'} | ConvertTo-Json; return }
if ($Mode -eq 'DesktopApply') { Install-NativeDesktop; return }
if ($Mode -in @('Bootstrap','Apply')) {
    foreach ($package in $catalog.bootstrap) { Install-WinGetPackage $package }
    if ($Mode -eq 'Bootstrap') { return }
}
if ($Mode -eq 'Apply') {
    $arguments = @('--source',$repo)
    if ($ProfilePath) {
        $null = Get-Selection $ProfilePath
        $arguments += @('--override-data-file',$ProfilePath)
    }
    Invoke-Checked 'chezmoi' ($arguments + @('init','--apply'))
    return
}
if ($Mode -eq 'Diff') { Invoke-Checked 'chezmoi' @('--source',$repo,'diff'); return }
if ($Mode -eq 'Verify') {
    Invoke-Checked 'chezmoi' @('--source',$repo,'verify','--exclude=scripts')
    Test-WindowsTools (Join-Path $HOME '.local/state/dotfiles/review/windows')
}
