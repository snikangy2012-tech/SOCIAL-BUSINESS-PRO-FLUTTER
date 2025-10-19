// ===== lib/screens/acheteur/checkout.dart =====
// Processus de commande et paiement - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../services/analytics_service.dart';
import '../../services/mobile_money_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _analytics = AnalyticsService();

  // Contrôleurs
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // État
  int _currentStep = 0;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  // Données de commande (temporaire)
  final double _subtotal = 65000;
  final double _deliveryFee = 1500;
  double get _total => _subtotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('Checkout');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Valider le formulaire
  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _selectedPaymentMethod != null;
      default:
        return true;
    }
  }

  // Passer à l'étape suivante
  void _nextStep() {
    if (_validateStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _confirmOrder();
      }
    }
  }

  // Revenir en arrière
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Confirmer la commande
  Future<void> _confirmOrder() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Logger l'achat
      await _analytics.logPurchase(
        orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        value: _total,
        deliveryFee: _deliveryFee,
        items: [], // À compléter avec les vraies données
      );

      // TODO: Créer la commande dans Firestore

      // TODO: Initier le paiement si nécessaire

      // Afficher confirmation
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                SizedBox(width: AppSpacing.sm),
                Text('Commande confirmée !'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre commande a été enregistrée avec succès.'),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Vous recevrez une confirmation par SMS.',
                  style: TextStyle(fontSize: AppFontSizes.sm),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/acheteur/orders');
                },
                child: const Text('Voir mes commandes'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser ma commande'),
      ),
      body: Column(
        children: [
          // Stepper
          _buildStepper(),

          // Contenu
          Expanded(
            child: _buildStepContent(),
          ),

          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // Stepper
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Livraison'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Paiement'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Confirmation'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.xs,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  // Contenu de l'étape
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDeliveryStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  // Étape 1: Livraison
  Widget _buildDeliveryStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Informations de livraison',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Form(
          key: _formKey,
          child: Column(
            children: [
              // Nom complet
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  hintText: 'Ex: Jean Kouassi',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: 0749705404',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre numéro';
                  }
                  if (value.length < 10) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison',
                  hintText: 'Ex: Cocody, Angré 7e tranche',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre adresse';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Notes (optionnel)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Instructions (optionnel)',
                  hintText: 'Ex: Derrière la pharmacie',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Étape 2: Paiement
  Widget _buildPaymentStep() {
    final providers = MobileMoneyService.getAvailableProviders();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Options de paiement
        ...providers.map((provider) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RadioListTile<String>(
              value: provider['id'],
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
              title: Text(provider['name']),
              subtitle: Text(provider['description'] ?? ''),
              secondary: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse(provider['color'].replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),

        // Paiement à la livraison
        Card(
          child: RadioListTile<String>(
            value: 'cash',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() => _selectedPaymentMethod = value);
            },
            title: const Text('Paiement à la livraison'),
            subtitle: const Text('Payez en espèces au livreur'),
            secondary: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.money,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Étape 3: Confirmation
  Widget _buildConfirmationStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Récapitulatif',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Infos livraison
        _buildSummaryCard(
          'Livraison',
          [
            _buildSummaryItem('Nom', _nameController.text),
            _buildSummaryItem('Téléphone', _phoneController.text),
            _buildSummaryItem('Adresse', _addressController.text),
            if (_notesController.text.isNotEmpty)
              _buildSummaryItem('Notes', _notesController.text),
          ],
          Icons.local_shipping,
        ),

        const SizedBox(height: AppSpacing.md),

        // Méthode de paiement
        _buildSummaryCard(
          'Paiement',
          [
            _buildSummaryItem(
              'Méthode',
              _getPaymentMethodName(),
            ),
          ],
          Icons.payment,
        ),

        const SizedBox(height: AppSpacing.md),

        // Montants
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Montants',
                      style: TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                _buildAmountRow('Sous-total', _subtotal),
                const SizedBox(height: AppSpacing.sm),
                _buildAmountRow('Livraison', _deliveryFee),
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    List<Widget> items,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount) {
    return Row(
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
          '${amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName() {
    if (_selectedPaymentMethod == null) return 'Non sélectionné';
    if (_selectedPaymentMethod == 'cash') return 'Paiement à la livraison';

    final providers = MobileMoneyService.getAvailableProviders();
    final provider = providers.firstWhere(
      (p) => p['id'] == _selectedPaymentMethod,
      orElse: () => {'name': 'Inconnu'},
    );
    return provider['name'];
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton retour
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Retour'),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),

            // Bouton suivant/confirmer
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 2 ? 'Confirmer' : 'Suivant',
                        style: const TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
