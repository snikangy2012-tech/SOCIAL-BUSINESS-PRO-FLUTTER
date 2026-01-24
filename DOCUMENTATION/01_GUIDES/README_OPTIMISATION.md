# Guide d'utilisation des scripts d'optimisation RAM

## 📦 Scripts créés pour vous

Vous disposez maintenant de **4 scripts d'optimisation** adaptés à votre Dell Inspiron 3593 (8 Go RAM).

---

## 🔧 1. `optimiser_demarrage.ps1`

### Description
Script PowerShell qui désactive **définitivement** les processus inutiles au démarrage de Windows.

### Ce qu'il fait
- ✅ Désactive Dell Support Assistant (8 processus)
- ✅ Désactive MySQL au démarrage
- ✅ Désactive Tomcat au démarrage
- ✅ Désactive les services Windows non essentiels
- ✅ Supprime les tâches planifiées Dell

### Gain estimé après redémarrage
**1.4 - 2.5 Go de RAM libre en plus**

### Comment l'utiliser

#### Méthode 1 : Clic droit (RECOMMANDÉ)
1. Ouvrir l'explorateur de fichiers
2. Aller dans `C:\Users\ALLAH-PC\social_media_business_pro\`
3. Trouver `optimiser_demarrage.ps1`
4. **Clic droit** → **"Exécuter avec PowerShell"**
5. Si demandé, cliquer **"Oui"** pour les privilèges admin
6. Suivre les instructions à l'écran
7. **Redémarrer le PC** quand demandé

#### Méthode 2 : Ligne de commande
```powershell
# Ouvrir PowerShell en administrateur (Win + X > Windows PowerShell (Admin))
cd C:\Users\ALLAH-PC\social_media_business_pro
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\optimiser_demarrage.ps1
```

### Résultat attendu
```
========================================
  RESUME DES OPTIMISATIONS
========================================

Total d'elements optimises : 12

Details :
  - Dell Support : 8 elements
  - MySQL : 1 service(s)
  - Tomcat : 0 service(s)
  - Services Windows : 3 service(s)

========================================
  GAIN ESTIME DE RAM
========================================

  Dell Support : 800-1200 Mo
  MySQL : 200-400 Mo
  Services Windows : 100-300 Mo

  GAIN TOTAL : 1100-1900 Mo (1.1-1.9 Go)
```

### ⚠️ Important
Ce script modifie le démarrage de Windows. **Les changements sont permanents** jusqu'à ce que vous les annuliez manuellement.

---

## ⚡ 2. `arreter_processus_maintenant.ps1`

### Description
Script PowerShell qui arrête **immédiatement** les processus gourmands **SANS redémarrage**.

### Ce qu'il fait
- ✅ Arrête tous les processus Dell Support Assistant actifs
- ✅ Arrête MySQL
- ✅ Arrête Tomcat
- ✅ Arrête les processus Node.js gourmands (>100 Mo)
- ✅ Vide le cache DNS
- ✅ Affiche la RAM libérée avant/après

### Gain immédiat
**0.8 - 1.5 Go de RAM libre immédiatement**

### Comment l'utiliser

#### Méthode 1 : Clic droit (RECOMMANDÉ)
1. Ouvrir l'explorateur de fichiers
2. Aller dans `C:\Users\ALLAH-PC\social_media_business_pro\`
3. Trouver `arreter_processus_maintenant.ps1`
4. **Clic droit** → **"Exécuter avec PowerShell"**
5. Si demandé, cliquer **"Oui"** pour les privilèges admin
6. Voir les résultats à l'écran

#### Méthode 2 : Ligne de commande
```powershell
# Ouvrir PowerShell en administrateur
cd C:\Users\ALLAH-PC\social_media_business_pro
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\arreter_processus_maintenant.ps1
```

### Résultat attendu
```
[AVANT] Analyse de la memoire...
  RAM Totale : 7.9 Go
  RAM Libre : 2.7 Go
  RAM Utilisee : 5.2 Go

========================================
  ARRET DES PROCESSUS
========================================

[1/4] Arret de Dell Support Assistant...
   - SupportAssistAgent (PID: 5028) arrete
   - Dell.TechHub.Instrumentation.SubAgent (PID: 4572) arrete
   [OK] 8 processus Dell arretes

[2/4] Arret de MySQL...
   - mysqld (PID: 4392) arrete
   [OK] 1 processus MySQL arretes

========================================
  RESULTATS
========================================

[APRES] Analyse de la memoire...
  RAM Libre : 4.1 Go

  RAM LIBEREE : +1.4 Go
  Processus arretes : 10
