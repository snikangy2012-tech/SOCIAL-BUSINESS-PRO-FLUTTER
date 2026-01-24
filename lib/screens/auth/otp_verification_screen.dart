// ===== lib/screens/auth/otp_verification_screen.dart =====
// Interface de vérification OTP complète pour SMS et Email

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

import 'package:social_business_pro/config/constants.dart';
import '../../services/auth_service_extended.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationType; // 'sms' ou 'email'
  final String contact; // Numéro de téléphone ou email
  final String? name;
  final UserType? userType;
  final dynamic confirmationResult; // Pour SMS OTP

  const OTPVerificationScreen({
    super.key,
    required this.verificationType,
    required this.contact,
    this.name,
    this.userType,
    this.confirmationResult,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;
  StreamSubscription? _otpStatusSubscription;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenToOtpStatus();
  }

  void _listenToOtpStatus() {
    _otpStatusSubscription = AuthServiceExtended.otpStatusStream.listen((event) {
      if (!mounted) return;

      final eventType = event['event'];
      final message = event['message'];

      setState(() {
        _statusMessage = message;
      });

      if (eventType == 'autoRetrievalTimeout') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (eventType == 'verificationFailed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    _otpStatusSubscription?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOTP() async {
    if (widget.verificationType == 'sms' && _otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Le code doit contenir 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;

      if (widget.verificationType == 'sms') {
        // ✅ SI WEB avec confirmationResult
        if (kIsWeb && widget.confirmationResult != null) {
          debugPrint('🌐 Vérification OTP Web avec confirmationResult');

          try {
            // Confirmer le code
            final credential = await widget.confirmationResult.confirm(
              _otpController.text.trim(),
            );

            if (credential.user != null) {
              debugPrint('✅ OTP validé - Création profil Firestore');

              // Créer le profil dans Firestore
              await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
                'uid': credential.user!.uid,
                'phone': widget.contact,
                'displayName': widget.name ?? 'Utilisateur',
                'userType': widget.userType?.value ?? 'acheteur',
                'isVerified': true,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              result = {
                'success': true,
                'message': 'Inscription réussie !',
              };
            } else {
              throw Exception('Erreur de vérification');
            }
          } catch (e) {
            debugPrint('❌ Erreur vérification OTP Web: $e');

            result = {
              'success': false,
              'message': e.toString().contains('invalid-verification-code')
                  ? 'Code incorrect'
                  : 'Erreur de vérification',
            };
          }
        } else {
          // ✅ MOBILE - Ancienne méthode
          result = await AuthServiceExtended.verifyPhoneOTP(
            otpCode: _otpController.text,
            name: widget.name ?? 'Utilisateur',
            userType: widget.userType ?? UserType.acheteur,
          );
        }
      } else {
        // Vérification email
        final isVerified = await AuthServiceExtended.checkEmailVerified();
        result = {
          'success': isVerified,
          'message': isVerified ? 'Email vérifié avec succès !' : 'Email non encore vérifié.',
        };
      }

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Vérification réussie !'),
              backgroundColor: AppColors.success,
            ),
          );

          // Redirection selon le type d'utilisateur
          if (widget.userType == UserType.vendeur) {
            context.go('/vendeur-dashboard');
          } else if (widget.userType == UserType.livreur) {
            context.go('/livreur-dashboard');
          } else {
            context.go('/');
          }
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Code incorrect';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.verificationType == 'sms') {
        final result = await AuthServiceExtended.sendPhoneOTP(widget.contact);
        if (result['success']) {
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nouveau code envoyé !'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } else {
        final sent = await AuthServiceExtended.sendEmailVerification();
        if (sent) {
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email de vérification renvoyé !'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Impossible de renvoyer l\'email';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du renvoi: $e';
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
        title: const Text('Vérification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icône de vérification
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  widget.verificationType == 'sms' ? Icons.sms : Icons.email,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Titre
              const Text(
                'Vérification',
                style: TextStyle(
                  fontSize: AppFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                widget.verificationType == 'sms'
                    ? 'Nous avons envoyé un code de vérification à :'
                    : 'Vérifiez votre boîte email à l\'adresse :',
                style: const TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Contact
              Text(
                widget.contact,
                style: const TextStyle(
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Champ OTP (seulement pour SMS)
              if (widget.verificationType == 'sms') ...[
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
                          'Entrez le code à 6 chiffres',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Champ PIN
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            fieldHeight: 60,
                            fieldWidth: 50,
                            activeFillColor: AppColors.background,
                            selectedFillColor: AppColors.primaryLight,
                            inactiveFillColor: AppColors.backgroundSecondary,
                            activeColor: AppColors.primary,
                            selectedColor: AppColors.primary,
                            inactiveColor: AppColors.border,
                          ),
                          enableActiveFill: true,
                          onCompleted: (code) => _verifyOTP(),
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Bouton de vérification
                        CustomButton(
                          text: 'Vérifier le code',
                          icon: Icons.verified,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _verifyOTP,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Vérification email
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
                          Icons.email_outlined,
                          size: 48,
                          color: AppColors.info,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Vérifiez votre boîte email',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Cliquez sur le lien de vérification dans l\'email que nous vous avons envoyé.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        CustomButton(
                          text: 'J\'ai vérifié mon email',
                          icon: Icons.check_circle,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _verifyOTP,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Message d'erreur
              if (_errorMessage != null)
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

              const SizedBox(height: AppSpacing.lg),

              // Bouton renvoyer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Vous n\'avez pas reçu le code ?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        'Renvoyer',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Renvoyer dans ${_countdown}s',
                      style: const TextStyle(
                        color: AppColors.textLight,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Changer de méthode
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info, color: AppColors.info),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.verificationType == 'sms'
                          ? 'Problème avec le SMS ? Vous pouvez aussi vérifier par email.'
                          : 'Problème avec l\'email ? Vous pouvez aussi vérifier par SMS.',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.sm,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        // Retour à l'inscription pour changer de méthode
                        context.pop();
                      },
                      child: const Text(
                        'Changer de méthode',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Aide et support
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline, color: AppColors.textSecondary),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Besoin d\'aide ?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Si vous rencontrez des difficultés avec la vérification, '
                      'contactez notre support.',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Ouvrir WhatsApp support
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Support WhatsApp: ${AppConstants.supportWhatsApp}'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Ouvrir email support
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email: ${AppConstants.supportEmail}'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.email, size: 16),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.info,
                              side: const BorderSide(color: AppColors.info),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Footer informations
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: const Text(
                  'En cas de problème persistant, veuillez nous contacter.\n'
                  'Notre équipe support est disponible 24h/7j.',
                  style: TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
