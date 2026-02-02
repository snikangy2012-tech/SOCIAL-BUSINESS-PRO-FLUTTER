// ===== lib/screens/auth/login_screen_extended.dart =====
// Page de connexion avec design moderne utilisant les couleurs de l'app

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/providers/auth_provider_firebase.dart';
import '../../services/auth_service_web.dart';
import '../../services/auth_service_extended.dart';
import '../../widgets/system_ui_scaffold.dart';

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
  bool _obscurePassword = true;
  String? _errorMessage;
  String _authMethod = 'email';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateByUserType(UserType userType) {
    switch (userType) {
      case UserType.admin:
        context.go('/admin');
      case UserType.acheteur:
        context.go('/acheteur-home');
      case UserType.vendeur:
        context.go('/vendeur-dashboard');
      case UserType.livreur:
        context.go('/livreur-dashboard');
    }
  }

  Future<void> _handlePostLoginSequence(String successMessage) async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    await authProvider.loadUserFromFirebase();

    if (!mounted) return;

    final user = authProvider.user;

    if (user == null) {
      throw Exception('Erreur chargement utilisateur. Veuillez réessayer.');
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _navigateByUserType(user.userType);
  }

  void _handleError(dynamic error, String defaultMessage) {
    if (!mounted) return;

    String errorMessage = defaultMessage;

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
      Map<String, dynamic> result;

      if (kIsWeb) {
        result = await AuthServiceWeb.loginWeb(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        result = await AuthServiceExtended.signInWithIdentifier(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result['success']) {
        await _handlePostLoginSequence('Connexion réussie !');
      } else {
        throw Exception(result['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      _handleError(e, 'Erreur de connexion');
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _authMethod = 'google';
    });

    try {
      final result = await AuthServiceExtended.signInWithGoogle();

      if (result['success']) {
        await _handlePostLoginSequence('Connexion Google réussie !');
      } else {
        throw Exception(result['message'] ?? 'Erreur connexion Google');
      }
    } catch (e) {
      _handleError(e, 'Erreur connexion Google');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Espace en haut avec fond vert
            const SizedBox(height: 40),

            // Carte blanche principale
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Titre Connexion
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Champ Email
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Adresse email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
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

                        const SizedBox(height: 20),

                        // Champ Password
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Mot de passe',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Bouton Connexion
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading && _authMethod == 'email'
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Texte "Ou via réseaux sociaux"
                        Text(
                          'Ou via réseaux sociaux',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Boutons réseaux sociaux
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.facebook,
                              color: const Color(0xFF3B5998),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Facebook non disponible'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 15),
                            _buildSocialButton(
                              icon: Icons.g_mobiledata,
                              color: const Color(0xFFDB4437),
                              onTap: _isLoading ? null : _handleGoogleLogin,
                              isLoading: _isLoading && _authMethod == 'google',
                            ),
                            const SizedBox(width: 15),
                            _buildSocialButton(
                              icon: Icons.apple,
                              color: Colors.black,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Apple non disponible'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Message d'erreur
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
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
            ),

            // Footer "Pas encore de compte ? S'inscrire"
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pas encore de compte ? ",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      "S'inscrire",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword ? obscureText : false,
      validator: validator,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 22,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
      ),
    );
  }
}
