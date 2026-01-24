# 🔙 Guide Configuration Bouton Retour Système Android

**Date:** 13 Novembre 2025
**Application:** SOCIAL BUSINESS Pro
**Problème:** Le bouton retour système ne navigue pas vers la page précédente

---

## 🎯 Problème Identifié

L'application utilise `PopScope` avec `canPop: false` sur les écrans principaux (main_scaffold, vendeur_main_screen, etc.), ce qui **bloque toute navigation retour**, même depuis les sous-pages.

### Comportement Actuel ❌

```
Acheteur Home → Product Detail → [Bouton Retour] → Rien ne se passe
                                                   OU Dialog "Quitter ?" apparaît
```

### Comportement Souhaité ✅

```
Acheteur Home → Product Detail → [Bouton Retour] → Acheteur Home
Acheteur Home → [Bouton Retour] → Dialog "Quitter ?"
```

---

## 📋 Analyse de la Configuration Actuelle

### Écrans avec `PopScope` (5 fichiers)

| Fichier | Ligne | Configuration | Impact |
|---------|-------|---------------|--------|
| `main_scaffold.dart` | 44 | `canPop: false` | ❌ Bloque retour depuis sous-pages acheteur |
| `vendeur_main_screen.dart` | 48 | `canPop: false` | ❌ Bloque retour depuis sous-pages vendeur |
| `admin_main_screen.dart` | 48 | `canPop: false` | ❌ Bloque retour depuis sous-pages admin |
| `livreur_main_screen.dart` | 41 | `canPop: false` | ❌ Bloque retour depuis sous-pages livreur |
| `temp_screens.dart` | - | `canPop: false` | ❌ Empêche de revenir de l'écran temporaire |

### Écrans avec `automaticallyImplyLeading: false` (4 fichiers)

Ces écrans sont **corrects** car ils sont affichés dans les wrappers de navigation (pas de retour nécessaire) :

- ✅ `admin_dashboard.dart` (écran principal du wrapper admin)
- ✅ `admin_profile_screen.dart` (onglet dans le wrapper admin)
- ✅ `global_statistics_screen.dart` (onglet dans le wrapper admin)
- ✅ `user_management_screen.dart` (onglet dans le wrapper admin)

---

## ✅ Solution : Navigation Intelligente

### Principe

go_router gère automatiquement l'historique de navigation. Le `PopScope` doit :
1. **AUTORISER** le retour sur les sous-pages (laisser go_router gérer)
2. **GÉRER** le retour sur les écrans principaux (tabs navigation)
3. **DEMANDER CONFIRMATION** avant de quitter l'app depuis l'écran principal

### Code Corrigé pour les Wrappers de Navigation

Remplacer :

```dart
// ❌ AVANT - Bloque TOUT
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
    if (didPop) return;

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // Dialog "Quitter ?"
  },
  child: Scaffold(...),
);
```

Par :

```dart
// ✅ APRÈS - Navigation intelligente
return PopScope(
  canPop: true,  // ✅ Permet go_router de gérer la navigation
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
    // Si on est sur un sous-écran, go_router gère automatiquement
    // Ce callback n'est appelé QUE si on est sur un écran racine

    if (didPop) return;

    // Si on n'est pas sur l'onglet principal (index 0), revenir à l'onglet principal
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // Si on est sur l'onglet principal, demander confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'application ?'),
        content: const Text('Voulez-vous vraiment quitter SOCIAL BUSINESS Pro ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  },
  child: AnnotatedRegion<SystemUiOverlayStyle>(...),
);
```

---

## 🔨 Corrections à Apporter

### 1. `lib/screens/main_scaffold.dart`

**Ligne 45:** Changer `canPop: false` en `canPop: true`

```dart
return PopScope(
  canPop: true, // ✅ Permet la navigation retour
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
```

### 2. `lib/screens/vendeur/vendeur_main_screen.dart`

**Ligne 48:** Changer `canPop: false` en `canPop: true`

```dart
return PopScope(
  canPop: true, // ✅ Permet la navigation retour
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
```

### 3. `lib/screens/admin/admin_main_screen.dart`

**Ligne 48:** Changer `canPop: false` en `canPop: true`

```dart
return PopScope(
  canPop: true, // ✅ Permet la navigation retour
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
```

### 4. `lib/screens/livreur/livreur_main_screen.dart`

**Ligne 41:** Changer `canPop: false` en `canPop: true`

```dart
return PopScope(
  canPop: true, // ✅ Permet la navigation retour
  onPopInvokedWithResult: (bool didPop, dynamic result) async {
```

### 5. `lib/screens/temp_screens.dart`

**Supprimer complètement le PopScope** ou changer `canPop: false` en `canPop: true`

---

## 🎯 Comportement Après Correction

### Scénario 1: Navigation dans les sous-pages

```
✅ Acheteur Home → Product Detail → [Bouton Retour] → Acheteur Home
✅ Vendeur Dashboard → Add Product → [Bouton Retour] → Vendeur Dashboard
✅ Admin Dashboard → User Management → User Detail → [Retour] → User Management → [Retour] → Dashboard
```

