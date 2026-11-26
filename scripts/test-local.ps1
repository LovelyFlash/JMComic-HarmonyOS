# JMComic HarmonyOS - Local unit tests
# Usage: .\scripts\test-local.ps1
# Runs hypium local tests under ohos/entry/src/test (no device required).

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$ohosRoot = Join-Path $repoRoot "ohos"

$devEcoHome = $env:DEVECO_HOME
if ([string]::IsNullOrEmpty($devEcoHome)) {
    foreach ($candidate in @("D:\DevEco Studio", "F:\DevEco Studio")) {
        if (Test-Path (Join-Path $candidate "tools\hvigor\bin\hvigorw.bat")) {
            $devEcoHome = $candidate
            break
        }
    }
}
$hvigor = if ([string]::IsNullOrEmpty($devEcoHome)) {
    ""
} else {
    Join-Path $devEcoHome "tools\hvigor\bin\hvigorw.bat"
}
if ($hvigor -eq "" -or -not (Test-Path $hvigor)) {
    Write-Host "hvigor not found; set DEVECO_HOME or install DevEco Studio" -ForegroundColor Red
    exit 1
}

$env:DEVECO_SDK_HOME = Join-Path $devEcoHome "sdk"
$env:HOS_SDK_HOME = Join-Path $devEcoHome "sdk\default\openharmony"
$nodeBin = Join-Path $devEcoHome "tools\node"
if (Test-Path $nodeBin) {
    $env:PATH = "$nodeBin;" + $env:PATH
}

Push-Location $ohosRoot
try {
    & $hvigor test -p module=entry -p coverage=true --no-daemon
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

$resultFile = Join-Path $ohosRoot "entry\.test\default\intermediates\test\coverage_data\test_result.txt"
if (Test-Path $resultFile) {
    Write-Host "`n=== Test Result ===" -ForegroundColor Cyan
    Get-Content $resultFile | Select-Object -Last 20
}
exit $exitCode
