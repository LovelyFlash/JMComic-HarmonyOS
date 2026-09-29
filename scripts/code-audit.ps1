# PicaComic HarmonyOS - Code Quality Audit
# Usage: .\scripts\code-audit.ps1

$etsRoot = "F:\Programming\Code\VS_Code\ArkTS\PicaComic-HarmonyOS\ohos\entry\src\main\ets"
$files = Get-ChildItem $etsRoot -Recurse -Filter *.ets

Write-Host "=== Code Quality Audit ===" -ForegroundColor Cyan
Write-Host "Files: $($files.Count)`n"

$stats = @{
    emojiIcons = 0
    hardcodedColors = 0
    nestedTernary = 0
    anyUsage = 0
    componentV2Storage = 0
    forEachCount = 0
    lazyForEachCount = 0
    themeManagerUsage = 0
    svgIcons = 0
    encodingErrors = 0
}

foreach ($f in $files) {
    $c = Get-Content $f.FullName -Raw
    $lines = Get-Content $f.FullName

    # Emoji icons (check for common emoji ranges)
    if ($c -match '[\uD83C-\uDBFF][\uDC00-\uDFFF]') { $stats.emojiIcons++ }

    # Encoding errors
    if ($c -match '\uFFFD') { $stats.encodingErrors++ }

    # Hardcoded dark mode ternary
    foreach ($line in $lines) {
        if ($line -match "isDarkMode \? '#") { $stats.hardcodedColors++ }
        if ($line -match 'isDarkMode \? .+ : this\.isDarkMode') { $stats.nestedTernary++ }
        if ($line -match ':\s*any\b' -and $line -notmatch '//') { $stats.anyUsage++ }
    }

    # V2 + StorageLink conflict
    if ($c -match '@ComponentV2' -and $c -match '@StorageLink') { $stats.componentV2Storage++ }

    # ForEach vs LazyForEach
    $stats.forEachCount += ([regex]::Matches($c, '\bForEach\(')).Count
    $stats.lazyForEachCount += ([regex]::Matches($c, '\bLazyForEach\(')).Count

    # ThemeManager usage
    $stats.themeManagerUsage += ([regex]::Matches($c, 'ThemeManager\.')).Count

    # SVG icons
    $stats.svgIcons += ([regex]::Matches($c, "rawfile\('icons/")).Count
}

Write-Host "Performance:"
Write-Host "  ForEach: $($stats.forEachCount) | LazyForEach: $($stats.lazyForEachCount)"
Write-Host "`nDesign:"
Write-Host "  ThemeManager usages: $($stats.themeManagerUsage)"
Write-Host "  SVG icon refs: $($stats.svgIcons)"
Write-Host "  Hardcoded colors: $($stats.hardcodedColors)"
Write-Host "  Nested ternary: $($stats.nestedTernary)"
Write-Host "  Emoji icons: $($stats.emojiIcons)"
Write-Host "`nArkTS Compliance:"
Write-Host "  any/unknown: $($stats.anyUsage)"
Write-Host "  V2+StorageLink: $($stats.componentV2Storage)"
Write-Host "  Encoding errors: $($stats.encodingErrors)"

$issues = $stats.hardcodedColors + $stats.nestedTernary + $stats.anyUsage + $stats.componentV2Storage + $stats.encodingErrors + $stats.emojiIcons
Write-Host "`n=== Total Issues: $issues ===" -ForegroundColor $(if ($issues -eq 0) { 'Green' } else { 'Yellow' })
