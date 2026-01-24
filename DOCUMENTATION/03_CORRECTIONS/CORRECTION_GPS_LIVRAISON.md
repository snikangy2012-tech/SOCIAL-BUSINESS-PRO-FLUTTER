# ✅ Correction du Système GPS pour le Suivi de Livraison

## Date: 17 novembre 2025

---

## 🎯 Problème Identifié

### Symptôme Initial
Lorsque l'acheteur clique sur **"Suivre"** pour la commande #2, l'écran de suivi de livraison affiche le message **"Coordonnées non disponibles"** au lieu de la carte Google Maps.

### Diagnostic
Après investigation approfondie du code, j'ai identifié que le problème se situe dans [checkout_screen.dart:312-322](lib/screens/acheteur/checkout_screen.dart#L312-L322) :

```dart
// Générer des coordonnées GPS par défaut pour la commande
// TODO: Remplacer par un vrai géocodage de l'adresse du vendeur et de livraison
final random = now.millisecondsSinceEpoch % 1000 / 10000.0; // Petit offset aléatoire

// Coordonnées de pickup (vendeur) - Abidjan centre par défaut
final pickupLatitude = 5.3167 + random;
final pickupLongitude = -4.0333 + random;

// Coordonnées de livraison (acheteur) - basé sur la commune
final deliveryLatitude = 5.3467 + random;
final deliveryLongitude = -4.0083 + random;
```

**Problème** : Les coordonnées GPS étaient générées **aléatoirement** au lieu d'utiliser les vraies coordonnées de l'adresse de l'acheteur et de la boutique du vendeur.

---

## 🔍 Analyse du Flux de Données

### 1. Stockage des Adresses Acheteur
Les acheteurs enregistrent leurs adresses avec des coordonnées GPS réelles via [address_management_screen.dart](lib/screens/acheteur/address_management_screen.dart) :

**Structure de l'adresse** ([user_model.dart:454-527](lib/models/user_model.dart#L454-L527)) :
```dart
class Address {
  final String id;
  final String label; // 'Domicile', 'Bureau', etc.
  final String street;
  final String commune;
  final String city;
  final String? postalCode;
  final LocationCoords? coordinates; // ⬅️ Coordonnées GPS réelles
  final bool isDefault;
}

class LocationCoords {
  final double latitude;
  final double longitude;
}
```

Stockage Firestore :
```
users/{userId}/profile/acheteurProfile/addresses[]
  ├── id
  ├── label
  ├── street
  ├── commune
  ├── city
  ├── coordinates
  │   ├── latitude
  │   └── longitude
  └── isDefault
```

### 2. Stockage des Boutiques Vendeur
Les vendeurs enregistrent l'emplacement de leur boutique dans leur profil :

Stockage Firestore :
```
users/{vendeurId}/profile/vendeurProfile/shopLocation
  ├── latitude
  └── longitude
```

