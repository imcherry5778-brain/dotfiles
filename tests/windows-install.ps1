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
# Fresh personal Windows defaults to Restricted. Test that process-only Bypass
# does not leave future user profiles blocked; this is the disposable runner only.
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -Force
# PowerShell 7 stores its policy separately from Windows PowerShell 5.1.
$existingPwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
if ($existingPwsh) {
    & $existingPwsh.Source -NoProfile -Command 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined -Force; Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -Force'
    if ($LASTEXITCODE -ne 0) { throw 'Cannot prepare the disposable PowerShell 7 policy.' }
}
$profile = Join-Path $repo 'tests/profiles/windows-cli.json'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'install.ps1') -Mode Apply -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'First native install failed.' }
$env:Path = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'))
# Query a new native PowerShell 7 process, without an inherited process Bypass.
$processPolicy = $env:PSExecutionPolicyPreference
try {
    $env:PSExecutionPolicyPreference = $null
    $profileCheck = 'if ((Get-ExecutionPolicy -Scope CurrentUser) -ne "RemoteSigned" -or -not (Get-Command z -ErrorAction SilentlyContinue)) { exit 1 }'
    $encodedProfileCheck = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($profileCheck))
    & pwsh -EncodedCommand $encodedProfileCheck
    if ($LASTEXITCODE -ne 0) { throw 'Future native PowerShell 7 profiles remain blocked.' }
} finally { $env:PSExecutionPolicyPreference = $processPolicy }
if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'Restricted') { throw 'Windows PowerShell 5.1 policy was changed.' }
$before = & chezmoi --no-tty --no-pager diff | Out-String
if ($LASTEXITCODE -ne 0 -or $before.Trim()) { throw 'Unexpected diff after first installation.' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'install.ps1') -Mode Apply -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'Second native install failed.' }
$after = & chezmoi --no-tty --no-pager diff | Out-String
if ($LASTEXITCODE -ne 0 -or $after.Trim()) { throw 'Repeat apply is not stable.' }
if ((& git config --get acceptance.keep) -ne 'existing') { throw 'Existing Git setting was lost.' }
& pwsh -NoProfile -File (Join-Path $repo 'install.ps1') -Mode Verify -ProfilePath $profile
if ($LASTEXITCODE -ne 0) { throw 'Native CLI execution failed.' }
Write-Output 'Windows: 5.1 entry, native CLI installation, real execution and repeated apply passed. GUI/authentication excluded.'
