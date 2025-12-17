// ===== lib/screens/vendeur/payment_settings_screen.dart =====
// Configuration des moyens de paiement acceptés par le vendeur

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/payment_methods_config.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class VendeurPaymentSettingsScreen extends StatefulWidget {
  const VendeurPaymentSettingsScreen({super.key});

  @override
  State<VendeurPaymentSettingsScreen> createState() => _VendeurPaymentSettingsScreenState();
}

class _VendeurPaymentSettingsScreenState extends State<VendeurPaymentSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Méthodes de paiement activées
  Map<String, bool> _paymentMethods = {
    'cash': true,
    'orange_money': false,
    'mtn_money': false,
    'moov_money': false,
    'wave': false,
  };

  // Détails de paiement (numéros de téléphone)
  Map<String, String> _paymentDetails = {
    'orange_money': '',
    'mtn_money': '',
    'moov_money': '',
    'wave': '',
  };

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPaymentSettings();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _paymentDetails.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
  }

  Future<void> _loadPaymentSettings() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) return;

      final userDoc = await FirebaseService.getDocument(
        collection: FirebaseCollections.users,
        docId: userId,
      );

      if (userDoc != null && userDoc['profile'] != null) {
        final profile = userDoc['profile'] as Map<String, dynamic>;
        final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;

        if (vendeurProfile != null) {
          // Charger les méthodes activées
          if (vendeurProfile['paymentMethods'] != null) {
            final methods = vendeurProfile['paymentMethods'] as Map<String, dynamic>;
            setState(() {
              _paymentMethods = {
                'cash': methods['cash'] ?? true,
                'orange_money': methods['orange_money'] ?? false,
                'mtn_money': methods['mtn_money'] ?? false,
                'moov_money': methods['moov_money'] ?? false,
                'wave': methods['wave'] ?? false,
              };
            });
          }

          // Charger les détails de paiement
          if (vendeurProfile['paymentDetails'] != null) {
            final details = vendeurProfile['paymentDetails'] as Map<String, dynamic>;
            setState(() {
              _paymentDetails = {
                'orange_money': details['orange_money'] ?? '',
                'mtn_money': details['mtn_money'] ?? '',
                'moov_money': details['moov_money'] ?? '',
                'wave': details['wave'] ?? '',
              };
              // Mettre à jour les contrôleurs
              _paymentDetails.forEach((key, value) {
                _controllers[key]?.text = value;
              });
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement paramètres paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePaymentSettings() async {
    // Validation : au moins une méthode doit être activée
    if (!_paymentMethods.values.any((enabled) => enabled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez activer au moins un moyen de paiement'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validation : si une méthode Mobile Money est activée, son numéro doit être renseigné
    for (var method in ['orange_money', 'mtn_money', 'moov_money', 'wave']) {
      if (_paymentMethods[method] == true && _controllers[method]!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez renseigner le numéro ${_getMethodLabel(method)}'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Mettre à jour les détails depuis les contrôleurs
      _paymentDetails = {
        'orange_money': _controllers['orange_money']!.text.trim(),
        'mtn_money': _controllers['mtn_money']!.text.trim(),
        'moov_money': _controllers['moov_money']!.text.trim(),
        'wave': _controllers['wave']!.text.trim(),
      };

      // Sauvegarder dans Firestore
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: userId,
        data: {
          'profile.vendeurProfile.paymentMethods': _paymentMethods,
          'profile.vendeurProfile.paymentDetails': _paymentDetails,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paramètres de paiement enregistrés'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde paramètres paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getMethodLabel(String methodId) {
    switch (methodId) {
      case 'cash':
        return 'Paiement à la livraison';
      case 'orange_money':
        return 'Orange Money';
      case 'mtn_money':
        return 'MTN Money';
      case 'moov_money':
        return 'Moov Money';
      case 'wave':
        return 'Wave';
      default:
        return methodId;
    }
  }

  IconData _getMethodIcon(String methodId) {
    switch (methodId) {
      case 'cash':
        return Icons.money;
      case 'orange_money':
      case 'mtn_money':
      case 'moov_money':
      case 'wave':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Color _getMethodColor(String methodId) {
    switch (methodId) {
      case 'orange_money':
        return Colors.orange;
      case 'mtn_money':
        return Colors.yellow.shade700;
      case 'moov_money':
        return Colors.blue;
      case 'wave':
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildPaymentMethodCard(String methodId) {
    final isEnabled = _paymentMethods[methodId] ?? false;
    final isMobileMoney = methodId != 'cash';
    final controller = _controllers[methodId];

    return Card(
      elevation: isEnabled ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isEnabled ? _getMethodColor(methodId) : AppColors.border,
          width: isEnabled ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // En-tête avec toggle
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? _getMethodColor(methodId).withValues(alpha: 0.1)
                        : AppColors.border.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PaymentMethodsConfig.hasLogo(methodId)
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            PaymentMethodsConfig.getLogo(methodId)!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getMethodIcon(methodId),
                                color:
                                    isEnabled ? _getMethodColor(methodId) : AppColors.textSecondary,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _getMethodIcon(methodId),
                          color: isEnabled ? _getMethodColor(methodId) : AppColors.textSecondary,
                          size: 24,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMethodLabel(methodId),
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      if (isMobileMoney)
                        Text(
                          isEnabled ? 'Activé' : 'Désactivé',
                          style: TextStyle(
                            fontSize: AppFontSizes.xs,
                            color: isEnabled ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethods[methodId] = value;
                    });
                  },
                  activeTrackColor: _getMethodColor(methodId).withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _getMethodColor(methodId);
                    }
                    return null;
                  }),
                ),
              ],
            ),

            // Champ de numéro si Mobile Money et activé
            if (isMobileMoney && isEnabled && controller != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro ${_getMethodLabel(methodId)}',
                  hintText: '+225 XX XX XX XX XX',
                  prefixIcon: Icon(Icons.phone, color: _getMethodColor(methodId)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: _getMethodColor(methodId), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Moyens de paiement'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Moyens de paiement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.info),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configuration importante',
                                style: TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Sélectionnez les moyens de paiement que vous acceptez. Les acheteurs ne verront que ces options lors de leurs commandes.',
                                style: TextStyle(
                                  fontSize: AppFontSizes.xs,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Liste des méthodes
                  const Text(
                    'Méthodes disponibles',
                    style: TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Paiement à la livraison
                  _buildPaymentMethodCard('cash'),
                  const SizedBox(height: AppSpacing.md),

                  // Mobile Money
                  const Text(
                    'Mobile Money',
                    style: TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildPaymentMethodCard('orange_money'),
                  const SizedBox(height: AppSpacing.sm),

                  _buildPaymentMethodCard('mtn_money'),
                  const SizedBox(height: AppSpacing.sm),

                  _buildPaymentMethodCard('moov_money'),
                  const SizedBox(height: AppSpacing.sm),

                  _buildPaymentMethodCard('wave'),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bouton de sauvegarde
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePaymentSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enregistrer les paramètres',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
