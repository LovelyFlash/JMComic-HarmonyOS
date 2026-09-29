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
$env:DEVECO_SDK_HOME = "F:\DevEco Studio\sdk"
$env:HOS_SDK_HOME = "F:\DevEco Studio\sdk\default\openharmony"
Set-Location $projectRoot
$buildOutput = & "F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p module=entry -p product=default --no-daemon 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  BUILD SUCCESSFUL" -ForegroundColor Green
} else {
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    $buildOutput | Select-String "ERROR|Error Message" | Select-Object -First 10
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
