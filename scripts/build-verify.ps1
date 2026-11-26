# PicaComic HarmonyOS - Build Verification Script
# Usage: .\scripts\build-verify.ps1
# Exit code: 0 = all checks/build passed; 1 = any check/build failed.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$ohosRoot = Join-Path $repoRoot "ohos"
$etsRoot = Join-Path $ohosRoot "entry\src\main\ets"
$moduleRoot = Join-Path $ohosRoot "entry"
$resourcesRoot = Join-Path $moduleRoot "src\main\resources"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
    $failures.Add($message)
    Write-Host "  FAIL: $message" -ForegroundColor Red
}

function Read-Utf8Strict([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $encoder = New-Object System.Text.UTF8Encoding($false, $true)
    return $encoder.GetString($bytes)
}

function Get-RelativePath([string]$path) {
    return $path.Replace($repoRoot + "\", "")
}

Write-Host "=== JMComic HarmonyOS Build Verification ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"

# 1. Inventory
Write-Host "`n[1/7] File Inventory" -ForegroundColor Yellow
$etsFiles = @(Get-ChildItem $etsRoot -Recurse -Filter *.ets -File)
$resourceFiles = @(Get-ChildItem $resourcesRoot -Recurse -File -Include *.json,*.json5)
Write-Host "  ETS files: $($etsFiles.Count)"
Write-Host "  Resource JSON files: $($resourceFiles.Count)"
if ($etsFiles.Count -eq 0) {
    Add-Failure "no .ets source files found under $etsRoot"
}

# 2. Strict UTF-8 / U+FFFD
Write-Host "`n[2/7] Encoding Check" -ForegroundColor Yellow
$encodingErrors = 0
foreach ($f in @($etsFiles + $resourceFiles)) {
    try {
        $text = Read-Utf8Strict $f.FullName
        if ($text.Contains([char]0xFFFD)) {
            Add-Failure "U+FFFD in $(Get-RelativePath $f.FullName)"
            $encodingErrors++
        }
    } catch {
        Add-Failure "invalid UTF-8: $(Get-RelativePath $f.FullName)"
        $encodingErrors++
    }
}
if ($encodingErrors -eq 0) {
    Write-Host "  OK: all source/resource text is valid UTF-8" -ForegroundColor Green
}

# 3. Version consistency
Write-Host "`n[3/7] Version Consistency" -ForegroundColor Yellow
$appJsonPath = Join-Path $ohosRoot "AppScope\app.json5"
$constantsPath = Join-Path $etsRoot "common\Constants.ets"
$changelogPath = Join-Path $etsRoot "common\Changelog.ets"
$appVersionName = ""
$appVersionCode = ""
$constantVersion = ""
$changelogVersion = ""
try {
    $appText = Read-Utf8Strict $appJsonPath
    $m = [regex]::Match($appText, '"versionCode"\s*:\s*(\d+)')
    if ($m.Success) { $appVersionCode = $m.Groups[1].Value }
    $m = [regex]::Match($appText, '"versionName"\s*:\s*"([^"]+)"')
    if ($m.Success) { $appVersionName = $m.Groups[1].Value }
} catch {
    Add-Failure "cannot read AppScope/app.json5"
}
try {
    $constantText = Read-Utf8Strict $constantsPath
    $m = [regex]::Match($constantText, "(?m)^\s*static readonly APP_VERSION\s*=\s*'([^']+)'")
    if ($m.Success) { $constantVersion = $m.Groups[1].Value }
} catch {
    Add-Failure "cannot read common/Constants.ets"
}
try {
    $changelogText = Read-Utf8Strict $changelogPath
    $m = [regex]::Match($changelogText, "new ReleaseNote\('([^']+)'")
    if ($m.Success) { $changelogVersion = $m.Groups[1].Value }
} catch {
    Add-Failure "cannot read common/Changelog.ets"
}
Write-Host "  app.json5: versionName=$appVersionName versionCode=$appVersionCode"
Write-Host "  Constants.APP_VERSION=$constantVersion"
Write-Host "  Changelog latest=$changelogVersion"
if ($appVersionName -eq "" -or $constantVersion -eq "" -or $changelogVersion -eq "") {
    Add-Failure "version fields are missing"
} elseif ($appVersionName -ne $constantVersion -or $appVersionName -ne $changelogVersion) {
    Add-Failure "version mismatch: app.json5=$appVersionName Constants=$constantVersion Changelog=$changelogVersion"
}

# 4. Color token parity
Write-Host "`n[4/7] Color Token Parity" -ForegroundColor Yellow
$baseColorPath = Join-Path $resourcesRoot "base\element\color.json"
$darkColorPath = Join-Path $resourcesRoot "dark\element\color.json"
try {
    $baseColors = (ConvertFrom-Json (Read-Utf8Strict $baseColorPath)).color | ForEach-Object { $_.name }
    $darkColors = (ConvertFrom-Json (Read-Utf8Strict $darkColorPath)).color | ForEach-Object { $_.name }
    $missingDark = @(Compare-Object $baseColors $darkColors | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject })
    $missingBase = @(Compare-Object $baseColors $darkColors | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject })
    if ($missingDark.Count -gt 0) {
        Add-Failure "color token missing in dark: $($missingDark -join ', ')"
    }
    if ($missingBase.Count -gt 0) {
        Add-Failure "color token missing in base: $($missingBase -join ', ')"
    }
    if ($missingDark.Count -eq 0 -and $missingBase.Count -eq 0) {
        Write-Host "  OK: base/dark color tokens match ($(@($baseColors).Count))" -ForegroundColor Green
    }
} catch {
    Add-Failure "cannot parse color.json files"
}

