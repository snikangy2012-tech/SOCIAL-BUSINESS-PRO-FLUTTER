// ===== lib/screens/livreur/livreur_dashboard.dart =====

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  bool _isLoading = true;
  bool _isAvailable = true;
  
  // Stats mock
  final Map<String, dynamic> _stats = {
    'todayDeliveries': 12,
    'todayEarnings': 24000,
    'avgRating': 4.7,
    'completionRate': 94.5,
    'totalDistance': 87.5,
  };
  
  // Livraisons disponibles mock
  final List<Map<String, dynamic>> _availableDeliveries = [
    {
      'id': '1',
      'orderNumber': 'CMD-001',
      'vendorName': 'Tech Store CI',
      'clientName': 'Jean Kouassi',
      'pickupAddress': 'Cocody Angré, Abidjan',
      'deliveryAddress': 'Plateau, Abidjan',
      'distance': 8.5,
      'fee': 2000,
      'estimatedTime': 25,
      'priority': 'normal',
    },
    {
      'id': '2',
      'orderNumber': 'CMD-002',
      'vendorName': 'Fashion Shop',
      'clientName': 'Marie Koné',
      'pickupAddress': 'Marcory Zone 4, Abidjan',
      'deliveryAddress': 'Yopougon, Abidjan',
      'distance': 12.3,
      'fee': 2500,
      'estimatedTime': 35,
      'priority': 'express',
    },
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('🚚 === DeliveryDashboard initState ===');
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    debugPrint('🔄 Chargement dashboard livreur');
    
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Vérifier l'utilisateur
      final authProvider = context.read<auth.AuthProvider>();
      final user = authProvider.user;
      
      if (user == null || user.userType != UserType.livreur) {
        debugPrint('❌ User null ou pas livreur: ${user?.userType.value}');
        throw Exception('Accès non autorisé');
      }
      
      debugPrint('✅ User validé: ${user.displayName} (livreur)');
      
      // Simuler chargement
      await Future.delayed(const Duration(milliseconds: 800));
      
      debugPrint('✅ Dashboard livreur chargé');
      
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final user = authProvider.user;

    // Vérification sécurité
    if (user == null || user.userType != UserType.livreur) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('❌ Accès refusé - Redirection vers /');
          context.go('/');
        }
      });
      
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha:0.7)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Livreur'),
        backgroundColor: AppColors.primary,
        actions: [
          // ✅ Bouton Accueil
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Accueil',
            onPressed: () {
              // Retour à l'accueil acheteur
              context.go('/');
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Switch Disponibilité
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isAvailable ? AppColors.success : Colors.grey)
                            .withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isAvailable ? Icons.check_circle : Icons.cancel,
                        color: _isAvailable ? AppColors.success : Colors.grey,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut de disponibilité',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAvailable
                                ? 'Vous recevez des demandes'
                                : 'Vous êtes hors ligne',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() => _isAvailable = value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Vous êtes maintenant disponible'
                                  : 'Vous êtes maintenant hors ligne',
                            ),
                            backgroundColor:
                                value ? AppColors.success : Colors.grey,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistiques du jour
            const Text(
              'Aujourd\'hui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Livraisons',
                  '${_stats['todayDeliveries']}',
                  Icons.delivery_dining,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'Gains',
                  '${_stats['todayEarnings']} F',
                  Icons.payments,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Distance',
                  '${_stats['totalDistance']} km',
                  Icons.map,
                  AppColors.info,
                ),
                _buildStatCard(
                  'Note',
                  '${_stats['avgRating']}/5',
                  Icons.star,
                  AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Livraisons disponibles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Livraisons disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_availableDeliveries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_availableDeliveries.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Liste des livraisons
            if (!_isAvailable)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vous êtes hors ligne',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Activez votre disponibilité pour recevoir des livraisons',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_availableDeliveries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune livraison disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'De nouvelles demandes apparaîtront bientôt',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._availableDeliveries.map((delivery) {
                return _buildDeliveryCard(delivery);
              }),
          ],
        ),
      ),
    );
  }

  // Carte de statistique
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Carte de livraison disponible
  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final bool isExpress = delivery['priority'] == 'express';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpress
            ? const BorderSide(color: AppColors.error, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery['orderNumber'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${delivery['distance']} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isExpress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'EXPRESS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const Divider(height: 24),

            // Infos vendeur et client
            _buildAddressRow(
              Icons.store,
              'Récupération',
              delivery['vendorName'],
              delivery['pickupAddress'],
            ),
            const SizedBox(height: 12),
            _buildAddressRow(
              Icons.person,
              'Livraison',
              delivery['clientName'],
              delivery['deliveryAddress'],
            ),

            const Divider(height: 24),

            // Détails et action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payments,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${delivery['fee']} FCFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${delivery['estimatedTime']} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Confirmation
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Accepter cette livraison ?'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Distance: ${delivery['distance']} km'),
                            Text('Frais: ${delivery['fee']} FCFA'),
                            Text('Temps estimé: ${delivery['estimatedTime']} min'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Livraison acceptée !'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              // TODO: Navigation vers détail livraison
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: const Text('Accepter'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une adresse
  Widget _buildAddressRow(
    IconData icon,
    String label,
    String name,
    String address,
  ) {
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
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}