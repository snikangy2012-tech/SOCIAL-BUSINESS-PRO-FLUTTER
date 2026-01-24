# 🚀 Démarrage rapide - VS Code + Flutter

## ✅ Configuration terminée !

Votre environnement de développement Flutter est **100% opérationnel** dans VS Code.

---

## 🎯 Pour lancer votre app MAINTENANT

### Option 1 : Méthode la plus simple

1. Ouvrir VS Code dans ce dossier
2. Appuyer sur `F5`
3. Choisir **"Flutter Web (Chrome) - RECOMMANDÉ"**
4. Attendre 30-60 secondes
5. ✅ Votre app s'ouvre dans Chrome !

### Option 2 : Via le terminal

```bash
flutter run -d chrome --web-renderer html
```

---

## 🔥 Hot Reload : La magie de Flutter

1. L'app est lancée dans Chrome
2. Modifiez un fichier Dart (ex: changez une couleur)
3. Sauvegardez (`Ctrl + S`)
4. 💥 **L'app se met à jour instantanément** (1-2 secondes)

Aucun redémarrage, aucune recompilation complète !

---

## ⌨️ Raccourcis essentiels

| Touche | Action |
|--------|--------|
| `F5` | Lancer l'app |
| `Ctrl + S` | Sauvegarder + Hot Reload |
| `Shift + F5` | Arrêter l'app |
| `Ctrl + C` (terminal) | Arrêter l'app |

---

## 📱 Appareils disponibles

Vous pouvez développer sur :

✅ **Chrome (web)** - RECOMMANDÉ
- Le plus léger pour votre RAM
- Hot Reload ultra-rapide
- Parfait pour le développement

✅ **Windows (desktop)** - Disponible
- App Windows native
- Plus lourd en RAM

✅ **Appareil Android USB** - Si connecté
- Test sur un vrai téléphone
- Nécessite mode développeur activé

---

## 📚 Documentation créée pour vous

1. **[GUIDE_VSCODE_FLUTTER.md](GUIDE_VSCODE_FLUTTER.md)** - Guide complet VS Code + Flutter
2. **[GUIDE_OPTIMISATION_RAM.md](GUIDE_OPTIMISATION_RAM.md)** - Optimisation RAM détaillée
3. **[README_OPTIMISATION.md](README_OPTIMISATION.md)** - Utilisation des scripts d'optimisation

---

## 🛠️ Scripts d'optimisation disponibles

Pour libérer de la RAM avant de développer :

### `arreter_processus_maintenant.ps1`
Arrête les processus gourmands immédiatement (Dell Support, MySQL, etc.)

**Gain : 800 Mo - 1.5 Go**

### `optimiser_demarrage.ps1`
Désactive les processus inutiles au démarrage de Windows

**Gain permanent : 1.4 - 2.5 Go**

---

## ⚠️ En cas de problème

### L'app ne démarre pas
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Hot Reload ne fonctionne pas
1. Sauvegardez (`Ctrl + S`)
2. Si ça ne marche pas : `Shift + F5` puis `F5`

### "Flutter SDK not found"
Vérifier le chemin dans [.vscode/settings.json](.vscode/settings.json:11) :
```json
"dart.flutterSdkPath": "C:\\flutter"
```

---

## 💡 Pourquoi VS Code et pas Android Studio ?

| | VS Code | Android Studio |
|---|---------|----------------|
| **RAM** | ~500 Mo | 2-4 Go |
| **Démarrage** | 5 secondes | 30-60 secondes |
| **Hot Reload** | Ultra-rapide | Rapide |
| **Verdict** | ✅ Parfait pour 8 Go RAM | ❌ Trop lourd |

**Vous utilisez la meilleure solution pour votre configuration !**

---

## 🎉 C'est parti !

1. Ouvrez VS Code
2. Appuyez sur `F5`
3. Codez votre app
4. Sauvegardez pour voir les changements
5. Profitez du Hot Reload ! 🔥

---

**Bon développement !** 🚀
