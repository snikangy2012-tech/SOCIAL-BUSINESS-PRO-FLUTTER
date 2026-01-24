# ===== add_back_buttons.ps1 =====
# Script pour ajouter automatiquement des boutons retour sur tous les ecrans
# qui ont un AppBar mais pas de bouton retour explicite

Write-Host "AJOUT AUTOMATIQUE DES BOUTONS RETOUR" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Liste des ecrans racines qui NE doivent PAS avoir de bouton retour
$rootScreens = @(
    "acheteur_home.dart",
    "vendeur_dashboard.dart",
    "livreur_dashboard.dart",
    "admin_home.dart",
    "main_scaffold.dart",
    "change_initial_password_screen.dart"
)

# Compteurs
$totalProcessed = 0
$totalModified = 0
$skippedRootScreens = 0
$alreadyHasBackButton = 0
$errors = 0

# Fonction pour verifier si un fichier a deja un bouton retour
function Has-BackButton {
    param ([string]$Content)

    # Verifier si le fichier a deja un leading avec arrow_back
    if ($Content -match 'leading:\s*IconButton\s*\([^)]*Icons\.arrow_back') {
        return $true
    }

    return $false
}

# Fonction pour verifier si le fichier a un AppBar
function Has-AppBar {
    param ([string]$Content)

    return $Content -match 'appBar:\s*AppBar\s*\('
}

# Fonction pour ajouter le bouton retour
function Add-BackButton {
    param (
        [string]$FilePath,
        [string]$Content
    )

    # Pattern pour trouver AppBar sans leading
    $pattern = '(appBar:\s*AppBar\s*\(\s*(?:\/\/[^\n]*\n\s*)*)(title:)'

    # Replacement avec bouton retour
    $replacement = '$1leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
    ),
    $2'

    # Appliquer le remplacement
    $newContent = $Content -replace $pattern, $replacement

    # Verifier si le contenu a change
    if ($newContent -ne $Content) {
        # Verifier si l'import go_router existe
        if ($newContent -notmatch "import 'package:go_router/go_router.dart';") {
            # Ajouter l'import apres les autres imports Flutter
            $newContent = $newContent -replace "(import 'package:flutter/material.dart';)", "`$1`nimport 'package:go_router/go_router.dart';"
        }

        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8
        return $true
    }

    return $false
}

# Analyser tous les fichiers dans lib/screens
Write-Host "Recherche des fichiers a modifier..." -ForegroundColor Yellow
Write-Host ""

$screenFiles = Get-ChildItem -Path "lib\screens" -Filter "*.dart" -Recurse

foreach ($file in $screenFiles) {
    $totalProcessed++
    $fileName = $file.Name

    # Afficher progression
    $percent = [math]::Round(($totalProcessed / $screenFiles.Count) * 100)
    Write-Progress -Activity "Traitement des ecrans" -Status "$totalProcessed/$($screenFiles.Count)" -PercentComplete $percent

    # Verifier si c'est un ecran racine
    if ($rootScreens -contains $fileName) {
        Write-Host "  [SKIP] $fileName - Ecran racine (pas de bouton retour necessaire)" -ForegroundColor Gray
        $skippedRootScreens++
        continue
    }

    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # Verifier si le fichier a un AppBar
        if (-not (Has-AppBar $content)) {
            continue
        }

        # Verifier si le fichier a deja un bouton retour
        if (Has-BackButton $content) {
            Write-Host "  [OK] $fileName - A deja un bouton retour" -ForegroundColor Green
            $alreadyHasBackButton++
            continue
        }

        # Ajouter le bouton retour
        $modified = Add-BackButton -FilePath $file.FullName -Content $content

        if ($modified) {
            Write-Host "  [ADD] $fileName - Bouton retour ajoute!" -ForegroundColor Cyan
            $totalModified++
        }
    }
    catch {
        Write-Host "  [ERROR] $fileName - Erreur: $_" -ForegroundColor Red
        $errors++
    }
}

Write-Progress -Activity "Traitement des ecrans" -Completed

# Afficher le rapport final
Write-Host ""
Write-Host "RAPPORT FINAL" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers traites:                    $totalProcessed"
Write-Host "Fichiers modifies (bouton ajoute):   $totalModified" -ForegroundColor Cyan
Write-Host "Deja avec bouton retour:             $alreadyHasBackButton" -ForegroundColor Green
Write-Host "Ecrans racines ignores:              $skippedRootScreens" -ForegroundColor Gray
Write-Host "Erreurs:                             $errors" -ForegroundColor Red
Write-Host ""

if ($totalModified -gt 0) {
    Write-Host "RECOMMANDATION:" -ForegroundColor Yellow
    Write-Host "  1. Executez 'flutter analyze' pour verifier qu'il n'y a pas d'erreurs"
    Write-Host "  2. Testez l'application pour verifier que les boutons retour fonctionnent"
    Write-Host "  3. Ajustez manuellement les ecrans qui necessitent une logique speciale"
    Write-Host ""
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Traitement termine!" -ForegroundColor Cyan
