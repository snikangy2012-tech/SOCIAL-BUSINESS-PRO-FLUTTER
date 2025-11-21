// ===== lib/screens/auth/login_screen_extended.dart =====
// Page de connexion avec Google Sign-In et options OTP

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

// Import constants AVANT les autres fichiers locaux pour éviter les conflits
import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/providers/auth_provider_firebase.dart';
import '../../services/auth_service_web.dart';
import '../../services/auth_service_extended.dart';
import '../../widgets/custom_widgets.dart';

class LoginScreenExtended extends StatefulWidget {
  const LoginScreenExtended({super.key});

  @override
  State<LoginScreenExtended> createState() => _LoginScreenExtendedState();
}

class _LoginScreenExtendedState extends State<LoginScreenExtended> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _authMethod = 'email'; // 'email' ou 'google'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Méthode commune de navigation selon le type d'utilisateur
  void _navigateByUserType(UserType userType) {
    switch (userType) {
      case UserType.admin:
        debugPrint('🔀 Navigation → /admin');
        context.go('/admin');
      case UserType.acheteur:
        debugPrint('🔀 Navigation → /acheteur-home');
        context.go('/acheteur-home');
      case UserType.vendeur:
        debugPrint('🔀 Navigation → /vendeur-dashboard');
        context.go('/vendeur-dashboard');
      case UserType.livreur:
        debugPrint('🔀 Navigation → /livreur-dashboard');
        context.go('/livreur-dashboard');
    }
  }

  // Méthode commune pour gérer la séquence post-connexion
  Future<void> _handlePostLoginSequence(String successMessage) async {
    if (!mounted) return;

    // Masquer le clavier immédiatement
    FocusScope.of(context).unfocus();

    // Charger l'utilisateur depuis Firestore
    final authProvider = context.read<AuthProvider>();

    debugPrint('🔄 Chargement de l\'utilisateur depuis Firestore...');

    // Forcer le rechargement de l'utilisateur depuis Firestore
    await authProvider.loadUserFromFirebase();

    if (!mounted) return;

    final user = authProvider.user;

    if (user == null) {
      debugPrint('❌ Utilisateur non chargé après connexion');
      throw Exception('Erreur chargement utilisateur. Veuillez réessayer.');
    }

    debugPrint('✅ Utilisateur chargé: ${user.displayName} (${user.userType.value})');

    if (!mounted) return;

    // Arrêter le loading avant la navigation
    setState(() => _isLoading = false);

    // Petit délai pour que l'UI se mette à jour
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Afficher le message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );

    // Attendre que le SnackBar soit visible
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigation selon le type d'utilisateur
    _navigateByUserType(user.userType);
  }

  // Méthode commune pour gérer les erreurs
  void _handleError(dynamic error, String defaultMessage) {
    debugPrint('❌ Erreur: $error');

    if (!mounted) return;

    String errorMessage = defaultMessage;

    // Extraire le message d'erreur proprement
    if (error is Exception) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } else {
      errorMessage = error.toString();
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMessage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Connexion avec email/mot de passe
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _authMethod = 'email';
    });

    try {
      debugPrint('🔐 Tentative de connexion: ${_emailController.text.trim()}');

      Map<String, dynamic> result;

      // Sur Web : Connexion via auth_service_web
      if (kIsWeb) {
        result = await AuthServiceWeb.loginWeb(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Sur Mobile : Connexion complète
        result = await AuthServiceExtended.signInWithIdentifier(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result['success']) {
        debugPrint('✅ Connexion réussie');
        await _handlePostLoginSequence('✅ Connexion réussie !');
      } else {
        throw Exception(result['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      _handleError(e, 'Erreur de connexion');
    }
  }

  // Connexion avec Google
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _authMethod = 'google';
    });

    try {
      debugPrint('🔐 Connexion Google...');

      final result = await AuthServiceExtended.signInWithGoogle();

      if (result['success']) {
        debugPrint('✅ Connexion Google réussie');
        await _handlePostLoginSequence('✅ Connexion Google réussie !');
      } else {
        throw Exception(result['message'] ?? 'Erreur connexion Google');
      }
    } catch (e) {
      _handleError(e, 'Erreur connexion Google');
    }
  }

  // Widget personnalisé pour le bouton Google Sign-In
  Widget _buildGoogleSignInButton() {
    final bool isLoadingGoogle = _isLoading && _authMethod == 'google';

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: isLoadingGoogle
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Google (utilisant un Container avec des couleurs pour simuler le logo)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        // Fond blanc
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Logo Google stylisé avec icon
                        Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF4285F4), // Bleu Google
                                Color(0xFFEA4335), // Rouge Google
                                Color(0xFFFBBC05), // Jaune Google
                                Color(0xFF34A853), // Vert Google
                              ],
                              stops: [0.25, 0.5, 0.75, 1.0],
                            ).createShader(bounds),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continuer avec Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Logo de l'application
              const AppLogo(size: 120),

              const SizedBox(height: AppSpacing.xl),

              // Titre de connexion
              const Text(
                'Connexion',
                style: TextStyle(
                  fontSize: AppFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              const Text(
                'Connectez-vous pour accéder à votre compte',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Connexion rapide Google
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const Text(
                        'Connexion rapide',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildGoogleSignInButton(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Séparateur
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Formulaire de connexion classique
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

                        const SizedBox(height: AppSpacing.lg),

                        // Champ mot de passe
                        CustomTextField(
                          label: 'Mot de passe',
                          hint: 'Votre mot de passe',
                          icon: Icons.lock,
                          isPassword: true,
                          controller: _passwordController,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Lien mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Bouton de connexion
                        CustomButton(
                          text: 'Se connecter',
                          icon: Icons.login,
                          isLoading: _isLoading && _authMethod == 'email',
                          onPressed: _isLoading ? null : _handleEmailLogin,
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

              const SizedBox(height: AppSpacing.xl),

              // Section inscription
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Vous n\'avez pas encore de compte ?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.md,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      text: 'Créer un compte',
                      icon: Icons.person_add,
                      isOutlined: true,
                      backgroundColor: AppColors.secondary,
                      onPressed: () => context.go('/register'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Informations de test
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.info),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Mode Test - Utilisez ces emails :',
                            style: TextStyle(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '• admin@socialbusiness.ci (Admin)\n'
                      '• Ou créez un nouveau compte\n'
                      '• Ou connectez-vous avec Google',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
