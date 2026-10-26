#Requires -Version 7.0
[CmdletBinding()]
param([string] $Chezmoi = $env:CHEZMOI_BIN)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($IsWindows) { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) }
if (-not $IsWindows) { throw 'Native Windows verifier requires Windows.' }
if (-not $Chezmoi) { $Chezmoi = (Get-Command chezmoi -CommandType Application).Source }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-native-windows-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $scratch
function Invoke-Chezmoi {
    param([string[]] $Arguments)
    $output = & $Chezmoi @Arguments
    if ($LASTEXITCODE -ne 0) { throw "chezmoi failure: $($Arguments -join ' ')" }
    return ($output -join "`n")
}
function Get-FileState {
    param([string] $Directory)
    return @(Get-ChildItem -LiteralPath $Directory -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
        [IO.Path]::GetRelativePath($Directory,$_.FullName) + '=' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }) -join "`n"
}
try {
    foreach ($entry in Get-ChildItem -LiteralPath $repo -Recurse -Force) {
        if ($entry.FullName -match '[\\/]\.git[\\/]') { continue }
        if ($entry.Name -match '[<>:"|?*]' -or $entry.Name -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)' -or $entry.Name -match '[. ]$') {
            throw "Source name cannot be checked out on Windows: $($entry.Name)"
        }
    }
    $source = Join-Path $scratch 'source with spaces'
    $destination = Join-Path $scratch 'isolated user with spaces'
    $null = New-Item -ItemType Directory -Path $source,$destination
    foreach ($item in Get-ChildItem -LiteralPath $repo -Force) {
        if ($item.Name -notin @('.git','.artifacts','.cache','.tmp')) { Copy-Item -LiteralPath $item.FullName -Destination $source -Recurse }
    }
    & git -c init.templateDir= init --quiet --initial-branch=main -- $source
    if ($LASTEXITCODE -ne 0) { throw 'Fixture source init failed.' }
    $selection = Get-Content -LiteralPath (Join-Path $source 'tests/profiles/windows-full.json') -Raw | ConvertFrom-Json
    $override = Join-Path $scratch 'selection.json'
    $selection | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $override -Encoding utf8NoBOM
    $config = Join-Path $scratch 'chezmoi.toml'
    $base = @('--source',$source,'--destination',$destination,'--config',$config,'--cache',(Join-Path $scratch 'cache'),
        '--persistent-state',(Join-Path $scratch 'state.boltdb'),'--no-tty','--no-pager')
    $rendered = Invoke-Chezmoi ($base + @('--override-data-file',$override,'execute-template','--init','--file',(Join-Path $source 'home/.chezmoi.toml.tmpl')))
    $rendered | Set-Content -LiteralPath $config -Encoding utf8NoBOM
    $profileFile = Join-Path $destination 'Documents/PowerShell/profile.ps1'
    $legacyFile = Join-Path $destination 'Documents/WindowsPowerShell/profile.ps1'
    foreach ($path in @($profileFile,$legacyFile,(Join-Path $destination '.claude/settings.json'),(Join-Path $destination '.codex/config.toml'))) {
        $null = New-Item -ItemType Directory -Path (Split-Path $path) -Force
    }
    "function retained_customization { 'preserved' }`n" | Set-Content -LiteralPath $profileFile -Encoding utf8NoBOM
    'legacy PowerShell must survive' | Set-Content -LiteralPath $legacyFile -Encoding utf8NoBOM
    '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"retained-native-hook"}]}]},"statusLine":{"type":"command","command":"keep-me"}}' | Set-Content -LiteralPath (Join-Path $destination '.claude/settings.json') -Encoding utf8NoBOM
    '[custom]' + "`nretained = true`n" | Set-Content -LiteralPath (Join-Path $destination '.codex/config.toml') -Encoding utf8NoBOM
    'unmanaged must survive' | Set-Content -LiteralPath (Join-Path $destination 'unmanaged.txt') -Encoding utf8NoBOM
    $null = Invoke-Chezmoi ($base + @('apply'))
    $state = Get-FileState $destination
    $null = Invoke-Chezmoi ($base + @('apply'))
    if ($state -ne (Get-FileState $destination)) { throw 'Repeat Windows apply changed destination bytes.' }
    $null = Invoke-Chezmoi ($base + @('verify'))
    if ((Invoke-Chezmoi ($base + @('diff'))).Trim()) { throw 'Repeated Windows apply leaves a diff.' }
    $managed = @((Invoke-Chezmoi ($base + @('managed','--include=files,symlinks','--path-style=relative'))) -split "`n" | ForEach-Object { $_.Trim().Replace('\','/') })
    foreach ($relative in @('.config/powershell/Dotfiles.ps1','.config/mise/config.windows.toml','AppData/Local/nvim/init.lua','AppData/Roaming/GitHub CLI/config.yml','Documents/PowerShell/profile.ps1')) {
        if ($relative -notin $managed) { throw "Missing native target: $relative; managed=$($managed -join ' | ')" }
    }
    if ($managed | Where-Object { $_ -match '^\.(zsh|bash|tmux)' -or $_ -match '\.(oh-my-zsh|tmux)/' -or $_ -match '^\.config/nvim/' -or $_ -match 'auth\.json|hosts\.yml|credentials\.json' }) { throw 'Unix or credential targets leaked into Windows.' }
    if ((Get-Content -LiteralPath $legacyFile -Raw).Trim() -ne 'legacy PowerShell must survive') { throw 'Legacy PowerShell profile changed.' }
    $text = Get-Content -LiteralPath $profileFile -Raw
    $loader = ". (Join-Path " + '$HOME' + " '.config/powershell/Dotfiles.ps1')"
    if ($text -notmatch 'retained_customization' -or ([regex]::Matches($text,[regex]::Escape($loader))).Count -ne 1) { throw 'Profile insertion lost content or duplicated loader.' }
    $settings = Get-Content -LiteralPath (Join-Path $destination '.claude/settings.json') -Raw | ConvertFrom-Json
    if ($settings.hooks.UserPromptSubmit[0].hooks[0].command -ne 'retained-native-hook' -or $settings.statusLine.command -ne 'keep-me') { throw 'Existing Orca hooks were lost.' }
    $plan = Invoke-Chezmoi ($base + @('execute-template','--file',(Join-Path $source 'home/.chezmoitemplates/windows/plan.json.tmpl'))) | ConvertFrom-Json
    if ($plan.bootstrap.Count -ne 4 -or $plan.official.Count -ne 6) { throw 'Wrong bootstrap/native ownership.' }
    if ($plan.native.Count -ne 1 -or $plan.native[0].id -ne 'GitHub.Copilot' -or $plan.native[0].version -ne 'v1.0.103') { throw 'Wrong Copilot CLI WinGet declaration.' }
    if ($plan.PSObject.Properties.Name -contains 'winget') { throw 'CLI inventory leaked into WinGet.' }
    $keys = @($plan.mise.PSObject.Properties.Name)
    if ($keys.Count -ne 16 -or $keys -notcontains 'pypi:aider-chat' -or $keys -notcontains 'github:anomalyco/opencode') { throw 'Wrong Windows mise inventory.' }
    if ($plan.editor.Count -ne 1 -or $plan.editor[0].command -ne 'gcc' -or $keys -contains 'zig') { throw 'Wrong Windows parser compiler ownership.' }
    foreach ($key in $keys) {
        if ($key -match 'codex|claude|grok|pi-coding-agent|kiro|antigravity') { throw "Official provider duplicated in mise: $key" }
    }
    foreach ($item in $plan.official) {
        if ($item.url -notmatch '^https://' -or $item.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Unreviewed vendor script.' }
    }
    foreach ($file in @((Join-Path $destination '.config/powershell/Dotfiles.ps1'),$profileFile)) {
        $tokens=$null;$errors=$null
        $null=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)
        if ($errors.Count) { throw "Rendered PowerShell syntax is invalid: $file" }
    }
    $originalMiseEnv = $env:MISE_ENV
    try {
        $env:MISE_ENV = 'windows'
        & pwsh -NoProfile -File (Join-Path $source 'install.ps1') -Mode Plan
        if ($LASTEXITCODE -ne 0) { throw 'The selected native Windows mise environment was rejected.' }
        $env:MISE_ENV = 'unreviewed'
        & pwsh -NoProfile -File (Join-Path $source 'install.ps1') -Mode Plan *> (Join-Path $scratch 'expected-environment-error.txt')
        if ($LASTEXITCODE -eq 0) { throw 'An unreviewed mise environment was accepted.' }
        # The rejection is expected. Hosted pwsh checks the final native exit code.
        $global:LASTEXITCODE = 0
    } finally { $env:MISE_ENV = $originalMiseEnv }
    Write-Output 'Native Windows paths, preserved profile/hooks/legacy settings, provider ownership and repeated apply: OK'
} finally { Remove-Item -LiteralPath $scratch -Recurse -Force }
