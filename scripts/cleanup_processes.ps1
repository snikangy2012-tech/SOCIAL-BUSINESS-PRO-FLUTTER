# Script PowerShell pour nettoyer tous les processus Flutter/Java/Gradle
Write-Host "🧹 Nettoyage des processus en cours..." -ForegroundColor Yellow

# Arrêter tous les processus Java
Write-Host "`n🔴 Arrêt des processus Java..." -ForegroundColor Cyan
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Processus Java arrêtés" -ForegroundColor Green

# Arrêter tous les processus Dart
Write-Host "`n🔴 Arrêt des processus Dart..." -ForegroundColor Cyan
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Processus Dart arrêtés" -ForegroundColor Green

# Arrêter tous les processus Flutter
Write-Host "`n🔴 Arrêt des processus Flutter..." -ForegroundColor Cyan
Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Processus Flutter arrêtés" -ForegroundColor Green

# Arrêter tous les processus Gradle
Write-Host "`n🔴 Arrêt des processus Gradle..." -ForegroundColor Cyan
Get-Process -Name "gradle*" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✅ Processus Gradle arrêtés" -ForegroundColor Green

Write-Host "`n🎉 Nettoyage terminé ! RAM libérée.`n" -ForegroundColor Green
