// ===== lib/screens/vendeur/order_management.dart =====
// Gestion des commandes pour vendeurs - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider_firebase.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key, required String orderId});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  OrderStats? _stats;

  final List<String> _statusTabs = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'in_delivery',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Charger les commandes
  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      
      final authProvider = context.read<AuthProvider>();
      final vendeurId = authProvider.user?.id;
      
      if (vendeurId != null) {
        final orders = await OrderService.getVendorOrders(vendeurId);
        final stats = await OrderService.getOrderStats(vendeurId);
        
        setState(() {
          _allOrders = orders;
          _stats = stats;
        });
        
        _filterOrdersByStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement commandes: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filtrer par statut
  void _filterOrdersByStatus() {
    setState(() {
      if (_selectedStatus == 'all') {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders.where((order) => 
            order.status.toLowerCase() == _selectedStatus).toList();
      }
    });
  }

  // Changer d'onglet
  void _onTabChanged() {
    setState(() {
      _selectedStatus = _statusTabs[_tabController.index];
    });
    _filterOrdersByStatus();
  }

  // Mettre à jour le statut d'une commande
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await OrderService.updateOrderStatus(orderId, newStatus);
      _loadOrders(); // Recharger les commandes
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: $newStatus'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Annuler une commande
  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Text('Voulez-vous vraiment annuler la commande ${order.orderNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await OrderService.cancelOrder(order.id, 'Annulée par le vendeur');
        _loadOrders();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande annulée'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: _isLoading ? null : TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statusTabs.map((status) => Tab(
            text: _getStatusLabel(status),
          )).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                _buildStatsSection(),
                
                // Liste des commandes
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _statusTabs.map((status) => _buildOrdersList()).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  // Section statistiques
  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé des commandes',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildStatItem('Total', '${_stats!.totalOrders}', AppColors.primary),
              _buildStatItem('En attente', '${_stats!.pendingOrders}', AppColors.warning),
              _buildStatItem('Livrées', '${_stats!.deliveredOrders}', AppColors.success),
              _buildStatItem('Annulées', '${_stats!.cancelledOrders}', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Liste des commandes
  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Carte de commande
  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Informations client
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  order.buyerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  order.buyerPhone,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Articles de la commande
            Text(
              'Articles (${order.items.length})',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            ...order.items.take(2).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x ',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
            
            if (order.items.length > 2)
              Text(
                '... et ${order.items.length - 2} autre(s) article(s)',
                style: const TextStyle(
                  fontSize: AppFontSizes.xs,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Total et actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Bouton détail
                    OutlinedButton(
                      onPressed: () => _showOrderDetail(order),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      child: const Text(
                        'Détail',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.xs),
                    
                    // Actions selon le statut
                    _buildStatusAction(order),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Badge de statut
  Widget _buildStatusBadge(String status) {
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: statusInfo.color.withValues(alpha:0.3)),
      ),
      child: Text(
        statusInfo.label,
        style: TextStyle(
          fontSize: AppFontSizes.xs,
          color: statusInfo.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Actions selon le statut
  Widget _buildStatusAction(OrderModel order) {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order.id, 'confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: const Text('Confirmer'),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () => _cancelOrder(order),
              child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
        
      case 'confirmed':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(order.id, 'preparing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
          child: const Text('Préparer'),
        );
        
      case 'preparing':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(order.id, 'ready'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
          child: const Text('Prêt'),
        );
        
      case 'ready':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(order.id, 'in_delivery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
          child: const Text('En livraison'),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  // État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha:0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucune commande ${_selectedStatus == 'all' ? '' : _getStatusLabel(_selectedStatus).toLowerCase()}',
            style: const TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Afficher le détail d'une commande
  void _showOrderDetail(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Contenu
              Expanded(
                child: _buildOrderDetailContent(order, scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Contenu du détail de commande
  Widget _buildOrderDetailContent(OrderModel order, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: AppFontSizes.xl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: AppFontSizes.md,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Informations client
          _buildDetailSection('Informations client', [
            _buildDetailRow('Nom', order.buyerName),
            _buildDetailRow('Téléphone', order.buyerPhone),
          ]),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Adresse de livraison
          if (order.deliveryAddress.isNotEmpty)
            _buildDetailSection('Adresse de livraison', [
              Text(
                order.deliveryAddress,
                style: const TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textPrimary,
                ),
              ),
            ]),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Articles commandés
          _buildDetailSection('Articles commandés', [
            ...order.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Quantité: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Prix unitaire: ${item.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: AppFontSizes.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )),
          ]),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Récapitulatif des prix
          _buildDetailSection('Récapitulatif', [
            _buildDetailRow('Sous-total', '${order.subtotal.toStringAsFixed(0)} FCFA'),
            if (order.deliveryFee > 0)
              _buildDetailRow('Frais de livraison', '${order.deliveryFee.toStringAsFixed(0)} FCFA'),
            if (order.discount > 0)
              _buildDetailRow('Remise', '-${order.discount.toStringAsFixed(0)} FCFA'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ]),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Actions
          if (order.status.toLowerCase() != 'delivered' && order.status.toLowerCase() != 'cancelled')
            SizedBox(
              width: double.infinity,
              child: _buildStatusAction(order),
            ),
        ],
      ),
    );
  }

  // Section de détail
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  // Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir les informations de statut
  StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusInfo('En attente', AppColors.warning);
      case 'confirmed':
        return StatusInfo('Confirmée', AppColors.info);
      case 'preparing':
        return StatusInfo('En préparation', AppColors.primary);
      case 'ready':
        return StatusInfo('Prêt', AppColors.success);
      case 'in_delivery':
        return StatusInfo('En livraison', AppColors.secondary);
      case 'delivered':
        return StatusInfo('Livrée', AppColors.success);
      case 'cancelled':
        return StatusInfo('Annulée', AppColors.error);
      default:
        return StatusInfo(status, AppColors.textSecondary);
    }
  }

  // Obtenir le label du statut pour les onglets
  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'Toutes';
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmées';
      case 'preparing':
        return 'Préparation';
      case 'ready':
        return 'Prêtes';
      case 'in_delivery':
        return 'Livraison';
      case 'delivered':
        return 'Livrées';
      case 'cancelled':
        return 'Annulées';
      default:
        return status;
    }
  }

  // Formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Classe pour les informations de statut
class StatusInfo {
  final String label;
  final Color color;

  StatusInfo(this.label, this.color);
}

