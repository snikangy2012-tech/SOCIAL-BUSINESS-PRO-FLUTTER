// ===== lib/screens/acheteur/delivery_tracking_screen.dart =====
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/order_service.dart';
import 'package:social_business_pro/config/constants.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  DeliveryModel? _delivery;
  bool _isLoading = true;
  String? _errorMessage;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  StreamSubscription<DeliveryModel?>? _deliveryStream;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _startRealTimeTracking();
  }

  @override
  void dispose() {
    _deliveryStream?.cancel();
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await OrderService.getOrderById(widget.orderId);

      if (order != null) {
        // Query delivery by orderId since getDeliveryByOrderId doesn't exist
        final deliveryQuery = await FirebaseFirestore.instance
            .collection(FirebaseCollections.deliveries)
            .where('orderId', isEqualTo: widget.orderId)
            .limit(1)
            .get();

        DeliveryModel? delivery;
        if (deliveryQuery.docs.isNotEmpty) {
          delivery = DeliveryModel.fromMap(deliveryQuery.docs.first.data());
        }

        setState(() {
          _delivery = delivery;
          _isLoading = false;
        });

        if (delivery != null) {
          _setupMapMarkers();
        }
      } else {
        setState(() {
          _errorMessage = 'Commande introuvable';
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

  void _startRealTimeTracking() {
    // Poll every 10 seconds to update delivery status
    // Note: Stream-based tracking requires knowing the deliveryId first
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_delivery != null) {
        // If we have a delivery, track it using trackDelivery stream
        _deliveryStream?.cancel();
        _deliveryStream = _deliveryService
            .trackDelivery(_delivery!.id)
            .listen((delivery) {
          setState(() {
            _delivery = delivery;
          });
          _setupMapMarkers();
        });
      } else {
        // Otherwise keep polling to find the delivery
        _loadDeliveryData();
      }
    });
  }

  void _setupMapMarkers() {
    if (_delivery == null) return;

    Set<Marker> markers = {};

    // Delivery person's current location
    if (_delivery!.currentLocation != null) {
      final currentLat = _delivery!.currentLocation!['latitude'] as double?;
      final currentLng = _delivery!.currentLocation!['longitude'] as double?;

      if (currentLat != null && currentLng != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('delivery_person'),
            position: LatLng(currentLat, currentLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Livreur',
              snippet: 'En route vers vous',
            ),
          ),
        );
      }
    }

    // Pickup location (vendor)
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

    // Delivery location (customer)
    final deliveryLat = _delivery!.deliveryAddress['latitude'] as double?;
    final deliveryLng = _delivery!.deliveryAddress['longitude'] as double?;
    if (deliveryLat != null && deliveryLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(deliveryLat, deliveryLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Votre adresse',
            snippet: _delivery!.deliveryAddress['address'] as String? ?? 'N/A',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Auto-zoom to fit all markers
    if (markers.length > 1 && _mapController != null) {
      _zoomToFitMarkers();
    }
  }

  Future<void> _zoomToFitMarkers() async {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (var marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }


  Widget _buildMapSection() {
    if (_delivery == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'Carte non disponible',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Get delivery address coordinates
    final deliveryLat = _delivery!.deliveryAddress['latitude'] as double?;
    final deliveryLng = _delivery!.deliveryAddress['longitude'] as double?;

    if (deliveryLat == null || deliveryLng == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'Coordonnées non disponibles',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Determine initial position
    LatLng initialPosition;
    if (_delivery!.currentLocation != null) {
      final currentLat = _delivery!.currentLocation!['latitude'] as double?;
      final currentLng = _delivery!.currentLocation!['longitude'] as double?;
      if (currentLat != null && currentLng != null) {
        initialPosition = LatLng(currentLat, currentLng);
      } else {
        initialPosition = LatLng(deliveryLat, deliveryLng);
      }
    } else {
      initialPosition = LatLng(deliveryLat, deliveryLng);
    }

    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
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
            zoom: 13,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            _zoomToFitMarkers();
          },
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    if (_delivery == null) return const SizedBox.shrink();

    final statuses = [
      {'key': 'pending', 'label': 'En attente', 'icon': Icons.pending},
      {'key': 'picked_up', 'label': 'Récupéré', 'icon': Icons.check_circle},
      {'key': 'in_transit', 'label': 'En route', 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': 'Livré', 'icon': Icons.done_all},
    ];

    final currentStatus = _delivery!.status.toLowerCase();
    final currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suivi de livraison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status['icon'] as IconData,
                          color: isCompleted ? Colors.white : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCompleted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              _formatDateTime(_delivery!.updatedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    if (_delivery == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations livraison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Livreur assigné',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _delivery!.livreurId != null
                            ? 'ID: ${_delivery!.livreurId!.substring(0, 8)}'
                            : 'En attente d\'assignation',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_delivery!.distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frais de livraison',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_delivery!.deliveryFee.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
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
              : _delivery == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Livraison non assignée',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Votre commande sera bientôt prise en charge',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDeliveryData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Map
                            _buildMapSection(),

                            // Status timeline
                            _buildStatusTimeline(),

                            // Delivery info
                            _buildDeliveryInfo(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

