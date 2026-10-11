#Requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$release = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'chezmoi-release.json') -Raw | ConvertFrom-Json -AsHashtable
$osName = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'darwin' } elseif ($IsLinux) { 'linux' } else { throw 'Unsupported test operating system.' }
$architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
$archName = switch ($architecture) {
  'x64' { 'amd64' }
  'arm64' { 'arm64' }
  default { throw "Unsupported test architecture: $architecture" }
}
$assetKey = "$osName-$archName"
if (-not $release.assets.ContainsKey($assetKey)) { throw "No pinned test asset: $assetKey" }
$asset = $release.assets[$assetKey]
$directory = [IO.Path]::GetFullPath($Destination)
$null = [IO.Directory]::CreateDirectory($directory)
$binary = Join-Path $directory $asset.name
$url = "https://github.com/twpayne/chezmoi/releases/download/v$($release.version)/$($asset.name)"
Invoke-WebRequest -Uri $url -OutFile $binary
$actualHash = (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $asset.sha256) {
  Remove-Item -LiteralPath $binary
  throw "Checksum mismatch: $($asset.name)"
}
if (-not $IsWindows) {
  # The absolute path cannot begin with '-'; BSD chmod treats a post-mode '--' as a file.
  & chmod 755 $binary
  if ($LASTEXITCODE -ne 0) { throw 'Could not make the test binary executable.' }
}
Write-Output $binary
