# Guide d'optimisation RAM - Dell Inspiron 3593 (8 Go)

## 📊 Configuration actuelle

- **Modèle** : Dell Inspiron 3593
- **Processeur** : Intel Core i5-1035G1 (4 cœurs, 8 threads) @ 1.00GHz
- **RAM** : 8 Go DDR4
- **Disque** : HDD 1 To (mécanique, pas SSD)
- **Utilisation RAM actuelle** : ~5.1 Go / 7.9 Go (64%)
- **RAM disponible** : ~3.2 Go

## 🎯 Problématique

Votre ordinateur utilise déjà **64% de la RAM** avant même de lancer Android Studio, qui nécessite à lui seul **2-4 Go** de RAM.

## 🔴 Processus identifiés qui consomment votre RAM

### 1. Dell Support Assistant (~500-800 Mo)
**Processus concernés :**
- `SupportAssistAgent.exe`
- `Dell.TechHub.Instrumentation.SubAgent.exe`
- `Dell.TechHub.DataManager.SubAgent.exe`
- `SupportAssistHardwareDiags.exe`
- `Dell.CoreServices.Client.exe`

**Action recommandée :** DÉSACTIVER (peu utile au quotidien)

### 2. Serveurs Tomcat (~300-600 Mo chacun)
**Processus concernés :**
- `Tomcat9.exe`
- `Tomcat7.exe`

**Action recommandée :** ARRÊTER si vous ne faites pas de développement Java/JSP

### 3. VS Code (300-500 Mo par instance)
**Processus concernés :**
- Multiples instances de `Code.exe`

**Action recommandée :** Fermer les fenêtres inutilisées

### 4. Node.js
**Processus concernés :**
- `node.exe`

**Action recommandée :** Arrêter les processus orphelins

### 5. Dart/Flutter Runtime
**Processus concernés :**
- `dartaotruntime.exe`

**Action recommandée :** Normal si vous développez en Flutter

## ⚡ Scripts créés pour vous

### 1. `analyser_ram.bat`
Analyse détaillée de votre consommation RAM actuelle.

**Utilisation :**
```bash
analyser_ram.bat
```

**Ce qu'il fait :**
- Affiche la RAM totale et disponible
- Liste les 15 processus les plus gourmands
- Identifie les processus de développement actifs
- Détecte les processus Dell inutiles
- Donne des recommandations personnalisées

### 2. `nettoyer_ram.bat`
Nettoie automatiquement les processus inutiles.

**Utilisation :**
```bash
# Exécuter en tant qu'administrateur (clic droit > Exécuter en tant qu'administrateur)
nettoyer_ram.bat
```

**Ce qu'il fait :**
- Arrête Dell Support Assistant
- Arrête les serveurs Tomcat
- Nettoie les processus Node.js gourmands
- Vide le cache DNS
- Nettoie les fichiers temporaires
- Affiche la RAM libérée

**Gain estimé : 800 Mo - 1.5 Go**

## 🚀 Actions manuelles recommandées

### Action 1 : Désactiver Dell Support au démarrage

**Étapes :**
1. `Ctrl + Shift + Esc` (Gestionnaire des tâches)
2. Onglet **"Démarrage"**
3. Trouver **"Dell SupportAssist Agent Launcher"**
4. Clic droit > **"Désactiver"**
5. Redémarrer le PC

**Gain : 500-800 Mo au démarrage**

### Action 2 : Désactiver les services Tomcat

Si vous ne faites pas de développement Java :

1. `Win + R` > Taper `services.msc`
2. Chercher **"Apache Tomcat 7"** et **"Apache Tomcat 9"**
3. Double-clic > Type de démarrage : **"Désactivé"**
4. Clic sur **"Arrêter"**
5. OK

**Gain : 300-600 Mo**

### Action 3 : Limiter les extensions Chrome

Chrome est très gourmand en RAM. Si vous l'utilisez pour le dev Flutter Web :

1. Extensions > Gérer les extensions
2. Désactiver les extensions non essentielles
3. Utiliser Chrome uniquement pour le dev, Edge pour la navigation

**Gain : 200-400 Mo**

## 💡 Solutions pour Android Studio

### Option 1 : Visual Studio Code (RECOMMANDÉ pour votre config)

**Avantages :**
- Beaucoup plus léger : **~500 Mo** vs 2-4 Go
- Parfait pour le développement Flutter
- Démarrage rapide même sur HDD
- Intégration Git excellente

**Installation :**
1. Télécharger VS Code : https://code.visualstudio.com/
2. Installer les extensions :
   - **Flutter** (Dart-Code)
   - **Dart**
3. Ouvrir votre projet Flutter
4. `Ctrl + Shift + P` > "Flutter: Select Device" > Chrome

**Commandes utiles :**
```bash
# Lancer l'app en mode web
flutter run -d chrome

# Lancer sur appareil USB
flutter run

# Hot reload : r dans le terminal
# Hot restart : R dans le terminal
```

### Option 2 : Android Studio allégé (si vraiment nécessaire)

**Version recommandée :** Android Studio Hedgehog (2023.1.1)

**Configuration à appliquer :**

