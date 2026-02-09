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

class AcheteurProfileScreen extends StatefulWidget {
  const AcheteurProfileScreen({super.key});

  @override
  State<AcheteurProfileScreen> createState() => _AcheteurProfileScreenState();
}

class _AcheteurProfileScreenState extends State<AcheteurProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // New fields for birth date and gender
  DateTime? _selectedBirthDate;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    // Initialize birth date and gender from user profile
    if (user?.profile['birthDate'] != null) {
      _selectedBirthDate = (user!.profile['birthDate'] as Timestamp).toDate();
    }
    _selectedGender = user?.profile['gender'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Sélectionner une date de naissance
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

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

      // Add birth date and gender to profile map
      if (_selectedBirthDate != null) {
        updateData['profile.birthDate'] = Timestamp.fromDate(_selectedBirthDate!);
      }
      if (_selectedGender != null) {
        updateData['profile.gender'] = _selectedGender!;
      }

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

          // Mettre à jour date de naissance et genre
          if (updatedUser.profile['birthDate'] != null) {
            _selectedBirthDate = (updatedUser.profile['birthDate'] as Timestamp).toDate();
          }
          _selectedGender = updatedUser.profile['gender'] as String?;
        }

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
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/acheteur-home');
            }
          },
          tooltip: 'Retour',
        ),
    title: const Text('Mon Profil'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    const SizedBox(height: 16),

                    // Date de naissance
                    InkWell(
                      onTap: _isEditing ? _selectBirthDate : null,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de naissance',
                          prefixIcon: const Icon(Icons.cake),
                          suffixIcon: _isEditing ? const Icon(Icons.calendar_today) : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabled: _isEditing,
                        ),
                        child: Text(
                          _selectedBirthDate != null
                              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                              : 'Non renseignée',
                          style: TextStyle(
                            color: _selectedBirthDate != null ? Colors.black : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Genre
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabled: _isEditing,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'homme', child: Text('Homme')),
                        DropdownMenuItem(value: 'femme', child: Text('Femme')),
                        DropdownMenuItem(value: 'autre', child: Text('Autre')),
                      ],
                      onChanged: _isEditing
                          ? (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            }
                          : null,
                      hint: const Text('Sélectionnez votre genre'),
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
                                  // Reset birth date and gender
                                  if (user.profile['birthDate'] != null) {
                                    _selectedBirthDate = (user.profile['birthDate'] as Timestamp).toDate();
                                  } else {
                                    _selectedBirthDate = null;
                                  }
                                  _selectedGender = user.profile['gender'] as String?;
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

                    // Gestion du compte
                    const Text(
                      'Gestion du compte',
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

                    // Notifications
                    _buildMenuTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Gérer vos préférences de notifications',
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

                    // Préférences utilisateur
                    _buildMenuTile(
                      icon: Icons.settings,
                      title: 'Paramètres utilisateur',
                      subtitle: 'Notifications, thème, langue',
                      onTap: () => context.push('/user-settings'),
                    ),

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

