# Migration Multi-Catégories Vendeur

**Date**: 2026-01-04
**Status**: ✅ Complété

---

## 📋 Résumé

Migration du système de catégories vendeur d'une **catégorie unique** (`businessCategory: String`) vers un système **multi-catégories** (`businessCategories: List<String>`).

---

## 🔄 Changements Effectués

### 1. **Modèle VendeurProfile** (`lib/models/user_model.dart`)

#### Avant
```dart
class VendeurProfile {
  final String businessCategory;  // Une seule catégorie
  // ...
}
```

#### Après
```dart
class VendeurProfile {
  final List<String> businessCategories;  // Multiple catégories
  // ...
}
```

**Fonctionnalités** :
- ✅ Migration automatique dans `fromMap()` : si ancien format détecté, conversion automatique
- ✅ Valeur par défaut : `['Alimentation']`
- ✅ Sauvegarde uniquement du nouveau champ dans `toMap()`

---

### 2. **Shop Setup Screen** (`lib/screens/vendeur/shop_setup_screen.dart`)

**Changements** :
- ✅ Interface FilterChip pour sélection multiple
- ✅ Chargement des catégories existantes lors de l'édition
- ✅ Validation minimum 1 catégorie
- ✅ Protection contre décocher la dernière catégorie
- ✅ Navigation corrigée (suppression `onPageChanged`)

**Code clé** :
```dart
// État
List<String> _businessCategories = ['Alimentation'];

// Chargement édition
_businessCategories = List.from(_existingProfile!.businessCategories);

// Sélection multiple
FilterChip(
  selected: _businessCategories.contains(category.name),
  onSelected: (selected) {
    if (selected) {
      _businessCategories.add(category.name);
    } else {
      if (_businessCategories.length > 1) {
        _businessCategories.remove(category.name);
      } else {
        _showError('Vous devez avoir au moins une catégorie sélectionnée');
      }
    }
  },
)
```

---

### 3. **Add Product Screen** (`lib/screens/vendeur/add_product.dart`)

**Changements** :
- ✅ Chargement via `VendeurProfile.businessCategories`
- ✅ Filtrage strict : seules les catégories du vendeur apparaissent
- ✅ Chargement dans `initState()` au lieu de `didChangeDependencies()`

**Code** :
```dart
final vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
_allowedCategories = vendeurProfile.businessCategories;

// Dropdown filtré
ProductCategories.allCategories
  .where((category) => _allowedCategories.contains(category.name))
  .map((category) => DropdownMenuItem(...))
```

---

### 4. **My Shop Screen** (`lib/screens/vendeur/my_shop_screen.dart`)

**Changement** :
```dart
// Avant
value: _vendeurProfile!.allCategories.join(', ')

// Après
value: _vendeurProfile!.businessCategories.join(', ')
```

---

### 5. **Vendeur Profile Screen** (`lib/screens/vendeur/vendeur_profile_screen.dart`)

**Changements** :
- ✅ Affichage read-only des catégories
- ✅ Suppression de `_selectedBusinessCategory`
- ✅ Utilisation de `_displayCategories` pour l'affichage
- ✅ Redirection vers `/vendeur/shop-setup` pour modification

**Code** :
```dart
// État
String _displayCategories = 'Non définies';

// Initialisation
final vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
_displayCategories = vendeurProfile.businessCategories.join(', ');

// Affichage read-only
TextFormField(
  initialValue: _displayCategories,
  enabled: false,
  decoration: InputDecoration(labelText: 'Catégories d\'activité'),
)
```

---

### 6. **Auth Provider** (`lib/providers/auth_provider_firebase.dart`)

**Correction** :
```dart
// Profil par défaut vendeur
case UserType.vendeur:
  return VendeurProfile(
    businessName: '',
    businessCategories: ['Alimentation'],  // ✅ Nouveau format
    paymentInfo: PaymentInfo(),
    stats: BusinessStats(),
    deliverySettings: DeliverySettings(),
  ).toMap();
```

---

## 🔐 Firestore Rules Fix

**Problème** : Circularité dans `isAdmin()` empêchait l'admin de lire son propre profil

**Solution** :
```javascript
match /users/{userId} {
  // Utilisateur peut toujours lire son propre profil (évite la circularité)
  allow read: if isAuthenticated() && isOwner(userId);

  // Admin peut lire tous les profils
  allow read: if isAdmin();
  // ...
}
```

---

## ✅ Tests à Effectuer

### Test 1 : Création boutique multi-catégories
1. Connectez-vous comme vendeur
2. Allez dans Shop Setup
3. Sélectionnez 2-3 catégories (ex: "Alimentation", "Boissons", "Snacks")
4. Sauvegardez
5. **Attendu** : Catégories sauvegardées avec succès

