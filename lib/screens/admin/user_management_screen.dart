// ===== lib/screens/admin/user_management_screen.dart =====
// Gestion générale de tous les utilisateurs - Admin

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/user_model.dart';
import '../../models/admin_role_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  final List<String> _userTypeFilters = [
    'all',
    'acheteur',
    'vendeur',
    'livreur',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _userTypeFilters.length, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ Récupérer tous les utilisateurs sans orderBy pour éviter d'exclure les documents sans createdAt
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .get();

      final users = snapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc);
      }).toList();

      // Trier côté client par date de création (les plus récents en premier)
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  List<UserModel> _getFilteredUsers(String userType) {
    var users = userType == 'all'
        ? _allUsers
        : _allUsers.where((user) => user.userType.value == userType).toList();

    // Appliquer le filtre de recherche
    if (_searchQuery.isNotEmpty) {
      users = users.where((user) {
        final name = user.displayName.toLowerCase();
        final email = user.email.toLowerCase();
        final phone = user.phoneNumber?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) || email.contains(query) || phone.contains(query);
      }).toList();
    }

    return users;
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'all':
        return 'Tous';
      case 'acheteur':
        return 'Acheteurs';
      case 'vendeur':
        return 'Vendeurs';
      case 'livreur':
        return 'Livreurs';
      case 'admin':
        return 'Admins';
      default:
        return userType;
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.acheteur:
        return AppColors.info;
      case UserType.vendeur:
        return AppColors.success;
      case UserType.livreur:
        return AppColors.warning;
      case UserType.admin:
        return AppColors.error;
    }
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.acheteur:
        return Icons.shopping_bag;
      case UserType.vendeur:
        return Icons.store;
      case UserType.livreur:
        return Icons.local_shipping;
      case UserType.admin:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Gestion des Utilisateurs'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _userTypeFilters.map((type) {
                  final count = _getFilteredUsers(type).length;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getUserTypeLabel(type)),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text(
            'Chargement des utilisateurs...',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.md,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: _userTypeFilters.map((type) {
        final filteredUsers = _getFilteredUsers(type);

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: _loadUsers,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _buildUserCard(filteredUsers[index]);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String userType) {
    String message;
    IconData icon;

    switch (userType) {
      case 'all':
        message = 'Aucun utilisateur trouvé';
        icon = Icons.people_outline;
        break;
      case 'acheteur':
        message = 'Aucun acheteur';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'vendeur':
        message = 'Aucun vendeur';
        icon = Icons.store_outlined;
        break;
      case 'livreur':
        message = 'Aucun livreur';
        icon = Icons.local_shipping_outlined;
        break;
      case 'admin':
        message = 'Aucun admin';
        icon = Icons.admin_panel_settings_outlined;
        break;
      default:
        message = 'Aucun utilisateur';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.md,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final typeColor = _getUserTypeColor(user.userType);
    final typeIcon = _getUserTypeIcon(user.userType);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: typeColor.withValues(alpha: 0.2),
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Informations
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
                                  fontSize: AppFontSizes.md,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badge type utilisateur
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: typeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(typeIcon, size: 12, color: typeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.userType.label,
                                    style: TextStyle(
                                      color: typeColor,
                                      fontSize: AppFontSizes.xs,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.sm,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.phoneNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phoneNumber!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppFontSizes.sm,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Informations secondaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Statut
                  Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: user.isActive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Actif' : 'Suspendu',
                        style: TextStyle(
                          color: user.isActive ? AppColors.success : AppColors.error,
                          fontSize: AppFontSizes.sm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Date d'inscription
                  Text(
                    'Inscrit: ${_formatDate(user.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.xs,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleUserStatus(user),
                      icon: Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(user.isActive ? 'Suspendre' : 'Activer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isActive ? AppColors.error : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                _getUserTypeColor(user.userType).withValues(alpha: 0.2),
                            child: Icon(
                              _getUserTypeIcon(user.userType),
                              size: 40,
                              color: _getUserTypeColor(user.userType),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.xl,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user.userType.label,
                                  style: TextStyle(
                                    color: _getUserTypeColor(user.userType),
                                    fontSize: AppFontSizes.md,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Informations de base
                      _buildDetailSection('Informations', [
                        _buildDetailRow('Email', user.email),
                        if (user.phoneNumber != null)
                          _buildDetailRow('Téléphone', user.phoneNumber!),
                        _buildDetailRow(
                          'Statut',
                          user.isActive ? 'Actif' : 'Suspendu',
                        ),
                        _buildDetailRow(
                          'Vérifié',
                          user.isVerified ? 'Oui' : 'Non',
                        ),
                        _buildDetailRow(
                          'Date d\'inscription',
                          DateFormat('dd/MM/yyyy à HH:mm').format(user.createdAt),
                        ),
                        if (user.lastLoginAt != null)
                          _buildDetailRow(
                            'Dernière connexion',
                            DateFormat('dd/MM/yyyy à HH:mm').format(user.lastLoginAt!),
                          ),
                      ]),

                      const SizedBox(height: AppSpacing.xl),

                      // Gestion des rôles et permissions
                      _buildDetailSection('Gestion des rôles', [
                        const Text(
                          'Type d\'utilisateur actuel',
                          style: TextStyle(
                            fontSize: AppFontSizes.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: _getUserTypeColor(user.userType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _getUserTypeColor(user.userType).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_getUserTypeIcon(user.userType),
                                  color: _getUserTypeColor(user.userType)),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                user.userType.label,
                                style: TextStyle(
                                  fontSize: AppFontSizes.md,
                                  fontWeight: FontWeight.bold,
                                  color: _getUserTypeColor(user.userType),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showChangeUserTypeDialog(user);
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Changer le type d\'utilisateur'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.xl),

                      // Actions de vérification et statut
                      _buildDetailSection('Actions sur le compte', []),

                      // Bouton vérification
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleUserVerification(user);
                          },
                          icon: Icon(
                            user.isVerified ? Icons.verified : Icons.verified_user,
                          ),
                          label: Text(
                            user.isVerified ? 'Retirer la vérification' : 'Vérifier ce compte',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isVerified ? AppColors.warning : AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Bouton gestion abonnement (vendeur/livreur uniquement)
                      if (user.userType.value == 'vendeur' || user.userType.value == 'livreur')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Naviguer vers la page de gestion des abonnements
                              Navigator.pushNamed(context, '/admin/subscription-management');
                            },
                            icon: const Icon(Icons.card_membership),
                            label: const Text('Gérer les abonnements'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                      if (user.userType.value == 'vendeur' || user.userType.value == 'livreur')
                        const SizedBox(height: AppSpacing.sm),

                      // Bouton activation/suspension
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleUserStatus(user);
                          },
                          icon: Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                          ),
                          label: Text(
                            user.isActive ? 'Suspendre ce compte' : 'Activer ce compte',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isActive ? AppColors.error : AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteUser(user);
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Supprimer ce compte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Suspendre l\'utilisateur' : 'Activer l\'utilisateur'),
        content: Text(
          user.isActive
              ? 'Voulez-vous vraiment suspendre ${user.displayName} ?\n\nIl ne pourra plus se connecter.'
              : 'Voulez-vous vraiment activer ${user.displayName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(user.isActive ? 'Suspendre' : 'Activer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).update({
          'isActive': !user.isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isActive
                    ? 'Utilisateur suspendu avec succès'
                    : 'Utilisateur activé avec succès',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          _loadUsers(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Voulez-vous vraiment supprimer ${user.displayName} ?\n\n'
          'Cette action est IRRÉVERSIBLE et supprimera toutes ses données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(user.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur supprimé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          _loadUsers(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // ===== GESTION DES RÔLES ET PERMISSIONS =====

  Future<void> _showChangeUserTypeDialog(UserModel user) async {
    UserType? selectedType = user.userType;
    AdminRoleType? selectedAdminRole;

    // Si l'utilisateur est déjà admin, récupérer son rôle actuel
    if (user.userType == UserType.admin) {
      final adminRole = user.profile['adminRole'] as String?;
      if (adminRole != null) {
        selectedAdminRole = AdminRoleType.values.firstWhere(
          (r) => r.name == adminRole,
          orElse: () => AdminRoleType.admin,
        );
      } else {
        selectedAdminRole = AdminRoleType.admin;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le type d\'utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez le nouveau type pour ${user.displayName}',
                  style: const TextStyle(fontSize: AppFontSizes.sm),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Options de types d'utilisateur
                ...UserType.values.map((type) {
                  final isSelected = selectedType == type;
                  final color = _getUserTypeColor(type);
                  final icon = _getUserTypeIcon(type);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedType = type;
                        // Si on sélectionne admin et qu'il n'y a pas de rôle, définir par défaut
                        if (type == UserType.admin && selectedAdminRole == null) {
                          selectedAdminRole = AdminRoleType.admin;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? color : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _getUserTypeDescription(type),
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.xs,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: color),
                        ],
                      ),
                    ),
                  );
                }),

                // Si admin est sélectionné, afficher le sélecteur de rôle
                if (selectedType == UserType.admin) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Rôle Administrateur',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSizes.md,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<AdminRoleType>(
                    initialValue: selectedAdminRole,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner le rôle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shield),
                    ),
                    items: AdminRole.getAllRoles()
                        .where((role) => role.type != AdminRoleType.superAdmin) // Exclure super admin
                        .map((role) => DropdownMenuItem(
                              value: role.type,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    role.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    role.description,
                                    style: const TextStyle(
                                      fontSize: AppFontSizes.xs,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedAdminRole = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedType == user.userType &&
                         (selectedType != UserType.admin ||
                          selectedAdminRole?.name == user.profile['adminRole'])
                  ? null
                  : () => Navigator.pop(context, {
                        'userType': selectedType,
                        'adminRole': selectedAdminRole,
                      }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newType = result['userType'] as UserType?;
      final newAdminRole = result['adminRole'] as AdminRoleType?;

      if (newType != null) {
        if (newType != user.userType) {
          // Changement de type d'utilisateur
          await _changeUserType(user, newType, newAdminRole);
        } else if (newType == UserType.admin && newAdminRole != null) {
          // Même userType (admin) mais rôle admin différent
          await _changeUserType(user, newType, newAdminRole);
        }
      }
    }
  }

  String _getUserTypeDescription(UserType type) {
    switch (type) {
      case UserType.acheteur:
        return 'Peut acheter des produits et passer des commandes';
      case UserType.vendeur:
        return 'Peut vendre des produits et gérer son commerce';
      case UserType.livreur:
        return 'Peut effectuer des livraisons de commandes';
      case UserType.admin:
        return 'Accès complet à la gestion de la plateforme';
    }
  }

  Future<void> _changeUserType(UserModel user, UserType newType, [AdminRoleType? adminRole]) async {
    String confirmationMessage = 'Voulez-vous vraiment changer le type de ${user.displayName} ?\n\n'
        'De: ${user.userType.label}\n'
        'Vers: ${newType.label}';

    if (newType == UserType.admin && adminRole != null) {
      final role = AdminRole.getRole(adminRole);
      confirmationMessage += '\n\nRôle Admin: ${role.name}\n${role.description}';
    }

    confirmationMessage += '\n\nCette action modifiera les permissions et l\'accès de l\'utilisateur.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le changement'),
        content: Text(confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final updateData = <String, dynamic>{
          'userType': newType.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Si on change vers admin, ajouter le rôle admin
        if (newType == UserType.admin && adminRole != null) {
          updateData['adminRole'] = adminRole.name;
        }

        await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).update(updateData);

        if (mounted) {
          String successMessage = 'Type d\'utilisateur changé : ${user.userType.label} → ${newType.label}';
          if (newType == UserType.admin && adminRole != null) {
            final role = AdminRole.getRole(adminRole);
            successMessage += '\nRôle: ${role.name}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.success,
            ),
          );

          _loadUsers(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du changement de type: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserVerification(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isVerified ? 'Retirer la vérification' : 'Vérifier l\'utilisateur'),
        content: Text(
          user.isVerified
              ? 'Voulez-vous retirer la vérification de ${user.displayName} ?\n\n'
                  'L\'utilisateur perdra son badge vérifié.'
              : 'Voulez-vous vérifier ${user.displayName} ?\n\n'
                  'L\'utilisateur obtiendra un badge vérifié.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isVerified ? AppColors.warning : AppColors.info,
            ),
            child: Text(user.isVerified ? 'Retirer' : 'Vérifier'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).update({
          'isVerified': !user.isVerified,
          'verificationStatus': !user.isVerified ? 'verified' : 'notVerified',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isVerified
                    ? 'Vérification retirée avec succès'
                    : 'Utilisateur vérifié avec succès',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          _loadUsers(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

