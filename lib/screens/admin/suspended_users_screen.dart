// ===== lib/screens/admin/suspended_users_screen.dart =====
// Écran de gestion des utilisateurs suspendus

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class SuspendedUsersScreen extends StatefulWidget {
  const SuspendedUsersScreen({super.key});

  @override
  State<SuspendedUsersScreen> createState() => _SuspendedUsersScreenState();
}

class _SuspendedUsersScreenState extends State<SuspendedUsersScreen> {
  String _selectedUserType = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _userTypeFilters = [
    'Tous',
    'Vendeurs',
    'Acheteurs',
    'Livreurs',
  ];

  final Map<String, UserType> _userTypeMapping = {
    'Vendeurs': UserType.vendeur,
    'Acheteurs': UserType.acheteur,
    'Livreurs': UserType.livreur,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Utilisateurs Suspendus'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(),

          // Statistiques rapides
          _buildQuickStats(),

          // Liste des utilisateurs suspendus
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email ou téléphone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Filtre par type d'utilisateur
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Type d\'utilisateur',
              prefixIcon: const Icon(Icons.filter_list),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            items: _userTypeFilters.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            initialValue: _selectedUserType,
            onChanged: (value) {
              setState(() {
                _selectedUserType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('isActive', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final users = snapshot.data!.docs;
        final totalSuspended = users.length;
        final suspendedVendeurs = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userType'] == 'vendeur';
        }).length;
        final suspendedAcheteurs = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userType'] == 'acheteur';
        }).length;
        final suspendedLivreurs = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userType'] == 'livreur';
        }).length;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalSuspended.toString(),
                  Icons.block,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Vendeurs',
                  suspendedVendeurs.toString(),
                  Icons.store,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Acheteurs',
                  suspendedAcheteurs.toString(),
                  Icons.shopping_bag,
                  AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Livreurs',
                  suspendedLivreurs.toString(),
                  Icons.delivery_dining,
                  AppColors.info,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun utilisateur suspendu',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tous les utilisateurs sont actifs',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => _matchesFilters(user))
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun utilisateur ne correspond aux filtres',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .where('isActive', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  bool _matchesFilters(UserModel user) {
    // Filtre de recherche
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      if (!user.displayName.toLowerCase().contains(searchLower) &&
          !user.email.toLowerCase().contains(searchLower) &&
          !(user.phoneNumber?.toLowerCase().contains(searchLower) ?? false)) {
        return false;
      }
    }

    // Filtre par type d'utilisateur
    if (_selectedUserType != 'Tous') {
      final selectedType = _userTypeMapping[_selectedUserType];
      if (user.userType != selectedType) return false;
    }

    return true;
  }

  Widget _buildUserCard(UserModel user) {
    final userTypeColor = _getUserTypeColor(user.userType);
    final userTypeLabel = _getUserTypeLabel(user.userType);
    final userTypeIcon = _getUserTypeIcon(user.userType);

    // Récupérer les informations de suspension depuis le profil
    final suspensionInfo = _getSuspensionInfo(user);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec photo et informations
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: userTypeColor.withValues(alpha: 0.2),
                  child: Icon(
                    userTypeIcon,
                    color: userTypeColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Informations utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: userTypeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: userTypeColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              userTypeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: userTypeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (user.phoneNumber != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.phoneNumber!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Informations de suspension
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.block,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Compte suspendu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (suspensionInfo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    if (suspensionInfo['date'] != null)
                      Text(
                        'Date: ${suspensionInfo['date']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (suspensionInfo['reason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Raison: ${suspensionInfo['reason']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reactivateUser(user),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Réactiver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.vendeur:
        return AppColors.primary;
      case UserType.acheteur:
        return AppColors.secondary;
      case UserType.livreur:
        return AppColors.info;
      case UserType.admin:
        return AppColors.error;
    }
  }

  String _getUserTypeLabel(UserType type) {
    switch (type) {
      case UserType.vendeur:
        return 'Vendeur';
      case UserType.acheteur:
        return 'Acheteur';
      case UserType.livreur:
        return 'Livreur';
      case UserType.admin:
        return 'Admin';
    }
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.vendeur:
        return Icons.store;
      case UserType.acheteur:
        return Icons.shopping_bag;
      case UserType.livreur:
        return Icons.delivery_dining;
      case UserType.admin:
        return Icons.admin_panel_settings;
    }
  }

  Map<String, String?> _getSuspensionInfo(UserModel user) {
    final info = <String, String?>{};

    // Formater la date de dernière modification (probable date de suspension)
    info['date'] = DateFormat('dd/MM/yyyy HH:mm').format(user.updatedAt);

    // Chercher la raison dans le profil si elle existe
    if (user.profile.containsKey('suspensionReason')) {
      info['reason'] = user.profile['suspensionReason']?.toString();
    }

    return info;
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Détails de l\'utilisateur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar et nom
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                _getUserTypeColor(user.userType).withValues(alpha: 0.2),
                            child: Icon(
                              _getUserTypeIcon(user.userType),
                              color: _getUserTypeColor(user.userType),
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(user.userType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _getUserTypeLabel(user.userType),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getUserTypeColor(user.userType),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Informations principales
                    _buildSectionTitle('Informations'),
                    _buildInfoRow('Email', user.email),
                    if (user.phoneNumber != null) _buildInfoRow('Téléphone', user.phoneNumber!),
                    _buildInfoRow('ID', user.id),
                    _buildInfoRow(
                      'Créé le',
                      DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt),
                    ),
                    _buildInfoRow(
                      'Modifié le',
                      DateFormat('dd/MM/yyyy HH:mm').format(user.updatedAt),
                    ),
                    if (user.lastLoginAt != null)
                      _buildInfoRow(
                        'Dernière connexion',
                        DateFormat('dd/MM/yyyy HH:mm').format(user.lastLoginAt!),
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // Statut
                    _buildSectionTitle('Statut'),
                    _buildInfoRow(
                      'Compte',
                      user.isActive ? 'Actif' : 'Suspendu',
                    ),
                    _buildInfoRow(
                      'Vérifié',
                      user.isVerified ? 'Oui' : 'Non',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivateUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(child: Text('Réactiver l\'utilisateur')),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir réactiver le compte de "${user.displayName}" ?\n\n'
          'L\'utilisateur pourra à nouveau se connecter et utiliser la plateforme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Réactiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Réactiver l'utilisateur dans Firestore
      await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'profile.suspensionReason': FieldValue.delete(), // Supprimer la raison
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${user.displayName} a été réactivé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

