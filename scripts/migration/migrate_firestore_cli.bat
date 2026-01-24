@echo off
echo.
echo ========================================
echo  MIGRATION FIRESTORE - DATES STRING TO TIMESTAMP
echo ========================================
echo.

REM Vérifier si Firebase CLI est installé
firebase --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Firebase CLI n'est pas installe.
    echo.
    echo Installez-le avec : npm install -g firebase-tools
    echo Puis relancez ce script.
    pause
    exit /b 1
)

echo [OK] Firebase CLI detecte
echo.

REM Se connecter au projet
echo Connection au projet Firebase...
firebase use social-media-business-pro

echo.
echo ========================================
echo  EXECUTION DU SCRIPT DE MIGRATION
echo ========================================
echo.

REM Exécuter le script Firestore
firebase firestore:delete --all-collections --force users/*/createdAt
firebase firestore:delete --all-collections --force users/*/updatedAt
firebase firestore:delete --all-collections --force users/*/lastLoginAt

echo.
echo [INFO] Les dates ont ete supprimees.
echo [INFO] Elles seront regenerees au prochain login.
echo.
pause
