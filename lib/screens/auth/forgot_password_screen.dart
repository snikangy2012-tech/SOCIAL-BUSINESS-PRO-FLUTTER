// ===== lib/screens/auth/forgot_password_screen.dart =====
// Écran de réinitialisation du mot de passe

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      debugPrint('📧 Envoi email réinitialisation à: $email');

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de réinitialisation envoyé avec succès'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun compte associé à cette adresse email';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        case 'too-many-requests':
          errorMessage = 'Trop de tentatives. Réessayez plus tard';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }

      debugPrint('❌ Erreur réinitialisation: ${e.code}');

      if (!mounted) return;

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erreur inattendue: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icône
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: AppColors.primary,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Titre
              const Text(
                'Réinitialiser votre mot de passe',
                style: TextStyle(
                  fontSize: AppFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                _emailSent
                    ? 'Un email de réinitialisation a été envoyé à ${_emailController.text.trim()}.\n\n'
                        'Vérifiez votre boîte de réception et suivez les instructions.'
                    : 'Entrez votre adresse email et nous vous enverrons un lien '
                        'pour réinitialiser votre mot de passe.',
                style: const TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              if (!_emailSent) ...[
                // Formulaire
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Champ email
                          CustomTextField(
                            label: 'Email',
                            hint: 'Votre adresse email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            isRequired: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email requis';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Format d\'email invalide';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Bouton envoyer
                          CustomButton(
                            text: 'Envoyer le lien',
                            icon: Icons.send,
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _handlePasswordReset,
                          ),

                          // Message d'erreur
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: AppColors.error),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Email envoyé - Options
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mark_email_read,
                          size: 64,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Email envoyé',
                          style: TextStyle(
                            fontSize: AppFontSizes.xl,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bouton retour connexion
                CustomButton(
                  text: 'Retour à la connexion',
                  icon: Icons.login,
                  isOutlined: true,
                  onPressed: () => context.go('/login'),
                ),

                const SizedBox(height: AppSpacing.md),

                // Bouton renvoyer
                CustomButton(
                  text: 'Renvoyer l\'email',
                  icon: Icons.refresh,
                  backgroundColor: AppColors.secondary,
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                      _errorMessage = null;
                    });
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Informations supplémentaires
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: AppColors.info),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Conseils importants :',
                            style: TextStyle(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      '• Vérifiez votre dossier spam si vous ne voyez pas l\'email\n'
                      '• Le lien est valide pendant 1 heure\n'
                      '• Vous pouvez demander un nouveau lien à tout moment\n'
                      '• Assurez-vous d\'utiliser l\'email avec lequel vous vous êtes inscrit',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_emailSent) ...[
                const SizedBox(height: AppSpacing.lg),

                // Lien retour connexion
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: AppFontSizes.md,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
