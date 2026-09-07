# Launch the newest playable build.
# Usage: .\scripts\play.ps1

$ErrorActionPreference = "Stop"
$lib = Join-Path $PSScriptRoot "lib\engine.ps1"
. $lib

$repoRoot = Get-RepoRoot
$latestExe = Join-Path $repoRoot "builds\latest\IcarusAI.exe"

if (Test-Path -LiteralPath $latestExe) {
    $buildInfo = Join-Path $repoRoot "builds\latest\BUILD.txt"
    if (Test-Path -LiteralPath $buildInfo) {
        Write-Host (Get-Content -Raw -LiteralPath $buildInfo)
    }
    Write-Host "Launching $latestExe"
    Start-Process -FilePath $latestExe -WorkingDirectory (Split-Path $latestExe)
    exit 0
}

Write-Host "No exported build in builds/latest. Running the project in game mode."
$engine = Get-EnginePath
Start-Process -FilePath $engine -ArgumentList @("--path", $repoRoot) -WorkingDirectory $repoRoot
