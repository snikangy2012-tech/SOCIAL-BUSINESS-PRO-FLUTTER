// ===== lib/screens/vendeur/vendeur_statistics.dart =====
// Migration complète de src/components/Vendeur/Statistics.tsx vers Flutter

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';


import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/statistics_service.dart';
import '../../models/statistics_model.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // État
  String _selectedPeriod = '30d';
  String _selectedMetric = 'revenue';
  bool _isLoading = true;
  VendorStatsResponse? _statsData;

  // Options des périodes
  final List<Map<String, String>> _periods = [
    {'value': '7d', 'label': '7 jours'},
    {'value': '30d', 'label': '30 jours'},
    {'value': '90d', 'label': '3 mois'},
    {'value': '1y', 'label': '1 an'},
  ];

  // Options des métriques
  final List<Map<String, dynamic>> _metrics = [
    {'key': 'revenue', 'label': 'Revenus', 'color': AppColors.success},
    {'key': 'orders', 'label': 'Commandes', 'color': AppColors.info},
    {'key': 'views', 'label': 'Vues', 'color': AppColors.warning},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Charger les statistiques
  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);
      
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.user?.id;
      
      if (vendorId != null) {
        final stats = await StatisticsService.getVendorStats(vendorId, _selectedPeriod);
        setState(() {
          _statsData = stats;
        });
      }
    } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement statistiques: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Rafraîchir les données
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadStatistics();
    setState(() => _isLoading = false);
  }

  // Changer de période
  void _changePeriod(String newPeriod) {
    setState(() {
      _selectedPeriod = newPeriod;
    });
    _loadStatistics();
  }

  // Changer de métrique
  void _changeMetric(String newMetric) {
    setState(() {
      _selectedMetric = newMetric;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vue d\'ensemble'),
            Tab(text: 'Produits'),
            Tab(text: 'Clients'),
            Tab(text: 'Réseaux'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  // Sélecteur de période
                  _buildPeriodSelector(),
                  
                  // Contenu des onglets
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildProductsTab(),
                        _buildCustomersTab(),
                        _buildSocialTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Sélecteur de période
  Widget _buildPeriodSelector() {
    return Container(
      height: 60,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: _periods.map((period) {
            final isSelected = period['value'] == _selectedPeriod;
            return Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.sm, bottom: AppSpacing.sm),
              child: FilterChip(
                label: Text(period['label']!),
                selected: isSelected,
                onSelected: (_) => _changePeriod(period['value']!),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary.withValues(alpha:0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Onglet Vue d'ensemble
  Widget _buildOverviewTab() {
    if (_statsData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métriques principales
          _buildMetricsGrid(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Graphique principal
          _buildMainChart(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Résumé rapide
          _buildQuickSummary(),
        ],
      ),
    );
  }

  // Grille des métriques
  Widget _buildMetricsGrid() {
    final overview = _statsData!.overview;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Chiffre d\'affaires',
          '${overview.totalRevenue.toStringAsFixed(0)} FCFA',
          overview.growthRate,
          Icons.attach_money,
          AppColors.success,
        ),
        _buildMetricCard(
          'Commandes',
          overview.totalOrders.toString(),
          15.3, // Simulation
          Icons.receipt,
          AppColors.info,
        ),
        _buildMetricCard(
          'Panier moyen',
          '${overview.averageOrderValue.toStringAsFixed(0)} FCFA',
          -2.1, // Simulation
          Icons.shopping_cart,
          AppColors.warning,
        ),
        _buildMetricCard(
          'Taux conversion',
          '${overview.conversionRate.toStringAsFixed(1)}%',
          8.7, // Simulation
          Icons.trending_up,
          AppColors.primary,
        ),
      ],
    );
  }

  // Carte métrique
  Widget _buildMetricCard(String title, String value, double change, IconData icon, Color color) {
    final isPositive = change >= 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      Text(
                        '${change.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: AppFontSizes.xs,
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Graphique principal
  Widget _buildMainChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Évolution des performances',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Sélecteur de métrique
                _buildMetricSelector(),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Graphique
            SizedBox(
              height: 250,
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  // Sélecteur de métrique pour le graphique
  Widget _buildMetricSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _metrics.map((metric) {
          final isSelected = metric['key'] == _selectedMetric;
          return Container(
            margin: const EdgeInsets.only(left: AppSpacing.xs),
            child: FilterChip(
              label: Text(metric['label']),
              selected: isSelected,
              onSelected: (_) => _changeMetric(metric['key']),
              backgroundColor: Colors.transparent,
              selectedColor: metric['color'].withValues(alpha:0.2),
              labelStyle: TextStyle(
                color: isSelected ? metric['color'] : AppColors.textSecondary,
                fontSize: AppFontSizes.sm,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Graphique en ligne
  Widget _buildLineChart() {
    if (_statsData?.chartData == null || _statsData!.chartData.isEmpty) {
      return const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final chartData = _statsData!.chartData;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < chartData.length; i++) {
      final data = chartData[i];
      double value = 0;
      
      switch (_selectedMetric) {
        case 'revenue':
          value = data.revenue;
          break;
        case 'orders':
          value = data.orders.toDouble();
          break;
        case 'views':
          value = data.views.toDouble();
          break;
      }
      
      spots.add(FlSpot(i.toDouble(), value));
    }

    final metricInfo = _metrics.firstWhere((m) => m['key'] == _selectedMetric);
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: metricInfo['color'],
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: metricInfo['color'].withValues(alpha:0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatChartValue(value),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSizes.xs,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return Text(
                    _formatDate(chartData[index].date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.xs,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: null,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '${_formatChartValue(touchedSpot.y)}\n${_formatDate(chartData[touchedSpot.x.toInt()].date)}',
                  const TextStyle(color: Colors.white, fontSize: AppFontSizes.sm),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // Résumé rapide
  Widget _buildQuickSummary() {
    final overview = _statsData!.overview;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la période',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            _buildSummaryRow('Produit le plus vendu', overview.topProduct),
            _buildSummaryRow('Nombre de produits actifs', '${overview.activeProducts}'),
            _buildSummaryRow('Note moyenne', '${overview.averageRating}/5'),
            _buildSummaryRow('Vues ce mois', '${overview.viewsThisMonth}'),
          ],
        ),
      ),
    );
  }

  // Ligne de résumé
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.md,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Produits
  Widget _buildProductsTab() {
    if (_statsData?.productStats == null || _statsData!.productStats.isEmpty) {
      return const Center(
        child: Text(
          'Aucune donnée produit disponible',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _statsData!.productStats.length,
      itemBuilder: (context, index) {
        final product = _statsData!.productStats[index];
        return _buildProductStatCard(product);
      },
    );
  }

  // Carte statistique produit
  Widget _buildProductStatCard(ProductStat product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: AppColors.backgroundSecondary,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Informations du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppSpacing.xs),
                  
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  Row(
                    children: [
                      _buildProductMetric('${product.sales} ventes', AppColors.success),
                      const SizedBox(width: AppSpacing.md),
                      _buildProductMetric('${product.views} vues', AppColors.info),
                    ],
                  ),
                ],
              ),
            ),
            
            // Revenus
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.revenue.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xs),
                
                Text(
                  '${product.conversionRate.toStringAsFixed(1)}% conv.',
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métrique produit
  Widget _buildProductMetric(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSizes.xs,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Onglet Clients
  Widget _buildCustomersTab() {
    if (_statsData?.customerStats == null) return const SizedBox.shrink();

    final customerStats = _statsData!.customerStats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Statistiques clients générales
          _buildCustomerMetricsGrid(customerStats),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Graphique de rétention (simulation)
          _buildRetentionChart(),
        ],
      ),
    );
  }

  // Grille métriques clients
  Widget _buildCustomerMetricsGrid(CustomerStats customerStats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total clients',
          customerStats.totalCustomers.toString(),
          12.5,
          Icons.people,
          AppColors.primary,
        ),
        _buildMetricCard(
          'Nouveaux clients',
          customerStats.newCustomers.toString(),
          25.3,
          Icons.person_add,
          AppColors.success,
        ),
        _buildMetricCard(
          'Clients fidèles',
          customerStats.returningCustomers.toString(),
          8.1,
          Icons.favorite,
          AppColors.secondary,
        ),
        _buildMetricCard(
          'Taux de rétention',
          '${customerStats.customerRetentionRate.toStringAsFixed(1)}%',
          -2.4,
          Icons.trending_down,
          AppColors.warning,
        ),
      ],
    );
  }

  // Graphique de rétention (simulation)
  Widget _buildRetentionChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du nombre de clients',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 10),
                        const FlSpot(1, 15),
                        const FlSpot(2, 12),
                        const FlSpot(3, 18),
                        const FlSpot(4, 22),
                        const FlSpot(5, 25),
                        const FlSpot(6, 30),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha:0.1),
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Onglet Réseaux sociaux
  Widget _buildSocialTab() {
    if (_statsData?.socialStats == null) return const SizedBox.shrink();

    final socialStats = _statsData!.socialStats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildSocialPlatformCard('Instagram', socialStats.instagram, Icons.camera_alt, const Color(0xFFE4405F)),
          const SizedBox(height: AppSpacing.md),
          _buildSocialPlatformCard('TikTok', socialStats.tiktok, Icons.music_video, Colors.black),
          const SizedBox(height: AppSpacing.md),
          _buildSocialPlatformCard('Facebook', socialStats.facebook, Icons.facebook, const Color(0xFF4267B2)),
          const SizedBox(height: AppSpacing.md),
          _buildWhatsAppCard(socialStats.whatsapp),
        ],
      ),
    );
  }

  // Carte plateforme sociale
  Widget _buildSocialPlatformCard(String platform, SocialMediaStat stats, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  platform,
                  style: const TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialMetric('Followers', '${stats.followers}', Icons.people),
                _buildSocialMetric('Engagement', '${stats.engagement.toStringAsFixed(1)}%', Icons.favorite),
                _buildSocialMetric('Clics', '${stats.clicks}', Icons.touch_app),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Carte WhatsApp
  Widget _buildWhatsAppCard(Map<String, dynamic> whatsappStats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.message, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'WhatsApp Business',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialMetric('Contacts', '${whatsappStats['contacts']}', Icons.contacts),
                _buildSocialMetric('Messages', '${whatsappStats['messagesSent']}', Icons.send),
                _buildSocialMetric('Réponses', '${whatsappStats['responses']}', Icons.reply),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métrique sociale
  Widget _buildSocialMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
    );
  }

  // Méthodes utilitaires
  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}';
  }

}