# Shared native PowerShell 7 settings; never downloads tools or starts agents.
if ($PSVersionTable.PSVersion.Major -lt 7) { return }
if (Get-Command mise -CommandType Application -ErrorAction SilentlyContinue) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    (& zoxide init powershell) | Out-String | Invoke-Expression
}
if (Get-Command carapace -CommandType Application -ErrorAction SilentlyContinue) {
    (& carapace _carapace powershell) | Out-String | Invoke-Expression
}
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# Interactive host only. Standard PowerShell aliases (ls/cat/cd) remain intact.
if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History -HistoryNoDuplicates -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    if (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue) {
        Set-PSReadLineKeyHandler -Chord Ctrl+r -ScriptBlock {
            $path = (Get-PSReadLineOption).HistorySavePath
            if (Test-Path -LiteralPath $path) {
                $selection = Get-Content -LiteralPath $path | Select-Object -Unique | fzf --tac --no-sort
                if ($selection) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
                }
            }
        }
        Set-PSReadLineKeyHandler -Chord Ctrl+t -ScriptBlock {
            $selection = fd --type f --hidden --exclude .git | fzf
            if ($selection) {
                $quoted = "'" + $selection.Replace("'", "''") + "'"
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quoted)
            }
        }
    }
}
function yy {
    $file = Join-Path ([IO.Path]::GetTempPath()) ('yazi-cwd-' + [Guid]::NewGuid().ToString('N'))
    try {
        & yazi @args --cwd-file $file
        if (Test-Path -LiteralPath $file) {
            $directory = (Get-Content -LiteralPath $file -Raw).Trim()
            if ($directory -and (Test-Path -LiteralPath $directory -PathType Container)) { Set-Location -LiteralPath $directory }
        }
    } finally { if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file } }
}
