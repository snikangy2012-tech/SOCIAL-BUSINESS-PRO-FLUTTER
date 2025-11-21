@echo off
REM ========================================
REM Script d'analyse RAM detaillee
REM Dell Inspiron 3593 (8 Go RAM)
REM ========================================

echo.
echo ========================================
echo   ANALYSE DETAILLEE DE LA RAM
echo ========================================
echo.

REM Informations generales
echo [1] Informations systeme :
echo ----------------------------------------
systeminfo | findstr /C:"M\u00e9moire physique totale" /C:"M\u00e9moire physique disponible"
echo.

REM Calculer le pourcentage d'utilisation
echo [2] Processus les plus gourmands :
echo ----------------------------------------
echo.
echo Top 15 des processus par RAM :
powershell "Get-Process | Sort-Object WS -Descending | Select-Object -First 15 | Format-Table ProcessName,@{Label='RAM (Mo)';Expression={[int]($_.WS/1MB)}} -AutoSize"
echo.

REM Processus de developpement
echo [3] Processus de developpement actifs :
echo ----------------------------------------
echo.
echo VS Code :
tasklist | findstr /I "Code.exe" 2>nul || echo    Aucun processus VS Code
echo.
echo Android Studio :
tasklist | findstr /I "studio" 2>nul || echo    Aucun processus Android Studio
echo.
echo Java/Tomcat :
tasklist | findstr /I "java.exe Tomcat" 2>nul || echo    Aucun processus Java/Tomcat
echo.
echo Flutter/Dart :
tasklist | findstr /I "dart flutter" 2>nul || echo    Aucun processus Flutter/Dart
echo.
echo Chrome :
tasklist | findstr /I "chrome.exe" 2>nul || echo    Aucun processus Chrome
echo.

REM Processus Dell
echo [4] Processus Dell (potentiellement inutiles) :
echo ----------------------------------------
tasklist | findstr /I "Dell Support" 2>nul || echo    Aucun processus Dell actif
echo.

REM Services en arri\u00e8re-plan
echo [5] Services gourmands actifs :
echo ----------------------------------------
powershell "Get-Service | Where-Object {$_.Status -eq 'Running' -and ($_.Name -like '*Dell*' -or $_.Name -like '*Tomcat*')} | Select-Object Name,DisplayName,Status | Format-Table -AutoSize"
echo.

echo ========================================
echo   RECOMMANDATIONS PERSONNALISEES
echo ========================================
echo.

REM Compter les processus actifs
set /a PROCESSUS_CODE=0
set /a PROCESSUS_DELL=0
set /a PROCESSUS_JAVA=0

for /f %%a in ('tasklist ^| findstr /I "Code.exe" ^| find /c /v ""') do set PROCESSUS_CODE=%%a
for /f %%a in ('tasklist ^| findstr /I "Dell Support" ^| find /c /v ""') do set PROCESSUS_DELL=%%a
for /f %%a in ('tasklist ^| findstr /I "java.exe Tomcat" ^| find /c /v ""') do set PROCESSUS_JAVA=%%a

if %PROCESSUS_DELL% GTR 0 (
    echo [!] %PROCESSUS_DELL% processus Dell Support detectes
    echo     Gain potentiel : 500-800 Mo si arretes
    echo     Commande : nettoyer_ram.bat
    echo.
)

if %PROCESSUS_JAVA% GTR 0 (
    echo [!] %PROCESSUS_JAVA% processus Java/Tomcat detectes
    echo     Gain potentiel : 300-600 Mo si non utilises
    echo     Commande : nettoyer_ram.bat
    echo.
)

if %PROCESSUS_CODE% GTR 3 (
    echo [!] %PROCESSUS_CODE% processus VS Code detectes
    echo     Conseil : Fermer les fenetres VS Code inutilisees
    echo     Gain : ~300 Mo par fenetre
    echo.
)

echo ========================================
echo   POUR ANDROID STUDIO
echo ========================================
echo.
echo Votre configuration (8 Go RAM + HDD) :
echo.
echo Option 1 - VS Code (RECOMMANDE) :
echo   - Plus leger : ~500 Mo vs 2-4 Go
echo   - Parfait pour Flutter
echo   - Extensions : Flutter, Dart
echo.
echo Option 2 - Android Studio allege :
echo   - Version : Hedgehog (2023.1.1)
echo   - Heap limite : 2 Go max
echo   - Sans emulateur (appareil USB)
echo   - Plugins minimaux
echo.
echo ========================================

pause
