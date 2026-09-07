# Canonical build command.
# Usage: .\scripts\build.ps1
# Runs tests, exports a uniquely identified Windows build, and updates builds/latest.

$ErrorActionPreference = "Stop"
$lib = Join-Path $PSScriptRoot "lib\engine.ps1"
. $lib

$repoRoot = Get-RepoRoot
$engine = Get-EnginePath

Write-Host "=== TEST ==="
& (Join-Path $PSScriptRoot "test.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Tests failed; refusing to build."
}

$commit = (git -C $repoRoot rev-parse --short HEAD).Trim()
$count = (git -C $repoRoot rev-list --count HEAD).Trim()
$dirty = git -C $repoRoot status --porcelain
$fingerprint = if ($dirty) { "dirty" } else { "clean" }
$buildId = "{0:D5}" -f [int]$count
if ($dirty) { $buildId = "$buildId-dirty" }

$windowsDir = Join-Path $repoRoot "builds\windows"
$latestDir = Join-Path $repoRoot "builds\latest"
$archiveDir = Join-Path $repoRoot ("builds\{0}-{1}" -f $buildId, $commit)
New-Item -ItemType Directory -Force -Path $windowsDir, $latestDir, $archiveDir | Out-Null

$exeName = "IcarusAI.exe"
$exportPath = Join-Path $windowsDir $exeName

$templatesDir = Get-BundledExportTemplatesDir -EnginePath $engine
$presetsPath = Join-Path $repoRoot "export_presets.cfg"
$presetsOriginal = Get-Content -Raw -LiteralPath $presetsPath
$patched = $false

try {
    if ($templatesDir) {
        $releaseTemplate = (Join-Path $templatesDir "windows_release_x86_64.exe").Replace('\', '/')
        $debugTemplate = (Join-Path $templatesDir "windows_debug_x86_64.exe").Replace('\', '/')
        $presets = $presetsOriginal
        $presets = $presets.Replace('custom_template/release=""', "custom_template/release=`"$releaseTemplate`"")
        $presets = $presets.Replace('custom_template/debug=""', "custom_template/debug=`"$debugTemplate`"")
        Set-Content -LiteralPath $presetsPath -Value $presets -NoNewline
        $patched = $true
        Write-Host "Using export templates from $templatesDir"
    }

    Write-Host "=== EXPORT ==="
    $export = Invoke-Engine -EnginePath $engine -EngineArgs @(
        "--headless",
        "--path", $repoRoot,
        "--export-release", "WindowsDesktop", $exportPath
    ) -TimeoutSeconds 180 -LogPrefix "export"

    $combined = "$($export.StdOut)$($export.StdErr)"
    $exportOk = (Test-Path -LiteralPath $exportPath) -and ($combined -notmatch "Failed to export" -and $combined -notmatch "No export template")
    if (-not $exportOk) {
        throw "Export failed. Engine output did not produce $exportPath."
    }
}
finally {
    if ($patched) {
        Set-Content -LiteralPath $presetsPath -Value $presetsOriginal -NoNewline
    }
}

$buildRecord = @"
Build $buildId
Commit: $commit
Tree: $fingerprint
Platform: Windows
Status: PASS
Engine: $engine
Exported: $exportPath
"@

Set-Content -LiteralPath (Join-Path $windowsDir "BUILD.txt") -Value $buildRecord
Set-Content -LiteralPath (Join-Path $archiveDir "BUILD.txt") -Value $buildRecord
Copy-Item -LiteralPath $exportPath -Destination (Join-Path $archiveDir $exeName) -Force
Copy-Item -LiteralPath $exportPath -Destination (Join-Path $latestDir $exeName) -Force
Copy-Item -LiteralPath (Join-Path $windowsDir "BUILD.txt") -Destination (Join-Path $latestDir "BUILD.txt") -Force

Get-ChildItem -LiteralPath $windowsDir -Filter "IcarusAI.*" |
    Where-Object { $_.Name -ne $exeName } |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $latestDir $_.Name) -Force
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $archiveDir $_.Name) -Force
    }

Write-Host $buildRecord
Write-Host "Play with: .\scripts\play.ps1"
