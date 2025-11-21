// ===== lib/screens/acheteur/order_history_screen.dart =====
// Historique des commandes pour l'acheteur
// Affiche toutes les commandes passées avec filtres par statut

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/custom_widgets.dart';
import 'package:provider/provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtres par statut (SIMPLIFIÉS)
  final List<String> _statusFilters = [
    'all',
    'en_attente',
    'en_cours',
    'livree',
    'annulee',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Charger les commandes de l'acheteur
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final orders = await OrderService.getOrdersByBuyer(userId);

      // Trier par date (plus récent en premier)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des commandes: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Filtrer les commandes par statut
  List<OrderModel> _getFilteredOrders(String status) {
    if (status == 'all') {
      return _allOrders;
    }
    return _allOrders.where((order) => order.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Obtenir la couleur selon le statut (SIMPLIFIÉ)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return AppColors.warning;
      case 'en_cours':
        return AppColors.info;
      case 'livree':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  // Obtenir le libellé du statut (SIMPLIFIÉ)
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'Toutes';
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return status;
    }
  }

  // Obtenir l'icône du statut (SIMPLIFIÉ)
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return Icons.schedule;
      case 'en_cours':
        return Icons.local_shipping;
      case 'livree':
        return Icons.check_circle;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
            final count = _getFilteredOrders(status).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _getStatusLabel(status),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status.toLowerCase() == 'all' && _allOrders.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
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

  // État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text(
            'Chargement de vos commandes...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  // État d'erreur
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
            CustomButton(
              text: 'Réessayer',
              onPressed: _loadOrders,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  // Contenu principal
  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: _statusFilters.map((status) {
        final filteredOrders = _getFilteredOrders(status);
        
        if (filteredOrders.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filteredOrders.length,
            separatorBuilder: (context, index) => 
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _buildOrderCard(filteredOrders[index]);
            },
          ),
        );
      }).toList(),
    );
  }

  // État vide
  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'all':
        message = 'Vous n\'avez pas encore passé de commande';
        icon = Icons.shopping_cart_outlined;
        break;
      case 'pending':
        message = 'Aucune commande en attente';
        icon = Icons.hourglass_empty;
        break;
      case 'delivered':
        message = 'Aucune commande livrée';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'Aucune commande annulée';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Aucune commande avec ce statut';
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
          if (status.toLowerCase() == 'all') ...[
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              text: 'Découvrir les produits',
              onPressed: () => context.go('/categories'),
              icon: Icons.shopping_bag,
            ),
          ],
        ],
      ),
    );
  }

  // Carte de commande
  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final statusIcon = _getStatusIcon(order.status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _navigateToOrderDetail(order),
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
                          'Commande ${order.displayNumber}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
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
              
              // Informations vendeur
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vendeur',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${order.items.length} article(s)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.sm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Montant total
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant total',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(order.totalAmount)} FCFA',
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToOrderDetail(order),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Voir détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),

                  if (order.status.toLowerCase() == 'in_delivery') ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _trackOrder(order),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Suivre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  if (order.status.toLowerCase() == 'delivered') ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rateOrder(order),
                        icon: const Icon(Icons.star, size: 18),
                        label: const Text('Noter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation vers les détails de la commande
  void _navigateToOrderDetail(OrderModel order) {
    context.push('/acheteur/order/${order.id}');
  }

  // Suivre une commande en livraison
  void _trackOrder(OrderModel order) {
    context.push('/acheteur/order/${order.id}/tracking');
  }

  // Noter une commande livrée
  void _rateOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Noter cette commande'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Formater une date
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

  // Formater une devise
  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'fr_FR').format(amount);
  }
}