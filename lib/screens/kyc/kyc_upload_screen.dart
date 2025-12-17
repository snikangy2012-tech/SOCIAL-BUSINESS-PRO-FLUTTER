// ===== lib/screens/kyc/kyc_upload_screen.dart =====
// Écran d'upload des documents KYC pour vendeurs

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/kyc_verification_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';

class KYCUploadScreen extends StatefulWidget {
  const KYCUploadScreen({super.key});

  @override
  State<KYCUploadScreen> createState() => _KYCUploadScreenState();
}

class _KYCUploadScreenState extends State<KYCUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  // URLs des documents uploadés
  String? _cniUrl;
  String? _selfieUrl;
  String? _justificatifUrl;

  // Fichiers locaux sélectionnés
  XFile? _cniFile;
  XFile? _selfieFile;
  XFile? _justificatifFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Vérification d\'identité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              const Icon(
                Icons.verified_user,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Vérification d\'identité',
                style: TextStyle(
                  fontSize: AppFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              const Text(
                'Pour garantir la sécurité de tous, veuillez uploader vos documents d\'identité.',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Documents requis
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. CNI
                      _buildDocumentSection(
                        title: '1. Carte d\'identité (CNI)',
                        subtitle: 'Recto et verso, photo nette',
                        isRequired: true,
                        file: _cniFile,
                        url: _cniUrl,
                        onTap: () => _pickDocument('cni'),
                        onRemove: () => setState(() {
                          _cniFile = null;
                          _cniUrl = null;
                        }),
                      ),

                      const Divider(height: AppSpacing.xl),

                      // 2. Selfie
                      _buildDocumentSection(
                        title: '2. Selfie avec CNI',
                        subtitle: 'Vous tenant votre CNI, visage et CNI bien visibles',
                        isRequired: true,
                        file: _selfieFile,
                        url: _selfieUrl,
                        onTap: () => _pickDocument('selfie'),
                        onRemove: () => setState(() {
                          _selfieFile = null;
                          _selfieUrl = null;
                        }),
                      ),

                      const Divider(height: AppSpacing.xl),

                      // 3. Justificatif de domicile
                      _buildDocumentSection(
                        title: '3. Justificatif de domicile',
                        subtitle: 'Facture CIE/SODECI < 3 mois, contrat de bail (Recommandé)',
                        isRequired: false,
                        file: _justificatifFile,
                        url: _justificatifUrl,
                        onTap: () => _pickDocument('justificatif'),
                        onRemove: () => setState(() {
                          _justificatifFile = null;
                          _justificatifUrl = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
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
                const SizedBox(height: AppSpacing.lg),
              ],

              // Barre de progression
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload en cours... ${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Bouton soumettre
              CustomButton(
                text: 'Soumettre mes documents',
                icon: Icons.upload_file,
                isLoading: _isUploading,
                onPressed: _canSubmit() && !_isUploading ? _handleSubmit : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Informations importantes
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.info, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Informations importantes',
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSizes.md,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Documents acceptés: JPG, PNG, PDF\n'
                      '• Taille max: 5 MB par document\n'
                      '• Photos nettes et bien éclairées\n'
                      '• CNI et selfie obligatoires\n'
                      '• Validation sous 24-48h',
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

  /// Widget pour une section de document
  Widget _buildDocumentSection({
    required String title,
    required String subtitle,
    required bool isRequired,
    required XFile? file,
    required String? url,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasDocument = file != null || url != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Bouton upload ou aperçu
        if (!hasDocument)
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload),
            label: const Text('Choisir un document'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    file?.name ?? 'Document uploadé',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onRemove,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Vérifier si on peut soumettre les documents
  bool _canSubmit() {
    // CNI et Selfie obligatoires
    return (_cniFile != null || _cniUrl != null) && (_selfieFile != null || _selfieUrl != null);
  }

  /// Sélectionner un document
  Future<void> _pickDocument(String docType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (docType) {
            case 'cni':
              _cniFile = pickedFile;
              break;
            case 'selfie':
              _selfieFile = pickedFile;
              break;
            case 'justificatif':
              _justificatifFile = pickedFile;
              break;
          }
          _errorMessage = null;
        });

        debugPrint('✅ Document "$docType" sélectionné: ${pickedFile.name}');
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection document: $e');
      setState(() {
        _errorMessage = 'Erreur lors de la sélection du document';
      });
    }
  }

  /// Soumettre les documents
  Future<void> _handleSubmit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      debugPrint('📤 Début upload documents KYC pour user: ${user.id}');

      final Map<String, String> uploadedDocuments = {};
      int totalFiles = 0;
      int uploadedFiles = 0;

      // Compter le nombre de fichiers à uploader
      if (_cniFile != null) totalFiles++;
      if (_selfieFile != null) totalFiles++;
      if (_justificatifFile != null) totalFiles++;

      // Upload CNI
      if (_cniFile != null) {
        final url = await _uploadFile(_cniFile!, 'cni', user.id);
        uploadedDocuments['cni'] = url;
        uploadedFiles++;
        setState(() => _uploadProgress = uploadedFiles / totalFiles);
      }

      // Upload Selfie
      if (_selfieFile != null) {
        final url = await _uploadFile(_selfieFile!, 'selfie', user.id);
        uploadedDocuments['selfie'] = url;
        uploadedFiles++;
        setState(() => _uploadProgress = uploadedFiles / totalFiles);
      }

      // Upload Justificatif (optionnel)
      if (_justificatifFile != null) {
        final url = await _uploadFile(_justificatifFile!, 'justificatif', user.id);
        uploadedDocuments['justificatif'] = url;
        uploadedFiles++;
        setState(() => _uploadProgress = uploadedFiles / totalFiles);
      }

      debugPrint('✅ Tous les documents uploadés avec succès');

      // Soumettre à KYC service
      await KYCVerificationService.submitVerification(
        user.id,
        uploadedDocuments,
        user.userType,
      );

      if (!mounted) return;

      // Rediriger vers écran d'attente
      context.go('/kyc-pending');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents soumis avec succès ! Validation sous 24-48h.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur soumission documents: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erreur lors de l\'envoi des documents. Veuillez réessayer.';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  /// Uploader un fichier vers Firebase Storage
  Future<String> _uploadFile(XFile file, String docType, String userId) async {
    try {
      final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          FirebaseStorage.instance.ref().child('kyc_documents').child(userId).child(fileName);

      debugPrint('📤 Upload $docType vers Firebase Storage...');

      if (kIsWeb) {
        // Web: Upload depuis bytes
        final bytes = await file.readAsBytes();
        await ref.putData(bytes);
      } else {
        // Mobile: Upload depuis fichier
        await ref.putFile(File(file.path));
      }

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ $docType uploadé: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload $docType: $e');
      rethrow;
    }
  }
}
