# PowerShell script to update all AppBar widgets
# Adds backgroundColor: AppColors.primary and foregroundColor: Colors.white

$filesToUpdate = @(
    # Acheteur screens
    "lib/screens/acheteur/acheteur_profile_screen.dart",
    "lib/screens/acheteur/address_management_screen.dart",
    "lib/screens/acheteur/address_picker_screen.dart",
    "lib/screens/acheteur/business_pro_screen.dart",
    "lib/screens/acheteur/cart_screen.dart",
    "lib/screens/acheteur/delivery_tracking_screen.dart",
    "lib/screens/acheteur/my_reviews_screen.dart",
    "lib/screens/acheteur/nearby_vendors_screen.dart",
    "lib/screens/acheteur/product_search_screen.dart",
    "lib/screens/acheteur/request_refund_screen.dart"
)

foreach ($file in $filesToUpdate) {
    $fullPath = "c:/Users/ALLAH-PC/social_media_business_pro/$file"

    if (Test-Path $fullPath) {
        Write-Host "Processing: $file"

        $content = Get-Content $fullPath -Raw

        # Pattern 1: appBar: AppBar(\n        title:
        # Add properties after title line
        $pattern1 = '(appBar: AppBar\(\s*\n\s*title: const Text\([^\)]+\),)'
        $replacement1 = '$1' + "`n        backgroundColor: AppColors.primary," + "`n        foregroundColor: Colors.white,"

        $content = $content -replace $pattern1, $replacement1

        # Write back
        Set-Content -Path $fullPath -Value $content -NoNewline

        Write-Host "Updated: $file"
    } else {
        Write-Host "File not found: $file"
    }
}

Write-Host "`nDone!"
