#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string] $PlanPath, [Parameter(Mandatory)][string] $ReportPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if (-not $IsWindows) { throw 'Native Windows execution required.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$catalog = (Get-Content (Join-Path $repo 'home/.chezmoidata/windows.json') -Raw | ConvertFrom-Json).windows
$plan = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
$commands = @($plan.bootstrap.command) + @($catalog.mise.PSObject.Properties.Value.command) + @('node','npm','zig','aider','opencode','ya','uvx') + @($plan.official.command)
$results = @()
foreach ($name in $commands | Select-Object -Unique) {
    $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { throw "Missing command in the native mise environment: $name" }
    $output = & $command.Source --version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "$name --version failed (exit $LASTEXITCODE)." }
    $results += @{command=$name;path=$command.Source;version=$output.Trim();exitCode=$LASTEXITCODE}
}
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-cli-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    $file = Join-Path $scratch 'sample with spaces.json'
    '{"answer":42,"message":"native Windows"}' | Set-Content -LiteralPath $file -Encoding utf8NoBOM
    $found = & rg --files $scratch | Out-String
    if ($LASTEXITCODE -ne 0 -or $found -notmatch 'sample with spaces.json') { throw 'ripgrep file search failed.' }
    $found = & fd --type f --base-directory $scratch | Out-String
    if ($LASTEXITCODE -ne 0 -or $found -notmatch 'sample with spaces.json') { throw 'fd file search failed.' }
    $value = & jq -r .answer $file
    if ($LASTEXITCODE -ne 0 -or $value -ne '42') { throw 'jq JSON evaluation failed.' }
    $text = & bat --style=plain --color=never $file | Out-String
    if ($LASTEXITCODE -ne 0 -or $text -notmatch 'native Windows') { throw 'bat file reading failed.' }
    $picked = @('first','native Windows') | & fzf --filter 'native Windows'
    if ($LASTEXITCODE -ne 0 -or $picked -ne 'native Windows') { throw 'fzf filtering failed.' }
    & git -c init.templateDir= init --quiet $scratch
    if ($LASTEXITCODE -ne 0) { throw 'Git native initialization failed.' }
    $help = & codex --help | Out-String
    if ($LASTEXITCODE -ne 0 -or $help -notmatch 'Codex') { throw 'Codex command package failed.' }
    foreach ($name in @('agy','claude','aider','opencode','pi','kiro-cli','grok')) {
        $help = & $name --help 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not $help.Trim()) { throw "$name native help failed." }
    }
    # Avoid user config during this binary/runtime smoke test. LazyVim is checked separately.
    & nvim --headless -u NONE '+lua assert(vim.fn.has("win32") == 1); assert(vim.fn.filereadable(vim.env.VIMRUNTIME .. "/doc/help.txt") == 1)' +qa
    if ($LASTEXITCODE -ne 0) { throw 'Neovim Windows runtime failed.' }
    & mise exec 'pypi:aider-chat' -- python -c 'import sys; import aider; assert sys.version_info[:2] == (3, 12)'
    if ($LASTEXITCODE -ne 0) { throw 'Aider Python 3.12 isolation failed.' }
    @{tools=$results;functionalChecks='rg/fd/jq/bat/fzf/Git/AI help/Neovim runtime/Aider Python';verifiedAt=(Get-Date).ToUniversalTime().ToString('o')} |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportPath -Encoding utf8NoBOM
    Write-Output "Native execution passed for $($results.Count) commands and functional smoke checks."
} finally { Remove-Item -LiteralPath $scratch -Recurse -Force }