# 5. Translation parity
Write-Host "`n[5/7] Translation Parity" -ForegroundColor Yellow
try {
    $translationText = Read-Utf8Strict (Join-Path $etsRoot "common\Translations.ets")
    $fields = @([regex]::Matches($translationText, "(?m)^  ([A-Za-z0-9_]+): string = '';") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $zhKeys = @([regex]::Matches($translationText, "(?m)^\s*zhData\.([A-Za-z0-9_]+) =") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $enKeys = @([regex]::Matches($translationText, "(?m)^\s*enData\.([A-Za-z0-9_]+) =") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $caseKeys = @([regex]::Matches($translationText, "(?m)^\s*case '([A-Za-z0-9_]+)': return d\.") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missingZh = @(Compare-Object $fields $zhKeys | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject })
    $missingEn = @(Compare-Object $fields $enKeys | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject })
    $missingCase = @(Compare-Object $fields $caseKeys | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject })
    if ($missingZh.Count -gt 0) { Add-Failure "translation missing zh: $($missingZh -join ', ')" }
    if ($missingEn.Count -gt 0) { Add-Failure "translation missing en: $($missingEn -join ', ')" }
    if ($missingCase.Count -gt 0) { Add-Failure "translation missing switch case: $($missingCase -join ', ')" }
    if ($missingZh.Count -eq 0 -and $missingEn.Count -eq 0 -and $missingCase.Count -eq 0) {
        Write-Host "  OK: $($fields.Count) keys aligned across fields/zh/en/switch" -ForegroundColor Green
    }
} catch {
    Add-Failure "cannot parse Translations.ets"
}

# 6. Routing and ArkTS rules
Write-Host "`n[6/7] Routing / ArkTS Check" -ForegroundColor Yellow
$arktsViolations = 0
$dataSourceAssignments = 0
foreach ($f in $etsFiles) {
    $text = Read-Utf8Strict $f.FullName
    $lines = $text -split "\r?\n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match ':\s*any\b' -and $line -notmatch '//|interface|type\s') {
            Add-Failure "any: $(Get-RelativePath $f.FullName):$($i + 1)"
            $arktsViolations++
        }
        if ($line -match ':\s*unknown\b' -and $line -notmatch '//') {
            Add-Failure "unknown: $(Get-RelativePath $f.FullName):$($i + 1)"
            $arktsViolations++
        }
        if ($line -match 'isDarkMode\s*\?\s*''#') {
            Add-Failure "hardcoded dark-mode color: $(Get-RelativePath $f.FullName):$($i + 1)"
            $arktsViolations++
        }
        if ($line -match 'this\.[A-Za-z0-9_]*[Dd]ataSource\s*=\s*new\s+ArrayDataSource') {
            Add-Failure "LazyForEach dataSource reassignment: $(Get-RelativePath $f.FullName):$($i + 1)"
            $dataSourceAssignments++
        }
    }
    if ($text -match '@ComponentV2' -and $text -match '@StorageLink') {
        Add-Failure "V2 + StorageLink mixed: $(Get-RelativePath $f.FullName)"
        $arktsViolations++
    }
}
if ($arktsViolations -eq 0 -and $dataSourceAssignments -eq 0) {
    Write-Host "  OK: ArkTS rules and fixed dataSource rule" -ForegroundColor Green
}