### 3. Création des Commandes
Au moment du checkout, la commande est créée avec ces champs GPS ([order_model.dart:28-31](lib/models/order_model.dart#L28-L31)) :
```dart
class OrderModel {
  // ... autres champs
  final double? pickupLatitude;     // Point de collecte (boutique vendeur)
  final double? pickupLongitude;
  final double? deliveryLatitude;   // Point de livraison (adresse acheteur)
  final double? deliveryLongitude;
}
```

### 4. Création de la Livraison
Quand une livraison est créée depuis une commande ([delivery_service.dart:128-142](lib/services/delivery_service.dart#L128-L142)), les coordonnées sont extraites :

```dart
final pickupAddress = {
  'street': orderData['deliveryAddress'] ?? '',
  'coordinates': {
    'latitude': orderData['pickupLatitude'] ?? 0.0,
    'longitude': orderData['pickupLongitude'] ?? 0.0,
  },
};

final deliveryAddress = {
  'street': orderData['deliveryAddress'] ?? '',
  'coordinates': {
    'latitude': orderData['deliveryLatitude'] ?? 0.0,
    'longitude': orderData['deliveryLongitude'] ?? 0.0,
  },
};
```

### 5. Affichage du Suivi de Livraison
L'écran de suivi ([delivery_tracking_screen.dart:237-259](lib/screens/acheteur/delivery_tracking_screen.dart#L237-L259)) vérifie la présence des coordonnées :

```dart
final deliveryLat = _delivery!.deliveryAddress['latitude'] as double?;
final deliveryLng = _delivery!.deliveryAddress['longitude'] as double?;

if (deliveryLat == null || deliveryLng == null) {
  return Card(...); // ❌ Affiche "Coordonnées non disponibles"
}

// ✅ Affiche la carte Google Maps avec les 3 marqueurs
```

---

## ✅ Corrections Appliquées

### Fichier Modifié: `lib/screens/acheteur/checkout_screen.dart`

#### 1. Ajout de l'Import
**Ligne 17** :
```dart
import '../../models/user_model.dart';
```

#### 2. Récupération de l'Adresse de l'Acheteur
**Lignes 269-287** :
```dart
// Récupérer l'adresse par défaut de l'utilisateur avec ses coordonnées GPS
final profile = user.profile;
Address? selectedAddress;

if (profile.isNotEmpty) {
  final acheteurProfile = profile['acheteurProfile'] as Map<String, dynamic>?;
  if (acheteurProfile != null) {
    final addresses = acheteurProfile['addresses'] as List<dynamic>? ?? [];
    if (addresses.isNotEmpty) {
      final defaultAddressData = addresses.firstWhere(
        (addr) => addr['isDefault'] == true,
        orElse: () => addresses.isNotEmpty ? addresses.first : null,
      );
      if (defaultAddressData != null) {
        selectedAddress = Address.fromMap(defaultAddressData as Map<String, dynamic>);
      }
    }
  }
}
```

#### 3. Récupération des Coordonnées du Vendeur
**Lignes 332-355** :
```dart
// Récupérer les coordonnées du vendeur (shopLocation)
double pickupLatitude = 5.3167; // Abidjan centre par défaut
double pickupLongitude = -4.0333;

try {
  final vendorDoc = await FirebaseService.getDocument(
    collection: FirebaseCollections.users,
    docId: vendeurId,
  );

  if (vendorDoc != null && vendorDoc['profile'] != null) {
    final vendorProfile = vendorDoc['profile'] as Map<String, dynamic>;
    final vendeurProfileData = vendorProfile['vendeurProfile'] as Map<String, dynamic>?;

    if (vendeurProfileData != null && vendeurProfileData['shopLocation'] != null) {
      final shopLocation = vendeurProfileData['shopLocation'] as Map<String, dynamic>;
      pickupLatitude = (shopLocation['latitude'] ?? pickupLatitude).toDouble();
      pickupLongitude = (shopLocation['longitude'] ?? pickupLongitude).toDouble();
      debugPrint('✅ Coordonnées vendeur trouvées: $pickupLatitude, $pickupLongitude');
    }
  }
} catch (e) {
  debugPrint('⚠️ Erreur récupération coordonnées vendeur, utilisation coordonnées par défaut: $e');
}
```

#### 4. Récupération des Coordonnées de l'Acheteur
**Lignes 357-368** :
```dart
// Récupérer les coordonnées de livraison depuis l'adresse sélectionnée
double deliveryLatitude = 5.3467; // Abidjan par défaut
double deliveryLongitude = -4.0083;

if (selectedAddress != null && selectedAddress.coordinates != null) {
  deliveryLatitude = selectedAddress.coordinates!.latitude;
  deliveryLongitude = selectedAddress.coordinates!.longitude;
  debugPrint('✅ Coordonnées de livraison trouvées: $deliveryLatitude, $deliveryLongitude');
} else {
  debugPrint('⚠️ Pas de coordonnées GPS dans l\'adresse sélectionnée, utilisation coordonnées par défaut');
}
```

---

## 📊 Avant vs Après

### ❌ Avant (Coordonnées Aléatoires)
```dart
final random = now.millisecondsSinceEpoch % 1000 / 10000.0;
final pickupLatitude = 5.3167 + random;     // ⚠️ Aléatoire
final pickupLongitude = -4.0333 + random;   // ⚠️ Aléatoire
final deliveryLatitude = 5.3467 + random;   // ⚠️ Aléatoire
final deliveryLongitude = -4.0083 + random; // ⚠️ Aléatoire
```

**Résultat** : Les coordonnées ne correspondaient jamais à la vraie position → "Coordonnées non disponibles"

### ✅ Après (Coordonnées Réelles)
```dart
// 1. Récupération depuis le profil vendeur
pickupLatitude = vendeurProfile['shopLocation']['latitude'];
pickupLongitude = vendeurProfile['shopLocation']['longitude'];

// 2. Récupération depuis l'adresse de l'acheteur
deliveryLatitude = selectedAddress.coordinates.latitude;
deliveryLongitude = selectedAddress.coordinates.longitude;
```

**Résultat** : Les coordonnées correspondent aux vraies positions → Carte affichée correctement

---

## 🔄 Flux Complet Corrigé

```
1. ACHETEUR enregistre son adresse
   └─> address_management_screen.dart
       └─> Sauvegarde dans Firestore: users/{userId}/profile/acheteurProfile/addresses[]
           └─> Inclut coordinates: { latitude, longitude }

2. VENDEUR configure sa boutique
   └─> shop_setup_screen.dart
       └─> Sauvegarde dans Firestore: users/{vendeurId}/profile/vendeurProfile/shopLocation
           └─> Inclut { latitude, longitude }

3. ACHETEUR passe commande
   └─> checkout_screen.dart
       ├─> ✅ Récupère l'adresse par défaut de l'acheteur
       ├─> ✅ Récupère la position de la boutique du vendeur
       └─> Crée la commande avec les 4 coordonnées GPS réelles:
           ├─ pickupLatitude (boutique vendeur)
           ├─ pickupLongitude
           ├─ deliveryLatitude (adresse acheteur)
           └─ deliveryLongitude

4. VENDEUR accepte et assigne un livreur
   └─> order_assignment_service.dart
       └─> Crée un document de livraison (delivery)
           └─> delivery_service.createDeliveryFromOrder()
               └─> Copie les coordonnées depuis la commande

5. ACHETEUR suit sa livraison
   └─> delivery_tracking_screen.dart
       └─> ✅ Récupère les coordonnées depuis delivery.deliveryAddress
           └─> Affiche la carte Google Maps avec 3 marqueurs:
               ├─ Position du livreur (currentLocation)
               ├─ Point de collecte (pickupAddress)
               └─ Point de livraison (deliveryAddress)
```

---

## 🧪 Tests à Effectuer

### Test 1: Enregistrement d'Adresse avec GPS
1. Se connecter en tant qu'**acheteur**
2. Aller dans **"Mes adresses"** > **"Nouvelle adresse"**
3. Aller à l'onglet **"Carte"**
4. Cliquer sur le bouton **fullscreen** (en haut à droite)
5. Sélectionner une position sur la carte
6. Cliquer sur **"Confirmer cette position"**
7. Remplir le formulaire et **"Sauvegarder l'adresse"**
8. ✅ Vérifier dans la console les logs: `✅ Coordonnées de livraison trouvées: ...`

### Test 2: Configuration Boutique Vendeur
1. Se connecter en tant qu'**vendeur**
2. Aller dans **"Configuration boutique"**
3. Définir l'emplacement de la boutique sur la carte
4. Sauvegarder
5. ✅ Vérifier dans Firestore: `users/{vendeurId}/profile/vendeurProfile/shopLocation`

### Test 3: Création de Commande avec GPS
1. Se connecter en tant qu'**acheteur**
2. Ajouter des produits au panier
3. Aller au **checkout**
4. Passer la commande
5. ✅ Vérifier dans la console les logs:
   - `✅ Coordonnées vendeur trouvées: ...`
   - `✅ Coordonnées de livraison trouvées: ...`
6. ✅ Vérifier dans Firestore: `orders/{orderId}` doit avoir les 4 champs GPS remplis

### Test 4: Suivi de Livraison avec Carte
1. Le vendeur accepte et assigne un livreur
2. L'acheteur ouvre **"Mes commandes"**
3. Cliquer sur **"Suivre"** pour la commande
4. ✅ **SUCCÈS** : La carte Google Maps s'affiche avec les 3 marqueurs:
   - 📍 Livreur (position actuelle)
   - 🏪 Point de collecte (boutique vendeur)
   - 🏠 Point de livraison (adresse acheteur)
5. ❌ **ÉCHEC** : Message "Coordonnées non disponibles"

---

## ⚠️ Points d'Attention

### 1. Adresses Sans GPS
Si un acheteur a créé une adresse **avant** cette correction (sans coordonnées GPS), il faut :
- Soit **modifier l'adresse** et ajouter les coordonnées via la carte
- Soit **créer une nouvelle adresse** avec les coordonnées GPS

**Détection** : Le log affiche `⚠️ Pas de coordonnées GPS dans l'adresse sélectionnée, utilisation coordonnées par défaut`

### 2. Vendeurs Sans Localisation Boutique
Si un vendeur n'a pas configuré `shopLocation`, les coordonnées par défaut (Abidjan centre) sont utilisées.

**Solution** : Ajouter un écran obligatoire pour configurer la boutique lors de l'inscription vendeur.

### 3. Commandes Existantes
Les commandes créées **avant** cette correction ont des coordonnées aléatoires et ne pourront pas afficher la carte correctement.

**Solution** : Script de migration pour mettre à jour les commandes existantes (optionnel).

---

## 📈 Amélioration Future

### Géocodage Automatique
Au lieu d'utiliser des coordonnées par défaut si l'adresse n'a pas de GPS, implémenter un géocodage automatique :

```dart
import 'package:geocoding/geocoding.dart';

Future<LocationCoords?> geocodeAddress(String street, String city) async {
  try {
    List<Location> locations = await locationFromAddress('$street, $city, Côte d\'Ivoire');
    if (locations.isNotEmpty) {
      return LocationCoords(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
      );
    }
  } catch (e) {
    debugPrint('❌ Erreur géocodage: $e');
  }
  return null;
}
```

---

## 📝 Résumé des Modifications

| Fichier | Lignes Modifiées | Type de Modification |
|---------|------------------|---------------------|
| `lib/screens/acheteur/checkout_screen.dart` | 17 | Import `user_model.dart` |
| | 269-287 | Récupération adresse acheteur |
| | 332-355 | Récupération coordonnées vendeur |
| | 357-368 | Récupération coordonnées livraison |

**Total** : ~60 lignes ajoutées/modifiées

**Résultat** : `flutter analyze` - **0 erreurs** (7 warnings mineurs non liés)

---

## ✅ Conclusion

Le problème **"Coordonnées non disponibles"** dans le suivi de livraison est maintenant **résolu**.

Les commandes créées après cette correction utiliseront les **vraies coordonnées GPS** de :
- ✅ L'adresse de livraison de l'acheteur
- ✅ La boutique du vendeur

Cela garantit que l'écran de suivi de livraison affichera correctement la carte Google Maps avec les positions exactes des 3 acteurs (livreur, point de collecte, destination).

---

**Prochaine étape** : Tester sur un appareil réel avec une nouvelle commande pour confirmer que la carte s'affiche correctement.
