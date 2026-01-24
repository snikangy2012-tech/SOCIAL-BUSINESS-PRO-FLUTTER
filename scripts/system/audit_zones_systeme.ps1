# Script d'Audit des Zones Système - SOCIAL BUSINESS Pro
# Date: 13 Novembre 2025
# Détecte les écrans sans AppBar/SafeArea

Write-Host "🔍 Audit des Zones Système - SOCIAL BUSINESS Pro" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$screensPath = "lib\screens"
$totalFiles = 0
$issuesFound = 0
$results = @()

# Fonction pour vérifier un fichier
function Test-ScreenFile {
    param($filePath)

    $content = Get-Content $filePath -Raw
    $issues = @()
    $severity = "OK"

    # Vérifier si c'est un Scaffold
    if ($content -match "Scaffold\(") {

        # 1. Vérifier AppBar
        $hasAppBar = $content -match "appBar:\s*AppBar\("
        $hasNullAppBar = $content -match "appBar:\s*null"

        # 2. Vérifier SafeArea
        $hasSafeArea = $content -match "SafeArea\("

        # 3. Vérifier body: Stack (potentiellement problématique)
        $hasBodyStack = $content -match "body:\s*Stack\("

        # 4. Vérifier extendBodyBehindAppBar
        $extendsBody = $content -match "extendBodyBehindAppBar:\s*true"

        # 5. Vérifier GoogleMap (souvent plein écran)
        $hasGoogleMap = $content -match "GoogleMap\("

        # 6. Vérifier Positioned sans MediaQuery
        $hasPositionedTop = $content -match "Positioned\([^)]*top:\s*\d+"
        $usesMediaQuery = $content -match "MediaQuery\.of\(context\)\.padding"

        # Analyse des problèmes
        if (-not $hasAppBar -and -not $hasSafeArea) {
            $issues += "❌ CRITIQUE: Ni AppBar ni SafeArea"
            $severity = "CRITICAL"
        }
        elseif ($hasNullAppBar -and -not $hasSafeArea) {
            $issues += "⚠️  IMPORTANT: AppBar null sans SafeArea"
            if ($severity -ne "CRITICAL") { $severity = "HIGH" }
        }

        if ($hasBodyStack -and -not $hasSafeArea -and -not $hasAppBar) {
            $issues += "⚠️  body: Stack sans protection"
            if ($severity -eq "OK") { $severity = "MEDIUM" }
        }

        if ($extendsBody) {
            $issues += "⚠️  extendBodyBehindAppBar: true"
            if ($severity -eq "OK") { $severity = "MEDIUM" }
        }

        if ($hasGoogleMap) {
            $issues += "ℹ️  Contient GoogleMap (vérifier zones)"
            if ($severity -eq "OK") { $severity = "LOW" }
        }

        if ($hasPositionedTop -and -not $usesMediaQuery) {
            $issues += "⚠️  Positioned top sans MediaQuery"
            if ($severity -eq "OK") { $severity = "MEDIUM" }
        }
    }

    return @{
        Path = $filePath
        Severity = $severity
        Issues = $issues
        HasAppBar = $hasAppBar
        HasSafeArea = $hasSafeArea
    }
}

# Scanner tous les fichiers .dart dans lib/screens
Write-Host "📂 Scan du dossier: $screensPath" -ForegroundColor Yellow
Write-Host ""

Get-ChildItem -Path $screensPath -Recurse -Filter "*.dart" | ForEach-Object {
    $totalFiles++
    $result = Test-ScreenFile $_.FullName

    if ($result.Severity -ne "OK") {
        $issuesFound++
        $results += $result
    }
}

# Trier par sévérité
$sortOrder = @{
    "CRITICAL" = 1
    "HIGH" = 2
    "MEDIUM" = 3
    "LOW" = 4
    "OK" = 5
}

$results = $results | Sort-Object { $sortOrder[$_.Severity] }

# Afficher les résultats
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "📊 RÉSUMÉ" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Fichiers scannés: $totalFiles" -ForegroundColor White
Write-Host "Problèmes trouvés: $issuesFound" -ForegroundColor $(if ($issuesFound -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($issuesFound -eq 0) {
    Write-Host "✅ Tous les écrans respectent les zones système!" -ForegroundColor Green
} else {
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "🔍 DÉTAILS DES PROBLÈMES" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""

    $critical = ($results | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $high = ($results | Where-Object { $_.Severity -eq "HIGH" }).Count
    $medium = ($results | Where-Object { $_.Severity -eq "MEDIUM" }).Count
    $low = ($results | Where-Object { $_.Severity -eq "LOW" }).Count

    if ($critical -gt 0) {
        Write-Host "🔴 CRITIQUES: $critical" -ForegroundColor Red
    }
    if ($high -gt 0) {
        Write-Host "🟠 IMPORTANTES: $high" -ForegroundColor Yellow
    }
    if ($medium -gt 0) {
        Write-Host "🟡 MOYENNES: $medium" -ForegroundColor Yellow
    }
    if ($low -gt 0) {
        Write-Host "🔵 MINEURES: $low" -ForegroundColor Cyan
    }
    Write-Host ""

    foreach ($result in $results) {
        $relativePath = $result.Path -replace [regex]::Escape((Get-Location).Path + "\"), ""

        $severityColor = switch ($result.Severity) {
            "CRITICAL" { "Red" }
            "HIGH" { "Yellow" }
            "MEDIUM" { "Yellow" }
            "LOW" { "Cyan" }
            default { "White" }
        }

        $severityIcon = switch ($result.Severity) {
            "CRITICAL" { "🔴" }
            "HIGH" { "🟠" }
            "MEDIUM" { "🟡" }
            "LOW" { "🔵" }
            default { "ℹ️ " }
        }

        Write-Host "$severityIcon [$($result.Severity)]" -ForegroundColor $severityColor -NoNewline
        Write-Host " $relativePath" -ForegroundColor White

        foreach ($issue in $result.Issues) {
            Write-Host "    $issue" -ForegroundColor Gray
        }

        Write-Host "    État: AppBar=$($result.HasAppBar) | SafeArea=$($result.HasSafeArea)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

# Générer un rapport JSON
$reportPath = "audit_zones_systeme_report.json"
$report = @{
    Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $totalFiles
    IssuesFound = $issuesFound
    Results = $results | ForEach-Object {
        @{
            Path = $_.Path -replace [regex]::Escape((Get-Location).Path + "\"), ""
            Severity = $_.Severity
            Issues = $_.Issues
            HasAppBar = $_.HasAppBar
            HasSafeArea = $_.HasSafeArea
        }
    }
}

$report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "💾 Rapport JSON généré: $reportPath" -ForegroundColor Green
Write-Host ""

# Recommandations
if ($issuesFound -gt 0) {
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "💡 RECOMMANDATIONS" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Pour corriger les problèmes CRITIQUES:" -ForegroundColor Yellow
    Write-Host "1. Ajouter un AppBar (même invisible):" -ForegroundColor White
    Write-Host "   appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Ou entourer le body avec SafeArea:" -ForegroundColor White
    Write-Host "   body: SafeArea(child: ...)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Pour les Positioned, utiliser MediaQuery:" -ForegroundColor White
    Write-Host "   top: MediaQuery.of(context).padding.top + 16" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Consultez GUIDE_ZONES_SYSTEME.md pour plus de détails." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ Audit terminé!" -ForegroundColor Green
