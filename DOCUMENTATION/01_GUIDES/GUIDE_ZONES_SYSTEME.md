# 🖥️ Guide - Respect des Zones Système Android

**Date:** 13 Novembre 2025
**Problème:** Certains écrans s'affichent sur toute la hauteur sans respecter les zones système

---

## 🎯 Problème Identifié

### Symptômes
- Les écrans occupent **toute la hauteur** de l'appareil
- Le contenu passe **sous la status bar** (heure, batterie, etc.)
- Le contenu passe **sous la navigation bar** (boutons système)
- Le bouton "Retour" système ne fonctionne pas correctement

### Cause
Les écrans utilisent `Scaffold` sans configurer correctement :
- `SafeArea` pour respecter les zones système
- `AppBar` pour gérer le bouton retour
- Padding pour la status bar et navigation bar

---

## ✅ Solution Appliquée

### Pour l'Écran de Carte Plein Écran

**Fichier:** `lib/screens/acheteur/address_management_screen.dart`

**Ajout d'un AppBar transparent (lignes 1614-1619):**
```dart
return Scaffold(
  extendBodyBehindAppBar: false,  // Ne pas étendre derrière l'AppBar
  appBar: AppBar(
    toolbarHeight: 0,              // AppBar invisible mais fonctionnel
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  body: Stack(...),
);
```

**Avantages:**
- ✅ Bouton retour système fonctionne automatiquement
- ✅ Respect de la status bar
- ✅ Pas de contenu masqué
- ✅ Navigation cohérente avec le reste de l'app

---

## 🔍 Comment Identifier les Écrans Problématiques

### Recherche des Patterns à Risque

**1. Écrans sans AppBar:**
```bash
grep -r "Scaffold" lib/screens/ | grep -v "appBar:"
```

**2. Écrans avec body: Stack sans SafeArea:**
```bash
grep -r "body: Stack" lib/screens/
```

**3. Écrans plein écran:**
```bash
grep -r "extendBodyBehindAppBar: true" lib/screens/
```

### Liste des Écrans Potentiellement Affectés

#### Écrans à Vérifier
1. **`FullScreenMapPicker`** (address_management_screen.dart) - ✅ **CORRIGÉ**
2. **Écrans de splash/onboarding**
3. **Écrans modaux plein écran**
4. **Écrans avec Google Maps**
5. **Écrans avec vidéo/image plein écran**

---

## 🛠️ Solutions par Type d'Écran

### Type 1: Écran Standard avec AppBar

**Avant (Problématique):**
```dart
return Scaffold(
  body: Column(
    children: [
      // Contenu passe sous la status bar ❌
    ],
  ),
);
```

**Après (Correct):**
```dart
return Scaffold(
  appBar: AppBar(
    title: Text('Mon Écran'),
    // Le bouton retour est automatique ✅
  ),
  body: Column(
    children: [
      // Contenu respecte la status bar ✅
    ],
  ),
);
```

---

### Type 2: Écran Plein Écran avec Bouton Retour Custom

**Avant (Problématique):**
```dart
return Scaffold(
  body: Stack(
    children: [
      // Carte ou contenu plein écran
      GoogleMap(...),

      // Bouton retour custom
      Positioned(
        top: 16,  // ❌ Passe sous la status bar
        left: 16,
        child: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  ),
);
```

**Après (Correct - Solution 1: AppBar invisible):**
```dart
return Scaffold(
  extendBodyBehindAppBar: false,
  appBar: AppBar(
    toolbarHeight: 0,  // Invisible mais fonctionnel
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  body: Stack(
    children: [
      GoogleMap(...),

      Positioned(
        top: MediaQuery.of(context).padding.top + 16,  // ✅ Respecte la status bar
        left: 16,
        child: IconButton(...),
      ),
    ],
  ),
);
```

**Après (Correct - Solution 2: SafeArea):**
```dart
return Scaffold(
  body: SafeArea(  // ✅ Ajoute automatiquement le padding système
    child: Stack(
      children: [
        GoogleMap(...),

        Positioned(
          top: 16,  // ✅ Maintenant relatif à SafeArea
          left: 16,
          child: IconButton(...),
        ),
      ],
    ),
  ),
);
```

---

### Type 3: Écran Modal Plein Écran (BottomSheet)

**Avant (Problématique):**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height,  // ❌ Toute la hauteur
    child: Column(...),
  ),
);
```

**Après (Correct):**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,  // ✅ Respecte les zones système
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.9,  // 90% de la hauteur
    child: SafeArea(  // ✅ Protection supplémentaire
      child: Column(...),
    ),
  ),
);
```

---

### Type 4: Écran avec Barre de Recherche en Haut

**Avant (Problématique):**
```dart
return Scaffold(
  body: Stack(
    children: [
      GoogleMap(...),

      // Barre de recherche
      Positioned(
        top: 16,  // ❌ Sous la status bar
        left: 16,
        right: 16,
        child: Card(...),
      ),
    ],
  ),
);
```

**Après (Correct):**
```dart
return Scaffold(
  appBar: AppBar(
    toolbarHeight: 0,
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  body: Stack(
    children: [
      GoogleMap(...),

      Positioned(
        top: MediaQuery.of(context).padding.top + 16,  // ✅ Respecte status bar
        left: 16,
        right: 16,
        child: Card(...),
      ),
    ],
  ),
);
```

---

## 📱 Gestion du Bouton Retour Système

### Problème: Bouton Retour Android ne Fonctionne Pas

**Cause:** Pas d'AppBar, donc pas de gestion automatique du bouton retour

