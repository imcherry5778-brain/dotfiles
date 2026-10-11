# Windows provider adapters. Dot-source only; callers decide when to mutate.
function Add-UserCommandPath {
    param([string] $Directory)
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { throw "Missing command directory: $Directory" }
    $current = [Environment]::GetEnvironmentVariable('Path','User')
    $entries = @($current -split ';' | Where-Object { $_ })
    if ($Directory.TrimEnd('\','/') -notin @($entries | ForEach-Object { $_.TrimEnd('\','/') })) {
        [Environment]::SetEnvironmentVariable('Path',(($entries + $Directory) -join ';'),'User')
    }
    Update-SessionPath
}
function Get-OfficialCommandPath {
    param([string] $Tool)
    $directories = switch ($Tool) {
        'agy' { Join-Path $env:LOCALAPPDATA 'agy/bin' }
        'claude' { Join-Path $HOME '.local/bin' }
        'codex' { Join-Path $env:LOCALAPPDATA 'Programs/OpenAI/Codex/bin' }
        'pi' { Join-Path $HOME '.pi/agent/bin' }
        'kiro' { Join-Path $env:ProgramFiles 'Kiro-Cli' }
        'grok' { Join-Path $HOME '.grok/bin' }
        default { throw "Unknown official CLI: $Tool" }
    }
    return $directories
}
function Invoke-VendorInstaller {
    param([string] $Script, [string[]] $Arguments, [string] $Log)
    # A separate native process prevents vendor exit statements and preferences
    # from changing our installer. Closed stdin selects Pi's documented default.
    # mise exec makes the already-installed Node available without another Node install.
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command mise -CommandType Application).Source
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @('exec','--','pwsh','-NoLogo','-NoProfile','-NonInteractive','-File',$Script) + $Arguments) {
        $start.ArgumentList.Add($argument)
    }
    $start.Environment['CODEX_NON_INTERACTIVE'] = '1'
    $process = [Diagnostics.Process]::Start($start)
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    try {
        if (-not $process.WaitForExit(1200000)) {
            $process.Kill($true)
            throw "Vendor installer timed out: $Script"
        }
        [IO.File]::WriteAllText($Log,($stdout.GetAwaiter().GetResult() + "`n" + $stderr.GetAwaiter().GetResult()))
        if ($process.ExitCode -ne 0) { throw "Official installer failed (exit $($process.ExitCode)); inspect private log: $Log" }
    } finally { $process.Dispose() }
}
function Install-OfficialCli {
    param($Installer, [string] $Backup)
    $directory = Get-OfficialCommandPath $Installer.tool
    if (Get-Command $Installer.command -ErrorAction SilentlyContinue) {
        Write-Output "$($Installer.tool): existing provider preserved."
        return
    }
    $extension = if ($Installer.tool -eq 'pi') { '.cmd' } else { '.exe' }
    $binary = Join-Path $directory ($Installer.command + $extension)
    if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
        $script = Join-Path $Backup ($Installer.tool + '-official-install.ps1')
        Receive-VerifiedFile $Installer $script
        # Only the checksum-reviewed local script is unblocked; execution policy stays unchanged.
        Unblock-File -LiteralPath $script
        Invoke-VendorInstaller $script @($Installer.arguments) (Join-Path $Backup ($Installer.tool + '-install.log'))
    }
    if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
        throw "$($Installer.tool) did not produce its official native command: $binary"
    }
    # Some vendor installers only print PATH instructions. Register the actual
    # publisher directory once; keep the installed binary and all companion files.
    Add-UserCommandPath $directory
    if (-not (Get-Command $Installer.command -ErrorAction SilentlyContinue)) { throw "Missing $($Installer.command) after PATH registration." }
    Write-Output "$($Installer.tool): official installation complete."
}
function Test-WindowsTools {
    param([string] $Review)
    $report = Join-Path $Review 'tool-verification.json'
    Invoke-Checked 'mise' @('exec','--','pwsh','-NoProfile','-File',(Join-Path $PSScriptRoot 'verify-tools.ps1'),
        '-PlanPath',(Join-Path $Review 'packages.json'),'-ReportPath',$report)
    Write-Output "Actual Windows tool verification: $report"
}
