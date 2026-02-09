// ===== lib/screens/livreur/available_orders_screen.dart =====
// Écran des commandes disponibles pour livreurs - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/order_assignment_service.dart';
import '../../services/geolocation_service.dart';
import '../../services/delivery_service.dart';
import '../../services/payment_enforcement_service.dart';
import '../../utils/test_data_helper.dart';
import '../../utils/fix_orders_status.dart';
import '../../utils/add_gps_to_orders.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  Position? _currentPosition;
  bool _isLoadingPosition = true;
  bool _isAccepting = false;
  String? _acceptingOrderId;
  double _maxDistance = 20.0; // Distance maximale en km

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    setState(() => _isLoadingPosition = true);

    try {
      final position = await GeolocationService.getCurrentPosition();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingPosition = false;
        });

        // Mettre à jour la position du livreur dans Firestore
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.user;

        if (user != null) {
          await OrderAssignmentService.updateLivreurPosition(
            livreurId: user.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération position: $e');

      if (mounted) {
        setState(() => _isLoadingPosition = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadCurrentPosition,
            ),
          ),
        );
      }
    }
  }

  Future<void> _debugCheckOrders() async {
    try {
      debugPrint('🔍 === DEBUG: Vérification des commandes ===');

      // Récupérer TOUTES les commandes (sans filtre de statut)
      final allOrdersSnapshot =
          await FirebaseFirestore.instance.collection(FirebaseCollections.orders).get();

      debugPrint('📦 Total commandes dans Firestore: ${allOrdersSnapshot.docs.length}');

      int readyCount = 0;
      int confirmedCount = 0;
      int withoutLivreur = 0;
      int availableCount = 0;
      int withoutGPS = 0;

      for (var doc in allOrdersSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'N/A';
        final livreurId = data['livreurId'];
        final pickupLat = data['pickupLatitude'];
        final pickupLng = data['pickupLongitude'];
        final hasGPS = pickupLat != null && pickupLng != null;

        debugPrint(
            '  - ${doc.id}: status=$status, livreurId=${livreurId ?? "null"}, GPS=${hasGPS ? "OUI" : "NON"}');

        if (status == 'ready') readyCount++;
        if (status == 'confirmed') confirmedCount++;
        if (livreurId == null || livreurId.toString().isEmpty) withoutLivreur++;
        if (!hasGPS) withoutGPS++;
        if ((status == 'ready' || status == 'confirmed') &&
            (livreurId == null || livreurId.toString().isEmpty) &&
            hasGPS) {
          availableCount++;
        }
      }

      debugPrint('📊 Statistiques:');
      debugPrint('  - Commandes avec statut "ready": $readyCount');
      debugPrint('  - Commandes avec statut "confirmed": $confirmedCount');
      debugPrint('  - Commandes sans livreur: $withoutLivreur');
      debugPrint('  - Commandes sans coordonnées GPS: $withoutGPS');
      debugPrint(
          '  - Commandes DISPONIBLES (ready/confirmed + sans livreur + avec GPS): $availableCount');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Commandes'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total: ${allOrdersSnapshot.docs.length}'),
                  Text('Statut "ready": $readyCount'),
                  Text('Statut "confirmed": $confirmedCount'),
                  Text('Sans livreur: $withoutLivreur'),
                  Text('Sans GPS: $withoutGPS'),
                  Text('DISPONIBLES: $availableCount'),
                  const SizedBox(height: 16),
                  const Text('Voir les logs pour plus de détails'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur debug: $e');
    }
  }

  Future<void> _fixOrdersStatus() async {
    try {
      debugPrint('🔧 === Lancement correction des statuts ===');

      setState(() => _isLoadingPosition = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction des statuts en cours...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Exécuter toutes les corrections
      await FixOrdersStatus.fixAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correction des statuts terminée !'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur correction statuts: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur correction: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosition = false);
      }
    }
  }

  Future<void> _addGpsToOrders() async {
    try {
      debugPrint('📍 === Ajout de coordonnées GPS aux commandes ===');

      setState(() => _isLoadingPosition = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajout de coordonnées GPS en cours...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Ajouter les coordonnées GPS
      await AddGpsToOrders.addGpsToOrdersWithoutCoordinates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Coordonnées GPS ajoutées avec succès !'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur ajout GPS: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ajout GPS: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosition = false);
      }
    }
  }

  Future<void> _createTestOrders() async {
    try {
      setState(() => _isLoadingPosition = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Création de commandes de test...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Récupérer des IDs vendeur et acheteur
      final vendeurId = await TestDataHelper.getFirstVendeurId();
      final buyerId = await TestDataHelper.getFirstBuyerId();

      if (vendeurId == null || buyerId == null) {
        throw Exception('Aucun vendeur ou acheteur trouvé dans la base');
      }

      // Créer 5 commandes de test
      await TestDataHelper.createTestOrders(
        vendeurId: vendeurId,
        buyerId: buyerId,
        count: 5,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 5 commandes de test créées avec succès !'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur création commandes de test: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosition = false);
      }
    }
  }

  Future<void> _acceptOrder(String orderId, String orderNumber) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Utilisateur non connecté'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 🔒 Vérifier si le compte est bloqué pour paiements non effectués
    final isBlocked = await PaymentEnforcementService.isLivreurBlocked(user.id);
    if (isBlocked) {
      if (!mounted) return;

      // Afficher dialogue de blocage
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Compte bloqué',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Vous ne pouvez pas accepter de nouvelles livraisons car vous avez des paiements non effectués.\n\nVeuillez effectuer un dépôt pour débloquer votre compte.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.go('/livreur/payment-deposit');
              },
              icon: const Icon(Icons.payment),
              label: const Text('Effectuer un dépôt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter cette commande ?'),
        content: Text('Voulez-vous accepter la commande $orderNumber ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isAccepting = true;
      _acceptingOrderId = orderId;
    });

    try {
      // Assigner la commande au livreur
      // NOTE: assignOrderToLivreur crée déjà le document de livraison automatiquement
      await OrderAssignmentService.assignOrderToLivreur(
        orderId: orderId,
        livreurId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande acceptée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );

        // Naviguer vers le détail de la livraison
        // La livraison a été créée par assignOrderToLivreur, on peut la récupérer
        final delivery = await DeliveryService.getDeliveryByOrderId(orderId);
        if (delivery != null && mounted) {
          context.go('/livreur/delivery-detail/${delivery.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur acceptation commande: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
          _acceptingOrderId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/livreur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Commandes disponibles'),
        backgroundColor: AppColors.primary,
        actions: [
          // Bouton DEBUG pour vérifier les commandes
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug - Vérifier commandes',
            onPressed: _debugCheckOrders,
          ),
          // Bouton pour ajouter GPS aux commandes
          IconButton(
            icon: const Icon(Icons.add_location),
            tooltip: 'Ajouter GPS aux commandes',
            onPressed: _addGpsToOrders,
          ),
          // Bouton pour corriger les statuts des commandes
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: 'Corriger statuts commandes',
            onPressed: _fixOrdersStatus,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser position',
            onPressed: _loadCurrentPosition,
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer par distance',
            onSelected: (value) {
              setState(() => _maxDistance = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 5.0,
                child: Text('< 5 km'),
              ),
              PopupMenuItem(
                value: 10.0,
                child: Text('< 10 km'),
              ),
              PopupMenuItem(
                value: 20.0,
                child: Text('< 20 km'),
              ),
              PopupMenuItem(
                value: 50.0,
                child: Text('< 50 km'),
              ),
              PopupMenuItem(
                value: 100.0,
                child: Text('Toutes'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoadingPosition
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Localisation en cours...'),
                ],
              ),
            )
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Localisation indisponible',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Activez la localisation pour voir les commandes',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadCurrentPosition,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<OrderWithDistance>>(
                  stream: OrderAssignmentService.streamOrdersSortedByDistance(
                    livreurPosition: _currentPosition!,
                    maxDistanceKm: _maxDistance,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text('Erreur: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final orders = snapshot.data ?? [];

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aucune commande disponible',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Les commandes dans un rayon de ${_maxDistance.toStringAsFixed(0)} km apparaîtront ici',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadCurrentPosition,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(orders[index], allOrders: orders);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildOrderCard(OrderWithDistance orderWithDistance,
      {required List<OrderWithDistance> allOrders}) {
    final order = orderWithDistance.order;
    final isAcceptingThis = _isAccepting && _acceptingOrderId == order.id;

    // Déterminer la couleur selon la distance
    Color distanceColor;
    if (orderWithDistance.isNearby) {
      distanceColor = AppColors.success;
    } else if (orderWithDistance.isFar) {
      distanceColor = AppColors.warning;
    } else {
      distanceColor = AppColors.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: distanceColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatOrderNumber(order.id,
                                  allOrders: allOrders.map((o) => o.order).toList()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              order.buyerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: distanceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        orderWithDistance.formattedDistance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Informations de livraison
            _buildInfoRow(
              Icons.store,
              'Point de récupération',
              order.deliveryAddress, // TODO: Utiliser pickupAddress quand disponible
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.home,
              'Adresse de livraison',
              order.deliveryAddress,
            ),

            const Divider(height: 24),

            // Montant et temps estimé
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.payments,
                    'Montant',
                    formatPriceWithCurrency(order.totalAmount, currency: 'FCFA'),
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailChip(
                    Icons.access_time,
                    'Temps',
                    orderWithDistance.formattedTime,
                    AppColors.info,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Articles
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bouton accepter
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAcceptingThis
                    ? null
                    : () => _acceptOrder(
                        order.id,
                        formatOrderNumber(order.id,
                            allOrders: allOrders.map((o) => o.order).toList())),
                icon: isAcceptingThis
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  isAcceptingThis ? 'Acceptation...' : 'Accepter cette commande',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

