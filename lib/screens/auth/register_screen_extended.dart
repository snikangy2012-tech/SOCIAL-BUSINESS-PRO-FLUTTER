// ===== lib/screens/auth/register_screen_extended.dart =====
// Inscription avec OTP SMS, Email et Google Sign-In

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:social_business_pro/config/constants.dart';
import '../../services/auth_service_extended.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/auth_service_web.dart';
import '../../utils/permissions_helper.dart';
import '../../widgets/system_ui_scaffold.dart';

class RegisterScreenExtended extends StatefulWidget {
  const RegisterScreenExtended({super.key});

  @override
  State<RegisterScreenExtended> createState() => _RegisterScreenExtendedState();
}

class _RegisterScreenExtendedState extends State<RegisterScreenExtended> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserType _selectedUserType = UserType.acheteur;
  String _selectedCountryCode = '+225'; // Côte d'Ivoire par défaut
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Méthode de vérification sélectionnée
  String _verificationMethod = 'email'; // 'email', 'sms', ou 'google'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Inscription avec email et vérification choisie
  Future<void> _handleEmailRegister() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez accepter les conditions'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;

      // ✅ DIFFÉRENCIER WEB ET MOBILE
      if (kIsWeb) {
        // Sur Web : Inscription RAPIDE (Auth seulement)
        result = await AuthServiceWeb.registerWeb(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          userType: _selectedUserType.value, // ✅ Passer le type sélectionné
        );
      } else {
        result = await AuthServiceExtended.registerWithEmail(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: '$_selectedCountryCode${_phoneController.text.trim()}',
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          verificationType: _verificationMethod,
          userType: _selectedUserType,
        );
      }

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte créé avec succès ! 🎉\n'
              'Connectez-vous maintenant avec vos identifiants.',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );

        debugPrint('✅ Inscription terminée - Type: ${_selectedUserType.value} enregistré');

        // Attendre 2 secondes pour que l'utilisateur lise le message
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Rediriger vers la page de connexion
        // L'utilisateur va se connecter et sera automatiquement redirigé vers son dashboard
        context.go('/login');
      } else {
        throw Exception(result['message'] ?? 'Erreur d\'inscription');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Inscription avec SMS OTP
  Future<void> _handlePhoneRegister() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez accepter les conditions'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    // ✅ SMS OTP ACTIVÉ pour Web et Mobile
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sur Android, demander permissions SMS pour auto-vérification
      if (!kIsWeb) {
        await PermissionsHelper.requestSmsPermissions(context);
      }

      final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
      debugPrint('📱 Envoi SMS vers: $fullPhone (${kIsWeb ? "Web" : "Mobile"})');

      final result = await AuthServiceExtended.sendPhoneOTP(fullPhone);

      if (result['success']) {
        if (mounted) {
          // Passer confirmationResult pour Web
          final extra = {
            'verificationType': 'sms',
            'contact': fullPhone,
            'name': _nameController.text.trim(),
            'userType': _selectedUserType,
          };

          // Sur Web, ajouter le confirmationResult
          if (kIsWeb && result['confirmationResult'] != null) {
            extra['confirmationResult'] = result['confirmationResult'];
          }

          context.push('/verify-otp', extra: extra);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur d\'envoi du SMS';
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      setState(() {
        _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Inscription avec Google
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthServiceExtended.signInWithGoogle();

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['isNewUser'] ? 'Compte créé avec Google !' : 'Connexion Google réussie !',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          // Redirection vers dashboard acheteur (par défaut pour Google)
          context.go('/acheteur');
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo compact
                const AppLogo(size: 80, showText: false),

                const SizedBox(height: AppSpacing.lg),

                // Titre
                const Text(
                  'Rejoignez SOCIAL BUSINESS Pro',
                  style: TextStyle(
                    fontSize: AppFontSizes.xxl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Connexion rapide Google
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Text(
                          'Inscription rapide',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomButton(
                          text: 'Continuer avec Google',
                          icon: Icons.g_mobiledata,
                          backgroundColor: AppColors.info,
                          isLoading: _isLoading && _verificationMethod == 'google',
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _verificationMethod = 'google';
                                  });
                                  _handleGoogleSignIn();
                                },
                        ),
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

                // Formulaire d'inscription
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Sélecteur de type d'utilisateur
                        UserTypeSelector(
                          selectedType: _selectedUserType,
                          onChanged: (type) {
                            setState(() {
                              _selectedUserType = type;
                            });
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Nom complet
                        CustomTextField(
                          label: 'Nom complet',
                          hint: 'Votre nom et prénom',
                          icon: Icons.person,
                          controller: _nameController,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nom complet requis';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Email
                        CustomTextField(
                          label: 'Email',
                          hint: 'votre@email.com',
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

                        // Téléphone avec sélecteur de pays
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Téléphone *',
                              style: TextStyle(
                                fontSize: AppFontSizes.md,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  // Sélecteur de pays
                                  CountryCodePicker(
                                    onChanged: (code) {
                                      setState(() {
                                        _selectedCountryCode = code.dialCode!;
                                      });
                                    },
                                    initialSelection: 'CI',
                                    favorite: const ['+225', 'CI'],
                                    showCountryOnly: false,
                                    showOnlyCountryWhenClosed: false,
                                    alignLeft: false,
                                  ),

                                  // Séparateur
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: AppColors.border,
                                  ),

                                  // Champ téléphone
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        hintText: 'XX XX XX XX XX',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Numéro requis';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Mot de passe
                        CustomTextField(
                          label: 'Mot de passe',
                          hint: 'Au moins 6 caractères',
                          icon: Icons.lock,
                          isPassword: true,
                          controller: _passwordController,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                            if (value.length < 6) {
                              return 'Au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Confirmation mot de passe
                        CustomTextField(
                          label: 'Confirmer le mot de passe',
                          hint: 'Retapez votre mot de passe',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmPasswordController,
                          isRequired: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Méthode de vérification
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Méthode de vérification :',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.email, size: 20),
                                          SizedBox(width: 8),
                                          Text('Email'),
                                        ],
                                      ),
                                      value: 'email',
                                      groupValue: _verificationMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _verificationMethod = value!;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.sms, size: 20),
                                          SizedBox(width: 8),
                                          Text('SMS'),
                                        ],
                                      ),
                                      value: 'sms',
                                      groupValue: _verificationMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _verificationMethod = value!;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Case à cocher conditions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: const Text(
                                  'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.sm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Bouton d'inscription
                        CustomButton(
                          text: _verificationMethod == 'sms'
                              ? 'Créer compte et vérifier par SMS'
                              : 'Créer compte et vérifier par Email',
                          icon: _verificationMethod == 'sms' ? Icons.sms : Icons.email,
                          isLoading: _isLoading && _verificationMethod != 'google',
                          backgroundColor: _selectedUserType == UserType.vendeur
                              ? AppColors.primary
                              : _selectedUserType == UserType.acheteur
                                  ? AppColors.secondary
                                  : AppColors.success,
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_verificationMethod == 'sms') {
                                    _handlePhoneRegister();
                                  } else {
                                    _handleEmailRegister();
                                  }
                                },
                        ),

                        // Message d'erreur
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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

                const SizedBox(height: AppSpacing.xl),

                // Lien vers connexion
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
                        'Vous avez déjà un compte ?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSizes.md,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomButton(
                        text: 'Se connecter',
                        icon: Icons.login,
                        isOutlined: true,
                        backgroundColor: AppColors.primary,
                        onPressed: () => context.go('/login'),
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
}
