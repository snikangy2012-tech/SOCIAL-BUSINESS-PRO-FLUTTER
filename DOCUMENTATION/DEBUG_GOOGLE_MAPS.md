# 🗺️ Guide de Debug - Google Maps dans Address Management

**Date:** 13 Novembre 2025
**Problème:** La fenêtre popup pour la carte n'apparaît pas dans l'écran de gestion des adresses

---

## 🔍 Diagnostic du Problème

### Étape 1: Vérifier si le BottomSheet s'affiche

**Test:**
1. Allez dans l'écran "Mes adresses" (`/acheteur/addresses`)
2. Cliquez sur "+ Ajouter une adresse"

**Comportements possibles:**

#### Cas A: Rien ne se passe
**Symptôme:** Le bouton ne réagit pas, aucune popup n'apparaît

**Cause probable:** Erreur dans la méthode `_addOrEditAddress()`

**Solution:** Vérifiez la console pour voir les erreurs

#### Cas B: BottomSheet apparaît mais est vide/erreur
**Symptôme:** Une popup blanche ou avec erreur s'affiche

**Cause probable:** Erreur dans le widget `AddressFormSheet`

**Solution:** Vérifiez la console pour stack trace

#### Cas C: BottomSheet apparaît avec les 3 onglets
**Symptôme:** Vous voyez "Adresse", "Carte", "GPS" en haut

**Continuez à l'Étape 2**

---

### Étape 2: Vérifier l'onglet Carte

**Test:**
1. Cliquez sur l'onglet "Carte" (icône 🗺️)

**Comportements possibles:**

#### Cas A: Écran gris avec "Aucune position sélectionnée"
**C'est NORMAL !** La carte attend que vous définissiez une position.

**Solutions:**
1. Cliquez sur "Ma position actuelle" → La carte devrait charger votre position
2. Ou allez dans l'onglet "GPS" → Saisissez des coordonnées manuellement

#### Cas B: Carte Google Maps s'affiche mais est grise/vide
**Symptôme:** Vous voyez le logo Google Maps mais la carte est grise

**Cause:** Problème de clé API Google Maps

**Solutions:**
1. Vérifiez que la clé API est active dans Google Cloud Console
2. Vérifiez que l'API "Maps SDK for Android" est activée
3. Vérifiez que la clé n'a pas de restrictions d'IP

#### Cas C: Erreur "Google Maps not loaded"
**Symptôme:** Message d'erreur dans la carte

**Cause:** Package `google_maps_flutter` mal configuré

**Solution:** Vérifiez `pubspec.yaml` et réinstallez les dépendances

---

### Étape 3: Vérifier les permissions de localisation

**Sur Android:**
```bash
adb shell pm list permissions -g | findstr LOCATION
```

**Permissions requises dans AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

✅ **Ces permissions sont DÉJÀ configurées** (lignes 12-13 du AndroidManifest.xml)

---

## 🔧 Solutions par Problème

### Problème 1: BottomSheet ne s'affiche pas

**Vérification du code:**

```dart
// Ligne 76-82 de address_management_screen.dart
Future<void> _addOrEditAddress({Address? existingAddress}) async {
  final result = await showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddressFormSheet(address: existingAddress),
  );
  // ...
}
```

**Test dans la console:**
```dart
// Ajoutez ce debug print au début de _addOrEditAddress
debugPrint('🔧 DEBUG: _addOrEditAddress called');
```

**Si rien ne s'affiche dans la console:**
→ Le bouton n'appelle pas la méthode

**Si le debug s'affiche mais pas de popup:**
→ Erreur dans `AddressFormSheet`

---

### Problème 2: Google Maps ne charge pas

**Clé API Google Maps actuelle:**
```
AIzaSyD4E1-9kiFXjYwOMOp0csfheJxvqEo9joc
```

**Vérifications Google Cloud Console:**

1. **Allez sur:** https://console.cloud.google.com/
2. **Projet:** `social-media-business-pro`
3. **APIs & Services → Credentials**
4. **Vérifiez que cette clé existe et est active**

