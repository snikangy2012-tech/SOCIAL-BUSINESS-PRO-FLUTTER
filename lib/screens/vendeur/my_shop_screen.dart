// ===== lib/screens/vendeur/my_shop_screen.dart =====
// Écran pour visualiser et gérer sa propre boutique (vendeur)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../models/user_model.dart';
import '../../utils/number_formatter.dart';
import '../widgets/system_ui_scaffold.dart';

class MyShopScreen extends StatefulWidget {
  const MyShopScreen({super.key});

  @override
  State<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends State<MyShopScreen> {
  bool _isLoading = true;
  VendeurProfile? _vendeurProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Si la boutique n'est pas encore configurée, rediriger vers shop-setup
      final vendeurProfileData = user.profile['vendeurProfile'] as Map<String, dynamic>?;
      if (vendeurProfileData == null) {
        if (mounted) {
          context.go('/vendeur/shop-setup');
        }
        return;
      }

      setState(() {
        _vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
        _isLoading = false;
      });

      debugPrint('✅ Données boutique chargées');
    } catch (e) {
      debugPrint('❌ Erreur chargement boutique: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateShopImage() async {
    try {
      // Afficher choix entre caméra et galerie
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Sélectionner l'image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      // Afficher indicateur de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Upload de l\'image en cours...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      try {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.user;
        if (user == null) throw Exception('Utilisateur non connecté');

        // Upload vers Firebase Storage
        final fileName = 'shops/${user.id}/shop_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final imageFile = File(image.path);

        await storageRef.putFile(imageFile);
        final imageUrl = await storageRef.getDownloadURL();

        debugPrint('✅ Image uploadée: $imageUrl');

        // Mettre à jour Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'profile.vendeurProfile.shopImageUrl': imageUrl,
        });

        debugPrint('✅ Firestore mis à jour');

        // Recharger les données
        await _loadShopData();

        // Fermer le dialogue de chargement
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image de boutique mise à jour avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur upload image: $e');

        // Fermer le dialogue de chargement
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'upload: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Ma Boutique'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Ma Boutique'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erreur: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadShopData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_vendeurProfile == null) {
      return SystemUIScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Ma Boutique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/vendeur/shop-setup'),
            tooltip: 'Modifier les informations',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadShopData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Image de la boutique
              _buildShopImage(),

              // Informations générales
              _buildSection(
                title: 'Informations générales',
                children: [
                  _buildInfoTile(
                    icon: Icons.store,
                    label: 'Nom de la boutique',
                    value: _vendeurProfile!.businessName,
                  ),
                  _buildInfoTile(
                    icon: Icons.category,
                    label: 'Catégorie',
                    value: _vendeurProfile!.businessCategory,
                  ),
                  _buildInfoTile(
                    icon: Icons.business,
                    label: 'Type d\'entreprise',
                    value: _vendeurProfile!.businessType == 'individual'
                        ? 'Individuel'
                        : 'Entreprise',
                  ),
                  if (_vendeurProfile!.businessDescription != null)
                    _buildInfoTile(
                      icon: Icons.description,
                      label: 'Description',
                      value: _vendeurProfile!.businessDescription!,
                    ),
                ],
              ),

              // Localisation
              _buildSection(
                title: 'Localisation',
                children: [
                  if (_vendeurProfile!.businessAddress != null)
                    _buildInfoTile(
                      icon: Icons.location_on,
                      label: 'Adresse',
                      value: _vendeurProfile!.businessAddress!,
                    ),
                  if (_vendeurProfile!.businessLatitude != null &&
                      _vendeurProfile!.businessLongitude != null)
                    _buildInfoTile(
                      icon: Icons.gps_fixed,
                      label: 'Coordonnées GPS',
                      value:
                          '${_vendeurProfile!.businessLatitude!.toStringAsFixed(6)}, ${_vendeurProfile!.businessLongitude!.toStringAsFixed(6)}',
                    ),
                  _buildInfoTile(
                    icon: Icons.delivery_dining,
                    label: 'Zones de livraison',
                    value: _vendeurProfile!.deliveryZones.isEmpty
                        ? 'Aucune zone définie'
                        : _vendeurProfile!.deliveryZones.join(', '),
                  ),
                ],
              ),

              // Livraison et paiement
              _buildSection(
                title: 'Livraison & Paiement',
                children: [
                  _buildInfoTile(
                    icon: Icons.local_shipping,
                    label: 'Frais de livraison',
                    value: formatPriceWithCurrency(_vendeurProfile!.deliveryPrice),
                  ),
                  if (_vendeurProfile!.freeDeliveryThreshold != null)
                    _buildInfoTile(
                      icon: Icons.card_giftcard,
                      label: 'Livraison gratuite à partir de',
                      value: formatPriceWithCurrency(
                          _vendeurProfile!.freeDeliveryThreshold!),
                    ),
                  _buildInfoTile(
                    icon: Icons.payment,
                    label: 'Modes de paiement',
                    value: [
                      if (_vendeurProfile!.acceptsCashOnDelivery)
                        'Paiement à la livraison',
                      if (_vendeurProfile!.acceptsOnlinePayment)
                        'Paiement en ligne',
                    ].join(', '),
                  ),
                ],
              ),

              // Réseaux sociaux
              if (_vendeurProfile!.whatsappNumber != null ||
                  _vendeurProfile!.facebookPage != null ||
                  _vendeurProfile!.instagramHandle != null ||
                  _vendeurProfile!.tiktokHandle != null)
                _buildSection(
                  title: 'Réseaux sociaux',
                  children: [
                    if (_vendeurProfile!.whatsappNumber != null)
                      _buildInfoTile(
                        icon: Icons.phone,
                        label: 'WhatsApp',
                        value: _vendeurProfile!.whatsappNumber!,
                      ),
                    if (_vendeurProfile!.facebookPage != null)
                      _buildInfoTile(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        value: _vendeurProfile!.facebookPage!,
                      ),
                    if (_vendeurProfile!.instagramHandle != null)
                      _buildInfoTile(
                        icon: Icons.camera_alt,
                        label: 'Instagram',
                        value: '@${_vendeurProfile!.instagramHandle!}',
                      ),
                    if (_vendeurProfile!.tiktokHandle != null)
                      _buildInfoTile(
                        icon: Icons.music_note,
                        label: 'TikTok',
                        value: '@${_vendeurProfile!.tiktokHandle!}',
                      ),
                  ],
                ),

              // Statistiques
              _buildStatsSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            image: _vendeurProfile!.shopImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(_vendeurProfile!.shopImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _vendeurProfile!.shopImageUrl == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune image de boutique',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _updateShopImage,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.shopping_bag,
                  label: 'Ventes',
                  value: _vendeurProfile!.stats.totalOrders.toString(),
                ),
                _buildStatItem(
                  icon: Icons.star,
                  label: 'Note moyenne',
                  value: _vendeurProfile!.stats.averageRating.toStringAsFixed(1),
                ),
                _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'Revenus',
                  value: formatPriceWithCurrency(_vendeurProfile!.stats.totalRevenue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
