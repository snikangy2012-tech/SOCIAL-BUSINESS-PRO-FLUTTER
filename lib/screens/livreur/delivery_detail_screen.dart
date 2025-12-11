// ===== lib/screens/livreur/delivery_detail_screen.dart =====
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/audit_log_model.dart';
import '../../services/delivery_service.dart';
import '../../services/order_service.dart';
import '../../services/audit_service.dart';
import 'package:social_business_pro/config/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../utils/number_formatter.dart';
import '../widgets/system_ui_scaffold.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final String deliveryId;

  const DeliveryDetailScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  DeliveryModel? _delivery;
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _getCurrentLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final delivery = await _deliveryService.getDelivery(widget.deliveryId);

      if (delivery != null) {
        final order = await OrderService.getOrderById(delivery.orderId);

        setState(() {
          _delivery = delivery;
          _order = order;
          _isLoading = false;
        });

        _setupMapMarkers();
      } else {
        setState(() {
          _errorMessage = 'Livraison introuvable';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _setupMapMarkers();
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });

      // Mettre à jour la position dans Firestore
      if (_delivery != null) {
        _deliveryService.updateLivreurLocation(
          deliveryId: widget.deliveryId,
          position: position,
        ).catchError((error) {
          debugPrint('Erreur mise à jour position: $error');
        });
      }

      _setupMapMarkers();
    });
  }

  void _setupMapMarkers() {
    if (_delivery == null) return;

    Set<Marker> markers = {};

    // Marqueur position actuelle du livreur
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Ma position'),
        ),
      );
    }

    // Marqueur point de collecte (vendeur)
    final pickupLat = _delivery!.pickupAddress['latitude'] as double?;
    final pickupLng = _delivery!.pickupAddress['longitude'] as double?;
    if (pickupLat != null && pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Point de collecte',
            snippet: _delivery!.pickupAddress['address'] as String? ?? 'N/A',
          ),
        ),
      );
    }

    // Marqueur point de livraison (acheteur)
    final deliveryLat = _delivery!.deliveryAddress['latitude'] as double?;
    final deliveryLng = _delivery!.deliveryAddress['longitude'] as double?;
    if (deliveryLat != null && deliveryLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(deliveryLat, deliveryLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Point de livraison',
            snippet: _delivery!.deliveryAddress['address'] as String? ?? 'N/A',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _openGoogleMaps() async {
    if (_delivery == null) {
      _showErrorSnackBar('Aucune livraison chargée');
      return;
    }

    // Déterminer la destination selon le statut de la livraison
    double? lat;
    double? lng;
    String? street;
    String destination;

    if (_delivery!.status == 'assigned') {
      // Livraison assignée mais pas encore récupérée → aller chez le vendeur (pickup)
      lat = _delivery!.pickupAddress['latitude'] as double?;
      lng = _delivery!.pickupAddress['longitude'] as double?;
      street = _delivery!.pickupAddress['street'] as String?;
      destination = 'vendeur';
      debugPrint('📍 Itinéraire vers le VENDEUR (pickup) - Statut: assigned');
    } else if (_delivery!.status == 'picked_up' || _delivery!.status == 'in_transit') {
      // Colis récupéré → aller chez le client (delivery)
      lat = _delivery!.deliveryAddress['latitude'] as double?;
      lng = _delivery!.deliveryAddress['longitude'] as double?;
      street = _delivery!.deliveryAddress['street'] as String?;
      destination = 'client';
      debugPrint('📍 Itinéraire vers le CLIENT (delivery) - Statut: ${_delivery!.status}');
    } else {
      // Par défaut (delivered, cancelled, etc.) → client
      lat = _delivery!.deliveryAddress['latitude'] as double?;
      lng = _delivery!.deliveryAddress['longitude'] as double?;
      street = _delivery!.deliveryAddress['street'] as String?;
      destination = 'client';
      debugPrint('📍 Itinéraire vers le CLIENT (par défaut) - Statut: ${_delivery!.status}');
    }

    try {
      // Construire l'URL avec position de départ si disponible
      String url;

      // Cas 1: Coordonnées GPS disponibles (recommandé)
      if (lat != null && lng != null) {
        if (_currentPosition != null) {
          // Avec point de départ (position actuelle du livreur)
          url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=$lat,$lng&travelmode=driving';
        } else {
          // Sans point de départ (Google Maps utilisera la position actuelle de l'appareil)
          url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        }
      }
      // Cas 2: Coordonnées GPS manquantes → utiliser l'adresse textuelle
      else if (street != null && street.isNotEmpty) {
        debugPrint('⚠️ Coordonnées GPS manquantes, utilisation de l\'adresse textuelle pour $destination');
        final encodedAddress = Uri.encodeComponent(street);
        if (_currentPosition != null) {
          url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=$encodedAddress&travelmode=driving';
        } else {
          url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving';
        }
      }
      // Cas 3: Ni GPS ni adresse → erreur
      else {
        _showErrorSnackBar('Aucune information de localisation disponible pour le $destination');
        return;
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Google Maps ouvert avec succès vers $destination');
      } else {
        _showErrorSnackBar('Impossible d\'ouvrir Google Maps. Vérifiez que l\'application est installée.');
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture Google Maps: $e');
      _showErrorSnackBar('Erreur lors de l\'ouverture de l\'itinéraire: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _callCustomer() async {
    // Récupérer le numéro depuis la livraison en priorité, puis depuis la commande
    final phoneNumber = _delivery?.deliveryAddress['phone'] as String? ?? _order?.buyerPhone;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorSnackBar('Numéro de téléphone du client non disponible');
      return;
    }

    try {
      final url = 'tel:$phoneNumber';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('✅ Appel téléphonique initié vers $phoneNumber');
      } else {
        _showErrorSnackBar('Impossible de passer l\'appel. Vérifiez les permissions.');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'appel: $e');
      _showErrorSnackBar('Erreur lors de l\'appel: $e');
    }
  }

  Future<void> _updateDeliveryStatus(String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      await _deliveryService.updateDeliveryStatus(
        deliveryId: widget.deliveryId,
        status: newStatus,
      );

      // Logger la mise à jour du statut de livraison
      if (authProvider.user != null && _delivery != null) {
        final statusLabels = {
          'picked_up': 'Colis récupéré',
          'in_transit': 'En cours de livraison',
          'delivered': 'Livré',
        };

        await AuditService.log(
          userId: authProvider.user!.id,
          userType: authProvider.user!.userType.value,
          userEmail: authProvider.user!.email,
          userName: authProvider.user!.displayName,
          action: 'delivery_status_updated',
          actionLabel: 'Mise à jour statut livraison',
          category: AuditCategory.userAction,
          severity: newStatus == 'delivered' ? AuditSeverity.medium : AuditSeverity.low,
          description: 'Statut de livraison changé vers "${statusLabels[newStatus] ?? newStatus}"',
          targetType: 'delivery',
          targetId: widget.deliveryId,
          targetLabel: 'Livraison #${widget.deliveryId.substring(0, 8)}',
          metadata: {
            'deliveryId': widget.deliveryId,
            'orderId': _delivery!.orderId,
            'newStatus': newStatus,
            'statusLabel': statusLabels[newStatus] ?? newStatus,
            'deliveryFee': _delivery!.deliveryFee,
          },
        );
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Statut mis à jour: $newStatus')),
        );
      }

      _loadDeliveryData();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildMapSection() {
    if (_delivery == null) {
      return const SizedBox.shrink();
    }

    final deliveryLat = _delivery!.deliveryAddress['latitude'] as double?;
    final deliveryLng = _delivery!.deliveryAddress['longitude'] as double?;

    if (deliveryLat == null || deliveryLng == null) {
      return const SizedBox.shrink();
    }

    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(deliveryLat, deliveryLng);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_delivery == null) return const SizedBox.shrink();

    Color statusColor = AppColors.textSecondary;
    String statusText = _delivery!.status;

    switch (_delivery!.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case 'assigned':
        statusColor = AppColors.info;
        statusText = 'Assignée';
        break;
      case 'picked_up':
        statusColor = Colors.blue;
        statusText = 'Récupéré';
        break;
      case 'in_transit':
        statusColor = Colors.purple;
        statusText = 'En cours';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'Livré';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = 'Échec';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Spacer(),
            Chip(
              label: Text(
                '${_delivery!.distance.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: AppColors.background,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool hasLongValue = false}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          maxLines: hasLongValue ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_delivery == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Boutons d'action principaux
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.navigation),
                label: const Text('Itinéraire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callCustomer,
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Boutons de changement de statut
        if (_delivery!.status == 'pending' || _delivery!.status == 'assigned')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus('picked_up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Confirmer récupération'),
            ),
          ),

        if (_delivery!.status == 'picked_up')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus('in_transit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Démarrer la livraison'),
            ),
          ),

        if (_delivery!.status == 'in_transit')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus('delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Confirmer livraison'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Détails Livraison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeliveryData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadDeliveryData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Statut de la livraison
                              _buildStatusCard(),
                              const SizedBox(height: 16),

                              // Carte
                              _buildMapSection(),
                              const SizedBox(height: 16),

                              // Informations client
                              const Text(
                                'Informations Client',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoCard(
                                'Nom',
                                _order?.buyerName ?? 'N/A',
                                Icons.person,
                              ),
                              _buildInfoCard(
                                'Téléphone',
                                _delivery?.deliveryAddress['phone'] as String? ?? _order?.buyerPhone ?? 'N/A',
                                Icons.phone,
                              ),
                              _buildInfoCard(
                                'Adresse',
                                _delivery?.deliveryAddress['address'] as String? ?? _order?.deliveryAddress ?? 'N/A',
                                Icons.location_on,
                              ),
                              const SizedBox(height: 16),

                              // Informations commande
                              const Text(
                                'Informations Commande',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoCard(
                                'N° Commande',
                                _order?.id.substring(0, 8) ?? 'N/A',
                                Icons.receipt_long,
                              ),
                              _buildInfoCard(
                                'Montant',
                                formatPriceWithCurrency(_order?.totalAmount ?? 0, currency: 'FCFA'),
                                Icons.attach_money,
                                hasLongValue: true,
                              ),
                              _buildInfoCard(
                                'Frais de livraison',
                                formatPriceWithCurrency(_delivery?.deliveryFee ?? 0, currency: 'FCFA'),
                                Icons.local_shipping,
                                hasLongValue: true,
                              ),
                              const SizedBox(height: 100), // Espace pour les boutons fixes
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Boutons d'action fixes en bas avec SafeArea
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildActionButtons(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}