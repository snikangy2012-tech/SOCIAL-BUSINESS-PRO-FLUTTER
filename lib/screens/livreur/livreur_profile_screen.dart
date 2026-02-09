// ===== lib/screens/livreur/livreur_profile_screen.dart =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import '../../services/delivery_service.dart';
import '../../services/review_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../utils/number_formatter.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../widgets/system_ui_scaffold.dart';

class LivreurProfileScreen extends StatefulWidget {
  const LivreurProfileScreen({super.key});

  @override
  State<LivreurProfileScreen> createState() => _LivreurProfileScreenState();
}

class _LivreurProfileScreenState extends State<LivreurProfileScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _currentUser;
  List<DeliveryModel> _deliveryHistory = [];
  bool _isLoading = true;
  bool _isAvailable = false;

  // Statistics
  int _totalDeliveries = 0;
  int _completedDeliveries = 0;
  double _totalEarnings = 0;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null) {
        // ✅ Utiliser le user depuis AuthProvider au lieu de FirebaseService
        final user = authProvider.user;

        if (user != null) {
          // ✅ Charger les livraisons avec timeout
          List<DeliveryModel> deliveries = [];
          try {
            deliveries = await _deliveryService.getLivreurDeliveries(livreurId: userId).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⚠️ Timeout chargement livraisons');
                return <DeliveryModel>[];
              },
            );
          } catch (e) {
            debugPrint('❌ Erreur chargement livraisons: $e');
            deliveries = [];
          }

          if (mounted) {
            // Filtrer seulement les livraisons terminées pour l'historique
            final completedDeliveries = deliveries.where((d) {
              final status = d.status.toLowerCase();
              return status == 'delivered' || status == 'completed' || status == 'cancelled';
            }).toList();

            debugPrint(
                '📋 Historique: ${completedDeliveries.length} livraisons terminées sur ${deliveries.length} total');

            setState(() {
              _currentUser = user;
              _deliveryHistory = completedDeliveries;
              if (user.profile['isAvailable'] != null) {
                _isAvailable = user.profile['isAvailable'] as bool;
              } else {
                _isAvailable = false;
              }
            });

            _calculateStatistics();
          }
        }
      } else {
        // ✅ Si pas d'userId, utiliser quand même le user du provider
        final user = authProvider.user;
        if (user != null && mounted) {
          setState(() {
            _currentUser = user;
            _deliveryHistory = [];
            _isAvailable = false;
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Erreur _loadProfileData: $e');

      // ✅ Toujours charger le user depuis AuthProvider même en cas d'erreur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _calculateStatistics() async {
    _totalDeliveries = _deliveryHistory.length;
    _completedDeliveries =
        _deliveryHistory.where((d) => d.status.toLowerCase() == 'delivered').length;

    _totalEarnings = _deliveryHistory
        .where((d) => d.status.toLowerCase() == 'delivered')
        .fold<double>(0, (sum, delivery) => sum + delivery.deliveryFee);

    // Charger la note moyenne réelle depuis ReviewService
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      try {
        final reviewService = ReviewService();
        _averageRating = await reviewService.getAverageRating(userId, 'livreur');
        debugPrint('⭐ Note moyenne livreur chargée: $_averageRating');
      } catch (e) {
        debugPrint('⚠️ Erreur chargement note livreur: $e');
        _averageRating = 0;
      }
    } else {
      _averageRating = 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      final newStatus = !_isAvailable;

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: _currentUser!.id,
        data: {
          'profile.isAvailable': newStatus,
        },
      );

      setState(() {
        _isAvailable = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Vous êtes maintenant disponible pour les livraisons'
                  : 'Vous êtes maintenant indisponible',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final storageRef =
          FirebaseStorage.instance.ref().child('profile_photos').child('${_currentUser!.id}.jpg');

      File imageFile = File(image.path);
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: _currentUser!.id,
        data: {
          'profile.photoUrl': imageUrl,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo mise à jour')),
        );
      }

      _loadProfileData();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              try {
                await authProvider.logout();
                if (mounted) {
                  navigator.pop(); // Fermer le dialog
                  context.go('/login'); // Rediriger vers login
                }
              } catch (e) {
                if (mounted) {
                  navigator.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentUser?.displayName);
    final phoneController = TextEditingController(text: _currentUser?.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
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
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
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
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FirebaseService.updateDocument(
                  collection: FirebaseCollections.users,
                  docId: _currentUser!.id,
                  data: {
                    'displayName': nameController.text,
                    'phoneNumber': phoneController.text,
                  },
                );

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Profil mis à jour')),
                  );
                }

                _loadProfileData();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryHistoryItem(DeliveryModel delivery) {
    final statusColors = {
      'pending': Colors.orange,
      'picked_up': Colors.blue,
      'in_transit': Colors.purple,
      'delivered': Colors.green,
      'failed': Colors.red,
    };

    final statusLabels = {
      'pending': 'En attente',
      'picked_up': 'Récupéré',
      'in_transit': 'En cours',
      'delivered': 'Livré',
      'failed': 'Échec',
    };

    final status = delivery.status.toLowerCase();
    final color = statusColors[status] ?? Colors.grey;
    final label = statusLabels[status] ?? delivery.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_shipping, color: color),
        ),
        title: Text(
          formatDeliveryNumber(delivery.id, allDeliveries: _deliveryHistory),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              delivery.deliveryAddress['address'] as String? ?? 'Adresse non disponible',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${delivery.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${delivery.deliveryFee.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(delivery.createdAt),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return SystemUIScaffold(
        body: Center(child: CircularProgressIndicator()),
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
              context.go('/livreur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Modifier le profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _currentUser!.profile['photoUrl'] != null
                              ? NetworkImage(_currentUser!.profile['photoUrl'] as String)
                              : null,
                          child: _currentUser!.profile['photoUrl'] == null
                              ? Text(
                                  _currentUser!.displayName.isNotEmpty
                                      ? _currentUser!.displayName[0].toUpperCase()
                                      : 'L',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _updateProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentUser!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    if (_currentUser!.phoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentUser!.phoneNumber!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isAvailable ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable ? 'Disponible' : 'Indisponible',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) => _toggleAvailability(),
                            activeThumbColor: Colors.white,
                            activeTrackColor: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section Abonnement
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Abonnement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuTile(
                      icon: Icons.subscriptions,
                      title: 'Mon Abonnement',
                      subtitle: 'Voir votre plan actuel et historique',
                      onTap: () => context.push('/livreur/subscription'),
                    ),
                    _buildMenuTile(
                      icon: Icons.card_membership,
                      title: 'Plans et tarifs',
                      subtitle: 'Découvrir et changer d\'abonnement',
                      onTap: () => context.push('/subscription/plans'),
                    ),
                  ],
                ),
              ),

              // Section Documents
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuTile(
                      icon: Icons.folder_outlined,
                      title: 'Gérer mes documents',
                      subtitle: 'Permis, assurance, carte grise, etc.',
                      onTap: () => context.push('/livreur/documents'),
                    ),
                  ],
                ),
              ),

              // Section Paramètres
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuTile(
                      icon: Icons.rate_review,
                      title: 'Mes avis clients',
                      subtitle: 'Consulter vos avis et votre note',
                      onTap: () => context.push('/livreur/reviews'),
                    ),
                    _buildMenuTile(
                      icon: Icons.settings,
                      title: 'Paramètres utilisateur',
                      subtitle: 'Notifications, thème, langue',
                      onTap: () => context.push('/user-settings'),
                    ),
                    _buildMenuTile(
                      icon: Icons.lock_outline,
                      title: 'Mot de passe',
                      subtitle: 'Changer votre mot de passe',
                      onTap: () => context.push('/change-password'),
                    ),
                    _buildMenuTile(
                      icon: Icons.help,
                      title: 'Aide & Support',
                      subtitle: 'Besoin d\'aide ?',
                      onTap: () => context.push('/help'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bouton de déconnexion
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutDialog,
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

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            '$_totalDeliveries',
                            Icons.local_shipping,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Complétées',
                            '$_completedDeliveries',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Gains totaux',
                            '${_totalEarnings.toStringAsFixed(0)} FCFA',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Note moyenne',
                            _averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'N/A',
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Historique des livraisons',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              if (_deliveryHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune livraison pour le moment',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._deliveryHistory.map((delivery) => _buildDeliveryHistoryItem(delivery)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

