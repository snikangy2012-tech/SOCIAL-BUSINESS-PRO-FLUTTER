# ========================================
# Script d'optimisation du démarrage Windows
# Désactive les processus inutiles au démarrage
# Dell Inspiron 3593 (8 Go RAM)
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OPTIMISATION DU DEMARRAGE WINDOWS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier les privilèges administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERREUR] Ce script necessite les privileges administrateur !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Clic droit sur le script > Executer en tant qu'administrateur" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

Write-Host "[OK] Privileges administrateur detectes" -ForegroundColor Green
Write-Host ""

# ========================================
# 1. DÉSACTIVER DELL SUPPORT ASSISTANT
# ========================================

Write-Host "[1/4] Desactivation de Dell Support Assistant..." -ForegroundColor Yellow

$dellServices = @(
    "SupportAssistAgent",
    "Dell Hardware Support",
    "DellClientManagementService",
    "Dell Foundation Services"
)

$dellDisabled = 0

foreach ($service in $dellServices) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   - Service '$service' desactive" -ForegroundColor Green
            $dellDisabled++
        }
    } catch {
        Write-Host "   - Service '$service' introuvable (OK)" -ForegroundColor Gray
    }
}

# Désactiver les tâches planifiées Dell
Write-Host "   - Desactivation des taches planifiees Dell..." -ForegroundColor Yellow

$dellTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Dell*" -or $_.TaskName -like "*SupportAssist*" }

foreach ($task in $dellTasks) {
    try {
        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        Write-Host "     * Tache '$($task.TaskName)' desactivee" -ForegroundColor Green
        $dellDisabled++
    } catch {
        Write-Host "     * Erreur pour '$($task.TaskName)'" -ForegroundColor Red
    }
}

# Désactiver au démarrage via registre
$dellStartupApps = @(
    "Dell SupportAssistAgent",
    "DellTypeCStatus",
    "Dell Display Manager"
)

foreach ($app in $dellStartupApps) {
    try {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $app -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $app -ErrorAction SilentlyContinue
    } catch {
        # Silencieux si l'entrée n'existe pas
    }
}

Write-Host "   [OK] $dellDisabled elements Dell desactives" -ForegroundColor Green
Write-Host ""

# ========================================
# 2. DÉSACTIVER MYSQL (si non utilisé)
# ========================================

Write-Host "[2/4] Desactivation de MySQL..." -ForegroundColor Yellow

$mysqlServices = @("MySQL", "MySQL80", "MySQL57")
$mysqlDisabled = 0

foreach ($service in $mysqlServices) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
            Write-Host "   - Service '$service' mis en demarrage manuel" -ForegroundColor Green
            $mysqlDisabled++
        }
    } catch {
        Write-Host "   - Service '$service' introuvable (OK)" -ForegroundColor Gray
    }
}

if ($mysqlDisabled -eq 0) {
    Write-Host "   - Aucun service MySQL trouve" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $mysqlDisabled service(s) MySQL desactive(s)" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 3. DÉSACTIVER TOMCAT
# ========================================

Write-Host "[3/4] Desactivation de Tomcat..." -ForegroundColor Yellow

$tomcatServices = @("Tomcat7", "Tomcat8", "Tomcat9", "Tomcat10")
$tomcatDisabled = 0

foreach ($service in $tomcatServices) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
            Write-Host "   - Service '$service' mis en demarrage manuel" -ForegroundColor Green
            $tomcatDisabled++
        }
    } catch {
        Write-Host "   - Service '$service' introuvable (OK)" -ForegroundColor Gray
    }
}

if ($tomcatDisabled -eq 0) {
    Write-Host "   - Aucun service Tomcat trouve" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $tomcatDisabled service(s) Tomcat desactive(s)" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 4. OPTIMISER LES SERVICES WINDOWS
# ========================================

Write-Host "[4/4] Optimisation des services Windows..." -ForegroundColor Yellow

# Services Windows non essentiels pour le développement
$servicesOptionnels = @{
    "DiagTrack" = "Connected User Experiences and Telemetry (Telemetrie)"
    "dmwappushservice" = "WAP Push Message Routing Service"
    "RetailDemo" = "Retail Demo Service"
    "RemoteRegistry" = "Remote Registry"
    "RemoteAccess" = "Routing and Remote Access"
    "WSearch" = "Windows Search (Indexation - ralentit sur HDD)"
}

$optimized = 0

foreach ($service in $servicesOptionnels.Keys) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   - $($servicesOptionnels[$service]) desactive" -ForegroundColor Green
            $optimized++
        }
    } catch {
        # Silencieux si erreur
    }
}