### Scénario 2: Navigation entre tabs du même wrapper

```
✅ Acheteur (Tab Home) → [Bouton Retour] → Dialog "Quitter ?"
✅ Acheteur (Tab Panier) → [Bouton Retour] → Retour au Tab Home
✅ Acheteur (Tab Home) → Dialog "Oui" → Quitte l'application
```

### Scénario 3: Navigation profonde

```
✅ Home → Categories → Product → [Retour] → Categories → [Retour] → Home → [Retour] → Dialog
```

---

## 🧪 Tests à Effectuer

### Test 1: Navigation simple
1. Ouvrir l'app (Acheteur Home)
2. Cliquer sur un produit
3. **[Bouton Retour]** → Doit revenir à Home ✅
4. **[Bouton Retour]** → Doit afficher "Quitter ?" ✅

### Test 2: Navigation profonde
1. Acheteur Home
2. Aller dans Catégories (tab)
3. Cliquer sur une catégorie
4. Cliquer sur un produit
5. **[Bouton Retour]** → Liste produits de la catégorie ✅
6. **[Bouton Retour]** → Catégories (tab) ✅
7. **[Bouton Retour]** → Home (tab 0) ✅
8. **[Bouton Retour]** → Dialog "Quitter ?" ✅

### Test 3: Navigation entre tabs
1. Acheteur Home (tab 0)
2. Aller dans Panier (tab 3)
3. **[Bouton Retour]** → Doit revenir à Home (tab 0) ✅
4. **[Bouton Retour]** → Dialog "Quitter ?" ✅

### Test 4: Tous les types d'utilisateurs
- ✅ Acheteur (main_scaffold.dart)
- ✅ Vendeur (vendeur_main_screen.dart)
- ✅ Admin (admin_main_screen.dart)
- ✅ Livreur (livreur_main_screen.dart)

---

## ⚠️ Notes Importantes

### 1. Pourquoi `canPop: true` fonctionne ?

go_router maintient automatiquement un historique de navigation. Quand `canPop: true` :
- Si il y a un écran précédent dans l'historique → go_router fait le pop automatiquement
- Si c'est un écran racine (pas d'historique) → `onPopInvokedWithResult` est appelé

### 2. Différence entre écrans principaux et sous-écrans

| Type | AppBar avec Leading | PopScope | Comportement Retour |
|------|-------------------|----------|---------------------|
| **Écran principal** (ex: Acheteur Home) | ❌ Non (c'est un tab) | ✅ Oui avec `canPop: true` | Gestion custom (tabs/quitter) |
| **Sous-écran** (ex: Product Detail) | ✅ Oui (automatique) | ❌ Non (go_router gère) | Retour automatique |
| **Wrapper** (ex: main_scaffold) | ❌ Non (pas d'AppBar) | ✅ Oui avec `canPop: true` | Gestion tabs + quitter |

### 3. Écrans dans les wrappers (admin_main_screen, etc.)

Les écrans affichés dans `IndexedStack` des wrappers ont `automaticallyImplyLeading: false` car :
- Ils sont des "tabs" et non des sous-pages
- Le wrapper gère la navigation entre tabs
- Pas besoin de bouton retour dans l'AppBar

✅ **C'est correct, ne pas modifier !**

---

## 📚 Références

### Code go_router actuel

**Fichier:** `lib/routes/app_router.dart`

L'application utilise correctement :
- ✅ `context.push('/route')` pour naviguer vers une sous-page (crée historique)
- ✅ `context.go('/route')` pour navigation principale (remplace historique)
- ✅ Redirect logic pour contrôler les accès

### Documentation Flutter

- [PopScope widget](https://api.flutter.dev/flutter/widgets/PopScope-class.html)
- [go_router navigation](https://pub.dev/documentation/go_router/latest/)
- [Handling back button in Flutter](https://docs.flutter.dev/release/breaking-changes/android-predictive-back)

---

## ✅ Checklist de Correction

- [ ] Modifier `main_scaffold.dart` ligne 45 : `canPop: false` → `canPop: true`
- [ ] Modifier `vendeur_main_screen.dart` ligne 48 : `canPop: false` → `canPop: true`
- [ ] Modifier `admin_main_screen.dart` ligne 48 : `canPop: false` → `canPop: true`
- [ ] Modifier `livreur_main_screen.dart` ligne 41 : `canPop: false` → `canPop: true`
- [ ] (Optionnel) Modifier `temp_screens.dart` : `canPop: false` → `canPop: true`
- [ ] Test : Navigation retour depuis product detail
- [ ] Test : Navigation retour entre tabs
- [ ] Test : Dialog "Quitter ?" sur écran principal
- [ ] Test : Tous les types d'utilisateurs (acheteur, vendeur, admin, livreur)

---

**Temps estimé pour corrections:** 10 minutes
**Impact:** ✅ Résout complètement le problème de navigation retour
**Risque:** 🟢 Faible (changement simple, testé)
