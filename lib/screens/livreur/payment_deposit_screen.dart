// ===== lib/screens/livreur/payment_deposit_screen.dart =====
// Écran de dépôt des paiements collectés - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../services/payment_enforcement_service.dart';
import '../../services/unified_mobile_money_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class PaymentDepositScreen extends StatefulWidget {
  const PaymentDepositScreen({super.key});

  @override
  State<PaymentDepositScreen> createState() => _PaymentDepositScreenState();
}

class _PaymentDepositScreenState extends State<PaymentDepositScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _paymentStatus = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _depositHistory = [];

  // Formulaire de dépôt
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedProvider = 'orange_money';
  bool _isProcessingDeposit = false;

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
      final livreurId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Charger le statut actuel
      final status = await PaymentEnforcementService.checkPaymentStatus(
        livreurId: livreurId,
      );

      // Charger les statistiques
      final stats = await PaymentEnforcementService.getPaymentStats(
        livreurId: livreurId,
      );

      // Charger l'historique
      final history = await PaymentEnforcementService.getDepositHistory(
        livreurId: livreurId,
        limit: 10,
      );

      setState(() {
        _paymentStatus = status;
        _stats = stats;
        _depositHistory = history;
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

  Future<void> _initiateDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessingDeposit = true);

    try {
      final livreurId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final amount = double.parse(_amountController.text);
      final phoneNumber = _phoneController.text.trim();

      debugPrint('💳 Initiation dépôt: $amount FCFA');

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
      final transactionId = 'DEPOSIT_${DateTime.now().millisecondsSinceEpoch}_$livreurId';

      // Appeler l'API Mobile Money
      final result = await UnifiedMobileMoneyService.initiateClientPayment(
        orderId: transactionId,
        customerPhone: phoneNumber,
        amount: amount,
        provider: provider,
      );

      if (result.success) {
        // Enregistrer le dépôt dans Firestore
        await PaymentEnforcementService.recordPaymentDeposit(
          livreurId: livreurId,
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
      debugPrint('❌ Erreur dépôt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingDeposit = false);
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
            Text('Dépôt initié'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre demande de dépôt a été envoyée.',
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
        title: const Text('Dépôt des collectes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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

                    // Formulaire de dépôt
                    _buildDepositForm(),
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
    final unpaidBalance = (_paymentStatus['unpaidBalance'] as num?)?.toDouble() ?? 0.0;
    final threshold = (_paymentStatus['threshold'] as num?)?.toDouble() ?? 30000.0;
    final percentage = (_paymentStatus['percentageOfThreshold'] as num?)?.toDouble() ?? 0.0;
    final alertLevel = _paymentStatus['alertLevel'] as String? ?? 'none';
    final isBlocked = _paymentStatus['isBlocked'] as bool? ?? false;
    final trustLevel = _paymentStatus['trustLevel'] as String? ?? 'debutant';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isBlocked) {
      statusColor = AppColors.error;
      statusText = 'Compte bloqué';
      statusIcon = Icons.lock;
    } else if (alertLevel == 'softBlock') {
      statusColor = Colors.orange;
      statusText = 'Urgent - Dépôt requis';
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
                        'Argent collecté non déposé',
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
              formatPriceWithCurrency(unpaidBalance, currency: 'FCFA'),
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
            const SizedBox(height: 12),

            // Badge niveau de confiance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Niveau: ${_getTrustLevelLabel(trustLevel)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositForm() {
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
                'Effectuer un dépôt',
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

              // Bouton de dépôt
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessingDeposit ? null : _initiateDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessingDeposit
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Effectuer le dépôt',
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
    final totalDeposited = (_stats['totalPaymentsDeposited'] as num?)?.toDouble() ?? 0.0;
    final totalCollected = (_stats['totalCollected'] as num?)?.toDouble() ?? 0.0;

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
            _buildStatRow('Total collecté', totalCollected),
            const Divider(height: 24),
            _buildStatRow('Déjà déposé', totalDeposited, color: AppColors.success),
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
    if (_depositHistory.isEmpty) {
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
                  'Aucun dépôt',
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
          'Historique des dépôts',
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
            itemCount: _depositHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final deposit = _depositHistory[index];
              final amount = (deposit['amount'] as num?)?.toDouble() ?? 0.0;
              final method = deposit['paymentMethod'] as String? ?? 'N/A';
              final date = (deposit['depositedAt'] as Timestamp?)?.toDate();

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

  String _getTrustLevelLabel(String level) {
    switch (level) {
      case 'debutant':
        return 'Débutant';
      case 'confirme':
        return 'Confirmé';
      case 'expert':
        return 'Expert';
      case 'vip':
        return 'VIP';
      default:
        return 'Inconnu';
    }
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

