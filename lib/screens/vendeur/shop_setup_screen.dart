// ===== lib/screens/vendeur/shop_setup_screen.dart =====
// Configuration de la boutique vendeur - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../models/user_model.dart';
import '../../services/geolocation_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  // Contrôleurs de formulaire
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();

  // Valeurs du formulaire
  String _businessType = 'individual';
  String _businessCategory = 'Alimentation';
  List<String> _selectedZones = [];
  bool _acceptsCashOnDelivery = true;
  bool _acceptsOnlinePayment = false;

  // Coordonnées GPS de la boutique
  LocationCoords? _shopLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = false;
  bool _hasClickedMap = false; // Pour masquer le message après premier clic

  // Données existantes
  VendeurProfile? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _freeDeliveryThresholdController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Charger le profil existant s'il existe
  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Charger le profil depuis Firestore
      final userDoc =
          await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final profileData = userData['profile'] as Map<String, dynamic>?;

        if (profileData != null) {
          final vendeurProfileData = profileData['vendeurProfile'] as Map<String, dynamic>?;

          if (vendeurProfileData != null) {
            _existingProfile = VendeurProfile.fromMap(vendeurProfileData);

            // Pré-remplir le formulaire
            _businessNameController.text = _existingProfile!.businessName;
            _businessDescriptionController.text = _existingProfile!.businessDescription ?? '';
            _businessAddressController.text = _existingProfile!.businessAddress ?? '';
            _businessPhoneController.text = _existingProfile!.businessPhone ?? '';
            _businessType = _existingProfile!.businessType;

            // ✅ Valider que la catégorie existe dans le dropdown
            final validCategories = [
              'Alimentation',
              'Mode & Vêtements',
              'Électronique',
              'Maison & Décoration',
              'Beauté & Cosmétiques',
              'Services',
              'Autre',
            ];
            _businessCategory = validCategories.contains(_existingProfile!.businessCategory)
                ? _existingProfile!.businessCategory
                : 'Alimentation'; // Valeur par défaut si invalide
            _selectedZones = List.from(_existingProfile!.deliveryZones);
            _freeDeliveryThresholdController.text =
                _existingProfile!.freeDeliveryThreshold?.toString() ?? '';
            _acceptsCashOnDelivery = _existingProfile!.acceptsCashOnDelivery;
            _acceptsOnlinePayment = _existingProfile!.acceptsOnlinePayment;

            // Charger la position GPS de la boutique si elle existe
            // Priorité 1: businessLatitude/businessLongitude (nouveau système)
            // Priorité 2: shopLocation (ancien système pour compatibilité)
            if (_existingProfile!.businessLatitude != null &&
                _existingProfile!.businessLongitude != null) {
              _shopLocation = LocationCoords(
                latitude: _existingProfile!.businessLatitude!,
                longitude: _existingProfile!.businessLongitude!,
              );
              debugPrint('✅ GPS chargé depuis businessLatitude/businessLongitude');
            } else if (vendeurProfileData['shopLocation'] != null) {
              final shopLocationData = vendeurProfileData['shopLocation'] as Map<String, dynamic>;
              _shopLocation = LocationCoords(
                latitude: (shopLocationData['latitude'] ?? 0).toDouble(),
                longitude: (shopLocationData['longitude'] ?? 0).toDouble(),
              );
              debugPrint('✅ GPS chargé depuis shopLocation (ancien système)');
            }

            debugPrint('✅ Profil existant chargé avec GPS: ${_shopLocation != null}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement profil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Obtenir la position actuelle du vendeur
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      debugPrint('📍 Récupération position actuelle vendeur...');
      final position = await GeolocationService.getCurrentPosition();

      setState(() {
        _shopLocation = LocationCoords(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _isLoadingLocation = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      debugPrint('✅ Position boutique définie: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Position actuelle utilisée pour la boutique'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération position: $e');
      setState(() => _isLoadingLocation = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Impossible de récupérer votre position'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Sauvegarder le profil
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedZones.isEmpty) {
      _showError('Veuillez sélectionner au moins une zone de livraison');
      return;
    }

    if (_shopLocation == null) {
      _showError('Veuillez définir la position GPS de votre boutique');
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer le profil vendeur
      final profile = VendeurProfile(
        businessName: _businessNameController.text.trim(),
        businessType: _businessType,
        businessDescription: _businessDescriptionController.text.trim().isEmpty
            ? null
            : _businessDescriptionController.text.trim(),
        businessPhone: _businessPhoneController.text.trim().isEmpty
            ? null
            : _businessPhoneController.text.trim(),
        businessCategory: _businessCategory,
        businessAddress: _businessAddressController.text.trim().isEmpty
            ? null
            : _businessAddressController.text.trim(),
        deliveryZones: _selectedZones,
        // Prix par défaut: 1000 FCFA (minimum du delivery_service)
        // Le service calculera automatiquement selon la distance
        deliveryPrice: 1000.0,
        freeDeliveryThreshold: _freeDeliveryThresholdController.text.isEmpty
            ? null
            : double.parse(_freeDeliveryThresholdController.text),
        acceptsCashOnDelivery: _acceptsCashOnDelivery,
        acceptsOnlinePayment: _acceptsOnlinePayment,
        // ✅ Coordonnées GPS de la boutique (pour le système hybride de pickup)
        businessLatitude: _shopLocation!.latitude,
        businessLongitude: _shopLocation!.longitude,
        // Utiliser les valeurs existantes ou créer des valeurs par défaut
        paymentInfo: _existingProfile?.paymentInfo ?? PaymentInfo(),
        stats: _existingProfile?.stats ?? BusinessStats(),
        deliverySettings: _existingProfile?.deliverySettings ?? DeliverySettings(),
      );

      // Créer la map du profil et ajouter shopLocation
      final profileMap = profile.toMap();
      profileMap['shopLocation'] = {
        'latitude': _shopLocation!.latitude,
        'longitude': _shopLocation!.longitude,
      };

      // Mettre à jour Firestore avec le profil vendeur complet (avec shopLocation)
      await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(user.id).update({
        'profile.vendeurProfile': profileMap,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ Profil boutique sauvegardé avec GPS: ${_shopLocation!.latitude}, ${_shopLocation!.longitude}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Boutique configurée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );

        // Redirection vers le dashboard vendeur
        // Utiliser context.go() au lieu de context.pop() car la route shop-setup
        // est souvent une redirection initiale (pas un push)
        context.go('/vendeur-dashboard');
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde profil: $e');
      _showError('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Avancer d'une étape
  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Reculer d'une étape
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Configuration Boutique'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: Text(_existingProfile != null ? 'Modifier ma Boutique' : 'Créer ma Boutique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicateur d'étapes
            _buildStepIndicator(),

            // Contenu des étapes
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2GPS(),
                  _buildStep3Details(),
                  _buildStep4Delivery(),
                  _buildStep5Payment(),
                ],
              ),
            ),

            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // Indicateur d'étapes
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundSecondary,
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive ? AppColors.primary : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? AppColors.primary : Colors.grey[600],
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < 4)
                  Container(
                    height: 2,
                    width: 12,
                    color: isCompleted ? AppColors.primary : Colors.grey[300],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Infos';
      case 1:
        return 'GPS';
      case 2:
        return 'Détails';
      case 3:
        return 'Livraison';
      case 4:
        return 'Paiement';
      default:
        return '';
    }
  }

  // Étape 1: Informations de base
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de base',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par les informations essentielles de votre boutique',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Nom commercial
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Nom commercial *',
              hintText: 'Ex: Boutique Kouassi',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom commercial est requis';
              }
              if (value.trim().length < 3) {
                return 'Le nom doit contenir au moins 3 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Téléphone de la boutique
          TextFormField(
            controller: _businessPhoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone de la boutique',
              hintText: 'Ex: 07 XX XX XX XX',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                // Vérifier format ivoirien (commence par 0, 10 chiffres)
                final cleaned = value.replaceAll(RegExp(r'\s+'), '');
                if (cleaned.length != 10 || !cleaned.startsWith('0')) {
                  return 'Format invalide (10 chiffres commençant par 0)';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Type d'entreprise
          const Text(
            'Type d\'entreprise *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Individuel'),
                  subtitle: const Text('Entreprise individuelle'),
                  value: 'individual',
                  groupValue: _businessType,
                  onChanged: (value) {
                    setState(() => _businessType = value!);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Société'),
                  subtitle: const Text('Entreprise enregistrée'),
                  value: 'company',
                  groupValue: _businessType,
                  onChanged: (value) {
                    setState(() => _businessType = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Catégorie
          DropdownButtonFormField<String>(
            value: _businessCategory,
            decoration: const InputDecoration(
              labelText: 'Catégorie d\'activité *',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Alimentation',
                child: Text('Alimentation'),
              ),
              DropdownMenuItem(
                value: 'Mode & Vêtements',
                child: Text('Mode & Vêtements'),
              ),
              DropdownMenuItem(
                value: 'Électronique',
                child: Text('Électronique'),
              ),
              DropdownMenuItem(
                value: 'Maison & Décoration',
                child: Text('Maison & Décoration'),
              ),
              DropdownMenuItem(
                value: 'Beauté & Cosmétiques',
                child: Text('Beauté & Cosmétiques'),
              ),
              DropdownMenuItem(
                value: 'Services',
                child: Text('Services'),
              ),
              DropdownMenuItem(
                value: 'Autre',
                child: Text('Autre'),
              ),
            ],
            onChanged: (value) {
              setState(() => _businessCategory = value!);
            },
          ),
        ],
      ),
    );
  }

  // Étape 2: Position GPS
  Widget _buildStep2GPS() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.backgroundSecondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Position GPS de la boutique',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Définissez l\'emplacement exact de votre boutique pour le calcul des frais de livraison',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLoadingLocation
                      ? 'Récupération en cours...'
                      : 'Utiliser ma position actuelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_shopLocation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Position enregistrée',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: AppColors.success)),
                            Text(
                              'Lat: ${_shopLocation!.latitude.toStringAsFixed(6)}, Lng: ${_shopLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _shopLocation == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Aucune position définie',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Cliquez sur "Utiliser ma position actuelle" pour définir l\'emplacement de votre boutique',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_shopLocation!.latitude, _shopLocation!.longitude),
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (LatLng position) {
                        setState(() {
                          _shopLocation = LocationCoords(
                              latitude: position.latitude, longitude: position.longitude);
                          _hasClickedMap = true; // Masquer le message après premier clic
                        });
                        debugPrint(
                            '📍 Nouvelle position: ${position.latitude}, ${position.longitude}');
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('shop_location'),
                          position: LatLng(_shopLocation!.latitude, _shopLocation!.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          infoWindow: const InfoWindow(
                              title: 'Ma Boutique', snippet: 'Position de votre boutique'),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    // Message d'instruction - affiché uniquement si pas encore cliqué
                    if (!_hasClickedMap)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text('Cliquez sur la carte pour changer la position',
                                        style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // Étape 3: Détails
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de la boutique',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez plus d\'informations sur votre activité',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Description
          TextFormField(
            controller: _businessDescriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              hintText: 'Décrivez votre boutique et ce que vous proposez...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Adresse
          TextFormField(
            controller: _businessAddressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Adresse commerciale (optionnel)',
              hintText: 'Rue, quartier, ville...',
              prefixIcon: Icon(Icons.location_on),
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // Étape 4: Livraison
  Widget _buildStep4Delivery() {
    final availableZones = [
      'Abidjan - Cocody',
      'Abidjan - Bingerville',
      'Abidjan - Yopougon',
      'Abidjan - Abobo',
      'Abidjan - Adjamé',
      'Abidjan - Plateau',
      'Abidjan - Marcory',
      'Abidjan - Treichville',
      'Abidjan - Koumassi',
      'Abidjan - Port-Bouët',
      'Abidjan - Anyama',
      'Abidjan - Attécoubé',
      'Grand-Bassam',
      'Jacqueville',
      'Agboville',
      'Bouaké',
      'Daloa',
      'San-Pedro',
      'Yamoussoukro',
      'Autre', // Option pour zones non listées - calcul auto basé sur distance
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Options de livraison',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Définissez vos zones et tarifs de livraison',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Zones de livraison
          const Text(
            'Zones de livraison *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: availableZones.map((zone) {
                final isSelected = _selectedZones.contains(zone);
                return CheckboxListTile(
                  title: Text(zone),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedZones.add(zone);
                      } else {
                        _selectedZones.remove(zone);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Infobulle explicative sur les frais de livraison
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info),
            ),
            child: Row(
              children: const [
                Icon(Icons.info, color: AppColors.info, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les frais de livraison seront calculés automatiquement selon la distance entre votre boutique et le lieu de livraison (à partir de 1000 FCFA)',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Seuil livraison gratuite
          TextFormField(
            controller: _freeDeliveryThresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Livraison gratuite à partir de (FCFA)',
              hintText: 'Ex: 10000 (optionnel)',
              prefixIcon: Icon(Icons.local_shipping),
              border: OutlineInputBorder(),
              helperText: 'Offrez la livraison gratuite au-delà d\'un certain montant',
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final threshold = double.tryParse(value);
                if (threshold == null || threshold < 0) {
                  return 'Montant invalide';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Étape 5: Paiement
  Widget _buildStep5Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modes de paiement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez les modes de paiement que vous acceptez',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Paiement à la livraison
          SwitchListTile(
            title: const Text('Paiement à la livraison'),
            subtitle: const Text('Cash ou Mobile Money à la réception'),
            secondary: const Icon(Icons.payments, color: AppColors.primary),
            value: _acceptsCashOnDelivery,
            onChanged: (value) {
              setState(() => _acceptsCashOnDelivery = value);
            },
          ),
          const Divider(),

          // Paiement en ligne
          SwitchListTile(
            title: const Text('Paiement en ligne'),
            subtitle: const Text('Carte bancaire, Mobile Money en ligne'),
            secondary: const Icon(Icons.credit_card, color: AppColors.success),
            value: _acceptsOnlinePayment,
            onChanged: (value) {
              setState(() => _acceptsOnlinePayment = value);
            },
          ),

          if (!_acceptsCashOnDelivery && !_acceptsOnlinePayment)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous devez accepter au moins un mode de paiement',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Récapitulatif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Nom', _businessNameController.text),
                _buildSummaryRow('Type', _businessType == 'individual' ? 'Individuel' : 'Société'),
                _buildSummaryRow('Catégorie', _businessCategory),
                _buildSummaryRow(
                    'Position GPS',
                    _shopLocation != null
                        ? '${_shopLocation!.latitude.toStringAsFixed(4)}, ${_shopLocation!.longitude.toStringAsFixed(4)}'
                        : '❌ Non définie'),
                _buildSummaryRow('Zones', '${_selectedZones.length} zone(s)'),
                _buildSummaryRow('Prix livraison', 'Calcul automatique selon distance'),
                if (_shopLocation == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Position GPS non définie - Retournez à l\'étape 2',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!_acceptsCashOnDelivery && !_acceptsOnlinePayment)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Aucun mode de paiement sélectionné',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _previousStep,
                  child: const Text('Précédent'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : (_currentStep < 4 ? _nextStep : _saveProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_currentStep < 4 ? 'Suivant' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
