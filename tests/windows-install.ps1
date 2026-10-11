#Requires -Version 5.1
# Actual installation only on an ephemeral GitHub-hosted Windows runner.
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') { throw 'Hosted disposable CI only.' }
if ($HOME -ne $env:USERPROFILE) { throw 'Use the actual runner home.' }
$repo = Split-Path $PSScriptRoot
if (Test-Path (Join-Path $HOME '.config/chezmoi/chezmoi.toml')) { throw 'Expected a fresh dotfiles selection.' }
# WinGet is not guaranteed in runner images. Use Microsoft's supported bootstrap.
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module Microsoft.WinGet.Client -Repository PSGallery -Force -Scope CurrentUser
    Repair-WinGetPackageManager -Force -Latest
    $env:Path += ';' + (Join-Path $env:LOCALAPPDATA 'Microsoft/WindowsApps')
}
$identity = "[user]`n name = CI Existing User`n email = ci@example.invalid`n[acceptance]`n keep = existing`n"
$gitconfig = Join-Path $HOME '.gitconfig'
# Runner-provided settings are legitimate inputs too.
Add-Content -LiteralPath $gitconfig -Value $identity
$profile = Join-Path $repo 'tests/profiles/windows-cli.json'
& powershell.exe -NoProfile -File (Join-Path $repo 'install.ps1') -Mode Apply -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'First native install failed.' }
$env:Path = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'))
$before = & chezmoi --no-tty --no-pager diff | Out-String
if ($LASTEXITCODE -ne 0 -or $before.Trim()) { throw 'Unexpected diff after first installation.' }
& powershell.exe -NoProfile -File (Join-Path $repo 'install.ps1') -Mode Apply -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'Second native install failed.' }
$after = & chezmoi --no-tty --no-pager diff | Out-String
if ($LASTEXITCODE -ne 0 -or $after.Trim()) { throw 'Repeat apply is not stable.' }
if ((& git config --get acceptance.keep) -ne 'existing') { throw 'Existing Git setting was lost.' }
& pwsh -NoProfile -File (Join-Path $repo 'install.ps1') -Mode Verify -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'Native CLI execution failed.' }
Write-Output 'Windows: 5.1 entry, native CLI installation, real execution and repeated apply passed. GUI/authentication excluded.'
