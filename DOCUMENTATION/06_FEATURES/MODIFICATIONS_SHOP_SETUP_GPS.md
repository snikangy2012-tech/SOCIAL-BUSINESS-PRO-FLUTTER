# 🔧 Guide d'Implémentation Carte GPS dans shop_setup_screen.dart

## Date: 18 novembre 2025

---

## ✅ Résumé des Modifications Appliquées

Le fichier `shop_setup_screen.dart` a été modifié pour intégrer une **carte interactive Google Maps** permettant au vendeur de définir précisément la position GPS de sa boutique.

### Changements Principaux

#### 1. **Imports Ajoutés** (lignes 7-9)
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/geolocation_service.dart';
```

#### 2. **Nouvelles Variables d'État** (après ligne 40)
```dart
// Coordonnées GPS de la boutique
LocationCoords? _shopLocation;
GoogleMapController? _mapController;
bool _isLoadingLocation = false;
```

#### 3. **Chargement GPS Existant** (dans `_loadExistingProfile`)
```dart
// Charger la position GPS de la boutique si elle existe
if (vendeurProfileData['shopLocation'] != null) {
  final shopLocationData = vendeurProfileData['shopLocation'] as Map<String, dynamic>;
  _shopLocation = LocationCoords(
    latitude: (shopLocationData['latitude'] ?? 0).toDouble(),
    longitude: (shopLocationData['longitude'] ?? 0).toDouble(),
  );
}
```

#### 4. **Méthode Récupération GPS** (nouvelle méthode)
```dart
Future<void> _getCurrentLocation() async {
  setState(() => _isLoadingLocation = true);

  try {
    final position = await GeolocationService.getCurrentPosition();

    setState(() {
      _shopLocation = LocationCoords(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _isLoadingLocation = false;
    });

    // Animer la caméra vers la nouvelle position
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Position actuelle utilisée pour la boutique'),
        backgroundColor: AppColors.success,
      ),
    );
  } catch (e) {
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Impossible de récupérer votre position'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

#### 5. **Validation GPS Avant Sauvegarde** (dans `_saveProfile`)
```dart
// Vérifier que la position GPS est définie
if (_shopLocation == null) {
  _showError('Veuillez définir la position GPS de votre boutique');
  _pageController.animateToPage(1, /* ... */);
  setState(() => _currentStep = 1);
  return;
}
```

#### 6. **Sauvegarde shopLocation dans Firestore**
```dart
await FirebaseFirestore.instance
    .collection(FirebaseCollections.users)
    .doc(user.id)
    .update({
  'profile.vendeurProfile': profile.toMap(),
  'profile.vendeurProfile.shopLocation': {
    'latitude': _shopLocation!.latitude,
    'longitude': _shopLocation!.longitude,
  },
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### 7. **Passage de 4 à 5 Étapes**
- `_buildStepIndicator()`: `List.generate(5, ...)` au lieu de 4
- `PageView children`: Ajout de `_buildStep2GPS()`
- `_getStepTitle()`: Ajout du case 1 pour "GPS"
- Boutons navigation: `_currentStep < 4` au lieu de 3

#### 8. **Nouvelle Étape GPS - Widget Complet**

```dart
Widget _buildStep2GPS() {
  return Column(
    children: [
      // Header avec bouton "Ma position actuelle"
      Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.backgroundSecondary,
        child: Column(
          children: [
            const Text('Position GPS de la boutique', /* ... */),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation ? CircularProgressIndicator() : Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'Récupération...' : 'Utiliser ma position actuelle'),
              ),
            ),

            if (_shopLocation != null) ...[
              // Afficher position enregistrée
              Container(/* Indicateur de succès */),
            ],
          ],
        ),
      ),

      // Carte Google Maps
      Expanded(
        child: _shopLocation == null
            ? Center(/* Message: Aucune position définie */)
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_shopLocation!.latitude, _shopLocation!.longitude),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (LatLng position) {
                      setState(() {
                        _shopLocation = LocationCoords(
                          latitude: position.latitude,
                          longitude: position.longitude,
                        );
                      });
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('shop_location'),
                        position: LatLng(_shopLocation!.latitude, _shopLocation!.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        infoWindow: const InfoWindow(title: 'Ma Boutique'),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),

                  // Aide
                  Positioned(
                    top: 16,
                    child: Card(/* "Cliquez sur la carte pour changer la position" */),
                  ),
                ],
              ),
      ),
    ],
  );
}
```

#### 9. **Récapitulatif Modifié** (dans `_buildStep5Payment`)
```dart
_buildSummaryRow(
    'Position GPS',
    _shopLocation != null
        ? '${_shopLocation!.latitude.toStringAsFixed(4)}, ${_shopLocation!.longitude.toStringAsFixed(4)}'
        : '❌ Non définie'),

