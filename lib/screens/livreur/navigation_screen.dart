// ===== lib/screens/livreur/navigation_screen.dart =====
// Écran de navigation en temps réel style Yango/Google Maps
// Utilise Google Maps Directions API pour afficher les vrais itinéraires

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import '../../config/constants.dart';
import '../../services/geolocation_service.dart';
import '../../widgets/system_ui_scaffold.dart';

// Clé API Google Maps (pour Directions API)
const String _googleMapsApiKey = 'AIzaSyD4E1-9kiFXjYwOMOp0csfheJxvqEo9joc';

class NavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final String destinationType; // 'pickup' ou 'delivery'

  const NavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    this.destinationType = 'delivery',
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  double _distanceRemaining = 0.0;
  int _estimatedTimeMinutes = 0;
  double _currentSpeed = 0.0; // en km/h

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _hasArrived = false;
  bool _isLoading = true;

  // Points de l'itinéraire réel (depuis Google Directions API)
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _routeError;
  Position? _lastRouteFetchPosition; // Position lors du dernier fetch de route
  static const double _routeRefreshDistanceThreshold = 300.0; // Recalculer route après 300m de déviation

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initNavigation() async {
    try {
      // Obtenir la position initiale
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Récupérer l'itinéraire réel depuis Google Directions API
      await _fetchRoute();

      // Calculer la distance initiale
      _updateNavigationStats();

      // Créer les markers et polylines
      _createMarkers();

      // Démarrer le suivi de position
      _startPositionTracking();

    } catch (e) {
      debugPrint('❌ Erreur initialisation navigation: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Récupérer l'itinéraire réel depuis Google Directions API
  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    try {
      final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination = '${widget.destinationLat},${widget.destinationLng}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '&mode=driving'
        '&language=fr'
        '&key=$_googleMapsApiKey'
      );

      debugPrint('📍 Fetching route from: $origin to: $destination');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final overviewPolyline = route['overview_polyline']['points'] as String;

            // Décoder le polyline encodé
            _routePoints = _decodePolyline(overviewPolyline);

            // Extraire la distance et le temps depuis l'API
            final legs = route['legs'] as List;
            if (legs.isNotEmpty) {
              final leg = legs[0];
              final distanceValue = leg['distance']['value'] as int; // en mètres
              final durationValue = leg['duration']['value'] as int; // en secondes

              setState(() {
                _distanceRemaining = distanceValue / 1000.0; // Convertir en km
                _estimatedTimeMinutes = (durationValue / 60).round(); // Convertir en minutes
              });
            }

            // Sauvegarder la position du fetch pour éviter de refetch trop souvent
            _lastRouteFetchPosition = _currentPosition;
            debugPrint('✅ Route récupérée: ${_routePoints.length} points');
          } else {
            throw Exception('Aucun itinéraire trouvé');
          }
        } else if (data['status'] == 'ZERO_RESULTS') {
          throw Exception('Aucun itinéraire trouvé entre ces points');
        } else if (data['status'] == 'REQUEST_DENIED') {
          throw Exception('API Directions non activée ou clé invalide');
        } else {
          throw Exception('Erreur API: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération itinéraire: $e');
      setState(() {
        _routeError = e.toString();
      });

      // Fallback: utiliser une ligne droite si l'API échoue
      if (_currentPosition != null) {
        _routePoints = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(widget.destinationLat, widget.destinationLng),
        ];
      }
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  /// Décoder un polyline encodé Google (algorithme standard)
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Décoder la latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Décoder la longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      // Ajouter le point (précision 1e-5)
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  void _createMarkers() {
    _markers.clear();
    _polylines.clear();

    // Marker position actuelle (sera mis à jour automatiquement par myLocationEnabled)

    // Marker destination
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.destinationLat, widget.destinationLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          widget.destinationType == 'pickup'
            ? BitmapDescriptor.hueOrange
            : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: widget.destinationType == 'pickup' ? 'Point de récupération' : 'Point de livraison',
          snippet: widget.destinationName,
        ),
      ),
    );

    // Tracer l'itinéraire réel (depuis Google Directions API)
    if (_routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.primary,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
      debugPrint('📍 Polyline tracé avec ${_routePoints.length} points (itinéraire réel)');
    } else if (_currentPosition != null) {
      // Fallback: ligne droite si pas de route
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            LatLng(widget.destinationLat, widget.destinationLng),
          ],
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
      debugPrint('📍 Polyline fallback (ligne droite)');
    }

    setState(() {});
  }

  void _startPositionTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _currentSpeed = position.speed * 3.6; // m/s vers km/h
      });

      // Vérifier si on doit recalculer l'itinéraire
      _checkRouteRefresh(position);

      _updateNavigationStats();
      _createMarkers();
      _centerMapOnPosition();
      _checkArrival();
    });
  }

  /// Vérifier si on doit recalculer l'itinéraire (après déviation significative)
  void _checkRouteRefresh(Position currentPosition) {
    if (_lastRouteFetchPosition == null || _isLoadingRoute) return;

    // Calculer la distance depuis la dernière position où on a fetch la route
    final distanceFromLastFetch = GeolocationService.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _lastRouteFetchPosition!.latitude,
      _lastRouteFetchPosition!.longitude,
    ) * 1000; // Convertir en mètres

    // Si on a dévié de plus de 300m, recalculer la route
    if (distanceFromLastFetch > _routeRefreshDistanceThreshold) {
      debugPrint('🔄 Recalcul de l\'itinéraire (déviation: ${distanceFromLastFetch.toStringAsFixed(0)}m)');
      _fetchRoute();
    }
  }

  void _updateNavigationStats() {
    if (_currentPosition == null) return;

    // Calculer la distance restante
    _distanceRemaining = GeolocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    // Estimer le temps restant basé sur la vitesse actuelle
    if (_currentSpeed > 5) {
      // Si on se déplace
      _estimatedTimeMinutes = ((_distanceRemaining / _currentSpeed) * 60).round();
    } else {
      // Si on est arrêté, utiliser une vitesse moyenne de 30 km/h
      _estimatedTimeMinutes = ((_distanceRemaining / 30) * 60).round();
    }

    setState(() {});
  }

  void _centerMapOnPosition() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _checkArrival() {
    if (_distanceRemaining < 0.05) { // Moins de 50 mètres
      if (!_hasArrived) {
        setState(() => _hasArrived = true);
        _showArrivalDialog();
      }
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Text('Arrivé !'),
          ],
        ),
        content: Text(
          widget.destinationType == 'pickup'
              ? 'Vous êtes arrivé au point de récupération'
              : 'Vous êtes arrivé à la destination',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog
              Navigator.of(context).pop(); // Fermer l'écran de navigation
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Carte Google Maps en plein écran
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : LatLng(widget.destinationLat, widget.destinationLng),
                    zoom: 16,
                    tilt: 45, // Vue 3D légère
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // On va créer notre propre bouton
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  trafficEnabled: true, // Afficher le trafic si disponible
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Panneau d'informations en haut
                SafeArea(
                  child: Column(
                    children: [
                      // Barre d'info principale
                      _buildTopInfoPanel(),

                      const Spacer(),

                      // Boutons d'action en bas
                      _buildBottomControls(),
                    ],
                  ),
                ),

                // Indicateur de chargement de l'itinéraire
                if (_isLoadingRoute)
                  Positioned(
                    top: 140,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calcul de l\'itinéraire...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Message d'erreur si l'API échoue
                if (_routeError != null && !_isLoadingRoute)
                  Positioned(
                    top: 140,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Itinéraire simplifié (API indisponible)',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _routeError = null);
                              _fetchRoute();
                            },
                            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTopInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Distance et temps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Distance restante
              Column(
                children: [
                  Text(
                    _distanceRemaining < 1
                      ? '${(_distanceRemaining * 1000).toStringAsFixed(0)} m'
                      : '${_distanceRemaining.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Distance restante',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Temps estimé
              Column(
                children: [
                  Text(
                    _estimatedTimeMinutes < 60
                      ? '$_estimatedTimeMinutes min'
                      : '${(_estimatedTimeMinutes / 60).toStringAsFixed(0)}h ${_estimatedTimeMinutes % 60}min',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Text(
                    'Temps estimé',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Destination
          Row(
            children: [
              Icon(
                widget.destinationType == 'pickup'
                  ? Icons.store
                  : Icons.location_on,
                color: widget.destinationType == 'pickup'
                  ? AppColors.warning
                  : AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destinationType == 'pickup'
                        ? 'Récupération'
                        : 'Livraison',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.destinationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Vitesse actuelle
          if (_currentSpeed > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed, size: 16, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  '${_currentSpeed.toStringAsFixed(0)} km/h',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton retour
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            elevation: 4,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton recentrer
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            elevation: 4,
            child: InkWell(
              onTap: _centerMapOnPosition,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.info,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton recalculer itinéraire
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            elevation: 4,
            child: InkWell(
              onTap: _isLoadingRoute ? null : _fetchRoute,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _isLoadingRoute
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.alt_route,
                      color: AppColors.warning,
                    ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton ouvrir dans Google Maps
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.navigation),
              label: const Text('Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    try {
      final url = _currentPosition != null
          ? 'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${widget.destinationLat},${widget.destinationLng}&travelmode=driving'
          : 'https://www.google.com/maps/dir/?api=1&destination=${widget.destinationLat},${widget.destinationLng}&travelmode=driving';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Google Maps ouvert avec succès');
      } else {
        debugPrint('❌ Impossible d\'ouvrir Google Maps');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture Google Maps: $e');
    }
  }
}