**APIs à activer:**
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS (si déploiement iOS)
- ✅ Maps JavaScript API (pour Web)
- ✅ Geocoding API (pour recherche d'adresse)
- ✅ Places API (optionnel, pour autocomplétion)

**Quota et facturation:**
- Vérifiez que le quota n'est pas dépassé
- Vérifiez que la facturation est activée (Google Maps nécessite un compte avec CB)

---

### Problème 3: Permission de localisation refusée

**Symptôme:** Message "Permission de localisation refusée"

**Code de gestion (lignes 434-454):**
```dart
Future<void> _getCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Affiche un message explicatif
      ScaffoldMessenger.of(context).showSnackBar(...);
      return;
    }
    // ...
  }
}
```

**Solution utilisateur:**
1. Paramètres Android → Applications → Social Business Pro
2. Permissions → Localisation → Autoriser
3. Redémarrez l'app

---

### Problème 4: Recherche d'adresse ne fonctionne pas

**Package utilisé:** `geocoding`

**Méthode de recherche (lignes 526-634):**
```dart
Future<void> _searchAddress() async {
  final query = _searchController.text.trim();

  // Ajoute "Abidjan, Côte d'Ivoire" automatiquement
  final searchQuery = query.toLowerCase().contains('abidjan')
      ? query
      : '$query, Abidjan, Côte d\'Ivoire';

  final locations = await locationFromAddress(searchQuery);
  // ...
}
```

**Test manuel:**
1. Dans l'onglet "Carte"
2. Saisissez: "Cocody Riviera"
3. Cliquez "Rechercher"

**Résultat attendu:**
- La carte se centre sur Cocody
- Les coordonnées s'affichent
- Le marqueur apparaît

**Si erreur:**
→ Vérifiez que l'API "Geocoding API" est activée dans Google Cloud

---

## 🧪 Tests Manuels Recommandés

### Test 1: Ajouter une adresse sans GPS
1. Cliquez "+ Ajouter"
2. Onglet "Adresse"
3. Remplissez:
   - Libellé: "Test Domicile"
   - Rue: "Cocody Riviera Golf"
   - Commune: "Cocody"
   - Ville: "Abidjan"
4. Cliquez "Sauvegarder"

**Résultat attendu:**
- ✅ Adresse enregistrée (mais sans position GPS)
- ⚠️ Message orange "Utilisez l'onglet Carte ou GPS"

---

### Test 2: Ajouter position GPS manuellement
1. Cliquez "+ Ajouter"
2. Onglet "GPS"
3. Saisissez:
   - Latitude: `5.347850`
   - Longitude: `-3.987284`
4. Cliquez "Valider les coordonnées"
5. Retour onglet "Adresse"
6. Vérifiez le message vert "Position GPS enregistrée"

**Résultat attendu:**
- ✅ Coordonnées valides
- ✅ Message vert s'affiche
- ✅ Peut sauvegarder l'adresse

---

### Test 3: Utiliser "Ma position actuelle"
**Prérequis:**
- Permission de localisation accordée
- GPS activé sur l'appareil

1. Cliquez "+ Ajouter"
2. Onglet "Carte" ou "GPS"
3. Cliquez "Ma position actuelle"

**Résultat attendu:**
- ✅ Message "Position actuelle récupérée"
- ✅ Coordonnées remplies automatiquement
- ✅ Carte centrée sur votre position (si onglet Carte)

---

### Test 4: Rechercher une adresse
1. Cliquez "+ Ajouter"
2. Onglet "Carte"
3. Dans la barre de recherche en haut:
   - Tapez: "Plateau"
4. Cliquez "Rechercher"

**Résultat attendu:**
- ✅ Carte se centre sur le Plateau
- ✅ Coordonnées: ~5.319447, -4.012869
- ✅ Champs d'adresse remplis automatiquement

---

### Test 5: Déplacer le marqueur sur la carte
**Prérequis:** Position GPS déjà définie

1. Allez dans l'onglet "Carte"
2. Appuyez longuement sur le marqueur rouge
3. Glissez-le vers une autre position
4. Relâchez

**Résultat attendu:**
- ✅ Message "📍 Position mise à jour"
- ✅ Coordonnées mises à jour
- ✅ Adresse récupérée automatiquement

---

## 📊 Logs de Debug Utiles

**Ajoutez ces debug prints pour diagnostiquer:**

### Dans `_addOrEditAddress()`:
```dart
Future<void> _addOrEditAddress({Address? existingAddress}) async {
  debugPrint('🔧 DEBUG: Ouverture formulaire adresse');
  debugPrint('🔧 Mode: ${existingAddress == null ? "Nouvelle" : "Modification"}');

  final result = await showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddressFormSheet(address: existingAddress),
  );

  debugPrint('🔧 DEBUG: Résultat formulaire: ${result != null ? "Valide" : "Annulé"}');
  // ...
}
```

### Dans `_getCurrentLocation()`:
```dart
Future<void> _getCurrentLocation() async {
  debugPrint('📍 DEBUG: Demande de localisation');

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 Permission actuelle: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('📍 Demande de permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('📍 Permission après demande: $permission');
    }
    // ...
  } catch (e) {
    debugPrint('❌ Erreur géolocalisation: $e');
  }
}
```

### Dans `_searchAddress()`:
```dart
Future<void> _searchAddress() async {
  final query = _searchController.text.trim();
  debugPrint('🔍 DEBUG: Recherche adresse: "$query"');

  try {
    final searchQuery = query.toLowerCase().contains('abidjan')
        ? query
        : '$query, Abidjan, Côte d\'Ivoire';

    debugPrint('🔍 Query complète: "$searchQuery"');

    final locations = await locationFromAddress(searchQuery);
    debugPrint('🔍 Résultats trouvés: ${locations.length}');

    if (locations.isNotEmpty) {
      final location = locations.first;
      debugPrint('🔍 Position: ${location.latitude}, ${location.longitude}');
    }
  } catch (e) {
    debugPrint('❌ Erreur recherche: $e');
  }
}
```

---

## ✅ Checklist de Vérification

### Configuration
- [ ] Clé Google Maps présente dans `AndroidManifest.xml` (ligne 29-31)
- [ ] Permissions localisation dans `AndroidManifest.xml` (lignes 12-14)
- [ ] Package `google_maps_flutter` dans `pubspec.yaml`
- [ ] Package `geolocator` dans `pubspec.yaml`
- [ ] Package `geocoding` dans `pubspec.yaml`

### Google Cloud Console
- [ ] Projet `social-media-business-pro` existe
- [ ] Clé API `AIzaSyD4E1-9kiFXjYwOMOp0csfheJxvqEo9joc` active
- [ ] API "Maps SDK for Android" activée
- [ ] API "Geocoding API" activée
- [ ] Facturation activée (obligatoire pour Google Maps)
- [ ] Quota non dépassé

### Permissions App (Android)
- [ ] Permission "Localisation" accordée
- [ ] GPS activé sur l'appareil
- [ ] Internet activé

### Tests Fonctionnels
- [ ] BottomSheet s'affiche au clic sur "+ Ajouter"
- [ ] Onglets "Adresse", "Carte", "GPS" visibles
- [ ] Formulaire d'adresse fonctionnel
- [ ] Carte Google Maps s'affiche (ou message "Aucune position")
- [ ] Bouton "Ma position actuelle" fonctionne
- [ ] Recherche d'adresse fonctionne
- [ ] Saisie manuelle GPS fonctionne
- [ ] Sauvegarde d'adresse fonctionne

---

## 🚨 Erreurs Courantes et Solutions

### Erreur 1: "This application has exceeded its quota"
**Cause:** Quota Google Maps dépassé

**Solution:**
1. Google Cloud Console → Billing
2. Vérifier l'utilisation
3. Augmenter le quota si nécessaire
4. Ou activer la facturation

---

### Erreur 2: "API key not valid"
**Cause:** Clé API invalide ou restrictions activées

**Solution:**
1. Google Cloud Console → Credentials
2. Modifier la clé API
3. Vérifier "Application restrictions" → Aucune restriction
4. Ou ajouter le package name: `ci.socialbusinesspro.social_media_business_pro`

---

### Erreur 3: "Unable to get current location"
**Cause:** Permission refusée ou GPS désactivé

**Solution:**
1. Paramètres → Applications → Social Business Pro → Permissions
2. Autoriser "Localisation"
3. Activer le GPS de l'appareil
4. Redémarrer l'app

---

### Erreur 4: "Address not found"
**Cause:** Adresse trop vague ou hors Côte d'Ivoire

**Solution:**
- Soyez plus précis: "Cocody Riviera Golf" au lieu de "Cocody"
- Le code ajoute automatiquement ", Abidjan, Côte d'Ivoire"
- Essayez avec des lieux connus: "Plateau", "Yopougon", etc.

---

## 📝 Commandes de Debug

### Vérifier les permissions sur Android
```bash
adb shell dumpsys package ci.socialbusinesspro.social_media_business_pro | findstr permission
```

### Voir les logs en temps réel
```bash
flutter run --verbose
```

### Filtrer les logs Google Maps
```bash
adb logcat | findstr "GoogleMap"
```

### Tester la clé API manuellement
```bash
curl "https://maps.googleapis.com/maps/api/geocode/json?address=Abidjan&key=AIzaSyD4E1-9kiFXjYwOMOp0csfheJxvqEo9joc"
```

---

## 🎯 Prochaines Étapes

1. **Testez manuellement** l'écran avec les tests ci-dessus
2. **Notez le comportement exact** du problème
3. **Vérifiez la console** pour les erreurs
4. **Partagez les logs** pour diagnostic précis

---

**Dernière mise à jour:** 13 Novembre 2025
**Statut:** Guide de diagnostic complet
**Fichier source:** `lib/screens/acheteur/address_management_screen.dart`