Write-Host "   [OK] $optimized service(s) Windows optimise(s)" -ForegroundColor Green
Write-Host ""

# ========================================
# RÉSUMÉ DES OPTIMISATIONS
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUME DES OPTIMISATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalOptimized = $dellDisabled + $mysqlDisabled + $tomcatDisabled + $optimized

Write-Host "Total d'elements optimises : $totalOptimized" -ForegroundColor Green
Write-Host ""
Write-Host "Details :" -ForegroundColor White
Write-Host "  - Dell Support : $dellDisabled elements" -ForegroundColor White
Write-Host "  - MySQL : $mysqlDisabled service(s)" -ForegroundColor White
Write-Host "  - Tomcat : $tomcatDisabled service(s)" -ForegroundColor White
Write-Host "  - Services Windows : $optimized service(s)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GAIN ESTIME DE RAM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$gainMin = 0
$gainMax = 0

if ($dellDisabled -gt 0) {
    $gainMin += 800
    $gainMax += 1200
    Write-Host "  Dell Support : 800-1200 Mo" -ForegroundColor Yellow
}

if ($mysqlDisabled -gt 0) {
    $gainMin += 200
    $gainMax += 400
    Write-Host "  MySQL : 200-400 Mo" -ForegroundColor Yellow
}

if ($tomcatDisabled -gt 0) {
    $gainMin += 300
    $gainMax += 600
    Write-Host "  Tomcat : 300-600 Mo" -ForegroundColor Yellow
}

if ($optimized -gt 0) {
    $gainMin += 100
    $gainMax += 300
    Write-Host "  Services Windows : 100-300 Mo" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  GAIN TOTAL : $gainMin-$gainMax Mo ($([math]::Round($gainMin/1024,1))-$([math]::Round($gainMax/1024,1)) Go)" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PROCHAINES ETAPES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. REDEMARREZ votre PC pour appliquer les changements" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Apres le redemarrage, vous devriez avoir :" -ForegroundColor White
$ramActuelle = 2.7
$ramApres = [math]::Round($ramActuelle + ($gainMin + $gainMax) / 2 / 1024, 1)
Write-Host "   - RAM libre actuelle : $ramActuelle Go" -ForegroundColor White
Write-Host "   - RAM libre estimee : $ramApres Go" -ForegroundColor Green
Write-Host ""

Write-Host "3. Avec $ramApres Go de RAM libre :" -ForegroundColor White
if ($ramApres -ge 4.5) {
    Write-Host "   [OK] Vous pouvez installer Android Studio Hedgehog (2023.1.1)" -ForegroundColor Green
    Write-Host "        Configuration recommandee :" -ForegroundColor White
    Write-Host "        - Heap : 2 Go" -ForegroundColor White
    Write-Host "        - Sans emulateur (appareil USB ou Flutter Web)" -ForegroundColor White
} elseif ($ramApres -ge 3.5) {
    Write-Host "   [~] Vous pouvez installer Android Studio en mode TRES allege" -ForegroundColor Yellow
    Write-Host "       Mais VS Code reste recommande" -ForegroundColor Yellow
} else {
    Write-Host "   [!] Continuez avec VS Code (plus leger)" -ForegroundColor Red
    Write-Host "       Android Studio restera trop lourd" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Appuyez sur une touche pour redemarrer maintenant..." -ForegroundColor Yellow
Write-Host "(ou fermez cette fenetre pour redemarrer plus tard)" -ForegroundColor Gray
Write-Host ""

$reboot = Read-Host "Voulez-vous redemarrer maintenant ? (O/N)"

if ($reboot -eq "O" -or $reboot -eq "o" -or $reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host ""
    Write-Host "Redemarrage dans 10 secondes..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host ""
    Write-Host "N'oubliez pas de redemarrer pour appliquer les changements !" -ForegroundColor Yellow
    Write-Host ""
    pause
}
