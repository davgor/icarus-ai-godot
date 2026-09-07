# Canonical validation command.
# Usage: .\scripts\test.ps1

$ErrorActionPreference = "Stop"
$lib = Join-Path $PSScriptRoot "lib\engine.ps1"
. $lib

$repoRoot = Get-RepoRoot
$engine = Get-EnginePath
Write-Host "Engine: $engine"
Write-Host "Repo:   $repoRoot"

$lfsPointerPrefix = "version https://git-lfs.github.com/spec/v1"
$artRoot = Join-Path $repoRoot "game\art"
if (Test-Path $artRoot) {
    $lfsPointers = Get-ChildItem -Path $artRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^\.(glb|png|jpe?g|webp)$' -and $_.Length -le 300 } |
        Where-Object {
            $head = Get-Content -LiteralPath $_.FullName -TotalCount 1 -ErrorAction SilentlyContinue
            $head -eq $lfsPointerPrefix
        }
    if ($lfsPointers) {
        $names = $lfsPointers | ForEach-Object { $_.FullName.Substring($repoRoot.Length).TrimStart('\', '/') }
        Write-Error ("Git LFS payloads are missing (pointer files on disk). Run: git lfs install; git lfs pull`n  " + ($names -join "`n  "))
        exit 1
    }
}

$scriptErrors = @()
$gdFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.gd |
    Where-Object { $_.FullName -notmatch '\\.godot\\|\\builds\\' }

foreach ($gd in $gdFiles) {
    $resPath = "res://" + $gd.FullName.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/')
    Write-Host "Syntax check $resPath"
    $check = Invoke-Engine -EnginePath $engine -EngineArgs @(
        "--headless",
        "--path", $repoRoot,
        "--check-only",
        "-s", $resPath
    ) -TimeoutSeconds 30 -LogPrefix ("check-" + $gd.BaseName)

    $combined = "$($check.StdOut)$($check.StdErr)"
    if ($combined -match "Parse Error" -or $combined -match "SCRIPT ERROR" -or $combined -match "Compilation failed") {
        $scriptErrors += $resPath
    }
}

if ($scriptErrors.Count -gt 0) {
    Write-Error ("Syntax check failed:`n  " + ($scriptErrors -join "`n  "))
    exit 1
}

Write-Host "Running headless suite..."
$result = Invoke-Engine -EnginePath $engine -EngineArgs @(
    "--headless",
    "--path", $repoRoot,
    "-s", "res://tests/run_tests.gd"
) -TimeoutSeconds 90 -LogPrefix "test"

$combined = "$($result.StdOut)$($result.StdErr)"
if ($combined -match "SCRIPT ERROR" -or $combined -match "Parse Error") {
    Write-Error "Headless tests reported a script error."
    exit 1
}

if ($result.StdOut -notmatch "TEST_RESULT: PASS") {
    Write-Error "Headless tests did not report TEST_RESULT: PASS."
    exit 1
}

if ($result.ExitCode -ne 0) {
    Write-Error "Headless tests exited with code $($result.ExitCode)."
    exit $result.ExitCode
}

Write-Host "Tests passed."
exit 0
