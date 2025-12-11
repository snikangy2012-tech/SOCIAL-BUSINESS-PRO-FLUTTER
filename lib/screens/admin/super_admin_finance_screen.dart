// ===== lib/screens/admin/super_admin_finance_screen.dart =====
// Écran de gestion financière pour le super administrateur

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../services/platform_revenue_service.dart';
import '../../models/revenue_model.dart' as revenue;
import '../../models/financial_summary_model.dart';
import '../widgets/system_ui_scaffold.dart';

class SuperAdminFinanceScreen extends StatefulWidget {
  const SuperAdminFinanceScreen({super.key});

  @override
  State<SuperAdminFinanceScreen> createState() => _SuperAdminFinanceScreenState();
}

class _SuperAdminFinanceScreenState extends State<SuperAdminFinanceScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  // État du filtre de période
  String _selectedPeriod = 'month'; // 'week', 'month', '3months', 'year', 'all'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Données
  Map<String, dynamic>? _globalStats;
  FinancialSummary? _currentMonthSummary;
  List<revenue.RevenueModel> _recentRevenues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les statistiques globales
      final globalStats = await PlatformRevenueService.getGlobalStats();

      // Charger le résumé du mois en cours
      final now = DateTime.now();
      final monthSummary = await PlatformRevenueService.getMonthlySummary(now.year, now.month);

      // Charger les revenus récents (30 derniers jours)
      final recentRevenues = await PlatformRevenueService.getRevenueByPeriod(
        _startDate,
        _endDate,
      );

      setState(() {
        _globalStats = globalStats;
        _currentMonthSummary = monthSummary;
        _recentRevenues = recentRevenues;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données financières: $e');
      setState(() => _isLoading = false);
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case '3months':
          _startDate = now.subtract(const Duration(days: 90));
          _endDate = now;
          break;
        case 'year':
          _startDate = now.subtract(const Duration(days: 365));
          _endDate = now;
          break;
        case 'all':
          _startDate = DateTime(2020, 1, 1); // Date arbitraire ancienne
          _endDate = now;
          break;
      }
    });

    _loadFinancialData();
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Gestion Financière'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Bouton de rafraîchissement
          IconButton(
            onPressed: _loadFinancialData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur de période
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // Cartes statistiques principales
                    _buildStatsCards(),
                    const SizedBox(height: 24),

                    // Résumé du mois en cours
                    _buildCurrentMonthSummary(),
                    const SizedBox(height: 24),

                    // Transactions récentes
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  // Sélecteur de période
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPeriodButton('7j', 'week'),
          _buildPeriodButton('30j', 'month'),
          _buildPeriodButton('3m', '3months'),
          _buildPeriodButton('1an', 'year'),
          _buildPeriodButton('Tout', 'all'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _changePeriod(period),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.primary : Colors.white,
            foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  // Cartes de statistiques
  Widget _buildStatsCards() {
    if (_globalStats == null) {
      return const SizedBox();
    }

    final stats = _globalStats!;
    final totalRevenue = stats['totalRevenue'] as double;
    final commissionsVente = stats['commissionsVente'] as double;
    final commissionsLivraison = stats['commissionsLivraison'] as double;
    final abonnements = (stats['abonnementsVendeurs'] as double) +
                       (stats['abonnementsLivreurs'] as double);

    return Column(
      children: [
        // Revenu total (grande carte)
        _buildStatCard(
          title: 'Revenu Total',
          value: currencyFormat.format(totalRevenue),
          icon: Icons.account_balance_wallet,
          color: AppColors.primary,
          isLarge: true,
        ),
        const SizedBox(height: 12),

        // Trois cartes en ligne
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Commissions Ventes',
                value: currencyFormat.format(commissionsVente),
                icon: Icons.shopping_cart,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Commissions Livraisons',
                value: currencyFormat.format(commissionsLivraison),
                icon: Icons.local_shipping,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carte abonnements
        _buildStatCard(
          title: 'Abonnements',
          value: currencyFormat.format(abonnements),
          icon: Icons.card_membership,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isLarge ? 28 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isLarge ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: isLarge ? 24 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Résumé du mois en cours
  Widget _buildCurrentMonthSummary() {
    if (_currentMonthSummary == null) {
      return const SizedBox();
    }

    final summary = _currentMonthSummary!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                summary.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Statistiques du mois
          _buildSummaryRow('Commandes livrées', summary.nbCommandesLivrees.toString()),
          _buildSummaryRow('Livraisons effectuées', summary.nbLivraisons.toString()),
          _buildSummaryRow('Abonnements vendeurs actifs', summary.nbAbonnementsVendeursActifs.toString()),
          _buildSummaryRow('Abonnements livreurs actifs', summary.nbAbonnementsLivreursActifs.toString()),

          const Divider(height: 24),

          // Total du mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total du mois',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(summary.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Transactions récentes
  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Transactions récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          if (_recentRevenues.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune transaction pour la période sélectionnée',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentRevenues.length > 10 ? 10 : _recentRevenues.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rev = _recentRevenues[index];
                return _buildTransactionTile(rev);
              },
            ),

          if (_recentRevenues.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  '${_recentRevenues.length - 10} autres transactions...',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(revenue.RevenueModel rev) {
    IconData icon;
    Color color;

    switch (rev.type) {
      case revenue.RevenueType.commissionVente:
        icon = Icons.shopping_cart;
        color = AppColors.success;
        break;
      case revenue.RevenueType.commissionLivraison:
        icon = Icons.local_shipping;
        color = AppColors.info;
        break;
      case revenue.RevenueType.abonnementVendeur:
      case revenue.RevenueType.abonnementLivreur:
        icon = Icons.card_membership;
        color = AppColors.secondary;
        break;
    }

    final dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'fr_FR');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        rev.typeLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            rev.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(rev.createdAt),
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: Text(
        currencyFormat.format(rev.amount),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
