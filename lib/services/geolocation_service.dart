// ===== lib/services/geolocation_service.dart =====
// Service de géolocalisation - SOCIAL BUSINESS Pro

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Service de géolocalisation pour tracking des livreurs
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  /// Vérifier si les services de localisation sont activés
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Vérifier et demander les permissions de localisation
  static Future<LocationPermission> checkAndRequestPermission() async {
    debugPrint('🌍 Vérification permissions localisation...');

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 Permission actuelle: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('⚠️ Permission refusée, demande en cours...');
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permission refusée par l\'utilisateur');
        throw Exception('Les permissions de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission refusée définitivement');
      throw Exception(
        'Les permissions de localisation sont refusées définitivement. '
        'Veuillez les activer dans les paramètres de l\'application.'
      );
    }

    debugPrint('✅ Permission accordée: $permission');
    return permission;
  }

  /// Obtenir la position actuelle
  static Future<Position> getCurrentPosition() async {
    debugPrint('📍 Récupération position actuelle...');

    // Vérifier si le service est activé
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Service de localisation désactivé');
      throw Exception('Le service de localisation est désactivé');
    }

    // Vérifier les permissions
    await checkAndRequestPermission();

    // Obtenir la position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;

    } catch (e) {
      debugPrint('❌ Erreur récupération position: $e');
      throw Exception('Impossible de récupérer la position: $e');
    }
  }

  /// Calculer la distance entre deux points (en kilomètres)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    final distanceInKm = distanceInMeters / 1000;
    debugPrint('📏 Distance calculée: ${distanceInKm.toStringAsFixed(2)} km');

    return distanceInKm;
  }

  /// Calculer la distance entre une position et des coordonnées
  static double calculateDistanceFromPosition(
    Position position,
    double endLatitude,
    double endLongitude,
  ) {
    return calculateDistance(
      position.latitude,
      position.longitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Démarrer le suivi de position en temps réel
  Future<StreamSubscription<Position>> startPositionTracking({
    required Function(Position) onPositionChanged,
    Function(Object)? onError,
  }) async {
    debugPrint('🎯 Démarrage suivi position en temps réel...');

    // Vérifier permissions
    await checkAndRequestPermission();

    // Annuler le stream précédent s'il existe
    await stopPositionTracking();

    // Configuration du stream
    const locationOptions = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationOptions,
    ).listen(
      (Position position) {
        _currentPosition = position;
        debugPrint('📍 Position mise à jour: ${position.latitude}, ${position.longitude}');
        onPositionChanged(position);
      },
      onError: (error) {
        debugPrint('❌ Erreur stream position: $error');
        if (onError != null) {
          onError(error);
        }
      },
      cancelOnError: false,
    );

    debugPrint('✅ Suivi position démarré');
    return _positionStream!;
  }

  /// Arrêter le suivi de position
  Future<void> stopPositionTracking() async {
    if (_positionStream != null) {
      debugPrint('🛑 Arrêt suivi position...');
      await _positionStream!.cancel();
      _positionStream = null;
      debugPrint('✅ Suivi position arrêté');
    }
  }

  /// Obtenir la dernière position connue
  Position? getLastKnownPosition() {
    return _currentPosition;
  }

  /// Vérifier si une position est dans un rayon donné (en km)
  static bool isWithinRadius(
    double centerLatitude,
    double centerLongitude,
    double targetLatitude,
    double targetLongitude,
    double radiusInKm,
  ) {
    final distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      targetLatitude,
      targetLongitude,
    );

    final isWithin = distance <= radiusInKm;
    debugPrint('🎯 Distance: ${distance.toStringAsFixed(2)} km, Rayon: $radiusInKm km, Dans le rayon: $isWithin');

    return isWithin;
  }

  /// Obtenir les paramètres de localisation pour Android/iOS
  static LocationSettings getLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration? timeLimit,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  /// Formater la distance pour affichage
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Calculer le temps estimé de trajet (vitesse moyenne 30 km/h en ville)
  static int estimateTravelTime(double distanceInKm, {double speedKmh = 30}) {
    final timeInHours = distanceInKm / speedKmh;
    final timeInMinutes = (timeInHours * 60).ceil();
    debugPrint('⏱️ Temps estimé: $timeInMinutes min pour ${distanceInKm.toStringAsFixed(1)} km');
    return timeInMinutes;
  }

  /// Ouvrir les paramètres de localisation de l'appareil
  static Future<bool> openLocationSettings() async {
    debugPrint('⚙️ Ouverture paramètres localisation...');
    return await Geolocator.openLocationSettings();
  }

  /// Ouvrir les paramètres de l'application
  static Future<bool> openAppSettings() async {
    debugPrint('⚙️ Ouverture paramètres application...');
    return await Geolocator.openAppSettings();
  }
}

/// Classe pour représenter un point avec coordonnées
class GeoPoint {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  /// Calculer la distance vers un autre point
  double distanceTo(GeoPoint other) {
    return GeolocationService.calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  /// Vérifier si ce point est dans un rayon donné d'un autre point
  bool isWithinRadius(GeoPoint center, double radiusInKm) {
    return GeolocationService.isWithinRadius(
      center.latitude,
      center.longitude,
      latitude,
      longitude,
      radiusInKm,
    );
  }

  @override
  String toString() {
    return 'GeoPoint(lat: $latitude, lng: $longitude${name != null ? ', name: $name' : ''})';
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
    };
  }

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      name: json['name'],
      address: json['address'],
    );
  }
}
