// lib/screens/auth/change_password_screen.dart
// Écran de modification de mot de passe - SOCIAL BUSINESS Pro
// Transversal : utilisable par tous les types d'utilisateurs

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as app_auth;
import '../../widgets/system_ui_scaffold.dart';

class ChangePasswordScreen extends StatefulWidget {
  /// Si `isRequired` est true, le changement de mot de passe est obligatoire
  /// (pas de bouton retour, pas d'annulation possible)
  final bool isRequired;

  const ChangePasswordScreen({
    super.key,
    this.isRequired = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Ré-authentifier l'utilisateur avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Mettre à jour le mot de passe
      await user.updatePassword(_newPasswordController.text.trim());

      // Si changement obligatoire, mettre à jour Firestore
      if (widget.isRequired) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'needsPasswordChange': false,
          'passwordChangedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Recharger les données utilisateur
        if (mounted) {
          await context.read<app_auth.AuthProvider>().refreshUser();
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mot de passe modifié avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Redirection selon le contexte
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            if (widget.isRequired) {
              // Rediriger vers le dashboard approprié
              final user = context.read<app_auth.AuthProvider>().user;
              if (user != null) {
                switch (user.userType) {
                  case UserType.admin:
                    context.go('/admin-dashboard');
                    break;
                  case UserType.vendeur:
                    context.go('/vendeur-dashboard');
                    break;
                  case UserType.livreur:
                    context.go('/livreur-dashboard');
                    break;
                  case UserType.acheteur:
                    context.go('/acheteur-home');
                    break;
                }
              }
            } else {
              // Retour normal
              context.pop();
            }
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Le mot de passe actuel est incorrect';
            break;
          case 'weak-password':
            errorMessage = 'Le nouveau mot de passe est trop faible';
            break;
          case 'requires-recent-login':
            errorMessage = 'Veuillez vous reconnecter avant de changer votre mot de passe';
            break;
          default:
            errorMessage = 'Erreur: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur inattendue: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
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
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: Text(widget.isRequired
          ? 'Changement de mot de passe obligatoire'
          : 'Modifier le mot de passe'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isRequired, // Empêcher le retour si obligatoire
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête informatif
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: widget.isRequired
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: widget.isRequired
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.isRequired ? Icons.warning_amber_rounded : Icons.info_outline,
                              color: widget.isRequired ? AppColors.warning : AppColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                widget.isRequired
                                  ? 'Pour des raisons de sécurité, vous devez changer votre mot de passe avant de continuer. Votre mot de passe doit contenir au moins 6 caractères.'
                                  : 'Votre mot de passe doit contenir au moins 6 caractères',
                                style: TextStyle(
                                  color: widget.isRequired ? AppColors.warning : AppColors.info,
                                  fontSize: AppFontSizes.md,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Mot de passe actuel
                      const Text(
                        'Mot de passe actuel',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe actuel',
                          hintText: 'Entrez votre mot de passe actuel',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre mot de passe actuel';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Nouveau mot de passe
                      const Text(
                        'Nouveau mot de passe',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          hintText: 'Entrez votre nouveau mot de passe',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un nouveau mot de passe';
                          }
                          if (value.trim().length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          if (value.trim() == _currentPasswordController.text.trim()) {
                            return 'Le nouveau mot de passe doit être différent de l\'ancien';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Confirmer le nouveau mot de passe
                      const Text(
                        'Confirmer le nouveau mot de passe',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          hintText: 'Confirmez votre nouveau mot de passe',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez confirmer votre nouveau mot de passe';
                          }
                          if (value.trim() != _newPasswordController.text.trim()) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Bouton de sauvegarde
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _changePassword,
                          icon: const Icon(Icons.check_circle, size: 24),
                          label: const Text(
                            'Modifier le mot de passe',
                            style: TextStyle(
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),

                      // Bouton d'annulation (seulement si non obligatoire)
                      if (!widget.isRequired) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.cancel, size: 24),
                            label: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.textSecondary),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // Conseils de sécurité
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conseils de sécurité',
                              style: TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildSecurityTip(
                              icon: Icons.check_circle_outline,
                              text: 'Utilisez un mot de passe unique',
                            ),
                            _buildSecurityTip(
                              icon: Icons.check_circle_outline,
                              text: 'Mélangez lettres, chiffres et symboles',
                            ),
                            _buildSecurityTip(
                              icon: Icons.check_circle_outline,
                              text: 'Évitez les informations personnelles',
                            ),
                            _buildSecurityTip(
                              icon: Icons.check_circle_outline,
                              text: 'Ne partagez jamais votre mot de passe',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityTip({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

