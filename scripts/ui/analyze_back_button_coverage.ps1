# ===== analyze_back_button_coverage.ps1 =====
# Script d'analyse de la couverture du bouton retour systeme Android
# Identifie tous les ecrans et leur statut de gestion du bouton retour

Write-Host "ANALYSE DE LA COUVERTURE DU BOUTON RETOUR SYSTEME" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Compteurs
$totalFiles = 0
$filesWithSystemUIScaffold = 0
$filesWithSystemUIPopScaffold = 0
$filesWithScaffold = 0
$filesWithPopScope = 0
$filesOther = 0

# Listes pour le rapport detaille
$protectedFiles = @()
$unprotectedFiles = @()

# Fonction pour analyser un fichier
function Analyze-ScreenFile {
    param (
        [string]$FilePath
    )

    $content = Get-Content $FilePath -Raw
    $relativePath = $FilePath.Replace((Get-Location).Path + "\", "")

    # Verifier le type de protection
    $hasSystemUIScaffold = $content -match 'SystemUIScaffold\('
    $hasSystemUIPopScaffold = $content -match 'SystemUIPopScaffold\('
    $hasPopScope = $content -match 'PopScope\('
    $hasScaffold = $content -match 'return\s+Scaffold\('

    $status = @{
        Path = $relativePath
        Protected = $false
        Type = "None"
    }

    if ($hasSystemUIScaffold) {
        $status.Protected = $true
        $status.Type = "SystemUIScaffold (Protege automatiquement)"
        $script:filesWithSystemUIScaffold++
        $script:protectedFiles += $status
    }
    elseif ($hasSystemUIPopScaffold) {
        $status.Protected = $true
        $status.Type = "SystemUIPopScaffold (Protege avec PopScope)"
        $script:filesWithSystemUIPopScaffold++
        $script:protectedFiles += $status
    }
    elseif ($hasPopScope) {
        $status.Protected = $true
        $status.Type = "PopScope (Protection manuelle)"
        $script:filesWithPopScope++
        $script:protectedFiles += $status
    }
    elseif ($hasScaffold) {
        $status.Protected = $false
        $status.Type = "Scaffold (NON PROTEGE)"
        $script:filesWithScaffold++
        $script:unprotectedFiles += $status
    }
    else {
        $status.Protected = $false
        $status.Type = "Autre (A verifier)"
        $script:filesOther++
        $script:unprotectedFiles += $status
    }

    return $status
}

# Analyser tous les fichiers dans lib/screens
Write-Host "Analyse des fichiers dans lib/screens..." -ForegroundColor Yellow
Write-Host ""

$screenFiles = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse

foreach ($file in $screenFiles) {
    $totalFiles++
    $status = Analyze-ScreenFile $file.FullName

    # Afficher une barre de progression
    $percent = [math]::Round(($totalFiles / $screenFiles.Count) * 100)
    Write-Progress -Activity "Analyse des ecrans" -Status "$totalFiles/$($screenFiles.Count)" -PercentComplete $percent
}

Write-Progress -Activity "Analyse des ecrans" -Completed

# Afficher le rapport
Write-Host ""
Write-Host "RAPPORT D'ANALYSE" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "STATISTIQUES GLOBALES:" -ForegroundColor White
Write-Host "  Total de fichiers analyses:          $totalFiles"
Write-Host "  Fichiers PROTEGES:                   $($protectedFiles.Count) ($([math]::Round(($protectedFiles.Count / $totalFiles) * 100))%)" -ForegroundColor Green
Write-Host "  Fichiers NON PROTEGES:               $($unprotectedFiles.Count) ($([math]::Round(($unprotectedFiles.Count / $totalFiles) * 100))%)" -ForegroundColor Red
Write-Host ""

Write-Host "DETAIL PAR TYPE:" -ForegroundColor White
Write-Host "  SystemUIScaffold:                    $filesWithSystemUIScaffold" -ForegroundColor Green
Write-Host "  SystemUIPopScaffold:                 $filesWithSystemUIPopScaffold" -ForegroundColor Green
Write-Host "  PopScope manuel:                     $filesWithPopScope" -ForegroundColor Yellow
Write-Host "  Scaffold non protege:                $filesWithScaffold" -ForegroundColor Red
Write-Host "  Autre (a verifier):                  $filesOther" -ForegroundColor Gray
Write-Host ""

# Afficher les fichiers non proteges
if ($unprotectedFiles.Count -gt 0) {
    Write-Host "FICHIERS NON PROTEGES (ACTION REQUISE):" -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    foreach ($file in $unprotectedFiles) {
        Write-Host "  - $($file.Path)" -ForegroundColor Red
        Write-Host "    Type: $($file.Type)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Afficher les fichiers proteges (top 10)
if ($protectedFiles.Count -gt 0) {
    Write-Host "FICHIERS PROTEGES (echantillon):" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    $sample = $protectedFiles | Select-Object -First 10
    foreach ($file in $sample) {
        Write-Host "  - $($file.Path)" -ForegroundColor Green
        Write-Host "    Type: $($file.Type)" -ForegroundColor Gray
    }
    if ($protectedFiles.Count -gt 10) {
        Write-Host "  ... et $($protectedFiles.Count - 10) autres fichiers proteges" -ForegroundColor Gray
    }
    Write-Host ""
}

# Generer un fichier de rapport JSON
$report = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $totalFiles
    ProtectedFiles = $protectedFiles.Count
    UnprotectedFiles = $unprotectedFiles.Count
    Statistics = @{
        SystemUIScaffold = $filesWithSystemUIScaffold
        SystemUIPopScaffold = $filesWithSystemUIPopScaffold
        PopScope = $filesWithPopScope
        UnprotectedScaffold = $filesWithScaffold
        Other = $filesOther
    }
    UnprotectedList = $unprotectedFiles
    ProtectedList = $protectedFiles
}

$report | ConvertTo-Json -Depth 10 | Out-File "back_button_coverage_report.json"

Write-Host "Rapport detaille sauvegarde: back_button_coverage_report.json" -ForegroundColor Cyan
Write-Host ""

# Recommandations
Write-Host "RECOMMANDATIONS:" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

if ($unprotectedFiles.Count -eq 0) {
    Write-Host "  Parfait! Tous les ecrans sont proteges!" -ForegroundColor Green
}
else {
    Write-Host "  1. Remplacez 'Scaffold' par 'SystemUIScaffold' dans les fichiers non proteges" -ForegroundColor Yellow
    Write-Host "  2. Pour les ecrans racines, utilisez 'SystemUIPopScaffold' si necessaire" -ForegroundColor Yellow
    Write-Host "  3. Testez le bouton retour Android sur chaque ecran modifie" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Exemple de remplacement:" -ForegroundColor Cyan
    Write-Host "     return Scaffold(                    // AVANT" -ForegroundColor Red
    Write-Host "     return SystemUIScaffold(            // APRES" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Analyse terminee!" -ForegroundColor Cyan
