// ===== lib/screens/admin/global_statistics_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/delivery_model.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';

class GlobalStatisticsScreen extends StatefulWidget {
  const GlobalStatisticsScreen({super.key});

  @override
  State<GlobalStatisticsScreen> createState() => _GlobalStatisticsScreenState();
}

class _GlobalStatisticsScreenState extends State<GlobalStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = '7days'; // 7days, 30days, 90days, all

  // Statistics data
  List<UserModel> _allUsers = [];
  List<ProductModel> _allProducts = [];
  List<OrderModel> _allOrders = [];
  List<DeliveryModel> _allDeliveries = [];

  // Computed metrics
  int _totalVendeurs = 0;
  int _totalAcheteurs = 0;
  int _totalLivreurs = 0;
  int _totalProducts = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;
  double _averageOrderValue = 0;

  Map<String, int> _ordersByStatus = {};
  Map<String, int> _deliveriesByStatus = {};
  List<MapEntry<String, int>> _topCategories = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Load all data
      // Load users from Firestore
      final usersSnapshot = await _firestore.collection(FirebaseCollections.users).get();
      final users = usersSnapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();

      // Load products from Firestore
      final productsSnapshot = await _firestore.collection(FirebaseCollections.products).get();
      final products =
          productsSnapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();

      // Load orders from Firestore
      final ordersSnapshot = await _firestore.collection(FirebaseCollections.orders).get();
      final orders = ordersSnapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Load deliveries from Firestore
      final deliveriesSnapshot = await _firestore.collection(FirebaseCollections.deliveries).get();
      final deliveries =
          deliveriesSnapshot.docs.map((doc) => DeliveryModel.fromMap(doc.data())).toList();

      setState(() {
        _allUsers = users;
        _allProducts = products;
        _allOrders = orders;
        _allDeliveries = deliveries;
      });

      _calculateMetrics();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _calculateMetrics() {
    // Filter by period
    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedPeriod) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        startDate = DateTime(2000); // All time
    }

    final filteredOrders = _allOrders.where((order) => order.createdAt.isAfter(startDate)).toList();

    // User counts
    _totalVendeurs = _allUsers.where((u) => u.userType == UserType.vendeur).length;
    _totalAcheteurs = _allUsers.where((u) => u.userType == UserType.acheteur).length;
    _totalLivreurs = _allUsers.where((u) => u.userType == UserType.livreur).length;

    // Product count
    _totalProducts = _allProducts.length;

    // Order metrics
    _totalOrders = filteredOrders.length;
    _totalRevenue = filteredOrders
        .where((o) => o.status == 'delivered' || o.status == 'completed')
        .fold<double>(0, (total, order) => total + order.totalAmount);
    _averageOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;

    // Orders by status
    _ordersByStatus = {};
    for (var order in filteredOrders) {
      _ordersByStatus[order.status] = (_ordersByStatus[order.status] ?? 0) + 1;
    }

    // Deliveries by status
    _deliveriesByStatus = {};
    for (var delivery in _allDeliveries) {
      _deliveriesByStatus[delivery.status] = (_deliveriesByStatus[delivery.status] ?? 0) + 1;
    }

    // Top categories
    final categoryCount = <String, int>{};
    for (var product in _allProducts) {
      categoryCount[product.category] = (categoryCount[product.category] ?? 0) + 1;
    }
    _topCategories = categoryCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    setState(() {});
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersChart() {
    if (_ordersByStatus.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Aucune donnée')),
        ),
      );
    }

    final statusLabels = {
      'pending': 'En attente',
      'confirmed': 'Confirmées',
      'preparing': 'En préparation',
      'ready': 'Prêtes',
      'delivering': 'En livraison',
      'delivered': 'Livrées',
      'cancelled': 'Annulées',
    };

    final statusColors = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'preparing': Colors.purple,
      'ready': Colors.cyan,
      'delivering': Colors.amber,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commandes par statut',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _ordersByStatus.entries.map((entry) {
                    final color = statusColors[entry.key] ?? Colors.grey;
                    final percentage = (entry.value / _totalOrders * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '$percentage%',
                      color: color,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ordersByStatus.entries.map((entry) {
                final color = statusColors[entry.key] ?? Colors.grey;
                final label = statusLabels[entry.key] ?? entry.key;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$label (${entry.value})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    if (_topCategories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Aucune donnée')),
        ),
      );
    }

    final top5 = _topCategories.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Catégories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: top5.first.value.toDouble() * 1.2,
                  barGroups: top5.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < top5.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                top5[value.toInt()].key,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Statistiques Globales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _calculateMetrics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7days', child: Text('7 derniers jours')),
              const PopupMenuItem(value: '30days', child: Text('30 derniers jours')),
              const PopupMenuItem(value: '90days', child: Text('90 derniers jours')),
              const PopupMenuItem(value: 'all', child: Text('Tout le temps')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _selectedPeriod == '7days'
                        ? '7 jours'
                        : _selectedPeriod == '30days'
                            ? '30 jours'
                            : _selectedPeriod == '90days'
                                ? '90 jours'
                                : 'Tout',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User metrics
                    const Text(
                      'Utilisateurs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Vendeurs',
                            '$_totalVendeurs',
                            Icons.store,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Acheteurs',
                            '$_totalAcheteurs',
                            Icons.shopping_bag,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Livreurs',
                            '$_totalLivreurs',
                            Icons.delivery_dining,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Total',
                            '${_allUsers.length}',
                            Icons.people,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Business metrics
                    const Text(
                      'Activité commerciale',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Produits actifs',
                      '$_totalProducts',
                      Icons.inventory,
                      Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Commandes',
                      '$_totalOrders',
                      Icons.receipt_long,
                      Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Chiffre d\'affaires',
                      '${_totalRevenue.toStringAsFixed(0)} FCFA',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Panier moyen',
                      '${_averageOrderValue.toStringAsFixed(0)} FCFA',
                      Icons.shopping_cart,
                      Colors.indigo,
                    ),
                    const SizedBox(height: 24),

                    // Charts
                    const Text(
                      'Graphiques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOrdersChart(),
                    const SizedBox(height: 16),
                    _buildTopCategoriesChart(),
                    const SizedBox(height: 24),

                    // Delivery metrics
                    const Text(
                      'Livraisons',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _deliveriesByStatus.entries.map((entry) {
                            final statusLabels = {
                              'pending': 'En attente',
                              'picked_up': 'Récupérées',
                              'in_transit': 'En transit',
                              'delivered': 'Livrées',
                              'failed': 'Échouées',
                            };
                            final statusColors = {
                              'pending': Colors.orange,
                              'picked_up': Colors.blue,
                              'in_transit': Colors.purple,
                              'delivered': Colors.green,
                              'failed': Colors.red,
                            };

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: statusColors[entry.key] ?? Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(statusLabels[entry.key] ?? entry.key),
                                    ],
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

