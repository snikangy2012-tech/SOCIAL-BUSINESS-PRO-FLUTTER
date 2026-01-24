// ===== lib/services/places_autocomplete_service.dart =====
// Service d'autocomplétion d'adresses utilisant Google Places API
// Fournit des suggestions en temps réel comme Google Maps / Yango

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modèle pour une suggestion d'adresse
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting?['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting?['secondary_text'] ?? '',
    );
  }
}

/// Modèle pour les détails d'un lieu
class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final LatLng coordinates;
  final String? street;
  final String? locality;
  final String? administrativeArea;
  final String? country;

  PlaceDetails({
    required this.placeId,
    required this.formattedAddress,
    required this.coordinates,
    this.street,
    this.locality,
    this.administrativeArea,
    this.country,
  });
}

/// Service d'autocomplétion d'adresses avec Google Places API
class PlacesAutocompleteService {
  // Clé API Google Maps (la même que pour Maps et Directions)
  static const String _apiKey = 'AIzaSyD4E1-9kiFXjYwOMOp0csfheJxvqEo9joc';

  // URL de base pour l'API Places
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  // Configuration pour la Côte d'Ivoire
  static const String _countryCode = 'ci'; // Côte d'Ivoire
  static const String _language = 'fr';

  // Centre d'Abidjan pour la pondération des résultats
  static const double _abidjanLat = 5.3167;
  static const double _abidjanLng = -4.0333;
  static const int _radiusMeters = 50000; // 50km autour d'Abidjan

  /// Obtenir des suggestions d'adresses en temps réel
  ///
  /// [query] - Le texte saisi par l'utilisateur
  /// [sessionToken] - Token de session pour regrouper les requêtes (optionnel)
  static Future<List<PlaceSuggestion>> getAutocomplete(
    String query, {
    String? sessionToken,
  }) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
        'input': query,
        'key': _apiKey,
        'language': _language,
        'components': 'country:$_countryCode',
        'location': '$_abidjanLat,$_abidjanLng',
        'radius': _radiusMeters.toString(),
        'strictbounds': 'false', // Permettre des résultats hors du rayon
        if (sessionToken != null) 'sessiontoken': sessionToken,
      });

      debugPrint('🔍 Places Autocomplete: $query');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions
              .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
              .toList();

          debugPrint('✅ ${suggestions.length} suggestions trouvées');
          return suggestions;
        } else if (data['status'] == 'ZERO_RESULTS') {
          debugPrint('⚠️ Aucun résultat pour: $query');
          return [];
        } else if (data['status'] == 'REQUEST_DENIED') {
          debugPrint('❌ API Places non activée ou clé invalide');
          throw Exception('API Places non activée. Vérifiez la clé API.');
        } else {
          debugPrint('❌ Erreur API: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur autocomplétion: $e');
      return [];
    }
  }

  /// Obtenir les détails d'un lieu (coordonnées GPS, adresse complète, etc.)
  ///
  /// [placeId] - L'ID du lieu obtenu depuis les suggestions
  /// [sessionToken] - Le même token de session utilisé pour l'autocomplétion
  static Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      final uri = Uri.parse(_placeDetailsUrl).replace(queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'language': _language,
        'fields': 'place_id,formatted_address,geometry,address_components',
        if (sessionToken != null) 'sessiontoken': sessionToken,
      });

      debugPrint('📍 Récupération détails pour placeId: $placeId');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>;
          final location = geometry['location'] as Map<String, dynamic>;
          final addressComponents = result['address_components'] as List?;

          // Extraire les composants de l'adresse
          String? street;
          String? locality;
          String? administrativeArea;
          String? country;

          if (addressComponents != null) {
            for (final component in addressComponents) {
              final types = (component['types'] as List).cast<String>();
              final longName = component['long_name'] as String?;

              if (types.contains('route') || types.contains('street_address')) {
                street = longName;
              } else if (types.contains('locality') || types.contains('sublocality')) {
                locality = longName;
              } else if (types.contains('administrative_area_level_1')) {
                administrativeArea = longName;
              } else if (types.contains('country')) {
                country = longName;
              }
            }
          }

          final details = PlaceDetails(
            placeId: placeId,
            formattedAddress: result['formatted_address'] ?? '',
            coordinates: LatLng(
              (location['lat'] as num).toDouble(),
              (location['lng'] as num).toDouble(),
            ),
            street: street,
            locality: locality,
            administrativeArea: administrativeArea,
            country: country,
          );

          debugPrint('✅ Détails récupérés: ${details.formattedAddress}');
          debugPrint('   GPS: ${details.coordinates.latitude}, ${details.coordinates.longitude}');

          return details;
        } else {
          debugPrint('❌ Erreur API détails: ${data['status']}');
          return null;
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération détails: $e');
      return null;
    }
  }

  /// Générer un token de session unique pour regrouper les requêtes
  /// (Optimise la facturation Google - 1 session = 1 requête facturée)
  static String generateSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
