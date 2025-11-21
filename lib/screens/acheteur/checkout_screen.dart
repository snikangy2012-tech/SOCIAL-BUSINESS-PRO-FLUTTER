// ===== lib/screens/acheteur/checkout_screen.dart =====
// Processus de commande et paiement - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/config/payment_methods_config.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/mobile_money_service.dart';
import '../../services/counter_service.dart';
import '../../services/firebase_service.dart';
import '../../services/geolocation_service.dart';
import '../../services/stock_management_service.dart';
import '../../models/user_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _analytics = AnalyticsService();
  final _firestore = FirebaseFirestore.instance;

  // Contrôleurs
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _communeController = TextEditingController();
  final _notesController = TextEditingController();

  // État
  int _currentStep = 0;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _orderCompleted = false; // Empêche la redirection après commande réussie
  List<String> _availablePaymentMethods = []; // Méthodes disponibles selon les vendeurs
  bool _isLoadingPaymentMethods = false;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('Checkout');
    _loadUserInfo();
    _loadAvailablePaymentMethods();
  }

  // Charger les méthodes de paiement disponibles selon les vendeurs du panier
  Future<void> _loadAvailablePaymentMethods() async {
    setState(() => _isLoadingPaymentMethods = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final items = cartProvider.items;

      if (items.isEmpty) {
        setState(() {
          _availablePaymentMethods = [];
          _isLoadingPaymentMethods = false;
        });
        return;
      }

      // Récupérer les IDs des vendeurs uniques
      final vendeurIds = items.map((item) => item.vendeurId).toSet().toList();

      // Charger les préférences de paiement de chaque vendeur
      List<Map<String, bool>> vendorPaymentPreferences = [];

      for (final vendeurId in vendeurIds) {
        try {
          final vendorDoc = await FirebaseService.getDocument(
            collection: FirebaseCollections.users,
            docId: vendeurId,
          );

          if (vendorDoc != null && vendorDoc['profile'] != null) {
            final profile = vendorDoc['profile'] as Map<String, dynamic>;
            final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;

            if (vendeurProfile != null && vendeurProfile['paymentMethods'] != null) {
              final methods = vendeurProfile['paymentMethods'] as Map<String, dynamic>;
              vendorPaymentPreferences.add({
                'cash': methods['cash'] ?? true,
                'orange_money': methods['orange_money'] ?? false,
                'mtn_money': methods['mtn_money'] ?? false,
                'moov_money': methods['moov_money'] ?? false,
                'wave': methods['wave'] ?? false,
              });
            } else {
              // Si le vendeur n'a pas configuré, on assume qu'il accepte tout par défaut
              vendorPaymentPreferences.add({
                'cash': true,
                'orange_money': true,
                'mtn_money': true,
                'moov_money': true,
                'wave': true,
              });
            }
          }
        } catch (e) {
          debugPrint('⚠️ Erreur chargement préférences vendeur $vendeurId: $e');
          // En cas d'erreur, on assume que le vendeur accepte tout
          vendorPaymentPreferences.add({
            'cash': true,
            'orange_money': true,
            'mtn_money': true,
            'moov_money': true,
            'wave': true,
          });
        }
      }

      // Calculer l'intersection : une méthode est disponible si TOUS les vendeurs l'acceptent
      final allMethods = ['cash', 'orange_money', 'mtn_money', 'moov_money', 'wave'];
      final availableMethods = <String>[];

      for (final method in allMethods) {
        final allVendorsAcceptMethod = vendorPaymentPreferences.every(
          (prefs) => prefs[method] == true,
        );

        if (allVendorsAcceptMethod) {
          availableMethods.add(method);
        }
      }

      setState(() {
        _availablePaymentMethods = availableMethods;
        _isLoadingPaymentMethods = false;

        // Si la méthode sélectionnée n'est plus disponible, la réinitialiser
        if (_selectedPaymentMethod != null &&
            !_availablePaymentMethods.contains(_selectedPaymentMethod)) {
          _selectedPaymentMethod = null;
        }

        // Sélectionner automatiquement 'cash' s'il est disponible
        if (_selectedPaymentMethod == null && _availablePaymentMethods.contains('cash')) {
          _selectedPaymentMethod = 'cash';
        }
      });

      debugPrint('✅ Méthodes de paiement disponibles: $_availablePaymentMethods');

    } catch (e) {
      debugPrint('❌ Erreur chargement méthodes paiement: $e');
      setState(() {
        // En cas d'erreur, on affiche toutes les méthodes
        _availablePaymentMethods = ['cash', 'orange_money', 'mtn_money', 'moov_money', 'wave'];
        _isLoadingPaymentMethods = false;
      });
    }
  }

  // Charger les infos de l'utilisateur
  void _loadUserInfo() {
    final authProvider = context.read<auth.AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.phoneNumber ?? '';

      // Charger l'adresse par défaut si disponible
      final profile = user.profile;
      if (profile.isNotEmpty) {
        final acheteurProfile = profile['acheteurProfile'] as Map<String, dynamic>?;
        if (acheteurProfile != null) {
          final addresses = acheteurProfile['addresses'] as List<dynamic>? ?? [];
          if (addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
              orElse: () => addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
            );
            _addressController.text = defaultAddress['street'] ?? '';
            _communeController.text = defaultAddress['commune'] ?? '';
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _communeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Valider le formulaire
  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _selectedPaymentMethod != null;
      default:
        return true;
    }
  }

  // Passer à l'étape suivante
  void _nextStep() {
    if (_validateStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _confirmOrder();
      }
    } else {
      if (_currentStep == 1 && _selectedPaymentMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une méthode de paiement'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  // Revenir en arrière
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Confirmer la commande
  Future<void> _confirmOrder() async {
    if (_isProcessing) return;

    final authProvider = context.read<auth.AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour passer commande'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Récupérer l'adresse par défaut de l'utilisateur avec ses coordonnées GPS
      final profile = user.profile;
      Address? selectedAddress;

      if (profile.isNotEmpty) {
        final acheteurProfile = profile['acheteurProfile'] as Map<String, dynamic>?;
        if (acheteurProfile != null) {
          final addresses = acheteurProfile['addresses'] as List<dynamic>? ?? [];
          if (addresses.isNotEmpty) {
            final defaultAddressData = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
              orElse: () => addresses.isNotEmpty ? addresses.first : null,
            );
            if (defaultAddressData != null) {
              selectedAddress = Address.fromMap(defaultAddressData as Map<String, dynamic>);
            }
          }
        }
      }

      // Préparer l'adresse de livraison (format texte simple)
      final deliveryAddressText = '''
Nom: ${_nameController.text}
Téléphone: ${_phoneController.text}
Commune: ${_communeController.text}
Adresse: ${_addressController.text}
${_notesController.text.isNotEmpty ? 'Notes: ${_notesController.text}' : ''}
'''.trim();

      // Grouper les items par vendeur (une commande par vendeur)
      final itemsByVendor = <String, List<CartItem>>{};
      for (final item in cartProvider.items) {
        itemsByVendor.putIfAbsent(item.vendeurId, () => []).add(item);
      }

      final createdOrders = <String>[];
      final now = DateTime.now();

      // Créer une commande pour chaque vendeur
      for (final entry in itemsByVendor.entries) {
        final vendeurId = entry.key;
        final items = entry.value;

        // Calculer les montants
        final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
        const deliveryFee = 1500.0; // Frais fixe par vendeur
        final total = subtotal + deliveryFee;

        // Convertir CartItem en Map pour Firestore
        final orderItems = items.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'productImage': item.productImage,
          'quantity': item.quantity,
          'price': item.price,
        }).toList();

        // ✅ RÉSERVER LE STOCK AVANT DE CRÉER LA COMMANDE
        final productsQuantities = <String, int>{};
        for (final item in items) {
          productsQuantities[item.productId] = item.quantity;
        }

        final stockReserved = await StockManagementService.reserveStockBatch(
          productsQuantities: productsQuantities,
        );

        if (!stockReserved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Stock insuffisant pour un ou plusieurs produits'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        debugPrint('✅ Stock réservé pour ${items.length} produit(s)');

        // Générer un numéro de commande unique (pour le système)
        final orderNumber = 'ORD${now.millisecondsSinceEpoch}${vendeurId.substring(0, 4)}';

        // Obtenir le numéro d'affichage incrémental
        final displayNumber = await CounterService.getNextOrderNumber();

        // Récupérer les coordonnées du vendeur (shopLocation)
        double pickupLatitude = 5.3167; // Abidjan centre par défaut
        double pickupLongitude = -4.0333;

        try {
          final vendorDoc = await FirebaseService.getDocument(
            collection: FirebaseCollections.users,
            docId: vendeurId,
          );

          if (vendorDoc != null && vendorDoc['profile'] != null) {
            final vendorProfile = vendorDoc['profile'] as Map<String, dynamic>;
            final vendeurProfileData = vendorProfile['vendeurProfile'] as Map<String, dynamic>?;

            if (vendeurProfileData != null && vendeurProfileData['shopLocation'] != null) {
              final shopLocation = vendeurProfileData['shopLocation'] as Map<String, dynamic>;
              pickupLatitude = (shopLocation['latitude'] ?? pickupLatitude).toDouble();
              pickupLongitude = (shopLocation['longitude'] ?? pickupLongitude).toDouble();
              debugPrint('✅ Coordonnées vendeur trouvées: $pickupLatitude, $pickupLongitude');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Erreur récupération coordonnées vendeur, utilisation coordonnées par défaut: $e');
        }

        // Récupérer les coordonnées de livraison avec approche hybride
        double deliveryLatitude = 5.3467; // Abidjan par défaut (fallback final)
        double deliveryLongitude = -4.0083;

        if (selectedAddress != null && selectedAddress.coordinates != null) {
          // ✅ Priorité 1 : Adresse enregistrée avec coordonnées GPS
          deliveryLatitude = selectedAddress.coordinates!.latitude;
          deliveryLongitude = selectedAddress.coordinates!.longitude;
          debugPrint('✅ Coordonnées de livraison depuis adresse enregistrée: $deliveryLatitude, $deliveryLongitude');
        } else {
          // ⚠️ Priorité 2 : Position GPS actuelle de l'utilisateur (fallback automatique)
          debugPrint('⚠️ Aucune adresse enregistrée, tentative de géolocalisation automatique...');
          try {
            final position = await GeolocationService.getCurrentPosition();
            deliveryLatitude = position.latitude;
            deliveryLongitude = position.longitude;
            debugPrint('✅ Position actuelle utilisée pour livraison: $deliveryLatitude, $deliveryLongitude');
          } catch (e) {
            // ❌ Priorité 3 : Coordonnées par défaut (Abidjan centre)
            debugPrint('⚠️ Géolocalisation échouée ($e), utilisation coordonnées par défaut Abidjan');
          }
        }

        // Créer la commande dans Firestore
        final orderData = {
          'orderNumber': orderNumber,
          'displayNumber': displayNumber,
          'buyerId': user.id,
          'buyerName': user.displayName,
          'buyerPhone': user.phoneNumber ?? _phoneController.text,
          'vendeurId': vendeurId,
          'items': orderItems,
          'subtotal': subtotal,
          'deliveryFee': deliveryFee,
          'discount': 0.0,
          'totalAmount': total,
          'status': 'pending', // pending, confirmed, preparing, shipping, delivered, cancelled
          'deliveryAddress': deliveryAddressText,
          'paymentMethod': _selectedPaymentMethod,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': null,
          'deliveredAt': null,
          'cancellationReason': null,
          'cancelledAt': null,
          // Coordonnées GPS pour le système de livraison
          'pickupLatitude': pickupLatitude,
          'pickupLongitude': pickupLongitude,
          'deliveryLatitude': deliveryLatitude,
          'deliveryLongitude': deliveryLongitude,
        };

        // Enregistrer dans Firestore
        final docRef = await _firestore
            .collection(FirebaseCollections.orders)
            .add(orderData);

        createdOrders.add(docRef.id);

        debugPrint('✅ Commande créée: ${docRef.id} pour vendeur: $vendeurId');

        // Logger l'achat
        await _analytics.logPurchase(
          orderId: docRef.id,
          value: total,
          deliveryFee: deliveryFee,
          items: orderItems,
        );
      }

      // Vider le panier
      await cartProvider.clearCart();

      // Marquer la commande comme complétée pour éviter la redirection
      setState(() {
        _orderCompleted = true;
      });

      // Afficher un SnackBar de succès immédiat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    createdOrders.length == 1
                        ? 'Commande enregistrée avec succès !'
                        : '${createdOrders.length} commandes créées avec succès !',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Afficher confirmation dans un dialogue
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Commande confirmée !',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    createdOrders.length == 1
                        ? 'Votre commande a été enregistrée avec succès.'
                        : '${createdOrders.length} commandes ont été créées (une par vendeur).',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Vous recevrez une confirmation par notification.',
                    style: TextStyle(fontSize: AppFontSizes.sm),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _selectedPaymentMethod == 'cash'
                        ? 'Paiement à la livraison'
                        : 'Procédez au paiement Mobile Money',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: const Text('Accueil'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/acheteur/orders');
                },
                child: const Text('Mes commandes'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur création commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    // Rediriger si le panier est vide (sauf si une commande vient d'être complétée)
    if (cartProvider.items.isEmpty && !_isProcessing && !_orderCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/cart');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre panier est vide'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser ma commande'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Stepper
          _buildStepper(),

          // Contenu
          Expanded(
            child: _buildStepContent(cartProvider),
          ),

          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // Stepper
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Livraison'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Paiement'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Confirmation'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && step < _currentStep
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.xs,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  // Contenu de l'étape
  Widget _buildStepContent(CartProvider cartProvider) {
    switch (_currentStep) {
      case 0:
        return _buildDeliveryStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildConfirmationStep(cartProvider);
      default:
        return const SizedBox();
    }
  }

  // Étape 1: Livraison
  Widget _buildDeliveryStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Informations de livraison',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Form(
          key: _formKey,
          child: Column(
            children: [
              // Nom complet
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  hintText: 'Ex: Jean Kouassi',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  hintText: 'Ex: 0749705404',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre numéro';
                  }
                  if (value.length < 10) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Commune
              TextFormField(
                controller: _communeController,
                decoration: const InputDecoration(
                  labelText: 'Commune *',
                  hintText: 'Ex: Cocody, Yopougon, Abobo...',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre commune';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse détaillée *',
                  hintText: 'Ex: Angré 7e tranche, près de la pharmacie',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre adresse';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Notes (optionnel)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Instructions de livraison (optionnel)',
                  hintText: 'Ex: Appeler en arrivant, bâtiment B...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Étape 2: Paiement
  Widget _buildPaymentStep() {
    if (_isLoadingPaymentMethods) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des moyens de paiement...'),
          ],
        ),
      );
    }

    if (_availablePaymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text(
              'Aucun moyen de paiement disponible',
              style: TextStyle(fontSize: AppFontSizes.lg, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les vendeurs de votre panier n\'ont pas de méthode de paiement commune.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/cart'),
              child: const Text('Retour au panier'),
            ),
          ],
        ),
      );
    }

    final providers = MobileMoneyService.getAvailableProviders();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Moyens acceptés par tous les vendeurs de votre panier',
          style: TextStyle(
            fontSize: AppFontSizes.sm,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Paiement à la livraison (si disponible)
        if (_availablePaymentMethods.contains('cash'))
          Card(
            elevation: _selectedPaymentMethod == 'cash' ? 4 : 1,
            child: RadioListTile<String>(
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
              title: const Text(
                'Paiement à la livraison',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Payez en espèces au livreur'),
              secondary: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.money,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        if (_availablePaymentMethods.contains('cash'))
          const SizedBox(height: AppSpacing.md),

        // Divider avec texte (seulement si Mobile Money disponible)
        if (_availablePaymentMethods.any((method) => method != 'cash'))
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'OU',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

        if (_availablePaymentMethods.any((method) => method != 'cash'))
          const SizedBox(height: AppSpacing.md),

        // Options Mobile Money (filtrées selon les vendeurs)
        ...providers.where((provider) {
          // Afficher seulement si le provider est dans les méthodes disponibles
          return _availablePaymentMethods.contains(provider['id']);
        }).map((provider) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            elevation: _selectedPaymentMethod == provider['id'] ? 4 : 1,
            child: RadioListTile<String>(
              value: provider['id'] as String,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
              title: Text(
                provider['name'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(provider['description'] ?? ''),
              secondary: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: PaymentMethodsConfig.hasLogo(provider['id'] as String)
                      ? Colors.white
                      : Color(int.parse(provider['color'].replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: PaymentMethodsConfig.hasLogo(provider['id'] as String)
                      ? Border.all(color: AppColors.border, width: 1)
                      : null,
                ),
                child: PaymentMethodsConfig.hasLogo(provider['id'] as String)
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          PaymentMethodsConfig.getLogo(provider['id'] as String)!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.payment,
                              color: Colors.white,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.payment,
                        color: Colors.white,
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Étape 3: Confirmation
  Widget _buildConfirmationStep(CartProvider cartProvider) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text(
          'Récapitulatif de la commande',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Articles du panier
        _buildSummaryCard(
          'Articles (${cartProvider.itemCount})',
          cartProvider.items.map((item) =>
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.quantity}x ${item.productName}',
                      style: const TextStyle(fontSize: AppFontSizes.sm),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${item.total.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          Icons.shopping_cart,
        ),

        const SizedBox(height: AppSpacing.md),

        // Infos livraison
        _buildSummaryCard(
          'Livraison',
          [
            _buildSummaryItem('Nom', _nameController.text),
            _buildSummaryItem('Téléphone', _phoneController.text),
            _buildSummaryItem('Commune', _communeController.text),
            _buildSummaryItem('Adresse', _addressController.text),
            if (_notesController.text.isNotEmpty)
              _buildSummaryItem('Notes', _notesController.text),
          ],
          Icons.local_shipping,
        ),

        const SizedBox(height: AppSpacing.md),

        // Méthode de paiement
        _buildSummaryCard(
          'Paiement',
          [
            _buildSummaryItem(
              'Méthode',
              _getPaymentMethodName(),
            ),
          ],
          Icons.payment,
        ),

        const SizedBox(height: AppSpacing.md),

        // Montants
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Montants',
                      style: TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                _buildAmountRow('Sous-total', cartProvider.subtotal),
                const SizedBox(height: AppSpacing.sm),
                _buildAmountRow('Livraison', cartProvider.deliveryFee),
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${cartProvider.total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Info importante
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'En confirmant, vous acceptez nos conditions générales de vente. Vous recevrez une notification de confirmation.',
                  style: TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    List<Widget> items,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
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

  Widget _buildAmountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName() {
    if (_selectedPaymentMethod == null) return 'Non sélectionné';
    if (_selectedPaymentMethod == 'cash') return 'Paiement à la livraison';

    final providers = MobileMoneyService.getAvailableProviders();
    final provider = providers.firstWhere(
      (p) => p['id'] == _selectedPaymentMethod,
      orElse: () => <String, Object>{'name': 'Inconnu'},
    );
    return provider['name'] as String;
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton retour
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Retour'),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),

            // Bouton suivant/confirmer
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? 'Confirmer la commande' : 'Suivant',
                            style: const TextStyle(
                              fontSize: AppFontSizes.md,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                            size: 20,
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
}
