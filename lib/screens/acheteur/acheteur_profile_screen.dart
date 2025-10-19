import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../config/constants.dart';

class AcheteurProfileScreen extends StatefulWidget {
  const AcheteurProfileScreen({super.key});

  @override
  State<AcheteurProfileScreen> createState() => _AcheteurProfileScreenState();
}

class _AcheteurProfileScreenState extends State<AcheteurProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recharger les données utilisateur
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Modifier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo de profil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  color: Colors.white,
                                  onPressed: () {
                                    // TODO: Implémenter upload photo
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Fonctionnalité à venir'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Informations personnelles
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le téléphone est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Boutons de sauvegarde/annulation (si en mode édition)
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  // Réinitialiser les valeurs
                                  _nameController.text = user.displayName;
                                  _emailController.text = user.email;
                                  _phoneController.text = user.phoneNumber ?? '';
                                });
                              },
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Options du compte
                    const Text(
                      'Compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mes adresses
                    _buildMenuTile(
                      icon: Icons.location_on,
                      title: 'Mes adresses',
                      subtitle: 'Gérer vos adresses de livraison',
                      onTap: () => context.push('/acheteur/addresses'),
                    ),

                    // Moyens de paiement
                    _buildMenuTile(
                      icon: Icons.payment,
                      title: 'Moyens de paiement',
                      subtitle: 'Gérer vos cartes et comptes',
                      onTap: () => context.push('/acheteur/payment-methods'),
                    ),

                    // Historique des commandes
                    _buildMenuTile(
                      icon: Icons.shopping_bag,
                      title: 'Mes commandes',
                      subtitle: 'Voir l\'historique de vos commandes',
                      onTap: () => context.push('/acheteur/orders'),
                    ),

                    // Favoris
                    _buildMenuTile(
                      icon: Icons.favorite,
                      title: 'Mes favoris',
                      subtitle: 'Produits favoris',
                      onTap: () => context.push('/favorites'),
                    ),

                    // Notifications
                    _buildMenuTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Gérer vos notifications',
                      onTap: () => context.push('/notifications'),
                    ),

                    const SizedBox(height: 24),

                    // Paramètres
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Changer le mot de passe
                    _buildMenuTile(
                      icon: Icons.lock,
                      title: 'Mot de passe',
                      subtitle: 'Changer votre mot de passe',
                      onTap: () => context.push('/change-password'),
                    ),

                    // Aide
                    _buildMenuTile(
                      icon: Icons.help,
                      title: 'Aide & Support',
                      subtitle: 'Besoin d\'aide ?',
                      onTap: () => context.push('/help'),
                    ),

                    const SizedBox(height: 24),

                    // Bouton de déconnexion
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Se déconnecter',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Version
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
