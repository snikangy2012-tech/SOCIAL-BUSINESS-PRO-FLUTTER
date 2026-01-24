# Script pour corriger les boutons retour avec redirection selon le rôle
# Date: 2026-01-03

$projectRoot = "c:\Users\ALLAH-PC\social_media_business_pro"
$screensPath = Join-Path $projectRoot "lib\screens"

# Mapping des dossiers vers les routes de fallback
$routeMapping = @{
    "acheteur" = "/acheteur"
    "vendeur" = "/vendeur-dashboard"
    "livreur" = "/livreur"
    "admin" = "/admin-dashboard"
    "auth" = "/login"
    "shared" = "/"
    "subscription" = "/"
    "payment" = "/"
    "kyc" = "/"
}

# Pattern à rechercher (ancien code)
$oldPattern = @'
onPressed: \(\) \{
\s+if \(Navigator\.of\(context\)\.canPop\(\)\) \{
\s+Navigator\.of\(context\)\.pop\(\);
\s+\} else \{
\s+context\.go\('/'\);
\s+\}
\s+\}
'@

function Get-RoleFromPath {
    param($filePath)

    foreach ($role in $routeMapping.Keys) {
        if ($filePath -like "*\screens\$role\*") {
            return $role
        }
    }

    # Si le fichier est directement dans screens/ (pas dans un sous-dossier)
    if ($filePath -like "*\screens\*.dart" -and $filePath -notlike "*\screens\*\*") {
        return "shared"
    }

    return $null
}

function Update-BackButton {
    param(
        [string]$filePath,
        [string]$role
    )

    $fallbackRoute = $routeMapping[$role]

    # Nouveau pattern avec la route spécifique au rôle
    $newPattern = @"
onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('$fallbackRoute');
            }
          }
"@

    $content = Get-Content $filePath -Raw -Encoding UTF8

    # Utiliser une regex pour trouver et remplacer
    $pattern = 'onPressed:\s*\(\)\s*\{\s+if\s*\(Navigator\.of\(context\)\.canPop\(\)\)\s*\{\s+Navigator\.of\(context\)\.pop\(\);\s+\}\s+else\s*\{\s+context\.go\([''"]\/[''"]\);\s+\}\s+\}'

    if ($content -match $pattern) {
        $updatedContent = $content -replace $pattern, $newPattern

        # Sauvegarder avec UTF8 BOM (comme les fichiers Dart Flutter)
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($filePath, $updatedContent, $utf8BOM)

        return $true
    }

    return $false
}

# Statistiques
$stats = @{
    "acheteur" = 0
    "vendeur" = 0
    "livreur" = 0
    "admin" = 0
    "auth" = 0
    "shared" = 0
    "subscription" = 0
    "payment" = 0
    "kyc" = 0
}

$totalFiles = 0
$modifiedFiles = 0

Write-Host "🔍 Recherche des fichiers Dart dans lib/screens..." -ForegroundColor Cyan

# Parcourir tous les fichiers .dart dans lib/screens
Get-ChildItem -Path $screensPath -Filter "*.dart" -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $totalFiles++

    # Déterminer le rôle
    $role = Get-RoleFromPath -filePath $filePath

    if ($role) {
        Write-Host "📄 Traitement: $($_.Name) (rôle: $role)" -ForegroundColor Gray

        $wasModified = Update-BackButton -filePath $filePath -role $role

        if ($wasModified) {
            $modifiedFiles++
            $stats[$role]++
            Write-Host "   ✅ Modifié avec fallback: $($routeMapping[$role])" -ForegroundColor Green
        }
    }
}

# Afficher les statistiques
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 STATISTIQUES DE MODIFICATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Total fichiers analysés: $totalFiles" -ForegroundColor White
Write-Host "Total fichiers modifiés: $modifiedFiles" -ForegroundColor Green
Write-Host ""

Write-Host "Répartition par rôle:" -ForegroundColor Yellow
foreach ($role in $stats.Keys | Sort-Object) {
    if ($stats[$role] -gt 0) {
        $route = $routeMapping[$role]
        Write-Host "  $role : $($stats[$role]) fichiers → fallback: $route" -ForegroundColor Magenta
    }
}

Write-Host "`n✅ Script terminé avec succès!" -ForegroundColor Green
