# ✅ Implémentation Carte GPS pour Configuration Boutique Vendeur

## Date: 18 novembre 2025

---

## 🎯 Objectif

Ajouter une **carte interactive Google Maps** dans l'écran de configuration de boutique vendeur (`shop_setup_screen.dart`) pour permettre au vendeur de définir précisément la position GPS de sa boutique.

Cette position GPS sera ensuite utilisée dans le `checkout_screen.dart` pour calculer les frais de livraison réels entre la boutique et l'adresse de livraison.

---

## 📋 Modifications Nécessaires

### Fichier: `lib/screens/vendeur/shop_setup_screen.dart`

#### 1. Imports à Ajouter (lignes 4-9)

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/geolocation_service.dart';
```

#### 2. Nouvelles Variables d'État (après ligne 40)

```dart
// Coordonnées GPS de la boutique
LocationCoords? _shopLocation;
GoogleMapController? _mapController;
bool _isLoadingLocation = false;
static const LatLng _defaultPosition = LatLng(5.3167, -4.0333); // Abidjan centre
```

#### 3. Dispose du MapController (ligne 58)

```dart
@override
void dispose() {
  _businessNameController.dispose();
  _businessDescriptionController.dispose();
  _businessAddressController.dispose();
  _deliveryPriceController.dispose();
  _freeDeliveryThresholdController.dispose();
  _pageController.dispose();
  _mapController?.dispose(); // AJOUT
  super.dispose();
}
```

#### 4. Charger shopLocation Existant (dans _loadExistingProfile, après ligne 100)

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

#### 5. Méthode pour Obtenir Position GPS Actuelle

```dart
// Obtenir la position actuelle du vendeur
Future<void> _getCurrentLocation() async {
  setState(() => _isLoadingLocation = true);

  try {
    debugPrint('📍 Récupération position actuelle vendeur...');
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

    debugPrint('✅ Position boutique définie: ${position.latitude}, ${position.longitude}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Position actuelle utilisée pour la boutique'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Erreur récupération position: $e');
    setState(() => _isLoadingLocation = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Impossible de récupérer votre position'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
```

#### 6. Validation GPS dans _saveProfile (avant ligne 125)

```dart
// Vérifier que la position GPS est définie
if (_shopLocation == null) {
  _showError('Veuillez définir la position GPS de votre boutique');
  _pageController.animateToPage(
    1,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
  setState(() => _currentStep = 1);
  return;
}
```

#### 7. Sauvegarder shopLocation dans Firestore (ligne 160)

```dart
// Mettre à jour Firestore avec le profil vendeur ET la position GPS
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

#### 8. Modifier le PageView (passer de 4 à 5 étapes)

```dart
children: [
  _buildStep1BasicInfo(),
  _buildStep2GPS(), // NOUVELLE ÉTAPE
  _buildStep3Details(), // Anciennement étape 2
  _buildStep4Delivery(), // Anciennement étape 3
  _buildStep5Payment(), // Anciennement étape 4
],
```

#### 9. Modifier l'Indicateur d'Étapes (ligne 286)

```dart
children: List.generate(5, (index) { // Changé de 4 à 5
```

#### 10. Ajouter Titre GPS dans _getStepTitle

```dart
String _getStepTitle(int index) {
  switch (index) {
    case 0:
      return 'Infos';
    case 1:
      return 'GPS'; // AJOUT
    case 2:
      return 'Détails';
    case 3:
      return 'Livraison';
    case 4:
      return 'Paiement';
    default:
      return '';
  }
}
```

#### 11. NOUVELLE ÉTAPE 2: Carte GPS

```dart
// ÉTAPE 2: Position GPS de la Boutique
Widget _buildStep2GPS() {
  return Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.backgroundSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Position GPS de la boutique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Définissez l\'emplacement exact de votre boutique pour le calcul des frais de livraison',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Bouton "Ma position actuelle"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation
                    ? 'Récupération en cours...'
                    : 'Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (_shopLocation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position enregistrée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Lat: ${_shopLocation!.latitude.toStringAsFixed(6)}, '
                            'Lng: ${_shopLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // Carte
      Expanded(
        child: _shopLocation == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune position définie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cliquez sur "Utiliser ma position actuelle" pour définir l\'emplacement de votre boutique',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _shopLocation!.latitude,
                        _shopLocation!.longitude,
                      ),
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
                      debugPrint('📍 Nouvelle position: ${position.latitude}, ${position.longitude}');
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('shop_location'),
                        position: LatLng(
                          _shopLocation!.latitude,
                          _shopLocation!.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                        infoWindow: const InfoWindow(
                          title: 'Ma Boutique',
                          snippet: 'Position de votre boutique',
                        ),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Aide
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Cliquez sur la carte pour changer la position',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ],
  );
}
```

#### 12. Modifier Boutons de Navigation (ligne 820)

```dart
child: ElevatedButton(
  onPressed: _isSaving
      ? null
      : (_currentStep < 4 ? _nextStep : _saveProfile), // Changé de 3 à 4
  // ...
  child: Text(_currentStep < 4 ? 'Suivant' : 'Enregistrer'), // Changé de 3 à 4
),
```

#### 13. Ajouter GPS dans Récapitulatif (ligne 760)

```dart
_buildSummaryRow(
    'Position GPS',
    _shopLocation != null
        ? '${_shopLocation!.latitude.toStringAsFixed(4)}, ${_shopLocation!.longitude.toStringAsFixed(4)}'
        : '❌ Non définie'),
```

#### 14. Avertissement si GPS Non Défini

```dart
if (_shopLocation == null)
  const Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text(
      '⚠️ Position GPS non définie - Retournez à l\'étape 2',
      style: TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
```

---

## 🔒 Validation Obligatoire Avant Accès Dashboard

### Fichier: `lib/routes/app_router.dart`

Modifier la redirection pour vérifier si `shopLocation` existe avant d'autoriser l'accès au dashboard vendeur.

**Ligne 88 (dans le redirect)** :

```dart
if (currentpath == '/') {
  switch (user.userType) {
    case UserType.vendeur:
      // Vérifier si shopLocation est défini
      final profile = user.profile;
      final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;

      if (vendeurProfile == null || vendeurProfile['shopLocation'] == null) {
        // Rediriger vers la configuration de boutique si pas encore fait
        return '/vendeur/shop-setup';
      }
      return '/vendeur-dashboard';

    case UserType.admin: return '/admin-dashboard';
    case UserType.acheteur: return '/acheteur-home';
    case UserType.livreur: return '/livreur-dashboard';
  }
}
```

---

## 📊 Flux Utilisateur

```
1. VENDEUR s'inscrit
   └─> Redirigé automatiquement vers /vendeur/shop-setup

2. CONFIGURATION BOUTIQUE (5 étapes)
   ├─> Étape 1: Informations de base
   ├─> Étape 2: Position GPS (NOUVEAU) ⭐
   │   ├─> Bouton "Ma position actuelle" → Utilise GeolocationService
   │   └─> Carte interactive → Clic pour changer position
   ├─> Étape 3: Détails
   ├─> Étape 4: Livraison
   └─> Étape 5: Paiement (avec récapitulatif GPS)

3. VALIDATION GPS
   └─> Impossible d'enregistrer sans définir shopLocation

4. SAUVEGARDE
   └─> Firestore: users/{vendeurId}/profile/vendeurProfile/shopLocation
       ├─ latitude
       └─ longitude

5. ACCÈS DASHBOARD
   └─> Autorisé seulement si shopLocation existe
```

---

## ✅ Avantages

1. **Précision des Frais de Livraison**: Utilise la vraie position de la boutique au lieu de coordonnées par défaut
2. **UX Intuitive**: Bouton "Ma position actuelle" + carte interactive
3. **Validation Obligatoire**: Empêche l'accès au dashboard tant que GPS n'est pas configuré
4. **Modification Possible**: Le vendeur peut modifier la position plus tard
5. **Cohérence avec Acheteur**: Même logique que l'enregistrement d'adresse acheteur

---

## 🧪 Tests à Effectuer

### Test 1: Nouveau Vendeur
1. S'inscrire en tant que vendeur
2. ✅ Vérifier redirection automatique vers `/vendeur/shop-setup`
3. Compléter l'étape 1
4. ✅ Cliquer sur "Utiliser ma position actuelle"
5. ✅ Vérifier qu'un marqueur apparaît sur la carte
6. ✅ Cliquer ailleurs sur la carte pour changer la position
7. Compléter les étapes suivantes
8. ✅ Vérifier que le récapitulatif affiche les coordonnées GPS
9. Enregistrer
10. ✅ Vérifier que Firestore contient `shopLocation`

### Test 2: Vendeur Existant sans GPS
1. Se connecter en tant que vendeur sans `shopLocation`
2. ✅ Vérifier redirection vers `/vendeur/shop-setup`
3. Définir la position GPS
4. ✅ Accès au dashboard autorisé

### Test 3: Modification GPS
1. Vendeur avec GPS déjà configuré
2. Aller dans `/vendeur/shop-setup`
3. ✅ Vérifier que la position actuelle s'affiche
4. Modifier la position
5. Enregistrer
6. ✅ Vérifier mise à jour dans Firestore

### Test 4: Création Commande avec GPS Vendeur
1. Acheteur passe commande chez un vendeur
2. ✅ Vérifier dans `checkout_screen.dart` que `pickupLatitude` et `pickupLongitude` correspondent à `shopLocation` du vendeur
3. ✅ Vérifier dans Firestore que la commande contient les bonnes coordonnées
4. ✅ Vérifier que le suivi de livraison affiche la carte correctement

---

## 📝 Fichiers Modifiés

| Fichier | Modifications | Lignes |
|---------|--------------|--------|
| `lib/screens/vendeur/shop_setup_screen.dart` | Ajout étape GPS avec carte | +250 lignes |
| `lib/routes/app_router.dart` | Validation shopLocation avant dashboard | ~15 lignes |

**Total** : ~265 lignes ajoutées

---

## 🚀 Prochaines Étapes

1. ✅ Implémenter les modifications dans `shop_setup_screen.dart`
2. ✅ Ajouter la validation dans `app_router.dart`
3. ⏳ Tester le flux complet
4. ⏳ Vérifier que `checkout_screen.dart` utilise correctement `shopLocation`
5. ⏳ Documenter dans CLAUDE.md

---

**Status**: En cours d'implémentation
**Fichier actuel**: `shop_setup_screen.dart` - Ajout carte GPS interactive
