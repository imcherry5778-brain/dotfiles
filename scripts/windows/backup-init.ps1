#Requires -Version 5.1
param([Parameter(Mandatory)][string] $ConfigPath)
$ErrorActionPreference = 'Stop'
$path = [IO.Path]::GetFullPath($ConfigPath)
if (-not $path.StartsWith($HOME + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Config backup must be inside the actual login home.' }
if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).LinkType) { throw 'Config must be a regular file.' }
$backup = Join-Path $HOME ('.local/state/dotfiles/init-backups/init-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $backup -Force
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
& icacls $backup /inheritance:r /grant:r "*${sid}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Cannot protect config backup.' }
Copy-Item -LiteralPath $path -Destination (Join-Path $backup 'chezmoi.toml')
(Get-Acl -LiteralPath $path).Sddl | Set-Content -LiteralPath (Join-Path $backup 'acl.txt') -Encoding UTF8