1. **Limiter la mémoire heap :**
   - `Help > Edit Custom VM Options`
   - Modifier :
     ```
     -Xmx2048m  # Au lieu de 4096m
     -Xms512m
     ```

2. **Désactiver les plugins inutiles :**
   - `File > Settings > Plugins`
   - Désactiver :
     - Android NDK Support (si vous ne faites pas de C++)
     - Google Cloud Tools
     - Kotlin (si vous utilisez uniquement Dart/Flutter)
     - Designer (si vous ne faites pas d'UI Android native)

3. **Désactiver l'émulateur Android :**
   - Utiliser un appareil physique via USB
   - Ou utiliser Flutter Web (Chrome)

4. **Désactiver les indexations inutiles :**
   - `File > Settings > Build, Execution, Deployment`
   - Décocher "Automatically sync Gradle files"

**Gain : 1-2 Go de RAM économisée**

## 🔧 Optimisations Windows 10

### 1. Désactiver les effets visuels

1. `Win + R` > `sysdm.cpl`
2. Onglet **"Avancé"** > Performances > **"Paramètres"**
3. Choisir **"Ajuster afin d'obtenir les meilleures performances"**
4. Ou personnaliser (garder uniquement "Lisser les polices d'écran")

**Gain : 100-200 Mo**

### 2. Désactiver les applications en arrière-plan

1. `Paramètres Windows` > `Confidentialité`
2. **"Applications en arrière-plan"**
3. Désactiver les apps inutiles

**Gain : 50-150 Mo**

### 3. Désactiver l'indexation sur le HDD

1. `Ce PC` > Clic droit sur `C:` > `Propriétés`
2. Décocher **"Autoriser l'indexation du contenu des fichiers"**
3. Appliquer

**Gain : Amélioration des performances disque**

## 💾 Upgrade matériel (investissement recommandé)

Si vous voulez vraiment utiliser Android Studio confortablement :

### Priorité 1 : SSD 256 Go (~50-70€)
**Impact : ÉNORME**
- Vitesse de démarrage : 10x plus rapide
- Ouverture Android Studio : 30s au lieu de 3 minutes
- Build Flutter : 2x plus rapide
- Gradle sync : 3x plus rapide

**Modèles compatibles :**
- Crucial BX500 256 Go SATA
- Kingston A400 256 Go SATA
- WD Blue 250 Go SATA

### Priorité 2 : RAM 16 Go (~40-60€)
**Impact : Très important**
- Android Studio + Émulateur : Confortable
- Multitâche : Possible
- Build simultanés : OK

**Compatibilité Dell Inspiron 3593 :**
- 2 slots SO-DIMM DDR4
- Maximum supporté : 32 Go
- Recommandation : 1x 8 Go (total 16 Go) ou 2x 8 Go (remplacer les 8 Go actuels)

## 📋 Checklist d'optimisation

### Immédiat (maintenant)
- [ ] Exécuter `analyser_ram.bat` pour voir l'état actuel
- [ ] Exécuter `nettoyer_ram.bat` en tant qu'administrateur
- [ ] Fermer les applications inutilisées
- [ ] Redémarrer le PC

### Court terme (aujourd'hui)
- [ ] Désactiver Dell Support au démarrage
- [ ] Désactiver services Tomcat si non utilisés
- [ ] Installer VS Code avec extensions Flutter/Dart
- [ ] Tester le dev Flutter sur VS Code au lieu d'Android Studio

### Moyen terme (cette semaine)
- [ ] Appliquer les optimisations Windows 10
- [ ] Désactiver les effets visuels
- [ ] Désactiver l'indexation
- [ ] Nettoyer les fichiers temporaires (Nettoyage de disque)

### Long terme (si budget disponible)
- [ ] Acheter un SSD 256 Go (~50-70€)
- [ ] Acheter 8 Go RAM supplémentaire (~40-60€)
- [ ] Installer le SSD (faire migration système)
- [ ] Installer la RAM (simple, 2 clips à ouvrir)

## 🎯 Résumé : Quelle version d'Android Studio ?

### Pour votre config actuelle (8 Go RAM + HDD)

**Réponse courte :** **N'utilisez PAS Android Studio complet**

**Solution recommandée :**
1. **VS Code** pour l'éditeur de code
2. **Flutter Web** (Chrome) pour les tests
3. **Appareil physique USB** pour les tests mobile
4. **Android Studio Hedgehog** uniquement pour :
   - Gérer les SDK Android
   - Créer des profils d'émulateur (sans les lancer)
   - Éditer les fichiers natifs Android si nécessaire

### Si vous upgradez (SSD + 16 Go RAM)

**Vous pourrez utiliser :**
- **Android Studio Ladybug (2024.2.1)** - Dernière version stable
- Avec émulateur Android
- Multiples projets ouverts
- Gradle builds rapides

## 📞 Support

Si vous avez des questions ou problèmes :

1. **Exécuter d'abord** `analyser_ram.bat` et noter les résultats
2. **Vérifier** les services actifs
3. **Tester** VS Code avec Flutter avant d'investir dans un upgrade

---

**Créé pour :** SOCIAL BUSINESS Pro - Dell Inspiron 3593
**Date :** 2025-10-28
**Configuration :** Intel i5-1035G1, 8 Go RAM, HDD 1 To
