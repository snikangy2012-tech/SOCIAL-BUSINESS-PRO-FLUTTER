// ===== lib/screens/payment/payment_screen.dart =====
// Interface de paiement Mobile Money - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../services/mobile_money_service.dart';
import '../../models/order_model.dart';
// Import nécessaire pour Timer
import 'dart:async';
import '../../widgets/system_ui_scaffold.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.order,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedProvider;
  bool _isProcessing = false;
  bool _acceptTerms = false;
  String? _transactionId;
  PaymentStatus? _paymentStatus;
  String? _ussdCode;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Détecter automatiquement le provider selon le numéro
  void _onPhoneChanged() {
    final phone = _phoneController.text;
    if (phone.length >= 8) {
      final detectedProvider = MobileMoneyService.detectProvider(phone);
      if (detectedProvider != null && detectedProvider != _selectedProvider) {
        setState(() {
          _selectedProvider = detectedProvider;
        });
      }
    }
  }

  // Initier le paiement
  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate() || _selectedProvider == null) {
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar('Veuillez accepter les conditions de paiement', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await MobileMoneyService.initiatePayment(
        orderId: widget.order.id,
        amount: widget.order.totalAmount,
        phoneNumber: _phoneController.text.trim(),
        providerId: _selectedProvider!,
        description: 'Commande ${widget.order.orderNumber}',
        vendeurId: widget.order.vendeurId,
      );

      setState(() {
        _transactionId = result.transactionId;
        _paymentStatus = result.status;
        _ussdCode = result.ussdCode;
      });

      if (result.success) {
        _showPaymentInstructions();
        _startStatusPolling();
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors du paiement: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Afficher les instructions de paiement
  void _showPaymentInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildPaymentInstructionsSheet(),
    );
  }

  // Surveiller le statut du paiement
  void _startStatusPolling() {
    if (_transactionId == null) return;

    // Vérifier le statut toutes les 3 secondes pendant 5 minutes maximum
    int attempts = 0;
    const maxAttempts = 100; // 5 minutes

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;

      try {
        final result = await MobileMoneyService.checkPaymentStatus(_transactionId!);

        setState(() {
          _paymentStatus = result.status;
        });

        if (result.status == PaymentStatus.success) {
          timer.cancel();
          _handlePaymentSuccess();
        } else if (result.status == PaymentStatus.failed ||
            result.status == PaymentStatus.cancelled ||
            result.status == PaymentStatus.expired) {
          timer.cancel();
          _handlePaymentFailure(result.message);
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _handlePaymentTimeout();
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          timer.cancel();
          _handlePaymentTimeout();
        }
      }
    });
  }

  // Paiement réussi
  void _handlePaymentSuccess() {
    Navigator.pop(context); // Fermer le modal d'instructions

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: AppSpacing.sm),
            Text('Paiement réussi'),
          ],
        ),
        content: Text(
            'Votre paiement de ${widget.order.totalAmount.toStringAsFixed(0)} FCFA a été effectué avec succès.\n\n'
            'Votre commande ${widget.order.orderNumber} sera traitée sous peu.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              widget.onPaymentSuccess?.call();
              context.go('/acheteur/orders'); // Aller aux commandes
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Voir ma commande'),
          ),
        ],
      ),
    );
  }

  // Paiement échoué
  void _handlePaymentFailure(String message) {
    Navigator.pop(context); // Fermer le modal d'instructions

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: AppSpacing.sm),
            Text('Paiement échoué'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPayment();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // Timeout du paiement
  void _handlePaymentTimeout() {
    Navigator.pop(context); // Fermer le modal d'instructions

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: AppColors.warning, size: 28),
            SizedBox(width: AppSpacing.sm),
            Text('Vérification en cours'),
          ],
        ),
        content: const Text('La vérification du paiement prend plus de temps que prévu. '
            'Vous recevrez une notification dès que le statut sera confirmé.'),
        actions: [
          ElevatedButton(
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

  // Réinitialiser le paiement
  void _resetPayment() {
    setState(() {
      _transactionId = null;
      _paymentStatus = null;
      _ussdCode = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Paiement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Récapitulatif de la commande
            _buildOrderSummary(),

            const SizedBox(height: AppSpacing.xl),

            // Formulaire de paiement
            _buildPaymentForm(),

            const SizedBox(height: AppSpacing.xl),

            // Conditions d'utilisation
            _buildTermsAcceptance(),

            const SizedBox(height: AppSpacing.xl),

            // Bouton de paiement
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  // Récapitulatif de la commande
  Widget _buildOrderSummary() {
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
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.order.orderNumber,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...widget.order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        '${(item.price * item.quantity).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formulaire de paiement
  Widget _buildPaymentForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Numéro de téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: 0749705404',
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: '+225 ',
                  suffixIcon:
                      _selectedProvider != null ? _buildProviderIcon(_selectedProvider!) : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Numéro de téléphone requis';
                  }
                  if (value.length != 8) {
                    return 'Le numéro doit contenir 8 chiffres';
                  }
                  if (_selectedProvider == null) {
                    return 'Numéro non reconnu pour Mobile Money';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Providers disponibles
              if (_selectedProvider != null) _buildSelectedProvider(),
              if (_selectedProvider == null) _buildProvidersList(),
            ],
          ),
        ),
      ),
    );
  }

  // Provider sélectionné
  Widget _buildSelectedProvider() {
    final config = MobileMoneyService.getProviderConfig(_selectedProvider!)!;
    final fees = MobileMoneyService.calculateFees(widget.order.totalAmount, _selectedProvider!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${config.color.substring(1)}')).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Color(int.parse('0xFF${config.color.substring(1)}')).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProviderIcon(_selectedProvider!, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fees > 0)
                      Text(
                        'Frais: ${fees.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedProvider = null),
                child: const Text('Changer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Liste des providers
  Widget _buildProvidersList() {
    final providers = MobileMoneyService.getAvailableProviders();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez votre opérateur',
          style: TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...providers.map((provider) => _buildProviderOption(provider)),
      ],
    );
  }

  // Option de provider
  Widget _buildProviderOption(Map<String, dynamic> provider) {
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            _buildProviderIcon(provider['id'], size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'],
                    style: const TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Préfixes: ${provider['prefix'].join(', ')}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icône du provider
  Widget _buildProviderIcon(String providerId, {double size = 20}) {
    final config = MobileMoneyService.getProviderConfig(providerId);
    if (config == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${config.color.substring(1)}')),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          config.code.substring(0, 2),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Acceptation des conditions
  Widget _buildTermsAcceptance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: AppColors.textSecondary),
                children: [
                  TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'conditions de paiement',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' et autorise la transaction.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bouton de paiement
  Widget _buildPaymentButton() {
    final isEnabled = _selectedProvider != null && _acceptTerms && !_isProcessing;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? _initiatePayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('Traitement en cours...'),
                ],
              )
            : Text(
                'Payer ${widget.order.totalAmount.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Modal d'instructions de paiement
  Widget _buildPaymentInstructionsSheet() {
    final config = MobileMoneyService.getProviderConfig(_selectedProvider!)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Titre
            Row(
              children: [
                _buildProviderIcon(_selectedProvider!, size: 32),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Finaliser avec ${config.name}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Instructions
            if (_ussdCode != null) ...[
              const Text(
                'Composez le code USSD suivant :',
                style: TextStyle(fontSize: AppFontSizes.md),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _ussdCode!,
                          style: const TextStyle(
                            fontSize: AppFontSizes.xl,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _ussdCode!));
                            _showSnackBar('Code copié!');
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copier le code',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Appuyez longuement pour copier',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Étapes
            Expanded(
              child: ListView(
                children: [
                  _buildInstructionStep(
                    1,
                    'Composez le code USSD',
                    'Tapez ${_ussdCode ?? '*144#'} sur votre téléphone',
                    Icons.dialpad,
                  ),
                  _buildInstructionStep(
                    2,
                    'Suivez les instructions',
                    'Sélectionnez "Paiement marchand" dans le menu',
                    Icons.menu,
                  ),
                  _buildInstructionStep(
                    3,
                    'Entrez votre code PIN',
                    'Confirmez le paiement avec votre code PIN ${config.name}',
                    Icons.lock,
                  ),
                  _buildInstructionStep(
                    4,
                    'Attendez la confirmation',
                    'Vous recevrez un SMS de confirmation',
                    Icons.message,
                  ),
                ],
              ),
            ),

            // Statut du paiement
            if (_paymentStatus != null) _buildPaymentStatus(),

            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_transactionId != null) {
                        await MobileMoneyService.cancelPayment(_transactionId!);
                      }
                      Navigator.pop(context);
                      _resetPayment();
                    },
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _paymentStatus == PaymentStatus.success
                        ? () {
                            Navigator.pop(context);
                            _handlePaymentSuccess();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Continuer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Étape d'instruction
  Widget _buildInstructionStep(int step, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Statut du paiement
  Widget _buildPaymentStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_paymentStatus!) {
      case PaymentStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'En attente de confirmation...';
        statusIcon = Icons.schedule;
        break;
      case PaymentStatus.success:
        statusColor = AppColors.success;
        statusText = 'Paiement confirmé!';
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        statusColor = AppColors.error;
        statusText = 'Paiement échoué';
        statusIcon = Icons.error;
        break;
      case PaymentStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Paiement annulé';
        statusIcon = Icons.cancel;
        break;
      case PaymentStatus.expired:
        statusColor = AppColors.error;
        statusText = 'Paiement expiré';
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Statut inconnu';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_paymentStatus == PaymentStatus.pending) ...[
            const Spacer(),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: statusColor,
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Afficher un snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