### Test 2 : Édition catégories existantes
1. Retournez dans Shop Setup
2. **Attendu** : Les catégories précédemment sélectionnées sont cochées
3. Ajoutez une nouvelle catégorie
4. Retirez une ancienne catégorie (si plus d'une)
5. **Attendu** : Modifications sauvegardées

### Test 3 : Protection minimum 1 catégorie
1. Dans Shop Setup, tentez de décocher toutes les catégories sauf une
2. Tentez de décocher la dernière
3. **Attendu** : Message d'erreur "Vous devez avoir au moins une catégorie sélectionnée"

### Test 4 : Add Product filtré
1. Allez dans "Ajouter un produit"
2. Ouvrez le dropdown "Catégorie"
3. **Attendu** : Seules vos catégories configurées apparaissent

### Test 5 : My Shop affichage
1. Allez dans "Ma Boutique"
2. **Attendu** : Section "Catégories" affiche toutes vos catégories séparées par ", "

### Test 6 : Profile vendeur
1. Allez dans Profil
2. **Attendu** : "Catégories d'activité" affiche vos catégories (read-only)
3. Cliquez sur "Modifier" à côté
4. **Attendu** : Redirection vers Shop Setup

### Test 7 : Connexion Admin
1. Déconnectez-vous
2. Connectez-vous avec `admin@socialbusiness.ci`
3. **Attendu** : Connexion réussie, pas d'erreur "données utilisateur introuvables"

---

## 🗄️ Migration Firestore

### Migration Automatique
Le code gère automatiquement la migration grâce à `VendeurProfile.fromMap()` :

```dart
factory VendeurProfile.fromMap(Map<String, dynamic> data) {
  // Parse businessCategories avec fallback vers ancien champ
  List<String> categories = _parseStringList(data['businessCategories']);

  if (categories.isEmpty && data['businessCategory'] != null) {
    categories = [data['businessCategory'] as String];  // Migration auto
  }

  if (categories.isEmpty) {
    categories = ['Alimentation'];  // Fallback par défaut
  }

  return VendeurProfile(
    // ...
    businessCategories: categories,
  );
}
```

### Nettoyage Manuel (Optionnel)
Pour nettoyer complètement les anciens champs `businessCategory` :

```javascript
// Script Firebase Admin SDK
const admin = require('firebase-admin');
const db = admin.firestore();

async function cleanOldCategoryField() {
  const usersRef = db.collection('users');
  const snapshot = await usersRef.where('userType', '==', 'vendeur').get();

  const batch = db.batch();

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    if (data.profile?.vendeurProfile?.businessCategory) {
      batch.update(doc.ref, {
        'profile.vendeurProfile.businessCategory': admin.firestore.FieldValue.delete()
      });
    }
  });

  await batch.commit();
  console.log('✅ Ancien champ businessCategory supprimé');
}
```

---

## 📝 Notes Importantes

1. **Compatibilité arrière** : Le système lit toujours l'ancien `businessCategory` si `businessCategories` est vide
2. **Données de test** : Toutes les données actuelles sont des données de test, migration safe
3. **Catégories système** : Actuellement basé sur `ProductCategories.allCategories` (config statique)
4. **Future évolution** : Possibilité d'utiliser `CategoryService` et Firestore `product_categories` collection pour catégories dynamiques

---

## 🐛 Problèmes Résolus

| Problème | Cause | Solution |
|----------|-------|----------|
| Affichage étape précédente à l'étape 2 | Double update `_currentStep` | Suppression `onPageChanged` |
| Catégorie "Mode & Vêtements" fantôme | Ancien `businessCategory` + nouveau `businessCategories` | Migration complète vers nouveau champ |
| Add product ne montre qu'une catégorie | Filtrage incluait `_allowedCategories.isEmpty` | Filtrage strict avec `.contains()` |
| Impossible de décocher catégories | Pas de validation UI | Protection contre décocher dernière catégorie |
| Admin ne peut pas se connecter | Circularité dans règles Firestore | Règle `isOwner()` avant `isAdmin()` |

---

## 📚 Fichiers Modifiés

1. `lib/models/user_model.dart` - VendeurProfile
2. `lib/screens/vendeur/shop_setup_screen.dart` - UI multi-sélection
3. `lib/screens/vendeur/add_product.dart` - Chargement catégories
4. `lib/screens/vendeur/my_shop_screen.dart` - Affichage
5. `lib/screens/vendeur/vendeur_profile_screen.dart` - Affichage read-only
6. `lib/providers/auth_provider_firebase.dart` - Profil par défaut
7. `firestore.rules` - Fix circularité admin

---

**Statut Final** : ✅ **Production Ready** (après tests)

**Prochaine étape** : Déploiement des règles Firestore + Tests complets
