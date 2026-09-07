# Resolves a Godot-compatible editor binary.
# Preference: GODOT_BIN, then `godot` on PATH, then Summer Engine.

function Get-RepoRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-Path -LiteralPath (Join-Path $dir "project.godot")) {
            return (Resolve-Path -LiteralPath $dir).Path
        }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    throw "Could not find project.godot above $PSScriptRoot"
}

function Get-EnginePath {
    if ($env:GODOT_BIN -and (Test-Path -LiteralPath $env:GODOT_BIN)) {
        return (Resolve-Path -LiteralPath $env:GODOT_BIN).Path
    }

    $godotCmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($godotCmd -and $godotCmd.Source) {
        return $godotCmd.Source
    }

    $summer = Join-Path $env:LOCALAPPDATA "SummerEngine\current\Summer.exe"
    if (Test-Path -LiteralPath $summer) {
        return $summer
    }

    throw @"
No Godot-compatible editor found.
Set GODOT_BIN to a Godot 4.7 editor binary, install Godot on PATH, or install Summer Engine.
"@
}

function Get-BundledExportTemplatesDir {
    param([string]$EnginePath)
    $engineDir = Split-Path -Parent $EnginePath
    $candidate = Join-Path $engineDir "export_templates\4.7.2.stable"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }
    return $null
}

function Invoke-Engine {
    param(
        [string]$EnginePath,
        [string[]]$EngineArgs,
        [int]$TimeoutSeconds = 120,
        [string]$LogPrefix = "engine"
    )

    $repoRoot = Get-RepoRoot
    $logsDir = Join-Path $repoRoot "builds\.logs"
    New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
    $stdoutPath = Join-Path $logsDir "$LogPrefix.stdout.log"
    $stderrPath = Join-Path $logsDir "$LogPrefix.stderr.log"

    $argString = ($EngineArgs | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join ' '
    Write-Host "-> $EnginePath $argString"

    $proc = Start-Process -FilePath $EnginePath -ArgumentList $argString -WorkingDirectory $repoRoot -PassThru -Wait:$false -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    $finished = $proc.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) {
        try { $proc.Kill() } catch {}
        throw "Engine timed out after $TimeoutSeconds seconds ($LogPrefix)."
    }

    $proc.Refresh()
    $exitCode = 0
    if ($null -ne $proc.ExitCode) {
        $exitCode = [int]$proc.ExitCode
    }

    $stdout = ""
    $stderr = ""
    if (Test-Path $stdoutPath) { $stdout = Get-Content -Raw -LiteralPath $stdoutPath }
    if (Test-Path $stderrPath) { $stderr = Get-Content -Raw -LiteralPath $stderrPath }
    if ($stdout) { Write-Host $stdout }
    if ($stderr) { Write-Host $stderr }

    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut   = $stdout
        StdErr   = $stderr
    }
}
