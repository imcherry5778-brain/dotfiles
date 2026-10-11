#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Plan','Bootstrap','Diff','Apply','Verify','DesktopPlan','DesktopApply')]
    [string] $Mode = 'Plan',
    [string] $ProfilePath = '',
    [switch] $LibraryOnly
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
    if (($selection | ConvertTo-Json -Depth 10 -Compress) -ne ($expected | ConvertTo-Json -Depth 10 -Compress)) {
        throw 'Only the reviewed Windows full or CLI profile is supported.'
    }
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
if ($LibraryOnly) { return }
if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') { throw 'Reviewed Windows 11 x64 environment required.' }
if ($HOME -ne $env:USERPROFILE) { throw 'Run with the actual Windows user home.' }
foreach ($name in @('XDG_CONFIG_HOME','XDG_DATA_HOME','MISE_CONFIG_DIR','MISE_DATA_DIR','MISE_GLOBAL_CONFIG_FILE','GH_CONFIG_DIR')) {
    if ([Environment]::GetEnvironmentVariable($name)) { throw "$name redirects the native environment; review it first." }
}
if ($env:MISE_ENV -and $env:MISE_ENV -ne 'windows') { throw 'MISE_ENV selects an unreviewed Windows environment.' }
if ($Mode -eq 'Plan') {
    Write-Output 'Windows: WinGet bootstrap, mise CLI, official AI installers; deployment remains opt-in.'
    Write-Output 'Bootstrap -> Diff -> Apply -> Verify. Existing providers and authentication are preserved.'
    return
}
if ($Mode -eq 'DesktopPlan') {
    @{ghostty='unsupported: native Windows build is unavailable';orca='checksum-pinned official Windows installer'} | ConvertTo-Json
    return
}
if ($Mode -eq 'DesktopApply') { Install-NativeDesktop; return }
if ($Mode -in @('Bootstrap','Apply')) {
    foreach ($package in $catalog.bootstrap) { Install-WinGetPackage $package }
    if ($Mode -eq 'Bootstrap') { return }
}
if (-not $ProfilePath) { $ProfilePath = Join-Path $repo 'tests/profiles/windows-full.json' }
$selection = Get-MachineData (Get-Selection $ProfilePath)
foreach ($command in @('git','chezmoi','mise','winget')) {
    if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) { throw "Missing $command. Run Bootstrap before configuration review." }
}
$review = New-PrivateDirectory (Join-Path $HOME '.local/state/dotfiles/review/windows')
$override = Join-Path $review 'selection.json'
$selection | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $override -Encoding utf8NoBOM
$previewConfig = Join-Path $review 'preview.toml'
$config = Join-Path $HOME '.config/chezmoi/chezmoi.toml'
$base = @('--source',$repo,'--config',$previewConfig,'--no-tty','--no-pager')
$rendered = Get-ChezmoiOutput ($base + @('--override-data-file',$override,'execute-template','--init','--file',(Join-Path $repo 'home/.chezmoi.toml.tmpl')))
$rendered | Set-Content -LiteralPath $previewConfig -Encoding utf8NoBOM
$plan = Get-ChezmoiOutput ($base + @('execute-template','--file',(Join-Path $repo 'home/.chezmoitemplates/windows/plan.json.tmpl'))) | ConvertFrom-Json
$plan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $review 'packages.json') -Encoding utf8NoBOM
$diff = Get-ChezmoiOutput ($base + @('diff'))
$diff | Set-Content -LiteralPath (Join-Path $review 'config.diff') -Encoding utf8NoBOM
if ($Mode -eq 'Diff') {
    $diff
    Write-Output "Review artifacts: $review"
    Write-Output "Current-user script policy: $(Get-ExecutionPolicy). Restricted requires RemoteSigned for the reviewed PowerShell profile. Group policy is never overridden."
    return
}
$managed = @((Get-ChezmoiOutput ($base + @('managed','--include=files,symlinks','--path-style=relative'))) -split "`n" | Where-Object { $_ } | ForEach-Object { $_.Trim().Replace('\','/') })
if ($managed.Count -lt 15 -or $managed -contains '.zshrc' -or $managed -contains '.tmux.conf') { throw 'Empty or invalid Windows deployment targets.' }
if ($Mode -eq 'Verify') {
    if (-not (Test-Path -LiteralPath $config)) { throw 'Windows selection has not been applied.' }
    $null = Get-ChezmoiOutput @('--config',$config,'--no-tty','--no-pager','verify')
    Test-WindowsTools $review
    Write-Output 'Windows managed configuration and actual CLI execution verification passed.'
    return
}
# Capture only managed destinations plus the registry values changed by this workflow.
$backup = New-PrivateDirectory (Join-Path $HOME ('.local/state/dotfiles/backups/' + (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') + '-windows'))
$manifest = @()
$extraBackups = @('.config/chezmoi/chezmoi.toml',
    'Documents/PowerShell/Microsoft.PowerShell_profile.ps1',
    'Documents/WindowsPowerShell/profile.ps1',
    'Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1',
    '.pi/agent/settings.json', '.grok/config.toml')
foreach ($relative in @($managed + $extraBackups | Select-Object -Unique)) {
    $target = [IO.Path]::GetFullPath((Join-Path $HOME $relative))
    if (-not $target.StartsWith($HOME + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw "Target outside actual home: $relative" }
    $entry = @{path=$relative;exists=(Test-Path -LiteralPath $target -PathType Leaf)}
    if ($entry.exists) {
        $destination = Join-Path $backup ('files/' + $relative)
        $null = New-Item -ItemType Directory -Path (Split-Path $destination) -Force
        Copy-Item -LiteralPath $target -Destination $destination
        $entry.hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    }
    $manifest += $entry
}
@{files=$manifest;userPath=[Environment]::GetEnvironmentVariable('Path','User');policy=[Environment]::GetEnvironmentVariable('PSExecutionPolicyPreference');currentUserPolicy=(Get-ExecutionPolicy -Scope CurrentUser).ToString()} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding utf8NoBOM
Copy-Item -LiteralPath (Join-Path $review 'config.diff') -Destination (Join-Path $backup 'before.diff')
Write-Output "Private targeted backup: $backup"
$null = New-Item -ItemType Directory -Path (Split-Path $config) -Force
if (Test-Path -LiteralPath $config) {
    $existing = Get-ChezmoiOutput @('--config',$config,'data','--format','json') | ConvertFrom-Json
    Assert-ExistingSelection $existing $selection
}
Copy-Item -LiteralPath $previewConfig -Destination $config -Force
$actual = @('--config',$config,'--no-tty','--no-pager')
$null = Get-ChezmoiOutput ($actual + @('apply',(Join-Path $HOME '.config/mise')))
Push-Location $HOME
try { Invoke-Checked 'mise' @('install','--yes') } finally { Pop-Location }
foreach ($package in $plan.editor) { Install-WinGetPackage $package }
foreach ($installer in $plan.official) { Install-OfficialCli $installer $backup }
# Vendor installers can add profile/completion loaders. Review the final diff too.
$finalDiff = Get-ChezmoiOutput ($actual + @('diff'))
$finalDiff | Set-Content -LiteralPath (Join-Path $backup 'after-install.diff') -Encoding utf8NoBOM
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    foreach ($scope in @('MachinePolicy','UserPolicy')) {
        if ((Get-ExecutionPolicy -Scope $scope) -ne 'Undefined') { throw 'PowerShell execution group policy requires administrator review.' }
    }
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
}
# Apply mode is explicitly authorized; its latest diff and targets were backed up above.
# --no-tty redirects prompts to stdin, so it alone does not make apply noninteractive.
$null = Get-ChezmoiOutput ($actual + @('--force','apply'))
$null = Get-ChezmoiOutput ($actual + @('verify'))
if ($selection.features.desktop) { Install-NativeDesktop }
Test-WindowsTools $review
Write-Output 'Windows profile applied and CLI execution verified. AI authentication remains separate.'