**Solution 1: Ajouter un AppBar (Recommandé)**
```dart
return Scaffold(
  appBar: AppBar(
    toolbarHeight: 0,
    backgroundColor: Colors.transparent,
    elevation: 0,
    // Le bouton retour système fonctionne automatiquement ✅
  ),
  body: ...,
);
```

**Solution 2: WillPopScope (Si contrôle custom nécessaire)**
```dart
return WillPopScope(
  onWillPop: () async {
    // Logique custom avant de fermer l'écran
    debugPrint('Bouton retour pressé');
    return true;  // true = autoriser la navigation retour
  },
  child: Scaffold(
    body: ...,
  ),
);
```

**Solution 3: PopScope (Flutter 3.12+)**
```dart
return PopScope(
  canPop: true,
  onPopInvoked: (didPop) {
    debugPrint('Navigation retour: $didPop');
  },
  child: Scaffold(
    body: ...,
  ),
);
```

---

## 🧪 Tests Recommandés

### Test 1: Vérifier la Status Bar
1. Ouvrir l'écran
2. Vérifier que l'heure, batterie, signal sont **visibles**
3. Vérifier qu'**aucun contenu** ne passe derrière

### Test 2: Vérifier la Navigation Bar
1. Ouvrir l'écran
2. Vérifier que les boutons système (◀ ⭘ ☰) sont **visibles**
3. Vérifier qu'**aucun contenu** ne passe derrière

### Test 3: Bouton Retour Système
1. Ouvrir l'écran
2. Appuyer sur le bouton **← Retour** Android
3. Vérifier que l'écran se **ferme correctement**

### Test 4: Rotation (si applicable)
1. Ouvrir l'écran en portrait
2. Tourner l'appareil en paysage
3. Vérifier que les zones système sont **toujours respectées**

---

## 📋 Checklist de Correction

Pour chaque écran plein écran ou problématique :

- [ ] Ajouter `appBar: AppBar(toolbarHeight: 0, ...)` si absent
- [ ] Ou entourer le body avec `SafeArea(...)`
- [ ] Utiliser `MediaQuery.of(context).padding.top` pour les éléments Positioned en haut
- [ ] Utiliser `MediaQuery.of(context).padding.bottom` pour les éléments en bas
- [ ] Tester le bouton retour système Android
- [ ] Vérifier que la status bar est visible
- [ ] Vérifier que la navigation bar est visible
- [ ] Tester en portrait et paysage

---

## 🔧 Script de Détection Automatique

**Trouver les Scaffold sans AppBar:**
```bash
# Rechercher dans tous les fichiers Dart
find lib/screens -name "*.dart" -exec grep -l "Scaffold" {} \; | while read file; do
  if ! grep -q "appBar:" "$file"; then
    echo "⚠️ $file - Pas d'AppBar détecté"
  fi
done
```

**Trouver les Stack sans SafeArea:**
```bash
grep -rn "body: Stack" lib/screens/ | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  if ! grep -q "SafeArea" "$file"; then
    echo "⚠️ $file - Stack sans SafeArea"
  fi
done
```

---

## 📝 Exemples Concrets du Projet

### 1. FullScreenMapPicker - ✅ CORRIGÉ

**Avant:**
```dart
return Scaffold(
  body: Stack(
    children: [
      GoogleMap(...),
      Positioned(top: 16, ...),  // ❌ Sous status bar
    ],
  ),
);
```

**Après:**
```dart
return Scaffold(
  extendBodyBehindAppBar: false,
  appBar: AppBar(
    toolbarHeight: 0,
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  body: Stack(
    children: [
      GoogleMap(...),
      Positioned(
        top: MediaQuery.of(context).padding.top + 16,  // ✅ Corrigé
        ...
      ),
    ],
  ),
);
```

### 2. Autres Écrans à Vérifier

**Écrans Suspects (à vérifier manuellement):**
- `splash_screen.dart` - Écran de démarrage
- `delivery_tracking_screen.dart` - Carte de livraison
- Tous les écrans avec `GoogleMap`
- Tous les écrans avec `showModalBottomSheet`

---

## 🎨 Bonnes Pratiques

### 1. Toujours Utiliser AppBar
Même si invisible, ça gère automatiquement :
- Bouton retour système
- Status bar padding
- Cohérence de navigation

### 2. SafeArea pour les Stacks
Si pas d'AppBar, toujours entourer avec SafeArea :
```dart
body: SafeArea(
  child: Stack(...),
)
```

### 3. MediaQuery pour les Positioned
Pour un contrôle précis :
```dart
Positioned(
  top: MediaQuery.of(context).padding.top + 16,
  bottom: MediaQuery.of(context).padding.bottom + 16,
  ...
)
```

### 4. useSafeArea pour les BottomSheet
```dart
showModalBottomSheet(
  useSafeArea: true,  // ✅ Toujours activer
  ...
)
```

---

## ✅ Résultat Attendu

Après corrections, tous les écrans doivent :
- ✅ Respecter la **status bar** (heure, batterie visible)
- ✅ Respecter la **navigation bar** (boutons système visibles)
- ✅ Bouton **retour système** fonctionnel
- ✅ Pas de **contenu masqué** par les zones système
- ✅ **Cohérence visuelle** avec le reste de l'app

---

## 🚀 Prochaines Étapes

1. **Identifier** tous les écrans problématiques avec le script
2. **Corriger** un par un selon le type d'écran
3. **Tester** chaque écran sur appareil réel
4. **Valider** le bouton retour système partout

---

**Dernière mise à jour :** 13 Novembre 2025
**Écrans corrigés :** 1/? (FullScreenMapPicker)
**Statut :** En cours - Besoin d'audit complet
