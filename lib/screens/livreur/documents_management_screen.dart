// ===== lib/screens/livreur/documents_management_screen.dart =====
// Écran de gestion des documents pour livreurs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';

class DocumentsManagementScreen extends StatefulWidget {
  const DocumentsManagementScreen({super.key});

  @override
  State<DocumentsManagementScreen> createState() => _DocumentsManagementScreenState();
}

class _DocumentsManagementScreenState extends State<DocumentsManagementScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  String _uploadingDocument = '';

  Map<String, String> _documents = {};
  final Map<String, String> _documentLabels = {
    'drivingLicense': 'Permis de conduire',
    'vehicleRegistration': 'Carte grise',
    'insurance': 'Assurance',
    'identityCard': 'Carte d\'identité',
    'vehiclePhoto': 'Photo du véhicule',
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
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
        if (profile['documents'] != null) {
          setState(() {
            _documents = Map<String, String>.from(profile['documents']);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement documents: $e');
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    try {
      // Capturer les valeurs avant l'appel async
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final userName = authProvider.user?.displayName ?? 'Utilisateur';

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Sélectionner l'image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadingDocument = documentType;
      });

      // Uploader vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('livreur_documents')
          .child(userId)
          .child('$documentType.jpg');

      File imageFile = File(image.path);
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Mettre à jour Firestore
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: userId,
        data: {
          'profile.documents.$documentType': imageUrl,
        },
      );

      // Notifier les admins
      await NotificationService.notifyAllAdmins(
        type: 'document_upload',
        title: 'Nouveau document à valider',
        body: '$userName a uploadé: ${_documentLabels[documentType]}',
        data: {
          'userId': userId,
          'userType': 'livreur',
          'userName': userName,
          'documentType': documentType,
          'documentUrl': imageUrl,
        },
      );

      setState(() {
        _documents[documentType] = imageUrl;
        _isUploading = false;
        _uploadingDocument = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_documentLabels[documentType]} uploadé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur upload document: $e');
      setState(() {
        _isUploading = false;
        _uploadingDocument = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(String documentUrl) async {
    // Afficher le document en plein écran
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                documentUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: AppColors.error),
                        SizedBox(height: 16),
                        Text('Erreur de chargement'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String documentType) {
    final hasDocument = _documents.containsKey(documentType);
    final label = _documentLabels[documentType] ?? documentType;
    final isUploading = _isUploading && _uploadingDocument == documentType;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: isUploading
            ? null
            : hasDocument
                ? () => _viewDocument(_documents[documentType]!)
                : () => _uploadDocument(documentType),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icône ou image miniature
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: hasDocument
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.border.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: hasDocument ? AppColors.success : AppColors.border,
                  ),
                ),
                child: isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : hasDocument
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.network(
                              _documents[documentType]!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.description,
                                  color: AppColors.success,
                                  size: 32,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.upload_file,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasDocument
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasDocument ? Icons.check_circle : Icons.pending,
                                size: 14,
                                color: hasDocument ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasDocument ? 'Uploadé' : 'En attente',
                                style: TextStyle(
                                  fontSize: AppFontSizes.xs,
                                  color: hasDocument ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action
              Icon(
                hasDocument ? Icons.visibility : Icons.upload,
                color: hasDocument ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null || user.userType != UserType.livreur) {
      return SystemUIScaffold(
        appBar: AppBar(title: const Text('Documents')),
        body: const Center(
          child: Text('Accès réservé aux livreurs'),
        ),
      );
    }

    final totalDocuments = _documentLabels.length;
    final uploadedDocuments = _documents.length;
    final progress = uploadedDocuments / totalDocuments;

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Mes Documents'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progression
              Card(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progression des documents',
                            style: TextStyle(
                              fontSize: AppFontSizes.md,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$uploadedDocuments/$totalDocuments',
                            style: const TextStyle(
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      if (progress == 1.0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tous les documents ont été uploadés',
                              style: TextStyle(
                                fontSize: AppFontSizes.sm,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Instructions
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
                            'Instructions',
                            style: TextStyle(
                              fontSize: AppFontSizes.sm,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Tous les documents doivent être valides et lisibles\n'
                            '• Les photos doivent être de bonne qualité\n'
                            '• L\'admin validera vos documents sous 24-48h',
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

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Documents requis',
                style: TextStyle(
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Liste des documents
              ..._documentLabels.keys.map((type) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _buildDocumentCard(type),
                  )),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
