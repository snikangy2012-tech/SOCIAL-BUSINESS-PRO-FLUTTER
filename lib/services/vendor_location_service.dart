// ===== lib/services/vendor_location_service.dart =====
// Service pour récupérer les coordonnées GPS de la boutique d'un vendeur
// Système HYBRIDE avec fallback

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class VendorLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer les coordonnées GPS du pickup (boutique du vendeur)
  ///
  /// SYSTÈME HYBRIDE avec 3 niveaux de fallback:
  /// 1. Utiliser businessLatitude/businessLongitude du profil vendeur si disponibles
  /// 2. Utiliser les coordonnées d'Abidjan (centre-ville) comme fallback
  /// 3. Retourner null si aucune coordonnée n'est disponible
  static Future<Map<String, double>?> getVendorPickupCoordinates(
    String vendeurId,
  ) async {
    try {
      debugPrint('📍 Récupération coordonnées pickup pour vendeur: $vendeurId');

      // Récupérer le profil du vendeur
      final vendorDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(vendeurId)
          .get();

      if (!vendorDoc.exists) {
        debugPrint('❌ Vendeur introuvable: $vendeurId');
        return null;
      }

      final vendorData = vendorDoc.data()!;
      final profile = vendorData['profile'] as Map<String, dynamic>?;

      // NIVEAU 1: Utiliser les coordonnées GPS configurées par le vendeur
      if (profile != null) {
        // ✅ Structure correcte: profile.vendeurProfile.businessLatitude/businessLongitude
        // (comme défini dans shop_setup_screen.dart)
        final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;

        if (vendeurProfile != null) {
          final businessLat = vendeurProfile['businessLatitude'] as num?;
          final businessLng = vendeurProfile['businessLongitude'] as num?;

          if (businessLat != null && businessLng != null) {
            debugPrint('✅ Coordonnées GPS boutique trouvées dans vendeurProfile: $businessLat, $businessLng');
            return {
              'latitude': businessLat.toDouble(),
              'longitude': businessLng.toDouble(),
            };
          }

          // Fallback: Essayer shopLocation si businessLatitude n'existe pas
          final shopLocation = vendeurProfile['shopLocation'] as Map<String, dynamic>?;
          if (shopLocation != null) {
            final lat = shopLocation['latitude'] as num?;
            final lng = shopLocation['longitude'] as num?;
            if (lat != null && lng != null) {
              debugPrint('✅ Coordonnées GPS boutique trouvées dans shopLocation: $lat, $lng');
              return {
                'latitude': lat.toDouble(),
                'longitude': lng.toDouble(),
              };
            }
          }
        }

        // Fallback sur profile direct (ancien système)
        final businessLat = profile['businessLatitude'] as num?;
        final businessLng = profile['businessLongitude'] as num?;

        if (businessLat != null && businessLng != null) {
          debugPrint('✅ Coordonnées GPS boutique trouvées dans profile direct: $businessLat, $businessLng');
          return {
            'latitude': businessLat.toDouble(),
            'longitude': businessLng.toDouble(),
          };
        }
      }

      // NIVEAU 2: Fallback sur coordonnées par défaut (centre d'Abidjan, Côte d'Ivoire)
      debugPrint('⚠️ Coordonnées GPS boutique non configurées, utilisation fallback Abidjan');
      return _getAbidjanCenterCoordinates();

    } catch (e) {
      debugPrint('❌ Erreur récupération coordonnées vendeur: $e');
      // En cas d'erreur, retourner coordonnées Abidjan comme fallback
      return _getAbidjanCenterCoordinates();
    }
  }

  /// Coordonnées du centre d'Abidjan (Place de la République)
  /// Utilisé comme fallback quand le vendeur n'a pas configuré sa position
  static Map<String, double> _getAbidjanCenterCoordinates() {
    return {
      'latitude': 5.316667,   // Place de la République, Abidjan
      'longitude': -4.033333,
    };
  }

  /// Vérifier si un vendeur a configuré ses coordonnées GPS
  static Future<bool> hasVendorConfiguredGPS(String vendeurId) async {
    try {
      final vendorDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(vendeurId)
          .get();

      if (!vendorDoc.exists) return false;

      final vendorData = vendorDoc.data()!;
      final profile = vendorData['profile'] as Map<String, dynamic>?;

      if (profile == null) return false;

      // ✅ Vérifier dans vendeurProfile (structure correcte)
      final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;
      if (vendeurProfile != null) {
        final businessLat = vendeurProfile['businessLatitude'] as num?;
        final businessLng = vendeurProfile['businessLongitude'] as num?;
        if (businessLat != null && businessLng != null) {
          return true;
        }

        // Vérifier aussi shopLocation
        final shopLocation = vendeurProfile['shopLocation'] as Map<String, dynamic>?;
        if (shopLocation != null) {
          final lat = shopLocation['latitude'] as num?;
          final lng = shopLocation['longitude'] as num?;
          if (lat != null && lng != null) {
            return true;
          }
        }
      }

      // Fallback: vérifier profile direct (ancien système)
      final businessLat = profile['businessLatitude'] as num?;
      final businessLng = profile['businessLongitude'] as num?;

      return businessLat != null && businessLng != null;
    } catch (e) {
      debugPrint('❌ Erreur vérification GPS vendeur: $e');
      return false;
    }
  }

  /// Mettre à jour les coordonnées GPS de la boutique du vendeur
  static Future<bool> updateVendorGPSCoordinates({
    required String vendeurId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('📍 Mise à jour coordonnées boutique vendeur $vendeurId: $latitude, $longitude');

      // ✅ Sauvegarder dans vendeurProfile (structure correcte comme shop_setup_screen)
      await _firestore.collection(FirebaseCollections.users).doc(vendeurId).update({
        'profile.vendeurProfile.businessLatitude': latitude,
        'profile.vendeurProfile.businessLongitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Coordonnées GPS boutique mises à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour coordonnées GPS: $e');
      return false;
    }
  }

  /// Récupérer les coordonnées de pickup pour une liste de vendeurs
  /// Utile pour optimiser les requêtes quand on a plusieurs vendeurs
  static Future<Map<String, Map<String, double>>> getBulkVendorPickupCoordinates(
    List<String> vendeurIds,
  ) async {
    final coordinates = <String, Map<String, double>>{};

    for (final vendeurId in vendeurIds) {
      final coords = await getVendorPickupCoordinates(vendeurId);
      if (coords != null) {
        coordinates[vendeurId] = coords;
      }
    }

    return coordinates;
  }
}
