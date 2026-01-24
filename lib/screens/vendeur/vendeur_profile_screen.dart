import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../models/user_model.dart';

class VendeurProfileScreen extends StatefulWidget {
  const VendeurProfileScreen({super.key});

  @override
  State<VendeurProfileScreen> createState() => _VendeurProfileScreenState();
}

class _VendeurProfileScreenState extends State<VendeurProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _businessNameController;

  // Field for displaying business categories
  String _displayCategories = 'Non définies';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _businessNameController = TextEditingController(
      text: user?.profile['businessName'] as String? ?? '',
    );

    // Get all categories for display
    final vendeurProfileData = user?.profile['vendeurProfile'] as Map<String, dynamic>?;
    if (vendeurProfileData != null) {
      final vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
      _displayCategories = vendeurProfile.businessCategories.join(', ');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  /// Upload de la photo de profil vers Firebase Storage
  Future<void> _updateProfilePhoto() async {
    try {
      // Sélectionner une image depuis la galerie
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) throw Exception('Utilisateur non connecté');

      // Afficher un indicateur de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload vers Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_photos').child('$userId.jpg');

      File imageFile = File(image.path);
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Mettre à jour Firestore avec la nouvelle URL
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: userId,
        data: {
          'profile.photoURL': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        // Recharger le profil utilisateur depuis Firestore
        final authProvider = context.read<AuthProvider>();
        await authProvider.refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Photo de profil mise à jour avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          // Recharger le profil pour afficher la nouvelle photo
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur upload photo: $e');
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la mise à jour de la photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour Firestore
      final updateData = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add business info to profile map
      if (_businessNameController.text.trim().isNotEmpty) {
        updateData['profile.businessName'] = _businessNameController.text.trim();
      }
      // Note: Categories are managed via shop_setup only

      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);

      // Recharger les données utilisateur
      await authProvider.refreshUser();

      if (mounted) {
        // Mettre à jour les controllers avec les nouvelles valeurs
        final updatedUser = authProvider.user;
        if (updatedUser != null) {
          _nameController.text = updatedUser.displayName;
          _emailController.text = updatedUser.email;
          _phoneController.text = updatedUser.phoneNumber ?? '';
          _businessNameController.text = updatedUser.profile['businessName'] as String? ?? '';

          // Mettre à jour l'affichage des catégories
          final vendeurProfileData = updatedUser.profile['vendeurProfile'] as Map<String, dynamic>?;
          if (vendeurProfileData != null) {
            final vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
            _displayCategories = vendeurProfile.businessCategories.join(', ');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendeur-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mon Profil Vendeur'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                            backgroundImage: user.profile['photoURL'] != null
                                ? NetworkImage(user.profile['photoURL'])
                                : null,
                            child: user.profile['photoURL'] == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
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
                                  onPressed: _updateProfilePhoto,
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

                    // Informations de la boutique
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informations de la boutique',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/vendeur/shop-setup'),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Gérer'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nom de la boutique - READ ONLY
                    TextFormField(
                      controller: _businessNameController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Nom de la boutique',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Catégories d'activité - READ ONLY 
                    TextFormField(
                      initialValue: _displayCategories,
                      enabled: false,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catégories d\'activité',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,      
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pour modifier les informations de votre boutique, cliquez sur "Gérer" ci-dessus',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                  _businessNameController.text =
                                      user.profile['businessName'] as String? ?? '';
                                  // Reset display categories
                                  final vendeurProfileData =
                                      user.profile['vendeurProfile'] as Map<String, dynamic>?;
                                  if (vendeurProfileData != null) {
                                    final vendeurProfile =
                                        VendeurProfile.fromMap(vendeurProfileData);
                                    _displayCategories =
                                        vendeurProfile.businessCategories.join(', ');
                                  }
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

                    // Section Compte
                    const Text(
                      'Compte et Boutique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildMenuTile(
                      icon: Icons.subscriptions,
                      title: 'Gérer mon abonnement',
                      subtitle: 'Voir votre plan actuel et historique',
                      onTap: () => context.push('/vendeur/subscription'),
                    ),

                    _buildMenuTile(
                      icon: Icons.card_membership,
                      title: 'Plans et tarifs',
                      subtitle: 'Découvrir et souscrire aux offres',
                      onTap: () => context.push('/subscription/plans'),
                    ),

                    _buildMenuTile(
                      icon: Icons.storefront,
                      title: 'Ma Boutique',
                      subtitle: 'Voir et gérer les informations de votre boutique',
                      onTap: () => context.push('/vendeur/my-shop'),
                    ),

                    _buildMenuTile(
                      icon: Icons.payment,
                      title: 'Paiements',
                      subtitle: 'Voir l\'historique des paiements reçus',
                      onTap: () => context.push('/vendeur/payment-history'),
                    ),

                    const SizedBox(height: 24),

                    // Section Paramètres
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildMenuTile(
                      icon: Icons.payment,
                      title: 'Moyens de paiement',
                      subtitle: 'Configurer les modes de paiement acceptés',
                      onTap: () => context.push('/vendeur/payment-settings'),
                    ),

                    _buildMenuTile(
                      icon: Icons.rate_review,
                      title: 'Avis clients',
                      subtitle: 'Gérer vos avis et répondre aux clients',
                      onTap: () => context.push('/vendeur/reviews'),
                    ),

                    _buildMenuTile(
                      icon: Icons.settings,
                      title: 'Paramètres utilisateur',
                      subtitle: 'Notifications, thème, langue',
                      onTap: () => context.push('/user-settings'),
                    ),

                    _buildMenuTile(
                      icon: Icons.lock,
                      title: 'Mot de passe',
                      subtitle: 'Changer votre mot de passe',
                      onTap: () => context.push('/change-password'),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        label: const Text(
                          'Se déconnecter',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
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
