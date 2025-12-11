import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/system_ui_scaffold.dart';

/// Écran de souscription à un plan avec paiement Mobile Money
/// Accepte soit VendeurSubscriptionTier soit LivreurTier
class SubscriptionSubscribeScreen extends StatefulWidget {
  final Object tier; // Peut être VendeurSubscriptionTier ou LivreurTier

  const SubscriptionSubscribeScreen({
    super.key,
    required this.tier,
  });

  @override
  State<SubscriptionSubscribeScreen> createState() => _SubscriptionSubscribeScreenState();
}

class _SubscriptionSubscribeScreenState extends State<SubscriptionSubscribeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'Orange Money';
  bool _isProcessing = false;
  bool _acceptTerms = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'Orange Money',
      'icon': '🟠',
      'color': const Color(0xFFFF7900),
    },
    {
      'name': 'MTN Money',
      'icon': '🟡',
      'color': const Color(0xFFFFCC00),
    },
    {
      'name': 'Wave',
      'icon': '💙',
      'color': const Color(0xFF0084FF),
    },
    {
      'name': 'Moov Money',
      'icon': '🔵',
      'color': const Color(0xFF0066CC),
    },
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planDetails = _getPlanDetails();

    return SystemUIScaffold(
      appBar: AppBar(
        title: Text('Souscrire au plan ${_getTierName()}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Résumé du plan
              _buildPlanSummary(planDetails),
              const SizedBox(height: 24),

              // Sélection du fournisseur Mobile Money
              _buildProviderSelection(),
              const SizedBox(height: 24),

              // Numéro de téléphone
              _buildPhoneInput(),
              const SizedBox(height: 24),

              // Détails de facturation
              _buildBillingDetails(planDetails),
              const SizedBox(height: 24),

              // Conditions d'utilisation
              _buildTermsCheckbox(),
              const SizedBox(height: 24),

              // Bouton de paiement
              _buildPaymentButton(planDetails),
              const SizedBox(height: 16),

              // Note de sécurité
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSummary(Map<String, dynamic> details) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              details['color'] as Color,
              (details['color'] as Color).withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(details['icon'] as IconData, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              'Plan ${_getTierName()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details['subtitle'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${details['price']} FCFA / mois',
                style: TextStyle(
                  color: details['color'] as Color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Méthode de paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _providers.length,
          itemBuilder: (context, index) {
            final provider = _providers[index];
            final isSelected = _selectedProvider == provider['name'];

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedProvider = provider['name'] as String;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? provider['color'] as Color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? (provider['color'] as Color).withOpacity(0.1)
                      : Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        provider['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? provider['color'] as Color : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone Mobile Money',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Ex: 0707070707',
            prefixIcon: const Icon(Icons.phone_android),
            prefixText: '+225 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro';
            }
            if (value.length != 10) {
              return 'Le numéro doit contenir 10 chiffres';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Vous recevrez un code de confirmation sur ce numéro',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildBillingDetails(Map<String, dynamic> details) {
    final price = details['price'] as double;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de facturation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBillingRow('Plan ${_getTierName()}', '${price.toStringAsFixed(0)} FCFA'),
            const Divider(height: 24),
            _buildBillingRow(
              'Total à payer',
              '${price.toStringAsFixed(0)} FCFA',
              isTotal: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre abonnement sera renouvelé automatiquement chaque mois',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
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

  Widget _buildBillingRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    TextSpan(text: 'J\'accepte les '),
                    TextSpan(
                      text: 'conditions générales',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' et la '),
                    TextSpan(
                      text: 'politique de confidentialité',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(Map<String, dynamic> details) {
    return ElevatedButton(
      onPressed: _acceptTerms && !_isProcessing ? _processPayment : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: details['color'] as Color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Payer ${details['price']} FCFA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paiement 100% sécurisé via Mobile Money',
              style: TextStyle(
                fontSize: 13,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPlanDetails() {
    // Handle Vendeur plans
    if (widget.tier is VendeurSubscriptionTier) {
      switch (widget.tier) {
        case VendeurSubscriptionTier.pro:
          return {
            'price': 5000.0,
            'subtitle': 'Pour vendre plus',
            'color': AppColors.primary,
            'icon': Icons.rocket_launch,
          };
        case VendeurSubscriptionTier.premium:
          return {
            'price': 10000.0,
            'subtitle': 'Sans limites',
            'color': const Color(0xFFFFD700),
            'icon': Icons.diamond,
          };
        case VendeurSubscriptionTier.basique:
        default: // Fallback for free plans
          return {
            'price': 0.0,
            'subtitle': 'Idéal pour débuter',
            'color': Colors.grey,
            'icon': Icons.store,
          };
      }
    }

    // Handle Livreur plans (NOUVEAU MODÈLE HYBRIDE)
    if (widget.tier is LivreurTier) {
      switch (widget.tier) {
        case LivreurTier.pro:
          return {
            'price': 10000.0,
            'subtitle': 'Commission 20% - Débloqué à 50 livraisons + 4.0★',
            'color': Colors.blue,
            'icon': Icons.delivery_dining,
          };
        case LivreurTier.premium:
          return {
            'price': 30000.0,
            'subtitle': 'Commission 15% - Débloqué à 200 livraisons + 4.5★',
            'color': Colors.amber.shade700,
            'icon': Icons.workspace_premium,
          };
        case LivreurTier.starter:
        default: // Fallback for free plans
          return {
            'price': 0.0,
            'subtitle': 'Gratuit - Commission 25%',
            'color': Colors.grey,
            'icon': Icons.motorcycle,
          };
      }
    }

    // Fallback if tier is of an unknown type
    throw Exception('Type de plan non supporté: ${widget.tier.runtimeType}');
  }

  String _getTierName() {
    if (widget.tier is VendeurSubscriptionTier) {
      switch (widget.tier as VendeurSubscriptionTier) {
        case VendeurSubscriptionTier.basique:
          return 'BASIQUE';
        case VendeurSubscriptionTier.pro:
          return 'PRO';
        case VendeurSubscriptionTier.premium:
          return 'PREMIUM';
      }
    }
    if (widget.tier is LivreurTier) {
      switch (widget.tier as LivreurTier) {
        case LivreurTier.starter:
          return 'STARTER';
        case LivreurTier.pro:
          return 'PRO';
        case LivreurTier.premium:
          return 'PREMIUM';
      }
    }
    return 'Inconnu';
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final phone = '+225${_phoneController.text.trim()}';
      final amount = _getPlanDetails()['price'] as double;

      // Simuler le paiement Mobile Money (en production, utiliser le vrai service)
      debugPrint('💳 Paiement Mobile Money: $_selectedProvider, $phone, $amount FCFA');
      await Future.delayed(const Duration(seconds: 2));
      final transactionId = 'MM_${DateTime.now().millisecondsSinceEpoch}';

      bool success = false;

      // Déterminer si l'utilisateur est un vendeur ou un livreur et appeler la bonne méthode
      if (widget.tier is VendeurSubscriptionTier && user.userType == UserType.vendeur) {
        success = await subscriptionProvider.upgradeSubscription(
          vendeurId: user.id,
          newTier: widget.tier as VendeurSubscriptionTier,
          paymentMethod: _selectedProvider,
          transactionId: transactionId,
        );
      } else if (widget.tier is LivreurTier &&
          user.userType == UserType.livreur) {
        // Nouveau modèle hybride pour livreurs
        // Vérifier d'abord que le livreur a les stats nécessaires
        final currentSubscription = subscriptionProvider.livreurSubscription;
        if (currentSubscription == null) {
          throw Exception('Impossible de charger votre abonnement actuel');
        }

        success = await subscriptionProvider.upgradeLivreurSubscription(
          livreurId: user.id,
          newTier: widget.tier as LivreurTier,
          paymentMethod: _selectedProvider,
          transactionId: transactionId,
          currentDeliveries: currentSubscription.currentDeliveries,
          currentRating: currentSubscription.currentRating,
        );
      } else {
        throw Exception('Type de plan ou rôle utilisateur incompatible.');
      }

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception('Échec de l\'activation de l\'abonnement.');
      }
    } catch (e) {
      debugPrint('❌ Erreur paiement: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Paiement réussi !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre nouveau plan est maintenant actif. Profitez bien de ses avantages !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Retourne à l'écran de gestion d'abonnement
              context.pop();
              context.pop();
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