$routerPath = Join-Path $resourcesRoot "base\profile\router_map.json"
try {
    $router = ConvertFrom-Json (Read-Utf8Strict $routerPath)
    $routerCount = 0
    foreach ($entry in $router.routerMap) {
        $routerCount++
        $pagePath = Join-Path $moduleRoot ($entry.pageSourceFile -replace '/', '\')
        if (-not (Test-Path $pagePath)) {
            Add-Failure "router page missing: $($entry.name) -> $($entry.pageSourceFile)"
        } else {
            $pageText = Read-Utf8Strict $pagePath
            if ($pageText -notmatch ("export function " + [regex]::Escape($entry.buildFunction) + "\s*\(")) {
                Add-Failure "router buildFunction missing: $($entry.name) -> $($entry.buildFunction)"
            }
        }
    }
    Write-Host "  OK: $routerCount router entries checked" -ForegroundColor Green
} catch {
    Add-Failure "cannot parse router_map.json"
}

# 7. Build
Write-Host "`n[7/7] Build" -ForegroundColor Yellow
$devEcoHome = $env:DEVECO_HOME
if ([string]::IsNullOrEmpty($devEcoHome)) {
    foreach ($candidate in @("D:\DevEco Studio", "F:\DevEco Studio")) {
        if (Test-Path (Join-Path $candidate "tools\hvigor\bin\hvigorw.bat")) {
            $devEcoHome = $candidate
            break
        }
    }
}
$hvigor = if ([string]::IsNullOrEmpty($devEcoHome)) { "" } else { Join-Path $devEcoHome "tools\hvigor\bin\hvigorw.bat" }
if ($hvigor -eq "" -or -not (Test-Path $hvigor)) {
    Add-Failure "hvigor not found; set DEVECO_HOME or install DevEco Studio"
} else {
    $env:DEVECO_SDK_HOME = Join-Path $devEcoHome "sdk"
    $env:HOS_SDK_HOME = Join-Path $devEcoHome "sdk\default\openharmony"
    $nodeBin = Join-Path $devEcoHome "tools\node"
    if (Test-Path $nodeBin) { $env:PATH = "$nodeBin;" + $env:PATH }

    Push-Location $ohosRoot
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $buildOutput = & $hvigor assembleHap --mode module -p module=entry -p product=default --no-daemon 2>&1
    $buildExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    Pop-Location

    $buildFailed = $buildExit -ne 0
    if (-not $buildFailed) {
        $errLines = @($buildOutput | Select-String "ArkTS:ERROR")
        if ($errLines.Count -gt 0) { $buildFailed = $true }
    }
    if ($buildFailed) {
        Add-Failure "hvigor build failed (exit=$buildExit)"
        $buildOutput | Select-String "ERROR|Error Message" | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    } else {
        Write-Host "  BUILD SUCCESSFUL" -ForegroundColor Green
    }
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) issue(s)" -ForegroundColor Red
    exit 1
}
Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
exit 0
