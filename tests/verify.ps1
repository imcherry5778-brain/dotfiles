#Requires -Version 7.0
[CmdletBinding()]
param(
  [string] $Chezmoi = $env:CHEZMOI_BIN
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $Chezmoi) {
  $command = Get-Command chezmoi -CommandType Application -ErrorAction SilentlyContinue
  if (-not $command) { throw 'Provide -Chezmoi or CHEZMOI_BIN; this verifier does not install tools.' }
  $Chezmoi = $command.Source
}
$Chezmoi = (Get-Item -LiteralPath $Chezmoi).FullName

function Invoke-Chezmoi {
  param([string[]] $Arguments)
  $output = & $script:Chezmoi @Arguments
  if ($LASTEXITCODE -ne 0) { throw "chezmoi command failed: $($Arguments -join ' ')" }
  return ($output -join "`n")
}

function Get-DestinationState {
  param([string] $Directory)
  $entries = foreach ($item in Get-ChildItem -LiteralPath $Directory -Force -Recurse | Sort-Object FullName) {
    $relative = [IO.Path]::GetRelativePath($Directory, $item.FullName)
    $hash = if ($item.PSIsContainer) { 'directory' } else { (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
    "$relative=$hash"
  }
  return ($entries -join "`n")
}

# Parse all native PowerShell files without loading profiles or executing them.
foreach ($file in Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.ps1') {
  # modify_ templates are Go source; their rendered PowerShell targets are parsed separately.
  if ($file.Name.StartsWith('modify_')) { continue }
  $tokens = $null
  $parseErrors = $null
  $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref] $tokens, [ref] $parseErrors)
  if ($parseErrors.Count -gt 0) { throw "Invalid PowerShell syntax: $($file.FullName)" }
}

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-check-' + [Guid]::NewGuid().ToString('N'))
$null = [IO.Directory]::CreateDirectory($scratch)
try {
  # The source path intentionally contains spaces. Never initialize the real checkout here.
  $source = Join-Path $scratch 'source with spaces'
  $destination = Join-Path $scratch 'isolated home'
  $null = [IO.Directory]::CreateDirectory($source)
  $null = [IO.Directory]::CreateDirectory($destination)
  foreach ($entry in Get-ChildItem -LiteralPath $repoRoot -Force) {
    if ($entry.Name -notin @('.git', '.artifacts', '.cache', '.tmp')) {
      Copy-Item -LiteralPath $entry.FullName -Destination $source -Recurse -Force
    }
  }
  & git -c init.templateDir= init --quiet --initial-branch=main -- $source
  if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the isolated source repository.' }

  $null = & (Join-Path $source 'install.ps1') -Mode Plan
  if ($IsWindows) {
    & (Join-Path $source 'install.ps1') -Mode Check
    if ($LASTEXITCODE -ne 0) { throw 'Native PowerShell entry point failed.' }
  } else {
    & sh (Join-Path $source 'install.sh') --plan
    if ($LASTEXITCODE -ne 0) { throw 'POSIX plan failed.' }
    & sh (Join-Path $source 'install.sh') --check
    if ($LASTEXITCODE -ne 0) { throw 'POSIX check failed.' }
  }

  $config = Join-Path $scratch 'config.toml'
  $base = @('--source', $source, '--destination', $destination, '--config', $config,
    '--cache', (Join-Path $scratch 'cache'), '--persistent-state', (Join-Path $scratch 'state.boltdb'),
    '--no-tty', '--no-pager')

  # Fixture overrides simulate template data only. Native runner tests below are separate.
  foreach ($fixture in Get-ChildItem -LiteralPath (Join-Path $source 'tests/fixtures') -Filter '*.json' | Sort-Object Name) {
    $data = Get-Content -LiteralPath $fixture.FullName -Raw | ConvertFrom-Json
    $arguments = $base + @('--override-data-file', $fixture.FullName, 'execute-template', '--init', '--file', (Join-Path $source 'home/.chezmoi.toml.tmpl'))
    $rendered = Invoke-Chezmoi -Arguments $arguments
    if ($rendered -notmatch ('(?m)^platform = "' + [regex]::Escape($data.platform) + '"$')) {
      throw "Wrong platform rendering: $($fixture.Name)"
    }
    if ($rendered -notmatch '(?m)^sourceDir = ".+"$') { throw 'Missing sourceDir in initialization template.' }
    Write-Output "Template fixture: $($fixture.BaseName) OK"
  }

  $invalid = Join-Path $scratch 'invalid.json'
  '{"platform":"freebsd","chezmoi":{"os":"freebsd"}}' | Set-Content -LiteralPath $invalid -Encoding utf8NoBOM
  $null = & $Chezmoi @base --override-data-file $invalid execute-template --init --file (Join-Path $source 'home/.chezmoi.toml.tmpl') 2> (Join-Path $scratch 'expected-error.txt')
  if ($LASTEXITCODE -eq 0) { throw 'Unsupported platform was accepted.' }
  '{"platform":"fedora","chezmoi":{"os":"windows"}}' | Set-Content -LiteralPath $invalid -Encoding utf8NoBOM
  $null = & $Chezmoi @base --override-data-file $invalid execute-template --init --file (Join-Path $source 'home/.chezmoi.toml.tmpl') 2> (Join-Path $scratch 'expected-error.txt')
  if ($LASTEXITCODE -eq 0) { throw 'OS/platform mismatch was accepted.' }

  '.zshrc must survive' | Set-Content -LiteralPath (Join-Path $destination '.zshrc') -Encoding utf8NoBOM
  'Unmanaged file must survive' | Set-Content -LiteralPath (Join-Path $destination 'existing-marker.txt') -Encoding utf8NoBOM
  $before = Get-DestinationState -Directory $destination

  # Real init on this runner, with config/cache/state/destination all under scratch.
  $null = Invoke-Chezmoi -Arguments ($base + @('init', '--config-path', $config))
  $firstConfig = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash
  $null = Invoke-Chezmoi -Arguments ($base + @('init', '--config-path', $config))
  if ((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash -ne $firstConfig) { throw 'Repeat initialization changed machine data.' }

  # Omit --source here: persisted config must work without masking a wrong pointer.
  $configured = @('--destination', $destination, '--config', $config,
    '--cache', (Join-Path $scratch 'cache'), '--persistent-state', (Join-Path $scratch 'state.boltdb'),
    '--no-tty', '--no-pager')
  $actualData = Invoke-Chezmoi -Arguments ($configured + @('data', '--format', 'json')) | ConvertFrom-Json
  if ([IO.Path]::GetFullPath($actualData.chezmoi.workingTree) -ne [IO.Path]::GetFullPath($source)) {
    throw 'Persisted sourceDir does not identify the actual checkout root.'
  }
  if ([IO.Path]::GetFullPath($actualData.chezmoi.sourceDir) -ne [IO.Path]::GetFullPath((Join-Path $source 'home'))) {
    throw 'Effective source state root does not identify the home subdirectory.'
  }
  if (-not $actualData.repository -or $actualData.repository.owner -ne 'imcherry5778-brain') { throw 'Shared data was not loaded from home.' }
  if (-not $actualData.features.ai -or $actualData.deployment.enabled -or $actualData.deployment.externals) { throw 'Safe machine defaults are wrong.' }
  if ($actualData.features.personal_fedora -or $actualData.features.conda -or $actualData.features.editor_web) { throw 'Personal Fedora features were selected implicitly.' }

  $managed = Invoke-Chezmoi -Arguments ($configured + @('managed'))
  if ($managed.Trim()) { throw "Unexpected foundation deployment targets: $managed" }
  $diff = Invoke-Chezmoi -Arguments ($configured + @('diff'))
  if ($diff.Trim()) { throw 'Foundation produces a target diff.' }
  $null = Invoke-Chezmoi -Arguments ($configured + @('apply'))
  $null = Invoke-Chezmoi -Arguments ($configured + @('apply'))
  if ((Get-DestinationState -Directory $destination) -ne $before) { throw 'Isolated apply changed existing destination contents.' }
  Write-Output 'Native init, repeat init, zero targets/diff and unmanaged-file preservation: OK'
} finally {
  Remove-Item -LiteralPath $scratch -Recurse -Force
}

Write-Output 'Foundation verification passed. Real user home was not a destination.'
