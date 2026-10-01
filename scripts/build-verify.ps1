# PicaComic HarmonyOS - Build Verification Script
# Usage: .\scripts\build-verify.ps1

$ErrorActionPreference = "Stop"
$projectRoot = "F:\Programming\Code\VS_Code\ArkTS\PicaComic-HarmonyOS\ohos"
$etsRoot = Join-Path $projectRoot "entry\src\main\ets"

Write-Host "=== PicaComic HarmonyOS Build Verification ===" -ForegroundColor Cyan

# 1. Check file counts
$etsFiles = Get-ChildItem $etsRoot -Recurse -Filter *.ets
Write-Host "`n[1/5] File Inventory" -ForegroundColor Yellow
Write-Host "  Source files: $($etsFiles.Count)"

# 2. Check for encoding corruption
Write-Host "`n[2/5] Encoding Check" -ForegroundColor Yellow
$corruptCount = 0
foreach ($f in $etsFiles) {
    $c = Get-Content $f.FullName -Raw
    if ($c -match '\uFFFD') {
        Write-Host "  CORRUPT: $($f.Name)" -ForegroundColor Red
        $corruptCount++
    }
}
if ($corruptCount -eq 0) { Write-Host "  OK: No encoding corruption" -ForegroundColor Green }

# 3. Check for ArkTS violations
Write-Host "`n[3/5] ArkTS Compliance Check" -ForegroundColor Yellow
$violations = 0
foreach ($f in $etsFiles) {
    $c = Get-Content $f.FullName -Raw
    $lines = Get-Content $f.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match ':\s*any\b' -and $line -notmatch '//|interface|type\s') {
            Write-Host "  ANY: $($f.Name):$($i+1)" -ForegroundColor Red
            $violations++
        }
        if ($line -match ':\s*unknown\b' -and $line -notmatch '//') {
            Write-Host "  UNKNOWN: $($f.Name):$($i+1)" -ForegroundColor Red
            $violations++
        }
    }
    if ($c -match '@ComponentV2' -and $c -match '@StorageLink') {
        Write-Host "  V2+STORAGELINK: $($f.Name)" -ForegroundColor Red
        $violations++
    }
}
if ($violations -eq 0) { Write-Host "  OK: No ArkTS violations" -ForegroundColor Green }

# 4. Check for design token usage
Write-Host "`n[4/5] Design Token Check" -ForegroundColor Yellow
$hardcodedColors = 0
foreach ($f in $etsFiles) {
    $lines = Get-Content $f.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "isDarkMode \? '#") {
            Write-Host "  HARDCODED: $($f.Name):$($i+1)" -ForegroundColor Red
            $hardcodedColors++
        }
    }
}
if ($hardcodedColors -eq 0) { Write-Host "  OK: All colors use ThemeManager" -ForegroundColor Green }

# 5. Build
Write-Host "`n[5/5] Build" -ForegroundColor Yellow
$devEcoHome = "D:\DevEco Studio"
if (-not (Test-Path (Join-Path $devEcoHome "tools\hvigor\bin\hvigorw.bat"))) {
    $devEcoHome = "F:\DevEco Studio"
}
$env:DEVECO_SDK_HOME = Join-Path $devEcoHome "sdk"
$env:HOS_SDK_HOME = Join-Path $devEcoHome "sdk\default\openharmony"
$nodeBin = Join-Path $devEcoHome "tools\node"
if (Test-Path $nodeBin) { $env:PATH = "$nodeBin;" + $env:PATH }
Set-Location $projectRoot
# hvigor 把 WARN 写到 stderr，PowerShell 在 ErrorActionPreference=Stop 下会把原生命令 stderr 当终止错误，构建期间临时降级
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$buildOutput = & (Join-Path $devEcoHome "tools\hvigor\bin\hvigorw.bat") assembleHap --mode module -p module=entry -p product=default --no-daemon 2>&1
$ErrorActionPreference = $prevEap
$buildFailed = $LASTEXITCODE -ne 0
if (-not $buildFailed) {
    $errLines = @($buildOutput | Select-String "ArkTS:ERROR")
    if ($errLines.Count -gt 0) { $buildFailed = $true }
}
if (-not $buildFailed) {
    Write-Host "  BUILD SUCCESSFUL" -ForegroundColor Green
} else {
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    $buildOutput | Select-String "ERROR|Error Message" | Select-Object -First 10
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
