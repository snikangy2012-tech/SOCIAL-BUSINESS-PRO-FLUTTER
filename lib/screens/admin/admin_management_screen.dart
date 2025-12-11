// ===== lib/screens/admin/admin_management_screen.dart =====
// Écran de gestion des administrateurs (SUPER ADMIN ONLY)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/admin_role_model.dart';
import '../widgets/system_ui_scaffold.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<AdminUser> _admins = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'admin')
          .orderBy('createdAt', descending: true)
          .get();

      final admins = snapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc))
          .toList();

      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement admins: $e');
      setState(() => _isLoading = false);
    }
  }

  List<AdminUser> get _filteredAdmins {
    if (_searchQuery.isEmpty) return _admins;

    return _admins.where((admin) {
      final query = _searchQuery.toLowerCase();
      return admin.displayName.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query) ||
          AdminRole.getRole(admin.role).name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Gestion des Administrateurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de recherche et bouton ajouter
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un administrateur...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateAdminDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvel Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des admins
                Expanded(
                  child: _filteredAdmins.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Aucun administrateur'
                                : 'Aucun résultat pour "$_searchQuery"',
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAdmins,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAdmins.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final admin = _filteredAdmins[index];
                              return _buildAdminCard(admin);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAdminCard(AdminUser admin) {
    final role = AdminRole.getRole(admin.role);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: admin.isSuperAdmin
                      ? AppColors.primary
                      : AppColors.secondary,
                  child: Text(
                    admin.displayName.isNotEmpty
                        ? admin.displayName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              admin.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (admin.isSuperAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SUPER ADMIN',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.email,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.shield,
                            size: 14,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            role.name,
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: admin.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: admin.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  child: Text(
                    admin.isActive ? 'Actif' : 'Suspendu',
                    style: TextStyle(
                      color: admin.isActive
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Informations supplémentaires
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(
                  'Créé le ${dateFormat.format(admin.createdAt)}',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${admin.allPrivileges.length} privilèges',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAdminDetails(admin),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Détails'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: 8),
                if (!admin.isSuperAdmin) ...[
                  TextButton.icon(
                    onPressed: () => _showEditAdminDialog(admin),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _toggleAdminStatus(admin),
                    icon: Icon(
                      admin.isActive ? Icons.block : Icons.check_circle,
                      size: 18,
                    ),
                    label: Text(admin.isActive ? 'Suspendre' : 'Activer'),
                    style: TextButton.styleFrom(
                      foregroundColor: admin.isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Détails d'un admin
  void _showAdminDetails(AdminUser admin) {
    final role = AdminRole.getRole(admin.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: 8),
            const Text('Détails Administrateur'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nom', admin.displayName),
              _buildDetailRow('Email', admin.email),
              _buildDetailRow('Rôle', role.name),
              _buildDetailRow('Statut', admin.isActive ? 'Actif' : 'Suspendu'),
              const Divider(height: 24),
              const Text(
                'Privilèges',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...admin.allPrivileges.map((privilege) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPrivilegeLabel(privilege),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPrivilegeLabel(AdminPrivilege privilege) {
    switch (privilege) {
      case AdminPrivilege.viewUsers:
        return 'Voir les utilisateurs';
      case AdminPrivilege.manageUsers:
        return 'Gérer les utilisateurs';
      case AdminPrivilege.deleteUsers:
        return 'Supprimer les utilisateurs';
      case AdminPrivilege.viewVendors:
        return 'Voir les vendeurs';
      case AdminPrivilege.manageVendors:
        return 'Gérer les vendeurs';
      case AdminPrivilege.viewDelivery:
        return 'Voir les livreurs';
      case AdminPrivilege.manageDelivery:
        return 'Gérer les livreurs';
      case AdminPrivilege.viewProducts:
        return 'Voir les produits';
      case AdminPrivilege.manageProducts:
        return 'Gérer les produits';
      case AdminPrivilege.viewOrders:
        return 'Voir les commandes';
      case AdminPrivilege.manageOrders:
        return 'Gérer les commandes';
      case AdminPrivilege.viewFinance:
        return 'Voir les finances';
      case AdminPrivilege.manageFinance:
        return 'Gérer les finances';
      case AdminPrivilege.viewSubscriptions:
        return 'Voir les abonnements';
      case AdminPrivilege.manageSubscriptions:
        return 'Gérer les abonnements';
      case AdminPrivilege.viewAdmins:
        return 'Voir les administrateurs';
      case AdminPrivilege.manageAdmins:
        return 'Gérer les administrateurs';
      case AdminPrivilege.viewReports:
        return 'Voir les signalements';
      case AdminPrivilege.manageReports:
        return 'Gérer les signalements';
      case AdminPrivilege.viewSettings:
        return 'Voir les paramètres';
      case AdminPrivilege.manageSettings:
        return 'Gérer les paramètres';
    }
  }

  // Dialogue de création d'un admin
  void _showCreateAdminDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    AdminRoleType selectedRole = AdminRoleType.support;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Créer un Administrateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AdminRoleType>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: AdminRole.getAllRoles()
                      .where((role) => role.type != AdminRoleType.superAdmin)
                      .map((role) => DropdownMenuItem(
                            value: role.type,
                            child: Text(role.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _createAdmin(
                emailController.text,
                nameController.text,
                passwordController.text,
                selectedRole,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  // Créer un admin
  Future<void> _createAdmin(
    String email,
    String name,
    String password,
    AdminRoleType role,
  ) async {
    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    try {
      Navigator.pop(context); // Fermer le dialogue

      // Créer l'utilisateur dans Firebase Auth (via un Cloud Function dans une vraie app)
      // Pour l'instant, on crée juste le document Firestore
      final docRef = await _firestore.collection(FirebaseCollections.users).add({
        'email': email,
        'displayName': name,
        'userType': 'admin',
        'adminRole': role.name,
        'isSuperAdmin': false,
        'customPrivileges': [],
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'createdBy': _auth.currentUser?.uid,
      });

      _showSuccess('Administrateur créé avec succès');
      _loadAdmins();
    } catch (e) {
      _showError('Erreur lors de la création: $e');
    }
  }

  // Dialogue de modification d'un admin
  void _showEditAdminDialog(AdminUser admin) {
    final nameController = TextEditingController(text: admin.displayName);
    AdminRoleType selectedRole = admin.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'Administrateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdminRoleType>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: AdminRole.getAllRoles()
                    .where((role) => role.type != AdminRoleType.superAdmin)
                    .map((role) => DropdownMenuItem(
                          value: role.type,
                          child: Text(role.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _updateAdmin(admin, nameController.text, selectedRole),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // Mettre à jour un admin
  Future<void> _updateAdmin(AdminUser admin, String newName, AdminRoleType newRole) async {
    try {
      Navigator.pop(context);

      await _firestore.collection(FirebaseCollections.users).doc(admin.uid).update({
        'displayName': newName,
        'adminRole': newRole.name,
        'updatedAt': Timestamp.now(),
      });

      _showSuccess('Administrateur mis à jour');
      _loadAdmins();
    } catch (e) {
      _showError('Erreur lors de la mise à jour: $e');
    }
  }

  // Activer/Suspendre un admin
  Future<void> _toggleAdminStatus(AdminUser admin) async {
    final action = admin.isActive ? 'suspendre' : 'activer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.substring(0, 1).toUpperCase()}${action.substring(1)} cet administrateur ?'),
        content: Text('Voulez-vous vraiment $action ${admin.displayName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: admin.isActive ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(action.substring(0, 1).toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection(FirebaseCollections.users).doc(admin.uid).update({
        'isActive': !admin.isActive,
        'updatedAt': Timestamp.now(),
      });

      _showSuccess('Statut mis à jour');
      _loadAdmins();
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
