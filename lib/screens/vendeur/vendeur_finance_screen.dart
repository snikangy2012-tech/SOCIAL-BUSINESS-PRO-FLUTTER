// ===== lib/screens/vendeur/vendeur_finance_screen.dart =====
// Écran de gestion des finances - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../models/order_model.dart';
import '../../utils/order_status_helper.dart';
import '../../utils/number_formatter.dart';
import '../widgets/system_ui_scaffold.dart';

class VendeurFinanceScreen extends StatefulWidget {
  const VendeurFinanceScreen({super.key});

  @override
  State<VendeurFinanceScreen> createState() => _VendeurFinanceScreenState();
}

class _VendeurFinanceScreenState extends State<VendeurFinanceScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<OrderModel> _allSales = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Statistiques
  double _totalRevenue = 0;
  double _monthRevenue = 0;
  double _weekRevenue = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;

  // Filtres
  late TabController _tabController;
  final List<String> _periodFilters = ['Tout', 'Aujourd\'hui', 'Semaine', 'Mois', 'Année'];
  int _selectedPeriodIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('📊 Chargement des ventes pour vendeur: $userId');

      // Récupérer toutes les commandes du vendeur
      final querySnapshot = await _db
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _allSales = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      _calculateStatistics();

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ ${_allSales.length} ventes chargées');
    } catch (e) {
      debugPrint('❌ Erreur chargement ventes: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    _totalRevenue = 0;
    _monthRevenue = 0;
    _weekRevenue = 0;
    _totalOrders = _allSales.length;
    _completedOrders = 0;

    for (var sale in _allSales) {
      if (sale.status == 'delivered' || sale.status == 'completed') {
        _totalRevenue += sale.totalAmount;
        _completedOrders++;

        if (sale.createdAt.isAfter(startOfMonth)) {
          _monthRevenue += sale.totalAmount;
        }

        if (sale.createdAt.isAfter(startOfWeek)) {
          _weekRevenue += sale.totalAmount;
        }
      }
    }
  }

  List<OrderModel> _getFilteredSales() {
    final now = DateTime.now();

    switch (_selectedPeriodIndex) {
      case 1: // Aujourd'hui
        return _allSales.where((sale) {
          final saleDate = sale.createdAt;
          return saleDate.year == now.year &&
                 saleDate.month == now.month &&
                 saleDate.day == now.day;
        }).toList();

      case 2: // Semaine
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return _allSales.where((sale) => sale.createdAt.isAfter(startOfWeek)).toList();

      case 3: // Mois
        final startOfMonth = DateTime(now.year, now.month, 1);
        return _allSales.where((sale) => sale.createdAt.isAfter(startOfMonth)).toList();

      case 4: // Année
        final startOfYear = DateTime(now.year, 1, 1);
        return _allSales.where((sale) => sale.createdAt.isAfter(startOfYear)).toList();

      default: // Tout
        return _allSales;
    }
  }

  List<OrderModel> _getSalesByStatus(String status) {
    final filtered = _getFilteredSales();

    switch (status.toLowerCase()) {
      case 'all':
        return filtered;
      case 'pending':
        return filtered.where((s) {
          final st = s.status.toLowerCase();
          return st == 'pending' || st == 'en_attente';
        }).toList();
      case 'processing':
        // En cours: confirmée, en préparation, prête, ou en livraison
        return filtered.where((s) {
          final st = s.status.toLowerCase();
          return st == 'confirmed' ||
                 st == 'preparing' ||
                 st == 'ready' ||
                 st == 'in_delivery' ||
                 st == 'in delivery' ||
                 st == 'processing' ||
                 st == 'en_cours';
        }).toList();
      case 'completed':
        return filtered.where((s) {
          final st = s.status.toLowerCase();
          return st == 'delivered' || st == 'completed' || st == 'livree';
        }).toList();
      case 'cancelled':
        return filtered.where((s) {
          final st = s.status.toLowerCase();
          return st == 'cancelled' || st == 'canceled' || st == 'annulee';
        }).toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Finances & Ventes'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Tout (${_getSalesByStatus('all').length})'),
            Tab(text: 'En attente (${_getSalesByStatus('pending').length})'),
            Tab(text: 'En cours (${_getSalesByStatus('processing').length})'),
            Tab(text: 'Terminées (${_getSalesByStatus('completed').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : Column(
                  children: [
                    _buildStatisticsSection(),
                    _buildPeriodFilter(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSalesList(_getSalesByStatus('all')),
                          _buildSalesList(_getSalesByStatus('pending')),
                          _buildSalesList(_getSalesByStatus('processing')),
                          _buildSalesList(_getSalesByStatus('completed')),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSales,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Cartes statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Revenu Total',
                  formatPriceWithCurrency(_totalRevenue, currency: 'FCFA'),
                  Icons.account_balance_wallet,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ce Mois',
                  formatPriceWithCurrency(_monthRevenue, currency: 'FCFA'),
                  Icons.calendar_today,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Commandes',
                  '$_totalOrders',
                  Icons.shopping_bag,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Livrées',
                  '$_completedOrders',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _periodFilters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedPeriodIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periodFilters[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPeriodIndex = index;
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesList(List<OrderModel> sales) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les ventes apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final sale = sales[index];
          return _buildSaleCard(sale);
        },
      ),
    );
  }

  Widget _buildSaleCard(OrderModel sale) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/vendeur/sale-detail/${sale.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande ${sale.displayNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(sale.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(sale.status),
                ],
              ),

              const Divider(height: 24),

              // Détails
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sale.buyerName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.shopping_bag, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${sale.items.length} article(s)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatPriceWithCurrency(sale.totalAmount, currency: 'FCFA'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    // ✅ Utiliser le helper centralisé pour les statuts
    return OrderStatusHelper.statusBadge(status, compact: true);
  }
}
