#Requires -Version 5.1
[CmdletBinding()]
param(
  [ValidateSet('Plan', 'Check', 'Bootstrap', 'Diff', 'Apply', 'Verify', 'DesktopPlan', 'DesktopApply')]
  [string] $Mode = 'Plan',
  [string] $ProfilePath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$isNativeWindows = $env:OS -eq 'Windows_NT'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  if ($Mode -in @('Plan','Check','DesktopPlan')) {
    Write-Output 'PowerShell 5.1 entry point: Apply/Bootstrap prepares PowerShell 7 through WinGet, then continues.'
    return
  }
  if (-not $isNativeWindows) { throw 'PowerShell 7 is required on non-Windows platforms.' }
  $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
  if (-not $pwsh) {
    if ($Mode -notin @('Apply','Bootstrap','DesktopApply')) {
      throw 'PowerShell 7 is unavailable. Prepare it with explicit Apply or Bootstrap; read-only modes never install it.'
    }
    if (-not (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue)) {
      throw 'Install or update Microsoft App Installer to enable WinGet, then repeat this command.'
    }
    $catalog = (Get-Content -LiteralPath (Join-Path $repoRoot 'home/.chezmoidata/windows.json') -Raw | ConvertFrom-Json).windows
    $package = $catalog.bootstrap | Where-Object command -eq 'pwsh'
    & winget install --id $package.id --exact --version $package.version --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "PowerShell installation failed: $LASTEXITCODE" }
    $env:Path = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'))
    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
    if (-not $pwsh) {
      $candidate = Join-Path $env:ProgramFiles 'PowerShell/7/pwsh.exe'
      if (-not (Test-Path -LiteralPath $candidate)) { throw 'PowerShell 7 command is unavailable after installation.' }
      $pwsh = @{Source=$candidate}
    }
  }
  # The reviewed entry script must also run when PowerShell 7 starts Restricted.
  # This process-only option does not override Group Policy.
  $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $repoRoot 'install.ps1'),'-Mode',$Mode)
  if ($ProfilePath) { $arguments += @('-ProfilePath',$ProfilePath) }
  & $pwsh.Source @arguments
  exit $LASTEXITCODE
}

if ($IsWindows -and $Mode -ne 'Check') {
  & (Join-Path $repoRoot 'scripts/windows/install.ps1') -Mode $Mode -ProfilePath $ProfilePath
  exit 0
}

if ($Mode -in @('DesktopPlan', 'DesktopApply')) {
  $python = Get-Command python3, python -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $python) { throw 'Python 3.11+ is required for native application installation.' }
  $stage = if ($Mode -eq 'DesktopPlan') { '--desktop-plan' } else { '--desktop-only' }
  & $python.Source (Join-Path $repoRoot 'scripts/unix/install.py') $stage
  exit $LASTEXITCODE
}

if ($Mode -eq 'Check') {
  & (Join-Path $repoRoot 'scripts/windows/check.ps1')
  exit 0
}

Write-Output 'dotfiles: Fedora configuration draft; deployment disabled'
Write-Output "Repository: $repoRoot"
Write-Output '1. Review platform, current configuration and installation ownership.'
Write-Output '2. Prepare Git, mise and chezmoi in a separately authorized bootstrap.'
Write-Output '3. Initialize machine data and review a configuration diff.'
Write-Output '4. Prepare selected tool prerequisites, then apply only the separately reviewed migration.'
Write-Output 'This entry point currently prints a plan or checks prerequisites only.'