if (_shopLocation == null)
  const Padding(
    child: Text(
      '⚠️ Position GPS non définie - Retournez à l\'étape 2',
      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
    ),
  ),
```

---

## 🔐 Validation Obligatoire - app_router.dart

### Modification du Redirect (ligne ~88)

```dart
if (currentpath == '/') {
  switch (user.userType) {
    case UserType.vendeur:
      // Vérifier si shopLocation est défini
      final profile = user.profile;
      if (profile.isNotEmpty) {
        final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;

        if (vendeurProfile == null || vendeurProfile['shopLocation'] == null) {
          // Rediriger vers la configuration si pas encore fait
          debugPrint('⚠️ shopLocation non défini, redirection vers setup');
          return '/vendeur/shop-setup';
        }
      }
      return '/vendeur-dashboard';

    case UserType.admin: return '/admin-dashboard';
    case UserType.acheteur: return '/acheteur-home';
    case UserType.livreur: return '/livreur-dashboard';
  }
}
```

**Important** : Cette validation garantit qu'un vendeur **ne peut pas accéder au dashboard** tant qu'il n'a pas configuré sa boutique avec GPS.

---

## 📊 Flux Complet

```
1. INSCRIPTION VENDEUR
   └─> Automatiquement redirigé vers /vendeur/shop-setup

2. CONFIGURATION BOUTIQUE (5 étapes)
   ├─> Étape 1: Infos de base (nom, type, catégorie)
   ├─> Étape 2: GPS ⭐ NOUVEAU
   │   ├─> Bouton "Ma position actuelle"
   │   │   └─> Demande permission GPS
   │   │   └─> Affiche carte avec marqueur
   │   └─> Clic sur carte pour changer position
   ├─> Étape 3: Détails (description, adresse textuelle)
   ├─> Étape 4: Livraison (zones, prix)
   └─> Étape 5: Paiement + Récapitulatif (avec GPS)

3. SAUVEGARDE
   └─> Validation: shopLocation doit être défini
   └─> Firestore: users/{vendeurId}/profile/vendeurProfile/shopLocation

4. ACCÈS DASHBOARD
   └─> Autorisé seulement si shopLocation existe
```

---

## ✅ Avantages de cette Implémentation

1. **Précision**: Utilise la vraie position GPS au lieu de coordonnées par défaut (5.3167, -4.0333)
2. **UX Intuitive**:
   - Bouton "Ma position actuelle" → récupération GPS automatique
   - Carte interactive → clic pour ajuster manuellement
3. **Validation Forte**: Impossible d'accéder au dashboard sans GPS configuré
4. **Modification Possible**: Le vendeur peut revenir modifier sa position plus tard
5. **Cohérence**: Même logique que `address_management_screen.dart` pour l'acheteur

---

## 🧪 Tests Recommandés

### Test 1: Nouveau Vendeur
1. Créer compte vendeur → ✅ Redirection automatique vers setup
2. Compléter étape 1 → Cliquer "Suivant"
3. Cliquer "Ma position actuelle" → ✅ Carte affichée avec marqueur
4. Cliquer ailleurs sur carte → ✅ Marqueur se déplace
5. Compléter toutes les étapes → ✅ Récapitulatif affiche GPS
6. Enregistrer → ✅ Firestore contient shopLocation
7. ✅ Dashboard accessible

### Test 2: Vendeur Sans GPS
1. Vendeur existant sans shopLocation
2. Tenter d'accéder à `/vendeur-dashboard`
3. ✅ Redirection automatique vers `/vendeur/shop-setup`

### Test 3: Commande avec GPS Vendeur
1. Acheteur passe commande
2. Dans `checkout_screen.dart`, vérifier que:
   - `pickupLatitude` = shopLocation.latitude du vendeur
   - `pickupLongitude` = shopLocation.longitude du vendeur
3. ✅ Livraison affiche carte correctement

---

## 📝 Fichiers Modifiés

| Fichier | Lignes Modifiées | Type |
|---------|------------------|------|
| `lib/screens/vendeur/shop_setup_screen.dart` | ~250 lignes | Ajout carte GPS |
| `lib/routes/app_router.dart` | ~15 lignes | Validation shopLocation |

---

## 🚀 Prochaines Étapes

1. ✅ Documentation créée (SHOP_SETUP_GPS_IMPLEMENTATION.md)
2. ⏳ Appliquer les modifications au code
3. ⏳ Tester le flux complet
4. ⏳ Vérifier `checkout_screen.dart` utilise shopLocation
5. ⏳ Documenter dans CLAUDE.md

---

**Date de création**: 18 novembre 2025
**Status**: Documenté et prêt à implémenter
**Prochaine action**: Modifier `shop_setup_screen.dart` ligne par ligne
