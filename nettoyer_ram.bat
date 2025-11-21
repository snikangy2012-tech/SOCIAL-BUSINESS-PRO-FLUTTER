@echo off
REM ========================================
REM Script de nettoyage RAM - SOCIAL BUSINESS Pro
REM Optimisation pour Dell Inspiron 3593 (8 Go RAM)
REM ========================================

echo.
echo ========================================
echo   NETTOYAGE RAM - Analyse initiale
echo ========================================
echo.

REM Afficher la RAM avant nettoyage
echo [AVANT] Analyse de la memoire...
for /f "tokens=4" %%a in ('systeminfo ^| findstr "M\u00e9moire physique disponible"') do set RAM_AVANT=%%a
echo RAM disponible AVANT : %RAM_AVANT%
echo.

echo ========================================
echo   Arret des processus gourmands
echo ========================================
echo.

REM Arr\u00eater Dell Support Assistant (libere ~500-800 Mo)
echo [1/5] Arret de Dell Support Assistant...
taskkill /F /IM "SupportAssistAgent.exe" 2>nul
taskkill /F /IM "Dell.TechHub.Instrumentation.SubAgent.exe" 2>nul
taskkill /F /IM "Dell.TechHub.DataManager.SubAgent.exe" 2>nul
taskkill /F /IM "SupportAssistHardwareDiags.exe" 2>nul
taskkill /F /IM "Dell.CoreServices.Client.exe" 2>nul
echo    - Support Assistant arrete
timeout /t 2 >nul

REM Arr\u00eater Tomcat si non utilis\u00e9 (libere ~300-600 Mo)
echo [2/5] Arret des serveurs Tomcat...
taskkill /F /IM "Tomcat9.exe" 2>nul
taskkill /F /IM "Tomcat7.exe" 2>nul
net stop Tomcat9 2>nul
net stop Tomcat7 2>nul
echo    - Tomcat arrete
timeout /t 2 >nul

REM Nettoyer les processus Node.js orphelins
echo [3/5] Nettoyage des processus Node.js...
taskkill /F /IM "node.exe" /FI "MEMUSAGE gt 100000" 2>nul
echo    - Node.js nettoye
timeout /t 1 >nul

REM Vider le cache DNS
echo [4/5] Vidage du cache DNS...
ipconfig /flushdns >nul 2>&1
echo    - Cache DNS vide
timeout /t 1 >nul

REM Vider les fichiers temporaires systeme
echo [5/5] Nettoyage des fichiers temporaires...
del /q /f /s %TEMP%\* 2>nul
echo    - Fichiers temporaires nettoyes
timeout /t 1 >nul

echo.
echo ========================================
echo   Nettoyage termine !
echo ========================================
echo.

REM Afficher la RAM apr\u00e8s nettoyage
echo [APRES] Analyse de la memoire...
timeout /t 3 >nul
for /f "tokens=4" %%a in ('systeminfo ^| findstr "M\u00e9moire physique disponible"') do set RAM_APRES=%%a
echo RAM disponible APRES : %RAM_APRES%
echo.

echo ========================================
echo   RECOMMANDATIONS
echo ========================================
echo.
echo 1. Redemarrer le PC pour un nettoyage optimal
echo 2. Desactiver Dell Support au demarrage :
echo    - Gestionnaire des taches ^> Demarrage
echo    - Desactiver "Dell SupportAssist"
echo.
echo 3. Pour dev Flutter, privilegier :
echo    - VS Code (plus leger qu'Android Studio)
echo    - Flutter web (chrome)
echo    - Appareil physique USB (pas d'emulateur)
echo.
echo ========================================

pause
