# Update back button fallback routes by role
# Acheteur -> /acheteur
# Vendeur -> /vendeur-dashboard
# Livreur -> /livreur
# Admin -> /admin-dashboard

$stats = @{
    acheteur = 0
    vendeur = 0
    livreur = 0
    admin = 0
}

function Update-Files {
    param(
        [string]$folder,
        [string]$newRoute,
        [string]$role
    )

    $path = "c:\Users\ALLAH-PC\social_media_business_pro\lib\screens\$folder"

    if (!(Test-Path $path)) {
        Write-Host "Folder not found: $path" -ForegroundColor Yellow
        return
    }

    $files = Get-ChildItem -Path $path -Filter "*.dart" -File

    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        # Replace context.go('/') with role-specific route
        $originalContent = $content
        $content = $content -replace "context\.go\('/'\);", "context.go('$newRoute');"

        if ($content -ne $originalContent) {
            # Save with UTF8 BOM
            $utf8BOM = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8BOM)

            Write-Host "  $($file.Name)" -ForegroundColor Green
            $stats[$role]++
        }
    }
}

Write-Host "Updating back button routes..." -ForegroundColor Cyan
Write-Host ""

Write-Host "ACHETEUR files -> /acheteur" -ForegroundColor Magenta
Update-Files -folder "acheteur" -newRoute "/acheteur" -role "acheteur"

Write-Host ""
Write-Host "VENDEUR files -> /vendeur-dashboard" -ForegroundColor Magenta
Update-Files -folder "vendeur" -newRoute "/vendeur-dashboard" -role "vendeur"

Write-Host ""
Write-Host "LIVREUR files -> /livreur" -ForegroundColor Magenta
Update-Files -folder "livreur" -newRoute "/livreur" -role "livreur"

Write-Host ""
Write-Host "ADMIN files -> /admin-dashboard" -ForegroundColor Magenta
Update-Files -folder "admin" -newRoute "/admin-dashboard" -role "admin"

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Acheteur:  $($stats.acheteur) files" -ForegroundColor White
Write-Host "Vendeur:   $($stats.vendeur) files" -ForegroundColor White
Write-Host "Livreur:   $($stats.livreur) files" -ForegroundColor White
Write-Host "Admin:     $($stats.admin) files" -ForegroundColor White
$total = $stats.acheteur + $stats.vendeur + $stats.livreur + $stats.admin
Write-Host "TOTAL:     $total files modified" -ForegroundColor Green
