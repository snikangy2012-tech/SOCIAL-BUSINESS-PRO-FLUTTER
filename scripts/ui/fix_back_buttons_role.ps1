# Fix back buttons with role-specific fallback routes
$projectRoot = "c:\Users\ALLAH-PC\social_media_business_pro\lib\screens"

$roleRoutes = @{
    "acheteur" = "/acheteur"
    "vendeur" = "/vendeur-dashboard"
    "livreur" = "/livreur"
    "admin" = "/admin-dashboard"
}

$totalModified = 0

foreach ($role in $roleRoutes.Keys) {
    $roleFolder = Join-Path $projectRoot $role
    $fallbackRoute = $roleRoutes[$role]

    if (Test-Path $roleFolder) {
        $files = Get-ChildItem -Path $roleFolder -Filter "*.dart" -File

        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -Encoding UTF8

            # Pattern to find and replace
            $oldPattern = "context\.go\('/'\);"
            $newPattern = "context.go('$fallbackRoute');"

            if ($content -match [regex]::Escape($oldPattern)) {
                $newContent = $content -replace [regex]::Escape($oldPattern), $newPattern

                # Save with UTF8 BOM
                $utf8BOM = New-Object System.Text.UTF8Encoding $true
                [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8BOM)

                Write-Host "Modified: $($file.Name) -> $fallbackRoute" -ForegroundColor Green
                $totalModified++
            }
        }
    }
}

Write-Host "`nTotal files modified: $totalModified" -ForegroundColor Cyan
