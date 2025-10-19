// ===== lib/screens/auth/login_screen.dart =====
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/auth_service_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Méthode de connexion
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      bool success;

      // Différencier Web et Mobile
      if (kIsWeb) {
        // Sur Web : Connexion rapide (Auth seulement)
        final result = await AuthServiceWeb.loginWeb(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );

        if (result['success']) {
          success = true;
        } else {
          throw Exception(result['message'] ?? 'Erreur connexion');
        }
      } else {
        // Sur Mobile : Connexion complète (Auth + Firestore)
        success = await authProvider.login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (success && mounted) {
        // Redirection selon le type d'utilisateur
        final user = authProvider.user;
        if (user != null) {
          switch (user.userType) {
            case UserType.vendeur:
              context.go('/vendeur-dashboard');
              break;
            case UserType.acheteur:
              context.go('/acheteur-home');
              break;
            case UserType.livreur:
              context.go('/livreur-dashboard');
              break;
            case UserType.admin:
              context.go('/admin-dashboard');
              break;
          }
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo et titre
                      const Icon(
                        Icons.store,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      const Text(
                        'SOCIAL BUSINESS Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppFontSizes.xxl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      const Text(
                        'Connectez-vous à votre compte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Champ identifiant (email, téléphone ou nom)
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          labelText: 'Email, Téléphone ou Nom',
                          hintText: 'Entrez votre identifiant',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre identifiant';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: 'Entrez votre mot de passe',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha:0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.lg,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Divider avec "OU"
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Bouton inscription
                      OutlinedButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Overlay de chargement
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connexion en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}