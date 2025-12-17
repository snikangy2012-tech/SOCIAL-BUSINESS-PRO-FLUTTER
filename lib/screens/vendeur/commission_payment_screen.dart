// ===== lib/screens/vendeur/commission_payment_screen.dart =====
// Écran de paiement des commissions - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../services/commission_enforcement_service.dart';
import '../../services/unified_mobile_money_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class CommissionPaymentScreen extends StatefulWidget {
  const CommissionPaymentScreen({super.key});

  @override
  State<CommissionPaymentScreen> createState() => _CommissionPaymentScreenState();
}

class _CommissionPaymentScreenState extends State<CommissionPaymentScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _commissionStatus = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _paymentHistory = [];

  // Formulaire de paiement
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedProvider = 'orange_money';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final vendorId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Charger le statut actuel
      final status = await CommissionEnforcementService.checkCommissionStatus(
        vendorId: vendorId,
      );

      // Charger les statistiques
      final stats = await CommissionEnforcementService.getCommissionStats(
        vendorId: vendorId,
      );

      // Charger l'historique
      final history = await CommissionEnforcementService.getPaymentHistory(
        vendorId: vendorId,
        limit: 10,
      );

      setState(() {
        _commissionStatus = status;
        _stats = stats;
        _paymentHistory = history;
      });

    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessingPayment = true);

    try {
      final vendorId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final amount = double.parse(_amountController.text);
      final phoneNumber = _phoneController.text.trim();

      debugPrint('💳 Initiation paiement commission: $amount FCFA');

      // Convertir le provider string en enum
      MobileMoneyProvider provider;
      switch (_selectedProvider) {
        case 'orange_money':
          provider = MobileMoneyProvider.orange;
          break;
        case 'mtn_momo':
          provider = MobileMoneyProvider.mtn;
          break;
        case 'moov_money':
          provider = MobileMoneyProvider.moov;
          break;
        case 'wave':
          provider = MobileMoneyProvider.wave;
          break;
        default:
          provider = MobileMoneyProvider.orange;
      }

      // Générer un ID de transaction unique
      final transactionId = 'COMMISSION_${DateTime.now().millisecondsSinceEpoch}_$vendorId';

      // Appeler l'API Mobile Money
      final result = await UnifiedMobileMoneyService.initiateClientPayment(
        orderId: transactionId,
        customerPhone: phoneNumber,
        amount: amount,
        provider: provider,
      );

      if (result.success) {
        // Enregistrer le versement dans Firestore
        await CommissionEnforcementService.recordCommissionPayment(
          vendorId: vendorId,
          amount: amount,
          paymentMethod: _selectedProvider,
          transactionId: result.reference,
        );

        if (mounted) {
          // Afficher le code USSD
          _showSuccessDialog(result.ussdCode);

          // Recharger les données
          await _loadData();

          // Réinitialiser le formulaire
          _formKey.currentState!.reset();
          _amountController.clear();
          _phoneController.clear();
        }
      } else {
        throw Exception(result.error ?? 'Échec du paiement');
      }

    } catch (e) {
      debugPrint('❌ Erreur paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  void _showSuccessDialog(String? ussdCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text('Paiement initié'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre demande de paiement a été envoyée.',
              style: TextStyle(fontSize: 14),
            ),
            if (ussdCode != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Code de confirmation:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ussdCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Composez ce code sur votre téléphone pour confirmer.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Versement commissions'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statut actuel
                    _buildStatusCard(),
                    const SizedBox(height: 24),

                    // Formulaire de paiement
                    _buildPaymentForm(),
                    const SizedBox(height: 24),

                    // Statistiques
                    _buildStatsCard(),
                    const SizedBox(height: 24),

                    // Historique
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final unpaidAmount = (_commissionStatus['unpaidCommissions'] as num?)?.toDouble() ?? 0.0;
    final threshold = (_commissionStatus['threshold'] as num?)?.toDouble() ?? 50000.0;
    final percentage = (_commissionStatus['percentageOfThreshold'] as num?)?.toDouble() ?? 0.0;
    final alertLevel = _commissionStatus['alertLevel'] as String? ?? 'none';
    final isBlocked = _commissionStatus['isBlocked'] as bool? ?? false;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isBlocked) {
      statusColor = AppColors.error;
      statusText = 'Compte bloqué';
      statusIcon = Icons.lock;
    } else if (alertLevel == 'softBlock') {
      statusColor = Colors.orange;
      statusText = 'Urgent - Versement requis';
      statusIcon = Icons.warning;
    } else if (alertLevel == 'warning') {
      statusColor = Colors.amber;
      statusText = 'Attention';
      statusIcon = Icons.info;
    } else {
      statusColor = AppColors.success;
      statusText = 'OK';
      statusIcon = Icons.check_circle;
    }

    return Card(
      elevation: 3,
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Commissions à verser',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Montant impayé
            Text(
              formatPriceWithCurrency(unpaidAmount, currency: 'FCFA'),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% du seuil (${formatPriceWithCurrency(threshold, currency: 'FCFA')})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Effectuer un versement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Numéro de téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '07/05/01 XX XX XX XX',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro';
                  }
                  if (value.length < 10) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fournisseur Mobile Money
              DropdownButtonFormField<String>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Fournisseur',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                  DropdownMenuItem(value: 'mtn_momo', child: Text('MTN Mobile Money')),
                  DropdownMenuItem(value: 'moov_money', child: Text('Moov Money')),
                  DropdownMenuItem(value: 'wave', child: Text('Wave')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedProvider = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Bouton de paiement
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessingPayment
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Effectuer le versement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalPaid = (_stats['totalCommissionsPaid'] as num?)?.toDouble() ?? 0.0;
    final totalCommissions = (_stats['totalCommissions'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total commissions', totalCommissions),
            const Divider(height: 24),
            _buildStatRow('Déjà versé', totalPaid, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          formatPriceWithCurrency(value, currency: 'FCFA'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_paymentHistory.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Aucun versement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des versements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paymentHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = _paymentHistory[index];
              final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
              final method = payment['paymentMethod'] as String? ?? 'N/A';
              final date = (payment['paidAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(
                  formatPriceWithCurrency(amount, currency: 'FCFA'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${_getProviderLabel(method)}${date != null ? ' • ${_formatDate(date)}' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getProviderLabel(String provider) {
    switch (provider) {
      case 'orange_money':
        return 'Orange Money';
      case 'mtn_momo':
        return 'MTN MoMo';
      case 'moov_money':
        return 'Moov Money';
      case 'wave':
        return 'Wave';
      default:
        return provider;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
