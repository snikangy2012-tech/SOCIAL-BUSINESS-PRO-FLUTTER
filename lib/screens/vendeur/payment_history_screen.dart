// ===== lib/screens/vendeur/payment_history_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../models/payment_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedPeriod = '30';
  String _selectedMethod = 'all';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vendeurId = authProvider.user?.id;

    if (vendeurId == null) {
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendeur-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Historique des Paiements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSummaryCards(vendeurId),
          Expanded(child: _buildPaymentsList(vendeurId)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundSecondary,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Période',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                    value: '7', child: Text('7 jours', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: '30', child: Text('30 jours', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: '90', child: Text('3 mois', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'all', child: Text('Tout', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Méthode',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous')),
                DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(value: 'card', child: Text('Carte')),
              ],
              onChanged: (value) {
                setState(() => _selectedMethod = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String vendeurId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPaymentsStream(vendeurId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100);
        }

        final payments = snapshot.data!.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();

        final totalValidated = payments
            .where((p) => p.status == 'completed')
            .fold<double>(0, (sum, p) => sum + p.amount);

        final totalPending = payments
            .where((p) => p.status == 'pending')
            .fold<double>(0, (sum, p) => sum + p.amount);

        final totalFees = payments
            .where((p) => p.status == 'completed')
            .fold<double>(0, (sum, p) => sum + (p.transactionFee ?? 0));

        final netAmount = totalValidated - totalFees;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Validé',
                      '${NumberFormat('#,##0').format(totalValidated)} FCFA',
                      AppColors.success,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'En Attente',
                      '${NumberFormat('#,##0').format(totalPending)} FCFA',
                      AppColors.warning,
                      Icons.pending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Frais',
                      '${NumberFormat('#,##0').format(totalFees)} FCFA',
                      AppColors.error,
                      Icons.remove_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Net à Recevoir',
                      '${NumberFormat('#,##0').format(netAmount)} FCFA',
                      AppColors.primary,
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(String vendeurId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPaymentsStream(vendeurId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun paiement',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final payments = snapshot.data!.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: payments.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final statusIcon = _getStatusIcon(payment.status);
    final statusColor = _getStatusColor(payment.status);
    final methodIcon = _getMethodIcon(payment.paymentMethod);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(methodIcon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.orderNumber ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getMethodLabel(payment.paymentMethod),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(payment.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0').format(payment.amount)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (payment.transactionFee != null && payment.transactionFee! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Frais',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '- ${NumberFormat('#,##0').format(payment.transactionFee)} FCFA',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(payment.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getPaymentsStream(String vendeurId) {
    Query query = FirebaseFirestore.instance
        .collection(FirebaseCollections.payments)
        .where('vendeurId', isEqualTo: vendeurId);

    // Filtre par période
    if (_selectedPeriod != 'all') {
      final days = int.parse(_selectedPeriod);
      final startDate = DateTime.now().subtract(Duration(days: days));
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    // Filtre par méthode
    if (_selectedMethod != 'all') {
      query = query.where('paymentMethod', isEqualTo: _selectedMethod);
    }

    // ✅ CORRECTION: Suppression du filtre "Statut" (non applicable aux paiements)
    // Les paiements ont leur propre workflow de validation, pas de "statut de commande"

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Validé';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échoué';
      default:
        return status;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'mobile_money':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte Bancaire';
      default:
        return method;
    }
  }
}

