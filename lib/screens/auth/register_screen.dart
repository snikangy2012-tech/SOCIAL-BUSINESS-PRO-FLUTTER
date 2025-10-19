// ===== lib/screens/auth/register_screen.dart (VERSION COMPLÈTE AVEC CHOIX SMS/EMAIL) =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:country_code_picker/country_code_picker.dart';

import '../../config/constants.dart';
import '../../services/auth_service_extended.dart';
import '../../services/auth_service_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // État
  UserType? _selectedUserType;
  bool _isCheckingUsername = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String _verificationType = 'sms';
  String _selectedCountryCode = '+225'; 

  @override
  void dispose() {
    _nameController.dispose();
	_usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un type de compte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      // ✅ DIFFÉRENCIER WEB ET MOBILE
      if (kIsWeb) {
        // Sur Web : Auth seulement (rapide)
        result = await AuthServiceWeb.registerWeb(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Sur Mobile : Auth + Firestore (fonctionne bien)
        result = await AuthServiceExtended.registerWithEmailDirect(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: '$_selectedCountryCode${_phoneController.text.trim()}',
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          userType: _selectedUserType!,
          verificationType: _verificationType,
        );
      }

      if (result['success'] && mounted) {
        // ✅ REDIRECTION IMMÉDIATE
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé ! Bienvenue 🎉'),
            backgroundColor: AppColors.success,
          ),
        );

        // Redirection selon le type d'utilisateur
        switch (_selectedUserType!) {
          case UserType.vendeur:
            context.go('/vendeur-dashboard');
            break;
          case UserType.acheteur:
            context.go('/acheteur-home');
            break;
          case UserType.livreur:
            context.go('/livreur-dashboard');
            break;
          default:
            context.go('/');
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur inscription');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// ✅ AJOUTER méthode pour Google
  Future<void> _handleGoogleSignIn() async {
    if (_selectedUserType == null) {
      _showSnackBar('Sélectionnez d\'abord un type de compte', isError: true);
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar('Veuillez accepter les conditions', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthServiceExtended.signInWithGoogle();

      if (result['success'] && mounted) {
        // Redirection selon le type d'utilisateur
        switch (_selectedUserType!) {
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
        if (mounted) {
          _showSnackBar(result['message'] ?? 'Erreur Google', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur Google: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
  
  // Vérification en temps réel du nom d'utilisateur

  void _checkUsernameAvailability(String username) async {
    if (username.length < 3) return;
    setState(() => _isCheckingUsername = true);

    // Simuler une vérification (remplacer par vraie logique)

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isCheckingUsername = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: AppFontSizes.xxxl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Rejoignez SOCIAL BUSINESS Pro',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Nom complet
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    hintText: 'Votre nom et prénoms',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),
				
				// Nom d'utilisateur UNIQUE

				  TextFormField(
					controller: _usernameController,
					decoration: InputDecoration(
					  labelText: 'Nom d\'utilisateur',
					  hintText: 'Votre identifiant unique',
					  prefixIcon: const Icon(Icons.alternate_email),
					  suffixIcon: _isCheckingUsername
						  ? const SizedBox(
							  width: 20,
							  height: 20,
							  child: CircularProgressIndicator(strokeWidth: 2),
							)
						  : null,
					  border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(AppRadius.md),
					  ),
					  helperText: 'Utilisé pour se connecter (+ de 3 caractères )',
					),
					onChanged: _checkUsernameAvailability,
					validator: (value) {
					  if (value == null || value.trim().isEmpty) {
						return 'Nom d\'utilisateur requis';
					  }
					  if (value.trim().length < 3) {
						return 'Minimum 3 caractères';
					  }
					  if (value.contains(' ')) {
						return 'Pas d\'espaces autorisés';
					  }
					  return null;
					},
				  ),


              const SizedBox(height: AppSpacing.md),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Code pays
                CountryCodePicker(
                  onChanged: (country) {
                    setState(() {
                      _selectedCountryCode = country.dialCode!;
                    });
                  },
                  initialSelection: 'CI', // Côte d'Ivoire
                  favorite: const ['+225', 'CI'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
                  textStyle: const TextStyle(fontSize: AppFontSizes.md),
                ),
                
                const SizedBox(width: AppSpacing.sm),

                // Téléphone
                 TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: const Icon(Icons.phone),
                      hintText: 'XX XX XX XX XX',
                      prefixText: '+225 ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre téléphone';
                    }
                    if (value.length < 10) {
                      return 'Numéro invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
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
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Type de compte
                const Text(
                  'Type de compte',
                  style: TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildUserTypeChip(UserType.vendeur, 'Vendeur', Icons.store),
                    _buildUserTypeChip(UserType.acheteur, 'Acheteur', Icons.shopping_bag),
                    _buildUserTypeChip(UserType.livreur, 'Livreur', Icons.delivery_dining),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ✅ CHOIX DE VÉRIFICATION (SMS/EMAIL)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha:0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: AppColors.primary,
                            size: 20,
                          ),
                           SizedBox(width: AppSpacing.sm),
                           Text(
                            'Méthode de vérification',
                            style: TextStyle(
                              fontSize: AppFontSizes.md,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Choisissez comment vérifier votre compte',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Option SMS
                      InkWell(
                        onTap: () {
                          setState(() => _verificationType = 'sms');
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _verificationType == 'sms'
                                ? AppColors.primary.withValues(alpha:0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: _verificationType == 'sms'
                                  ? AppColors.primary
                                  : AppColors.border.withValues(alpha:0.3),
                              width: _verificationType == 'sms' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'sms',
                                groupValue: _verificationType,
                                onChanged: (value) {
                                  setState(() => _verificationType = value!);
                                },
                                activeColor: AppColors.primary,
                              ),
                              Icon(
                                Icons.sms,
                                color: _verificationType == 'sms'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vérification par SMS',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: _verificationType == 'sms'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _verificationType == 'sms'
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Code à 6 chiffres par message',
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
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Option Email
                      InkWell(
                        onTap: () {
                          setState(() => _verificationType = 'email');
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _verificationType == 'email'
                                ? AppColors.info.withValues(alpha:0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: _verificationType == 'email'
                                  ? AppColors.info
                                  : AppColors.border.withValues(alpha:0.3),
                              width: _verificationType == 'email' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'email',
                                groupValue: _verificationType,
                                onChanged: (value) {
                                  setState(() => _verificationType = value!);
                                },
                                activeColor: AppColors.info,
                              ),
                              Icon(
                                Icons.email,
                                color: _verificationType == 'email'
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vérification par Email',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: _verificationType == 'email'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _verificationType == 'email'
                                            ? AppColors.info
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Lien de vérification par email',
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ✅ AJOUTER ce bouton Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                    label: Text(
                      _isLoading ? 'Connexion...' : 'Continuer avec Google',
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Séparateur OU
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                // Checkbox CGU
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'J\'accepte les ',
                            style: TextStyle(fontSize: AppFontSizes.sm),
                            children: [
                              TextSpan(
                                text: 'conditions d\'utilisation',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Bouton S'inscrire
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Lien connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ? '),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(UserType type, String label, IconData icon) {
    final isSelected = _selectedUserType == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = selected ? type : null;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}