```

### ⚠️ Important
Les processus s'arrêtent temporairement. Ils **redémarreront au prochain démarrage de Windows** si vous n'exécutez pas `optimiser_demarrage.ps1`.

---

## 📊 3. `analyser_ram.bat`

### Description
Script batch qui analyse en détail votre consommation RAM.

### Ce qu'il fait
- ✅ Affiche la RAM totale et disponible
- ✅ Liste les 15 processus les plus gourmands
- ✅ Identifie les processus de développement (VS Code, Java, Tomcat, etc.)
- ✅ Détecte les processus Dell inutiles
- ✅ Donne des recommandations personnalisées

### Comment l'utiliser
Double-cliquer sur `analyser_ram.bat`

### Pas besoin de privilèges admin
Ce script fonctionne en mode utilisateur normal.

---

## 🧹 4. `nettoyer_ram.bat`

### Description
Script batch qui nettoie la RAM (version simplifiée de `arreter_processus_maintenant.ps1`).

### Ce qu'il fait
- ✅ Arrête Dell Support Assistant
- ✅ Arrête Tomcat 7 et 9
- ✅ Nettoie Node.js
- ✅ Vide le cache DNS
- ✅ Nettoie les fichiers temporaires
- ✅ Affiche la RAM libérée

### Comment l'utiliser
1. **Clic droit** sur `nettoyer_ram.bat`
2. **"Exécuter en tant qu'administrateur"**

---

## 🎯 Stratégie recommandée

### SCÉNARIO 1 : Optimisation complète (RECOMMANDÉ)

**Objectif** : Maximiser la RAM disponible en permanence

**Étapes** :
1. Exécuter `arreter_processus_maintenant.ps1` (gain immédiat)
2. Exécuter `optimiser_demarrage.ps1` (gain permanent)
3. Redémarrer le PC
4. Exécuter `analyser_ram.bat` pour vérifier

**Résultat attendu** : 4.5 - 6 Go de RAM libre

### SCÉNARIO 2 : Nettoyage rapide

**Objectif** : Libérer de la RAM maintenant sans redémarrage

**Étapes** :
1. Exécuter `arreter_processus_maintenant.ps1`
2. Fermer les fenêtres VS Code inutilisées

**Résultat attendu** : 3.5 - 4.5 Go de RAM libre (temporaire)

### SCÉNARIO 3 : Analyse uniquement

**Objectif** : Comprendre ce qui consomme la RAM

**Étapes** :
1. Exécuter `analyser_ram.bat`
2. Lire les recommandations

---

## ⚠️ Erreurs possibles et solutions

### Erreur : "Impossible d'exécuter les scripts car l'exécution de scripts est désactivée"

**Solution** :
```powershell
# Ouvrir PowerShell en administrateur
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Erreur : "Accès refusé"

**Solution** :
- Clic droit sur le script → **"Exécuter en tant qu'administrateur"**

### Erreur : "Le script n'a pas été signé numériquement"

**Solution** :
```powershell
# Dans PowerShell admin
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

## 📈 Comparaison des scripts

| Script | Type | Admin requis ? | Redémarrage ? | Gain immédiat | Gain permanent |
|--------|------|----------------|---------------|---------------|----------------|
| `analyser_ram.bat` | Analyse | ❌ Non | ❌ Non | Aucun | Aucun |
| `nettoyer_ram.bat` | Nettoyage | ✅ Oui | ❌ Non | 800 Mo - 1.5 Go | ❌ Non |
| `arreter_processus_maintenant.ps1` | Nettoyage | ✅ Oui | ❌ Non | 800 Mo - 1.5 Go | ❌ Non |
| `optimiser_demarrage.ps1` | Optimisation | ✅ Oui | ✅ Oui | Aucun | 1.4 - 2.5 Go |

---

## 🎯 Réponse finale : Android Studio ou VS Code ?

### APRÈS avoir exécuté `optimiser_demarrage.ps1` et redémarré

#### Si vous avez 5-6 Go de RAM libre
✅ **Installez Android Studio Hedgehog (2023.1.1)**
- Configuration : Heap 2 Go
- Sans émulateur (appareil USB ou Flutter Web)
- Plugins minimaux

#### Si vous avez 4-5 Go de RAM libre
⚠️ **Android Studio en mode TRÈS allégé possible**
- Mais **VS Code reste recommandé**

#### Si vous avez moins de 4 Go de RAM libre
❌ **Utilisez VS Code uniquement**
- Beaucoup plus léger
- Parfait pour Flutter
- Extensions : Flutter + Dart

---

## 🚀 Étapes suivantes

### Immédiatement (maintenant)
1. [ ] Exécuter `arreter_processus_maintenant.ps1` en admin
2. [ ] Vérifier la RAM libérée
3. [ ] Fermer les applications inutilisées (VS Code, Chrome)

### Court terme (aujourd'hui)
4. [ ] Exécuter `optimiser_demarrage.ps1` en admin
5. [ ] Redémarrer le PC
6. [ ] Exécuter `analyser_ram.bat` pour vérifier
7. [ ] Noter la RAM libre

### Décision finale
8. [ ] Si RAM libre ≥ 5 Go : Installer Android Studio Hedgehog
9. [ ] Si RAM libre < 5 Go : Utiliser VS Code + Flutter

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Exécuter** `analyser_ram.bat` et noter les résultats
2. **Vérifier** que vous exécutez les scripts PowerShell en tant qu'administrateur
3. **Redémarrer** le PC si les changements ne sont pas appliqués

---

## 🔄 Comment annuler les optimisations ?

Si vous voulez réactiver Dell Support ou MySQL :

### Via les Services
1. `Win + R` → `services.msc`
2. Chercher le service (ex: "Dell SupportAssist")
3. Double-clic → Type de démarrage : **"Automatique"**
4. Clic sur **"Démarrer"**

### Via le Gestionnaire des tâches
1. `Ctrl + Shift + Esc`
2. Onglet **"Démarrage"**
3. Clic droit sur l'application → **"Activer"**

---

**Créé pour :** SOCIAL BUSINESS Pro - Dell Inspiron 3593
**Date :** 2025-10-28
**Configuration :** Intel i5-1035G1, 8 Go RAM, HDD 1 To
