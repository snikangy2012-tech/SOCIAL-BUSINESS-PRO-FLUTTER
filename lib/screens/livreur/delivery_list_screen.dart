// ===== lib/screens/livreur/delivery_list_screen.dart =====
// Liste des livraisons disponibles et en cours pour le livreur

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/delivery_model.dart';
import '../../models/audit_log_model.dart';
import '../../services/delivery_service.dart';
import '../../services/delivery_grouping_service.dart';
import '../../services/audit_service.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../utils/number_formatter.dart';
import 'grouped_deliveries_screen.dart';
import '../widgets/system_ui_scaffold.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 20); // Plus fréquent pour les livraisons

  List<DeliveryModel> _allDeliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _statusFilters = [
    'assigned', // Assignées (livraisons assignées au livreur)
    'in_progress', // En cours (picked_up + in_transit)
    'delivered', // Terminées
    'cancelled', // Annulées
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadDeliveries();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh deliveries');
        _loadDeliveries();
      }
    });
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
    if (status == 'in_progress') {
      // "En cours" regroupe picked_up et in_transit
      return _allDeliveries
          .where((delivery) =>
              delivery.status.toLowerCase() == 'picked_up' ||
              delivery.status.toLowerCase() == 'in_transit')
          .toList();
    }

    return _allDeliveries
        .where((delivery) => delivery.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppColors.info;
      case 'in_progress':
      case 'picked_up':
      case 'in_transit':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Assignées';
      case 'in_progress':
      case 'picked_up':
      case 'in_transit':
        return 'En cours';
      case 'delivered':
        return 'Terminées';
      case 'cancelled':
        return 'Annulées';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
      case 'picked_up':
      case 'in_transit':
        return Icons.directions_car;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détecter les opportunités de tournées groupées dans les livraisons assignées
    final assignedDeliveries = _getFilteredDeliveries('assigned');
    final groupedOpportunities = DeliveryGroupingService.findMultiDeliveryVendors(assignedDeliveries);

    return SystemUIScaffold(
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
              : Column(
                  children: [
                    // Indicateur de tournées groupées disponibles
                    if (groupedOpportunities.isNotEmpty)
                      _buildGroupedOpportunitiesBanner(context, groupedOpportunities),
                    // Contenu principal
                    Expanded(child: _buildContent()),
                  ],
                ),
    );
  }

  Widget _buildGroupedOpportunitiesBanner(
    BuildContext context,
    Map<String, List<DeliveryModel>> opportunities,
  ) {
    // Compter le nombre total de livraisons groupables
    final totalGroupedDeliveries = opportunities.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _showGroupedOpportunitiesSheet(context, opportunities),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tournées groupées disponibles !',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalGroupedDeliveries livraisons · ${opportunities.length} vendeur(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupedOpportunitiesSheet(
    BuildContext context,
    Map<String, List<DeliveryModel>> opportunities,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Titre
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Tournées groupées disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Liste des opportunités
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  final vendeurId = opportunities.keys.elementAt(index);
                  final deliveries = opportunities[vendeurId]!;
                  final stats = DeliveryGroupingService.calculateGroupStats(deliveries);
                  final timeSaved = DeliveryGroupingService.estimateTimeSaved(deliveries);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupedDeliveriesScreen(
                              deliveries: deliveries,
                              vendeurId: vendeurId,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom du vendeur
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    stats.vendeurName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Statistiques
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatChip(
                                    '${stats.totalDeliveries}',
                                    'livraisons',
                                    Icons.inventory_2,
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildStatChip(
                                    '$timeSaved min',
                                    'économisées',
                                    Icons.timer,
                                    AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildStatChip(
                                    '${stats.totalFee.toStringAsFixed(0)} F',
                                    'à gagner',
                                    Icons.monetization_on,
                                    AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
        onTap: () => context.push('/livreur/delivery-detail/${delivery.id}'),
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
                          formatDeliveryNumber(delivery.id, allDeliveries: _allDeliveries),
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
                          formatPriceWithCurrency(delivery.deliveryFee, currency: 'FCFA'),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

      case 'assigned': // ✅ Ajouté: livraisons assignées au livreur
      case 'accepted':
        return ElevatedButton.icon(
          onPressed: () => context.push('/livreur/delivery-detail/${delivery.id}'),
          icon: const Icon(Icons.directions_car, size: 18),
          label: const Text('Démarrer la livraison'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );

      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: () => context.push('/livreur/delivery-detail/${delivery.id}'),
          icon: const Icon(Icons.navigation, size: 18),
          label: const Text('Continuer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );

      case 'completed':
        return OutlinedButton.icon(
          onPressed: () => context.push('/livreur/delivery-detail/${delivery.id}'),
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
          'Voulez-vous accepter la livraison ${formatDeliveryNumber(delivery.id, allDeliveries: _allDeliveries)} ?\n\n'
          'Montant: ${formatPriceWithCurrency(delivery.deliveryFee, currency: 'FCFA')}',
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
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

        // Logger l'acceptation de livraison
        await AuditService.log(
          userId: livreurId,
          userType: authProvider.user!.userType.value,
          userEmail: authProvider.user!.email,
          userName: authProvider.user!.displayName,
          action: 'delivery_accepted',
          actionLabel: 'Acceptation de livraison',
          category: AuditCategory.userAction,
          severity: AuditSeverity.low,
          description: 'Acceptation de la livraison ${formatDeliveryNumber(delivery.id, allDeliveries: _allDeliveries)}',
          targetType: 'delivery',
          targetId: delivery.id,
          targetLabel: 'Livraison ${formatDeliveryNumber(delivery.id, allDeliveries: _allDeliveries)}',
          metadata: {
            'deliveryId': delivery.id,
            'orderId': delivery.orderId,
            'deliveryFee': delivery.deliveryFee,
            'pickupAddress': delivery.pickupAddress,
            'deliveryAddress': delivery.deliveryAddress,
          },
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
