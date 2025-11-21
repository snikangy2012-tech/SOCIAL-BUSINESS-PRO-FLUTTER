// ===== lib/screens/admin/kyc_validation_screen.dart =====
// Dashboard admin pour validation des documents KYC

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/kyc_verification_service.dart';
import '../../widgets/custom_widgets.dart';

class KYCValidationScreen extends StatefulWidget {
  const KYCValidationScreen({super.key});

  @override
  State<KYCValidationScreen> createState() => _KYCValidationScreenState();
}

class _KYCValidationScreenState extends State<KYCValidationScreen> {
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await KYCVerificationService.getPendingVerifications();

      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });

      debugPrint('✅ ${users.length} vérifications en attente chargées');
    } catch (e) {
      debugPrint('❌ Erreur chargement vérifications: $e');

      setState(() {
        _errorMessage = 'Erreur lors du chargement des vérifications';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    // Vérifier que l'utilisateur est admin
    if (currentUser?.userType != UserType.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
          backgroundColor: AppColors.error,
        ),
        body: const Center(
          child: Text('Accès réservé aux administrateurs'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Validations KYC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingVerifications,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildValidationList(),
    );
  }

  /// Vue d'erreur
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppFontSizes.lg,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              text: 'Réessayer',
              icon: Icons.refresh,
              onPressed: _loadPendingVerifications,
            ),
          ],
        ),
      ),
    );
  }

  /// Liste des validations en attente
  Widget _buildValidationList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Aucune validation en attente',
                style: TextStyle(
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Toutes les vérifications ont été traitées',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingVerifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          final user = _pendingUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  /// Card pour un utilisateur en attente
  Widget _buildUserCard(UserModel user) {
    final isVendeur = user.userType == UserType.vendeur;
    final userTypeLabel = isVendeur ? 'Vendeur' : 'Livreur';
    final userTypeColor = isVendeur ? AppColors.primary : AppColors.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: userTypeColor.withOpacity(0.2),
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                      color: userTypeColor,
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Infos utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: userTypeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              userTypeLabel,
                              style: TextStyle(
                                fontSize: AppFontSizes.xs,
                                fontWeight: FontWeight.bold,
                                color: userTypeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.pending,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Text(
                            'En attente',
                            style: TextStyle(
                              fontSize: AppFontSizes.sm,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Informations contact
            _buildInfoRow(Icons.email, user.email),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
              _buildInfoRow(Icons.phone, user.phoneNumber!),

            const SizedBox(height: AppSpacing.md),

            // Documents soumis
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, size: 16, color: AppColors.info),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Documents soumis',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getDocumentsList(user),
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Voir détails',
                    icon: Icons.visibility,
                    isOutlined: true,
                    onPressed: () => _showUserDetails(user),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CustomButton(
                    text: 'Approuver',
                    icon: Icons.check,
                    backgroundColor: AppColors.success,
                    onPressed: () => _showApproveDialog(user),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CustomButton(
                    text: 'Rejeter',
                    icon: Icons.close,
                    backgroundColor: AppColors.error,
                    onPressed: () => _showRejectDialog(user),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour une ligne d'information
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
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

  /// Obtenir la liste des documents
  String _getDocumentsList(UserModel user) {
    final docs = <String>[];

    if (user.userType == UserType.vendeur) {
      docs.addAll(['CNI', 'Selfie', 'Justificatif domicile']);
    } else if (user.userType == UserType.livreur) {
      final livreurProfile = user.profile['livreurProfile'] as Map<String, dynamic>?;
      final documents = livreurProfile?['documents'] as Map<String, dynamic>?;

      if (documents != null) {
        if (documents.containsKey('identityCard')) docs.add('CNI');
        if (documents.containsKey('drivingLicense')) docs.add('Permis');
        if (documents.containsKey('vehicleRegistration')) docs.add('Carte grise');
        if (documents.containsKey('insurance')) docs.add('Assurance');
        if (documents.containsKey('vehiclePhoto')) docs.add('Photo véhicule');
      }
    }

    return docs.isEmpty ? 'Aucun document' : docs.join(', ');
  }

  /// Afficher les détails de l'utilisateur
  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${user.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Téléphone', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Type', user.userType.toString().split('.').last),
              _buildDetailRow('Statut', user.verificationStatus.toString().split('.').last),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Documents:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppFontSizes.md,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_getDocumentsList(user)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppFontSizes.sm,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: AppFontSizes.sm),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog pour approuver
  void _showApproveDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approuver la vérification'),
        content: Text(
          'Êtes-vous sûr de vouloir approuver la vérification de ${user.displayName} ?\n\n'
          'L\'utilisateur pourra immédiatement commencer à ${user.userType == UserType.vendeur ? "vendre" : "effectuer des livraisons"}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  /// Dialog pour rejeter
  void _showRejectDialog(UserModel user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Indiquez la raison du rejet pour ${user.displayName}:',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Ex: CNI floue, document expiré...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez indiquer une raison'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _rejectUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  /// Approuver un utilisateur
  Future<void> _approveUser(UserModel user) async {
    try {
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser == null) return;

      await KYCVerificationService.validateKYC(
        user.id,
        true,
        adminId: currentUser.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName} approuvé avec succès'),
          backgroundColor: AppColors.success,
        ),
      );

      // Recharger la liste
      await _loadPendingVerifications();
    } catch (e) {
      debugPrint('❌ Erreur approbation: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'approbation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Rejeter un utilisateur
  Future<void> _rejectUser(UserModel user, String reason) async {
    try {
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser == null) return;

      await KYCVerificationService.validateKYC(
        user.id,
        false,
        rejectionReason: reason,
        adminId: currentUser.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName} rejeté'),
          backgroundColor: AppColors.warning,
        ),
      );

      // Recharger la liste
      await _loadPendingVerifications();
    } catch (e) {
      debugPrint('❌ Erreur rejet: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du rejet'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
