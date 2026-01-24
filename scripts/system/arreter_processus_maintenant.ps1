# ========================================
# Script d'arrêt immédiat des processus gourmands
# Libère la RAM MAINTENANT (sans redémarrage)
# Dell Inspiron 3593 (8 Go RAM)
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ARRET IMMEDIAT DES PROCESSUS" -ForegroundColor Cyan
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

# Afficher la RAM avant
Write-Host "[AVANT] Analyse de la memoire..." -ForegroundColor Yellow
$os = Get-WmiObject -Class Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeRAMBefore = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRAMBefore = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)

Write-Host "  RAM Totale : $totalRAM Go" -ForegroundColor White
Write-Host "  RAM Libre : $freeRAMBefore Go" -ForegroundColor Yellow
Write-Host "  RAM Utilisee : $usedRAMBefore Go" -ForegroundColor Red
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ARRET DES PROCESSUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalKilled = 0

# ========================================
# 1. ARRÊTER DELL SUPPORT ASSISTANT
# ========================================

Write-Host "[1/4] Arret de Dell Support Assistant..." -ForegroundColor Yellow

$dellProcesses = @(
    "SupportAssistAgent",
    "Dell.TechHub.Instrumentation.SubAgent",
    "Dell.TechHub.DataManager.SubAgent",
    "Dell.TechHub.Diagnostics.SubAgent",
    "Dell.TechHub.Analytics.SubAgent",
    "Dell.CoreServices.Client",
    "Dell.TechHub.Instrumentation.UserProcess",
    "Dell.TechHub",
    "SupportAssistHardwareDiags"
)

$dellKilled = 0

foreach ($process in $dellProcesses) {
    try {
        $procs = Get-Process -Name $process -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($proc in $procs) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "   - $process (PID: $($proc.Id)) arrete" -ForegroundColor Green
                $dellKilled++
                $totalKilled++
            }
        }
    } catch {
        # Silencieux
    }
}

if ($dellKilled -eq 0) {
    Write-Host "   - Aucun processus Dell actif" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $dellKilled processus Dell arretes" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 2. ARRÊTER MYSQL
# ========================================

Write-Host "[2/4] Arret de MySQL..." -ForegroundColor Yellow

$mysqlProcesses = @("mysqld", "mysqld-nt")
$mysqlKilled = 0

foreach ($process in $mysqlProcesses) {
    try {
        $procs = Get-Process -Name $process -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($proc in $procs) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "   - $process (PID: $($proc.Id)) arrete" -ForegroundColor Green
                $mysqlKilled++
                $totalKilled++
            }
        }
    } catch {
        # Silencieux
    }
}

# Arrêter le service aussi
try {
    $mysqlSvc = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
    if ($mysqlSvc) {
        Stop-Service -Name $mysqlSvc.Name -Force -ErrorAction SilentlyContinue
        Write-Host "   - Service MySQL arrete" -ForegroundColor Green
    }
} catch {
    # Silencieux
}

if ($mysqlKilled -eq 0) {
    Write-Host "   - Aucun processus MySQL actif" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $mysqlKilled processus MySQL arretes" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 3. ARRÊTER TOMCAT
# ========================================

Write-Host "[3/4] Arret de Tomcat..." -ForegroundColor Yellow

$tomcatProcesses = @("Tomcat7", "Tomcat8", "Tomcat9", "Tomcat10")
$tomcatKilled = 0

foreach ($process in $tomcatProcesses) {
    try {
        $procs = Get-Process -Name $process -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($proc in $procs) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "   - $process (PID: $($proc.Id)) arrete" -ForegroundColor Green
                $tomcatKilled++
                $totalKilled++
            }
        }
    } catch {
        # Silencieux
    }
}

if ($tomcatKilled -eq 0) {
    Write-Host "   - Aucun processus Tomcat actif" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $tomcatKilled processus Tomcat arretes" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 4. NETTOYER NODE.JS GOURMANDS
# ========================================

Write-Host "[4/4] Nettoyage des processus Node.js gourmands..." -ForegroundColor Yellow

$nodeKilled = 0

try {
    $nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { ($_.WS / 1MB) -gt 100 }

    if ($nodeProcs) {
        foreach ($proc in $nodeProcs) {
            $ramMB = [math]::Round($proc.WS / 1MB, 0)
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "   - node.exe (PID: $($proc.Id), $ramMB Mo) arrete" -ForegroundColor Green
            $nodeKilled++
            $totalKilled++
        }
    }
} catch {
    # Silencieux
}

if ($nodeKilled -eq 0) {
    Write-Host "   - Aucun processus Node.js gourmand" -ForegroundColor Gray
} else {
    Write-Host "   [OK] $nodeKilled processus Node.js arretes" -ForegroundColor Green
}

Write-Host ""

# ========================================
# NETTOYAGE SUPPLÉMENTAIRE
# ========================================

Write-Host "Nettoyage supplementaire..." -ForegroundColor Yellow

# Vider le cache DNS
ipconfig /flushdns | Out-Null
Write-Host "  - Cache DNS vide" -ForegroundColor Green

# Vider le presse-papier
echo $null | clip
Write-Host "  - Presse-papier vide" -ForegroundColor Green

Write-Host ""

# Attendre que les processus se terminent
Start-Sleep -Seconds 3

# ========================================
# AFFICHER LA RAM APRÈS
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESULTATS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$os = Get-WmiObject -Class Win32_OperatingSystem
$freeRAMAfter = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRAMAfter = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
$gainRAM = [math]::Round($freeRAMAfter - $freeRAMBefore, 1)

Write-Host "[APRES] Analyse de la memoire..." -ForegroundColor Yellow
Write-Host "  RAM Libre : $freeRAMAfter Go" -ForegroundColor Green
Write-Host "  RAM Utilisee : $usedRAMAfter Go" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($gainRAM -gt 0) {
    Write-Host "  RAM LIBEREE : +$gainRAM Go" -ForegroundColor Green
} else {
    Write-Host "  RAM LIBEREE : $gainRAM Go (aucun processus gourmand trouve)" -ForegroundColor Yellow
}

Write-Host "  Processus arretes : $totalKilled" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Recommandations
if ($freeRAMAfter -ge 4.5) {
    Write-Host "[OK] Vous avez maintenant $freeRAMAfter Go de RAM libre !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous pouvez maintenant :" -ForegroundColor White
    Write-Host "  1. Lancer Android Studio Hedgehog (2023.1.1)" -ForegroundColor White
    Write-Host "     Configuration : Heap 2 Go, sans emulateur" -ForegroundColor Gray
    Write-Host "  2. Ou continuer avec VS Code (plus leger)" -ForegroundColor White
} elseif ($freeRAMAfter -ge 3.5) {
    Write-Host "[~] Vous avez $freeRAMAfter Go de RAM libre" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Recommandation : Utilisez VS Code pour le dev Flutter" -ForegroundColor Yellow
    Write-Host "Android Studio restera limite avec cette RAM" -ForegroundColor Yellow
} else {
    Write-Host "[!] Vous avez seulement $freeRAMAfter Go de RAM libre" -ForegroundColor Red
    Write-Host ""
    Write-Host "Actions supplementaires recommandees :" -ForegroundColor Yellow
    Write-Host "  1. Fermez les fenetres VS Code inutilisees" -ForegroundColor White
    Write-Host "  2. Fermez Chrome/navigateurs" -ForegroundColor White
    Write-Host "  3. Executez 'optimiser_demarrage.ps1' puis redemarrez" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

pause
