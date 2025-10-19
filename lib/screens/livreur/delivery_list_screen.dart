// ===== lib/screens/livreur/delivery_list_screen.dart =====
// Liste des livraisons disponibles et en cours pour le livreur

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../providers/auth_provider_firebase.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DeliveryModel> _allDeliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _statusFilters = [
    'available', // Disponibles
    'accepted', // Acceptées
    'in_progress', // En cours
    'completed', // Terminées
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadDeliveries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final livreurId = authProvider.user?.id;

      if (livreurId == null) {
        throw Exception('Livreur non connecté');
      }

      // Charger les livraisons du livreur
      final deliveries = await DeliveryService().getLivreurDeliveries(
        livreurId: livreurId,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _allDeliveries = deliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<DeliveryModel> _getFilteredDeliveries(String status) {
    return _allDeliveries
        .where((delivery) => delivery.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.info;
      case 'accepted':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponibles';
      case 'accepted':
        return 'Acceptées';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminées';
      case 'cancelled':
        return 'Annulées';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.local_shipping_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statusFilters.map((status) {
            final count = _getFilteredDeliveries(status).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getStatusLabel(status)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text(
            'Chargement des livraisons...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.md,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadDeliveries,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: _statusFilters.map((status) {
        final filteredDeliveries = _getFilteredDeliveries(status);

        if (filteredDeliveries.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: _loadDeliveries,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filteredDeliveries.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _buildDeliveryCard(filteredDeliveries[index]);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'available':
        message = 'Aucune livraison disponible';
        icon = Icons.inbox_outlined;
        break;
      case 'accepted':
        message = 'Aucune livraison acceptée';
        icon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        message = 'Aucune livraison en cours';
        icon = Icons.directions_car_outlined;
        break;
      case 'completed':
        message = 'Aucune livraison terminée';
        icon = Icons.done_all_outlined;
        break;
      default:
        message = 'Aucune livraison';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.md,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    final statusColor = _getStatusColor(delivery.status);
    final statusLabel = _getStatusLabel(delivery.status);
    final statusIcon = _getStatusIcon(delivery.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/livreur/delivery/${delivery.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livraison #${delivery.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(delivery.createdAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.sm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: statusColor.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Adresse de livraison
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      delivery.deliveryAddress['address'] ?? delivery.deliveryAddress['city'] ?? 'Adresse non disponible',
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Package description
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      delivery.packageDescription,
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Montant et distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${delivery.deliveryFee.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.route,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${delivery.distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: AppFontSizes.sm,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(delivery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(DeliveryModel delivery) {
    switch (delivery.status.toLowerCase()) {
      case 'available':
        return ElevatedButton.icon(
          onPressed: () => _acceptDelivery(delivery),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Accepter cette livraison'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
        );

      case 'accepted':
        return ElevatedButton.icon(
          onPressed: () => context.push('/livreur/delivery/${delivery.id}'),
          icon: const Icon(Icons.directions_car, size: 18),
          label: const Text('Démarrer la livraison'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );

      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: () => context.push('/livreur/delivery/${delivery.id}'),
          icon: const Icon(Icons.navigation, size: 18),
          label: const Text('Continuer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );

      case 'completed':
        return OutlinedButton.icon(
          onPressed: () => context.push('/livreur/delivery/${delivery.id}'),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('Voir les détails'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _acceptDelivery(DeliveryModel delivery) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la livraison'),
        content: Text(
          'Voulez-vous accepter la livraison #${delivery.id.substring(0, 8)} ?\n\n'
          'Montant: ${delivery.deliveryFee.toStringAsFixed(0)} FCFA',
        ),
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

    if (confirm == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        final livreurId = authProvider.user?.id;

        if (livreurId == null) {
          throw Exception('Livreur non connecté');
        }

        // Accepter la livraison
        await DeliveryService().assignDelivery(
          deliveryId: delivery.id,
          livreurId: livreurId,
          estimatedPickup: DateTime.now().add(const Duration(minutes: 15)),
          estimatedDelivery: DateTime.now().add(Duration(minutes: delivery.estimatedDuration)),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison acceptée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          _loadDeliveries(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
