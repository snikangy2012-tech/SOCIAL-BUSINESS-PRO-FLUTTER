// ===== lib/screens/livreur/livreur_commissions_screen.dart =====
// Écran pour que les livreurs voient leurs commissions à payer à la plateforme

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/platform_transaction_model.dart';
import '../../services/platform_transaction_service.dart';
import '../../services/livreur_stats_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class LivreurCommissionsScreen extends StatefulWidget {
  const LivreurCommissionsScreen({super.key});

  @override
  State<LivreurCommissionsScreen> createState() => _LivreurCommissionsScreenState();
}

class _LivreurCommissionsScreenState extends State<LivreurCommissionsScreen> {
  bool _isLoading = true;
  List<PlatformTransaction> _pendingCommissions = [];
  double _totalDebt = 0.0;
  final String _livreurId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Statistiques mensuelles
  double _monthEarnings = 0.0;
  double _commissionRate = 0.25;
  double _monthCommission = 0.0;
  double _monthNetRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    if (_livreurId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Charger les commissions en attente
      final pending = await PlatformTransactionService.getPendingLivreurCommissions(_livreurId);

      // Calculer le total dû
      final total = await PlatformTransactionService.getTotalLivreurDebt(_livreurId);

      // Charger les statistiques mensuelles
      final livreurStats = await LivreurStatsService.getLivreurStats(_livreurId);

      // Charger le taux de commission
      final subscriptionService = SubscriptionService();
      double commissionRate = 0.25;
      try {
        commissionRate = await subscriptionService.getLivreurCommissionRate(_livreurId);
      } catch (e) {
        debugPrint('⚠️ Erreur chargement taux commission: $e');
      }

      // Calculer commission et revenu net
      final monthCommission = livreurStats.monthEarnings * commissionRate;
      final monthNetRevenue = livreurStats.monthEarnings - monthCommission;

      setState(() {
        _pendingCommissions = pending;
        _totalDebt = total;
        _monthEarnings = livreurStats.monthEarnings.toDouble();
        _commissionRate = commissionRate;
        _monthCommission = monthCommission.toDouble();
        _monthNetRevenue = monthNetRevenue.toDouble();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement commissions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/livreur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mes Commissions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCommissions,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistiques mensuelles
        _buildMonthlyStatsCard(),
        const SizedBox(height: 24),

        // Carte total dû
        _buildTotalDebtCard(),
        const SizedBox(height: 24),

        // Explication
        _buildExplanationCard(),
        const SizedBox(height: 24),

        // Liste des commissions en attente
        if (_pendingCommissions.isEmpty) ...[
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Aucune commission en attente',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Vous êtes à jour avec vos paiements !',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(
            'Commissions en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._pendingCommissions.map((transaction) => _buildCommissionCard(transaction)),
        ],
      ],
    );
  }

  Widget _buildMonthlyStatsCard() {
    return Card(
      elevation: 4,
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Statistiques du mois',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Revenu brut
            _buildStatRow(
              'Revenu brut',
              formatPriceWithCurrency(_monthEarnings, currency: 'FCFA'),
              AppColors.primary,
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Commission
            _buildStatRow(
              'Commission (${(_commissionRate * 100).toStringAsFixed(0)}%)',
              '- ${formatPriceWithCurrency(_monthCommission, currency: 'FCFA')}',
              AppColors.error,
              Icons.percent,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Revenu net
            _buildStatRow(
              'Revenu net',
              formatPriceWithCurrency(_monthNetRevenue, currency: 'FCFA'),
              AppColors.success,
              Icons.account_balance,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon, {bool isBold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalDebtCard() {
    final hasDebt = _totalDebt > 0;

    return Card(
      elevation: 4,
      color: hasDebt ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasDebt ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: hasDebt ? Colors.orange : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Total à reverser',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${NumberFormat('#,###').format(_totalDebt)} FCFA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: hasDebt ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasDebt
                  ? '${_pendingCommissions.length} livraison(s) cash à régler'
                  : 'Vous êtes à jour !',
              style: TextStyle(
                fontSize: 14,
                color: hasDebt ? Colors.orange.shade900 : Colors.green.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Comment ça marche ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pour les paiements en CASH :\n\n'
            '• Vous collectez l\'argent auprès du client\n'
            '• La plateforme prélève une commission sur vos gains\n'
            '• Vous devez reverser cette commission à la plateforme\n'
            '• Contactez l\'administrateur pour effectuer le paiement\n\n'
            'Pour les paiements MOBILE MONEY :\n\n'
            '• Les commissions sont automatiquement retenues\n'
            '• Aucune action requise de votre part',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard(PlatformTransaction transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.money, color: Colors.brown),
        title: Text(
          'Commande #${transaction.metadata['displayNumber'] ?? transaction.orderId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Collecté le ${dateFormat.format(transaction.cashCollectedAt ?? transaction.createdAt)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PAIEMENT CASH',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,###').format(transaction.totalPlatformRevenue)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
            const Text(
              'À reverser',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la commission',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(height: 24),
                _buildDetailRow('Frais de livraison total',
                    '${NumberFormat('#,###').format(transaction.orderAmount)} FCFA'),
                _buildDetailRow('Votre part',
                    '${NumberFormat('#,###').format(transaction.livreurAmount)} FCFA'),
                _buildDetailRow('Commission plateforme vendeur',
                    '${NumberFormat('#,###').format(transaction.platformCommissionVendeur)} FCFA'),
                _buildDetailRow('Commission plateforme livreur',
                    '${NumberFormat('#,###').format(transaction.platformCommissionLivreur)} FCFA (${(transaction.livreurCommissionRate * 100).toStringAsFixed(0)}%)'),
                const Divider(height: 24),
                _buildDetailRow(
                  'Total à reverser',
                  '${NumberFormat('#,###').format(transaction.totalPlatformRevenue)} FCFA',
                  bold: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Contactez l\'administrateur pour effectuer le paiement de cette commission',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

