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
import '../../services/stock_management_service.dart';
import '../../services/audit_service.dart';
import '../../services/vendor_location_service.dart';
import '../../services/notification_service.dart';
import '../../services/geolocation_service.dart';
import '../../services/qr_code_service.dart';
import '../../models/user_model.dart';
import '../../models/audit_log_model.dart';
import '../../utils/number_formatter.dart';
import 'address_picker_screen.dart';
import '../../widgets/system_ui_scaffold.dart';

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
  List<Address> _savedAddresses = []; // Adresses enregistrées
  Address? _selectedAddress; // Adresse sélectionnée
  String _deliveryMethod = 'home_delivery'; // 'home_delivery' ou 'store_pickup'

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

      // Charger toutes les adresses enregistrées
      final profile = user.profile;
      if (profile.isNotEmpty && profile['addresses'] != null) {
        final addresses = profile['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          // Convertir en objets Address
          _savedAddresses =
              addresses.map((addr) => Address.fromMap(addr as Map<String, dynamic>)).toList();

          debugPrint('✅ Loaded ${_savedAddresses.length} addresses from user profile');

          // Sélectionner l'adresse par défaut
          final defaultIndex = _savedAddresses.indexWhere((addr) => addr.isDefault);
          if (defaultIndex != -1) {
            _selectedAddress = _savedAddresses[defaultIndex];
            _fillAddressFields(_selectedAddress!);
            debugPrint('✅ Selected default address: ${_selectedAddress!.label}');
          } else if (_savedAddresses.isNotEmpty) {
            _selectedAddress = _savedAddresses.first;
            _fillAddressFields(_selectedAddress!);
            debugPrint('✅ Selected first address: ${_selectedAddress!.label}');
          }
        }
      }
    }
  }

  // Remplir les champs avec une adresse
  void _fillAddressFields(Address address) {
    setState(() {
      _addressController.text = address.street;
      _communeController.text = address.commune;
    });
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
        // Pour la livraison à domicile, vérifier le formulaire ET l'adresse
        if (_deliveryMethod == 'home_delivery') {
          final formValid = _formKey.currentState?.validate() ?? false;
          if (!formValid) return false;

          // Vérifier qu'une adresse avec GPS est sélectionnée
          if (_selectedAddress == null || _selectedAddress!.coordinates == null) {
            return false;
          }
        }
        // Pour le retrait en boutique, pas de validation spéciale
        return true;
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
        // À l'étape 3, afficher d'abord la confirmation des frais de livraison
        _showDeliveryFeeConfirmation();
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

  // Afficher la confirmation des frais de livraison
  Future<void> _showDeliveryFeeConfirmation() async {
    final cartProvider = context.read<CartProvider>();

    // Pour le Click & Collect, pas de calcul de frais
    if (_deliveryMethod == 'store_pickup') {
      await _confirmOrder();
      return;
    }

    // Calculer les frais de livraison pour chaque vendeur
    try {
      final itemsByVendor = <String, List<CartItem>>{};
      for (final item in cartProvider.items) {
        itemsByVendor.putIfAbsent(item.vendeurId, () => []).add(item);
      }

      double totalDeliveryFee = 0.0;
      final vendorFees = <String, double>{};

      // Calculer les frais pour chaque vendeur
      for (final entry in itemsByVendor.entries) {
        final vendeurId = entry.key;

        // Récupérer les coordonnées GPS de la boutique
        final pickupCoords = await VendorLocationService.getVendorPickupCoordinates(vendeurId);
        final pickupLatitude = pickupCoords?['latitude'] ?? 5.316667;
        final pickupLongitude = pickupCoords?['longitude'] ?? -4.033333;

        // Coordonnées de livraison
        final deliveryLatitude = _selectedAddress!.coordinates!.latitude;
        final deliveryLongitude = _selectedAddress!.coordinates!.longitude;

        // Calculer la distance
        final distance = GeolocationService.calculateDistance(
          pickupLatitude,
          pickupLongitude,
          deliveryLatitude,
          deliveryLongitude,
        );

        // Calculer les frais
        final fee = _calculateDeliveryFee(distance);
        vendorFees[vendeurId] = fee;
        totalDeliveryFee += fee;

        debugPrint(
            '📍 Vendeur $vendeurId: Distance ${distance.toStringAsFixed(2)} km = ${fee.toStringAsFixed(0)} FCFA');
      }

      // Afficher le dialog de confirmation
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirmation des frais',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adresse de livraison
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAddress!.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedAddress!.street}, ${_selectedAddress!.commune}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Frais de livraison
                  const Text(
                    'Frais de livraison calculés:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Afficher les frais par vendeur si plusieurs vendeurs
                  if (vendorFees.length > 1)
                    ...vendorFees.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vendeur ${vendorFees.keys.toList().indexOf(entry.key) + 1}:',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              formatPriceWithCurrency(entry.value, currency: 'FCFA'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Total des frais
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total livraison:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatPriceWithCurrency(totalDeliveryFee, currency: 'FCFA'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Question
                  Text(
                    'Voulez-vous confirmer votre commande ou changer d\'adresse?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Bouton Changer d'adresse
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                icon: const Icon(Icons.edit_location, size: 18),
                label: const Text('Changer d\'adresse'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),

              // Bouton Confirmer
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Confirmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );

        // Si l'utilisateur a confirmé, créer la commande
        if (confirmed == true) {
          await _confirmOrder();
        } else {
          // Retour à l'étape 1 pour changer l'adresse
          setState(() => _currentStep = 0);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💡 Sélectionnez une autre adresse pour recalculer les frais'),
                backgroundColor: AppColors.info,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur calcul frais de livraison: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du calcul des frais: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
      // Utiliser l'adresse sélectionnée par l'utilisateur
      // (_selectedAddress a été définie lors du chargement ou de la sélection dans address_picker)
      debugPrint('📍 Using selected address: ${_selectedAddress?.label ?? "NONE"}');
      debugPrint('   GPS coordinates: ${_selectedAddress?.coordinates != null ? "YES" : "NO"}');

      // Préparer l'adresse de livraison (format texte - seulement localisation)
      final deliveryAddressText = '''
Commune: ${_communeController.text}
Adresse: ${_addressController.text}
'''
          .trim();

      // Grouper les items par vendeur (une commande par vendeur)
      final itemsByVendor = <String, List<CartItem>>{};
      for (final item in cartProvider.items) {
        itemsByVendor.putIfAbsent(item.vendeurId, () => []).add(item);
      }

      final createdOrders = <String>[];
      final now = DateTime.now();

      // 📦 Tracker les réservations de stock pour libération en cas d'erreur
      final allReservedStock = <String, int>{}; // productId -> quantity

      // Créer une commande pour chaque vendeur
      for (final entry in itemsByVendor.entries) {
        final vendeurId = entry.key;
        final items = entry.value;

        // Calculer le sous-total des articles
        final subtotal = items.fold(0.0, (sum, item) => sum + item.total);

        // Convertir CartItem en Map pour Firestore
        final orderItems = items
            .map((item) => {
                  'productId': item.productId,
                  'productName': item.productName,
                  'productImage': item.productImage,
                  'quantity': item.quantity,
                  'price': item.price,
                })
            .toList();

        // ✅ RÉSERVER LE STOCK AVANT DE CRÉER LA COMMANDE
        final productsQuantities = <String, int>{};
        for (final item in items) {
          productsQuantities[item.productId] = item.quantity;
        }

        final stockReserved = await StockManagementService.reserveStockBatch(
          productsQuantities: productsQuantities,
        );

        if (!stockReserved) {
          // ⚠️ Libérer tout le stock déjà réservé pour les commandes précédentes
          if (allReservedStock.isNotEmpty) {
            debugPrint('⚠️ Libération du stock déjà réservé pour les autres vendeurs...');
            await StockManagementService.releaseStockBatch(
              productsQuantities: allReservedStock,
            );
          }

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

        // ✅ Ajouter ces réservations au tracker global
        allReservedStock.addAll(productsQuantities);

        debugPrint('✅ Stock réservé pour ${items.length} produit(s)');

        // Obtenir le numéro d'affichage incrémental PAR VENDEUR
        // ✅ Chaque vendeur a ses propres numéros : 1, 2, 3...
        final displayNumber = await CounterService.getNextOrderNumber(vendeurId: vendeurId);

        // Générer un numéro de commande unique (pour le système/logs)
        final orderNumber = 'ORD${now.millisecondsSinceEpoch}${vendeurId.substring(0, 4)}';

        // Récupérer les coordonnées GPS de la boutique du vendeur (pickup)
        // Utilise le système hybride avec fallback sur Abidjan
        final pickupCoords = await VendorLocationService.getVendorPickupCoordinates(vendeurId);
        final pickupLatitude = pickupCoords?['latitude'] ?? 5.316667;
        final pickupLongitude = pickupCoords?['longitude'] ?? -4.033333;

        // ✅ RÉCUPÉRER LES INFORMATIONS DU VENDEUR pour la livraison
        String? vendeurName;
        String? vendeurShopName;
        String? vendeurPhone;
        String? vendeurLocation;

        try {
          final vendeurDoc = await _firestore
              .collection(FirebaseCollections.users)
              .doc(vendeurId)
              .get();

          if (vendeurDoc.exists) {
            final vendeurData = vendeurDoc.data();
            vendeurName = vendeurData?['displayName'];

            // Récupérer les infos de la boutique depuis le profil vendeur
            // Structure: profile.vendeurProfile.businessName (comme dans shop_setup_screen)
            final profile = vendeurData?['profile'] as Map<String, dynamic>?;
            if (profile != null) {
              // ✅ Chercher dans vendeurProfile (structure correcte)
              final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;
              if (vendeurProfile != null) {
                vendeurShopName = vendeurProfile['businessName'];
                vendeurPhone = vendeurProfile['businessPhone'];
                vendeurLocation = vendeurProfile['businessAddress'];
                debugPrint('📦 Infos trouvées dans vendeurProfile: shop=$vendeurShopName, phone=$vendeurPhone');
              }

              // Fallback sur profile direct si vendeurProfile vide
              vendeurShopName ??= profile['businessName'] ?? profile['shopName'];
              vendeurPhone ??= profile['businessPhone'] ?? profile['phone'];
              vendeurLocation ??= profile['businessAddress'] ?? profile['address'];
            }

            // Fallback sur les champs de premier niveau si profil vide
            vendeurShopName ??= vendeurData?['shopName'] ?? vendeurData?['businessName'] ?? vendeurName;
            vendeurPhone ??= vendeurData?['phoneNumber'] ?? vendeurData?['phone'];
          }
          debugPrint('✅ Infos vendeur récupérées - Boutique: $vendeurShopName, Tél: $vendeurPhone, Adresse: $vendeurLocation');
        } catch (e) {
          debugPrint('⚠️ Erreur récupération infos vendeur: $e');
        }

        // Variables pour les coordonnées et frais
        double deliveryLatitude;
        double deliveryLongitude;
        double deliveryFee;
        String? pickupQRCode;

        // ✅ CLICK & COLLECT: Pas besoin d'adresse de livraison
        if (_deliveryMethod == 'store_pickup') {
          // Pour le retrait en boutique, utiliser les coordonnées de la boutique
          deliveryLatitude = pickupLatitude;
          deliveryLongitude = pickupLongitude;
          deliveryFee = 0.0; // Gratuit pour le retrait en boutique

          // Générer le QR code pour le retrait
          pickupQRCode = QRCodeService.generatePickupQRCode(
            orderId: 'TEMP_${now.millisecondsSinceEpoch}', // Sera mis à jour après création
            buyerId: user.id,
          );

          debugPrint('🏪 Click & Collect: Frais de livraison = 0 FCFA');
          debugPrint('📱 QR Code généré pour le retrait');
        } else {
          // ✅ LIVRAISON À DOMICILE: Validation GPS OBLIGATOIRE
          if (_selectedAddress == null || _selectedAddress!.coordinates == null) {
            // ⚠️ LIBÉRER LE STOCK RÉSERVÉ car la validation a échoué
            debugPrint('⚠️ Validation GPS échouée, libération du stock réservé...');
            await StockManagementService.releaseStockBatch(
              productsQuantities: productsQuantities,
            );

            setState(() => _isProcessing = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '❌ Veuillez sélectionner une adresse avec coordonnées GPS.\n'
                    'Utilisez une adresse enregistrée ou ajoutez-en une nouvelle via votre profil.',
                  ),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            debugPrint('❌ Commande bloquée: Aucune adresse avec coordonnées GPS sélectionnée');
            return;
          }

          // Récupérer les coordonnées de livraison depuis l'adresse sélectionnée
          deliveryLatitude = _selectedAddress!.coordinates!.latitude;
          deliveryLongitude = _selectedAddress!.coordinates!.longitude;
          debugPrint(
              '✅ Coordonnées de livraison depuis adresse enregistrée: $deliveryLatitude, $deliveryLongitude');

          // ✅ CALCULER LA DISTANCE GPS entre la boutique et l'adresse de livraison
          final distance = GeolocationService.calculateDistance(
            pickupLatitude,
            pickupLongitude,
            deliveryLatitude,
            deliveryLongitude,
          );
          debugPrint('📏 Distance calculée: ${distance.toStringAsFixed(2)} km');

          // ✅ CALCULER LES FRAIS DE LIVRAISON selon la distance réelle
          deliveryFee = _calculateDeliveryFee(distance);
          debugPrint('💰 Frais de livraison: ${deliveryFee.toStringAsFixed(0)} FCFA');
        }

        // Calculer le montant total
        final total = subtotal + deliveryFee;
        debugPrint(
            '💵 Total commande: ${total.toStringAsFixed(0)} FCFA (Sous-total: ${subtotal.toStringAsFixed(0)} + Livraison: ${deliveryFee.toStringAsFixed(0)})');

        // Créer la commande dans Firestore
        final orderData = {
          'orderNumber': orderNumber,
          'displayNumber': displayNumber,
          'buyerId': user.id,
          'buyerName': user.displayName,
          'buyerPhone': user.phoneNumber ?? _phoneController.text,
          'vendeurId': vendeurId,
          // ✅ INFORMATIONS VENDEUR pour le livreur
          'vendeurName': vendeurName,
          'vendeurShopName': vendeurShopName,
          'vendeurPhone': vendeurPhone,
          'vendeurLocation': vendeurLocation,
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
          // ✅ Click & Collect fields
          'deliveryMethod': _deliveryMethod, // 'home_delivery' ou 'store_pickup'
          'pickupQRCode': pickupQRCode, // Code QR pour retrait en boutique (null si livraison)
          'pickupReadyAt': null, // Sera défini quand le vendeur marque "prêt"
          'pickedUpAt': null, // Sera défini quand le client récupère
        };

        // Enregistrer dans Firestore
        final docRef = await _firestore.collection(FirebaseCollections.orders).add(orderData);

        createdOrders.add(docRef.id);

        debugPrint('✅ Commande créée: ${docRef.id} pour vendeur: $vendeurId');

        // ✅ CLICK & COLLECT: Mettre à jour le QR code avec l'ID réel de la commande
        if (_deliveryMethod == 'store_pickup') {
          final finalQRCode = QRCodeService.generatePickupQRCode(
            orderId: docRef.id,
            buyerId: user.id,
          );
          await docRef.update({'pickupQRCode': finalQRCode});
          debugPrint('✅ QR Code mis à jour avec orderId: ${docRef.id}');

          // 📱 ENVOYER NOTIFICATION À L'ACHETEUR avec le QR code
          try {
            await NotificationService().createNotification(
              userId: user.id,
              type: 'pickup_qr_ready',
              title: '📱 Votre QR Code de retrait est prêt',
              body: 'Commande #$displayNumber - Présentez ce code au vendeur lors du retrait',
              data: {
                'orderId': docRef.id,
                'orderNumber': orderNumber,
                'displayNumber': displayNumber,
                'qrCode': finalQRCode,
                'route': '/acheteur/pickup-qr/${docRef.id}',
                'action': 'view_qr_code',
              },
            );
            debugPrint('✅ Notification QR code envoyée à l\'acheteur');
          } catch (e) {
            debugPrint('❌ Erreur envoi notification QR: $e');
            // L'erreur n'empêche pas la commande d'être créée
          }
        }

        // Logger l'achat dans Analytics
        await _analytics.logPurchase(
          orderId: docRef.id,
          value: total,
          deliveryFee: deliveryFee,
          items: orderItems,
        );

        // Logger la création de commande dans l'Audit
        await AuditService.log(
          userId: user.id,
          userType: user.userType.value,
          userEmail: user.email,
          userName: user.displayName,
          action: 'order_created',
          actionLabel: 'Création de commande',
          category: AuditCategory.userAction,
          severity: AuditSeverity.low,
          description: 'Création de commande #$displayNumber',
          targetType: 'order',
          targetId: docRef.id,
          targetLabel: 'Commande #$displayNumber',
          metadata: {
            'orderId': docRef.id,
            'orderNumber': orderNumber,
            'displayNumber': displayNumber,
            'vendeurId': vendeurId,
            'totalAmount': total,
            'subtotal': subtotal,
            'deliveryFee': deliveryFee,
            'itemCount': items.length,
            'paymentMethod': _selectedPaymentMethod,
          },
        );

        // 🔔 ENVOYER NOTIFICATION AU VENDEUR
        try {
          await NotificationService().createNotification(
            userId: vendeurId,
            type: 'new_order',
            title: 'Nouvelle commande !',
            body:
                'Commande #$displayNumber - ${formatPriceWithCurrency(total, currency: 'FCFA')} - ${items.length} article(s)',
            data: {
              'orderId': docRef.id,
              'orderNumber': orderNumber,
              'displayNumber': displayNumber,
              'totalAmount': total,
              'itemCount': items.length,
              'route': '/vendeur/order-detail/${docRef.id}',
            },
          );
          debugPrint('✅ Notification envoyée au vendeur $vendeurId');
        } catch (e) {
          debugPrint('❌ Erreur envoi notification: $e');
          // L'erreur n'empêche pas la commande d'être créée
        }

        // ℹ️ NOTE: L'assignation automatique du livreur se fera quand le vendeur
        // marquera la commande comme "ready" (après confirmation et préparation).
        // Voir order_detail_screen.dart ligne 108-123
        debugPrint('📋 Commande créée en statut "pending" - En attente de confirmation vendeur');
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
                  context.go('/acheteur-home');
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

      // ⚠️ LIBÉRER TOUT LE STOCK RÉSERVÉ en cas d'erreur
      try {
        // Récupérer tous les produits du panier
        final allProductsQuantities = <String, int>{};
        for (final item in cartProvider.items) {
          allProductsQuantities[item.productId] = item.quantity;
        }

        if (allProductsQuantities.isNotEmpty) {
          debugPrint('⚠️ Erreur détectée, libération de tout le stock réservé...');
          await StockManagementService.releaseStockBatch(
            productsQuantities: allProductsQuantities,
          );
          debugPrint('✅ Stock libéré suite à l\'erreur');
        }
      } catch (releaseError) {
        debugPrint('❌ Erreur lors de la libération du stock: $releaseError');
      }

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

  /// Calculer les frais de livraison basés sur la distance GPS
  /// Utilise la même logique que delivery_service.dart
  double _calculateDeliveryFee(double distance) {
    // Tarifs par distance (paliers identiques à DeliveryService)
    if (distance <= 10) return 1000; // 1000 FCFA pour 0-10km
    if (distance <= 20) return 1500; // 1500 FCFA pour 10-20km
    if (distance <= 30) return 2000; // 2000 FCFA pour 20-30km
    return 2000 + ((distance - 30) * 100); // 2000 FCFA + 100 FCFA/km au-delà de 30km
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    // Rediriger si le panier est vide (sauf si une commande vient d'être complétée)
    if (cartProvider.items.isEmpty && !_isProcessing && !_orderCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/acheteur/cart');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre panier est vide'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      });
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
        title: const Text('Finaliser ma commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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

        // ✅ CHOIX DU MODE DE LIVRAISON
        const Text(
          'Mode de livraison',
          style: TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Option 1: Livraison à domicile
        Card(
          elevation: _deliveryMethod == 'home_delivery' ? 4 : 1,
          child: RadioListTile<String>(
            value: 'home_delivery',
            groupValue: _deliveryMethod,
            onChanged: (value) {
              setState(() => _deliveryMethod = value!);
            },
            title: const Text(
              'Livraison à domicile',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Un livreur vous apporte votre commande'),
            secondary: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Option 2: Retrait en boutique (Click & Collect)
        Card(
          elevation: _deliveryMethod == 'store_pickup' ? 4 : 1,
          child: RadioListTile<String>(
            value: 'store_pickup',
            groupValue: _deliveryMethod,
            onChanged: (value) {
              setState(() => _deliveryMethod = value!);
            },
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Retrait en boutique',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'GRATUIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text('Récupérez votre commande chez le vendeur'),
            secondary: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.success,
                size: 28,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Afficher la sélection d'adresse seulement si livraison à domicile
        if (_deliveryMethod == 'home_delivery') ...[
          const Text(
            'Adresse de livraison',
            style: TextStyle(
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bouton de sélection d'adresse moderne
          Card(
            elevation: 2,
            child: InkWell(
              onTap: _openAddressPicker,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAddress != null
                                    ? (_selectedAddress!.label.isNotEmpty
                                        ? _selectedAddress!.label
                                        : 'Adresse sélectionnée')
                                    : 'Sélectionner une adresse',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.md,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress != null
                                    ? '${_selectedAddress!.street}, ${_selectedAddress!.commune}'
                                    : 'Choisissez parmi vos adresses ou utilisez la carte',
                                style: TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    if (_selectedAddress?.coordinates != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GPS validé',
                            style: TextStyle(
                              fontSize: AppFontSizes.sm,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
        ], // Fin du if (_deliveryMethod == 'home_delivery')

        // Informations communes (affichées pour les deux modes)
        if (_deliveryMethod == 'store_pickup') ...[
          const SizedBox(height: AppSpacing.md),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retrait en boutique',
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vous recevrez un code QR par notification. '
                        'Présentez-le au vendeur lors du retrait de votre commande.',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Ouvrir le sélecteur d'adresse moderne
  Future<void> _openAddressPicker() async {
    debugPrint('🔍 Opening address picker with ${_savedAddresses.length} saved addresses');
    for (var addr in _savedAddresses) {
      debugPrint('  - ${addr.label}: ${addr.street}, ${addr.commune}');
    }

    final result = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPickerScreen(
          savedAddresses: _savedAddresses,
          currentAddress: _selectedAddress,
        ),
      ),
    );

    if (result != null) {
      debugPrint('✅ Address selected: ${result.label} with GPS: ${result.coordinates != null}');
      setState(() {
        _selectedAddress = result;
      });
      _fillAddressFields(result);
    }
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
              onPressed: () => context.go('/acheteur/cart'),
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

        if (_availablePaymentMethods.contains('cash')) const SizedBox(height: AppSpacing.md),

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
          cartProvider.items
              .map(
                (item) => Padding(
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
                      Flexible(
                        child: Text(
                          formatPriceWithCurrency(item.total, currency: 'FCFA'),
                          style: const TextStyle(
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          Icons.shopping_cart,
        ),

        const SizedBox(height: AppSpacing.md),

        // Infos livraison
        _buildSummaryCard(
          _deliveryMethod == 'store_pickup' ? 'Retrait' : 'Livraison',
          [
            _buildSummaryItem(
              'Mode',
              _deliveryMethod == 'store_pickup'
                  ? '🏪 Retrait en boutique (GRATUIT)'
                  : '🚚 Livraison à domicile',
            ),
            if (_deliveryMethod == 'home_delivery') ...[
              _buildSummaryItem('Nom', _nameController.text),
              _buildSummaryItem('Téléphone', _phoneController.text),
              _buildSummaryItem('Commune', _communeController.text),
              _buildSummaryItem('Adresse', _addressController.text),
              if (_notesController.text.isNotEmpty)
                _buildSummaryItem('Notes', _notesController.text),
            ],
          ],
          _deliveryMethod == 'store_pickup' ? Icons.store : Icons.local_shipping,
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
                    Flexible(
                      child: Text(
                        formatPriceWithCurrency(cartProvider.total, currency: 'FCFA'),
                        style: const TextStyle(
                          fontSize: AppFontSizes.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        Flexible(
          child: Text(
            formatPriceWithCurrency(amount, currency: 'FCFA'),
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _currentStep == 2 ? 'Confirmer' : 'Suivant',
                              style: const TextStyle(
                                fontSize: AppFontSizes.md,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
