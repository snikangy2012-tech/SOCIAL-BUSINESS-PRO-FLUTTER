// ===== lib/screens/admin/admin_transactions_screen.dart =====
// Écran administrateur pour gérer les transactions et commissions de la plateforme

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../models/platform_transaction_model.dart';
import '../../services/platform_transaction_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<PlatformTransaction> _allTransactions = [];
  List<PlatformTransaction> _pendingTransactions = [];
  List<PlatformTransaction> _paidTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les statistiques globales
      final stats = await PlatformTransactionService.getGlobalTransactionStats();

      // Charger toutes les transactions
      final all = await PlatformTransactionService.getAllTransactions(limit: 100);

      // Charger les transactions en attente
      final pending = await PlatformTransactionService.getTransactionsByStatus(
        CommissionPaymentStatus.pending,
        limit: 50,
      );

      // Charger les transactions payées
      final paid = await PlatformTransactionService.getTransactionsByStatus(
        CommissionPaymentStatus.paid,
        limit: 50,
      );

      setState(() {
        _stats = stats;
        _allTransactions = all;
        _pendingTransactions = pending;
        _paidTransactions = paid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Gestion des Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'En attente'),
            Tab(text: 'Payées'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPendingTab(),
                _buildPaidTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final totalRevenue = _stats['totalRevenue'] ?? 0.0;
    final totalPending = _stats['totalPending'] ?? 0.0;
    final totalPaid = _stats['totalPaid'] ?? 0.0;
    final totalTransactions = _stats['totalTransactions'] ?? 0;
    final cashTransactions = _stats['cashTransactions'] ?? 0;
    final mobileMoneyTransactions = _stats['mobileMoneyTransactions'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte revenue total
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Total Plateforme',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${NumberFormat('#,###').format(totalRevenue)} FCFA',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques en grille
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  '${NumberFormat('#,###').format(totalPending)} FCFA',
                  Colors.orange,
                  Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Payées',
                  '${NumberFormat('#,###').format(totalPaid)} FCFA',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total transactions',
                  totalTransactions.toString(),
                  Colors.purple,
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Cash',
                  cashTransactions.toString(),
                  Colors.brown,
                  Icons.money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Mobile Money',
            mobileMoneyTransactions.toString(),
            Colors.teal,
            Icons.phone_android,
          ),
          const SizedBox(height: 24),

          // Dernières transactions
          const Text(
            'Dernières transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._allTransactions.take(10).map((transaction) => _buildTransactionCard(transaction)),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune commission en attente',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_pendingTransactions.length} commission(s) en attente de paiement',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._pendingTransactions
              .map((transaction) => _buildTransactionCard(transaction, showActions: true)),
        ],
      ),
    );
  }

  Widget _buildPaidTab() {
    if (_paidTransactions.isEmpty) {
      return const Center(
        child: Text('Aucune transaction payée'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children:
            _paidTransactions.map((transaction) => _buildTransactionCard(transaction)).toList(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(PlatformTransaction transaction, {bool showActions = false}) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isCash = transaction.paymentMethod == PaymentCollectionMethod.cash;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isCash ? Icons.money : Icons.phone_android,
          color: isCash ? Colors.brown : Colors.teal,
        ),
        title: Text(
          'Commande #${transaction.metadata['displayNumber'] ?? transaction.orderId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.metadata['vendeurName']}'),
            Text(
              dateFormat.format(transaction.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              ),
            ),
            _buildStatusBadge(transaction.status),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Méthode de paiement', isCash ? 'Cash' : 'Mobile Money'),
                _buildDetailRow('Commission vendeur',
                    '${NumberFormat('#,###').format(transaction.platformCommissionVendeur)} FCFA (${(transaction.vendeurCommissionRate * 100).toStringAsFixed(0)}%)'),
                _buildDetailRow('Commission livreur',
                    '${NumberFormat('#,###').format(transaction.platformCommissionLivreur)} FCFA (${(transaction.livreurCommissionRate * 100).toStringAsFixed(0)}%)'),
                _buildDetailRow('Total plateforme',
                    '${NumberFormat('#,###').format(transaction.totalPlatformRevenue)} FCFA'),
                const Divider(height: 24),
                _buildDetailRow('Montant vendeur',
                    '${NumberFormat('#,###').format(transaction.vendeurAmount)} FCFA'),
                _buildDetailRow('Montant livreur',
                    '${NumberFormat('#,###').format(transaction.livreurAmount)} FCFA'),
                if (showActions && transaction.status == CommissionPaymentStatus.pending) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _markAsPaid(transaction),
                    icon: const Icon(Icons.check),
                    label: const Text('Marquer comme payée'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CommissionPaymentStatus status) {
    Color color;
    String label;

    switch (status) {
      case CommissionPaymentStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case CommissionPaymentStatus.paid:
        color = Colors.green;
        label = 'Payée';
        break;
      case CommissionPaymentStatus.settled:
        color = Colors.blue;
        label = 'Réglée';
        break;
      case CommissionPaymentStatus.cancelled:
        color = Colors.red;
        label = 'Annulée';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _markAsPaid(PlatformTransaction transaction) async {
    // Demander la référence de paiement
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Marquer la commission de ${NumberFormat('#,###').format(transaction.totalPlatformRevenue)} FCFA comme payée ?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Référence de paiement',
                hintText: 'Ex: REF123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      try {
        final success = await PlatformTransactionService.markLivreurCommissionPaid(
          transactionId: transaction.id,
          paymentReference: controller.text,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commission marquée comme payée'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recharger les données
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

