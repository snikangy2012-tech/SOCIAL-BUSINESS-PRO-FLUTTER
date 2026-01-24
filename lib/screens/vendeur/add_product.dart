// ===== lib/screens/vendeur/add_product.dart =====
// Formulaire d'ajout de produits - SOCIAL BUSINESS Pro - Version moderne

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../providers/vendeur_navigation_provider.dart';
import '../../services/product_service.dart';
import '../../services/audit_service.dart';
import '../../services/commission_enforcement_service.dart';
import '../../services/category_service.dart';
import '../../models/audit_log_model.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../config/product_categories.dart';
import '../../config/product_subcategories.dart';
import '../../widgets/system_ui_scaffold.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _imagePicker = ImagePicker();

  // Controllers pour tous les champs
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _tagsController = TextEditingController();
  final _otherSubcategoryController = TextEditingController();

  // État du formulaire
  int _currentStep = 0;
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _otherSubcategory = '';
  List<File> _selectedImages = [];
  List<String> _allowedCategories = [];
  List<CategoryModel> _availableCategories = [];
  bool _isLoadingCategories = true;
  List<String> _tags = [];
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllowedCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _tagsController.dispose();
    _otherSubcategoryController.dispose();
    super.dispose();
  }

  // Charger les catégories autorisées pour ce vendeur
  Future<void> _loadAllowedCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null && user.profile.containsKey('vendeurProfile')) {
        final vendeurProfileData = user.profile['vendeurProfile'] as Map<String, dynamic>?;

        if (vendeurProfileData != null) {
          final vendeurProfile = VendeurProfile.fromMap(vendeurProfileData);
          _allowedCategories = vendeurProfile.businessCategories;
        }
      }

      // Charger les catégories de produits depuis Firestore
      try {
        final categories = await CategoryService.getActiveCategories();
        setState(() {
          _availableCategories = categories;
        });
      } catch (e) {
        debugPrint('⚠️ Erreur Firestore, fallback vers catégories statiques: $e');

        final fallbackCategories = ProductCategories.allCategories.map((pc) {
          return CategoryModel(
            id: pc.id,
            name: pc.name,
            iconCodePoint: IconHelper.iconToCodePoint(pc.icon),
            iconFontFamily: IconHelper.getIconFontFamily(pc.icon),
            subCategories: pc.subCategories ?? [],
            isActive: true,
            displayOrder: 0,
            createdAt: DateTime.now(),
          );
        }).toList();

        setState(() {
          _availableCategories = fallbackCategories;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des catégories: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorId = authProvider.user?.id ?? '';

    return FutureBuilder<bool>(
      future: CommissionEnforcementService.isVendorBlocked(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return SystemUIScaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/vendeur-dashboard'),
              ),
              title: const Text('Accès bloqué'),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 64, color: AppColors.error),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Compte bloqué',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Votre compte est temporairement bloqué pour non-paiement de commissions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildAddProductScreen();
      },
    );
  }

  Widget _buildAddProductScreen() {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/vendeur-dashboard');
              }
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Ajouter un produit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Précédent', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1BasicInfo(),
                _buildStep2Images(),
                _buildStep3PriceStock(),
                _buildStep4Review(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const stepTitles = ['Infos', 'Photos', 'Prix', 'Révision'];
    const stepIcons = [
      Icons.info_outline,
      Icons.photo_camera,
      Icons.payments,
      Icons.check_circle_outline
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression globale
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // Étapes avec titres
          Row(
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              final isFuture = index > _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    // Icône animée
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 56 : 48,
                      height: isActive ? 56 : 48,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.white, size: 28)
                            : Icon(
                                stepIcons[index],
                                color: isActive
                                    ? AppColors.primary
                                    : isFuture
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.white,
                                size: isActive ? 28 : 24,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Titre de l'étape
                    Text(
                      stepTitles[index],
                      style: TextStyle(
                        color: isActive || isCompleted
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: isActive ? 13 : 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ÉTAPE 1 : Informations de base
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête moderne avec carte
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations de base',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Décrivez votre produit en détail',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nom du produit
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du produit *',
              hintText: 'Ex: Robe en wax africain...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez votre produit en détail...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: 16),

          // Catégorie
          if (_isLoadingCategories) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_availableCategories
              .where((category) =>
                  _allowedCategories.isEmpty || _allowedCategories.contains(category.name))
              .isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Aucune catégorie configurée',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Veuillez configurer vos catégories dans les paramètres de votre boutique.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/vendeur/my-shop'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurer ma boutique'),
                  ),
                ],
              ),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _availableCategories
                  .where((category) =>
                      _allowedCategories.isEmpty || _allowedCategories.contains(category.name))
                  .map((category) {
                return DropdownMenuItem<String>(
                  value: category.id, // ✅ Utiliser l'ID comme edit_product
                  child: Row(
                    children: [
                      Icon(
                        category.icon, // Utilise le getter icon de CategoryModel
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                  _selectedSubcategory = '';
                  _otherSubcategory = '';
                  _otherSubcategoryController.clear();
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          // Sous-catégorie
          if (_selectedCategory.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: _selectedSubcategory.isEmpty ? null : _selectedSubcategory,
              decoration: const InputDecoration(
                labelText: 'Sous-catégorie *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.list),
              ),
              items: ProductSubcategories.getSubcategories(
                // ✅ Utiliser directement l'ID de la catégorie sélectionnée
                _selectedCategory.isNotEmpty ? _selectedCategory : '',
              ).map((subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubcategory = value ?? '';
                  if (_selectedSubcategory != 'Autre (à préciser)') {
                    _otherSubcategory = '';
                    _otherSubcategoryController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Champ "Autre sous-catégorie"
          if (_selectedSubcategory == 'Autre (à préciser)') ...[
            TextFormField(
              controller: _otherSubcategoryController,
              decoration: const InputDecoration(
                labelText: 'Précisez la sous-catégorie *',
                hintText: 'Ex: Vêtements enfants',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) =>
                  _otherSubcategory = value, // ✅ RETIRÉ setState pour éviter le rafraîchissement
            ),
            const SizedBox(height: 16),
          ],

          // Marque (optionnel)
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(
              labelText: 'Marque (optionnel)',
              hintText: 'Ex: Nike, Adidas...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.branding_watermark),
            ),
          ),
        ],
      ),
    );
  }

  // ÉTAPE 2 : Images
  Widget _buildStep2Images() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images du produit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez jusqu\'à ${AppLimits.maxProductImages} images pour présenter votre produit',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Grille d'images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length +
                (_selectedImages.length < AppLimits.maxProductImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(_selectedImages[index], index);
            },
          ),

          const SizedBox(height: 24),

          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (séparés par des virgules)',
              hintText: 'Ex: mode, femme, casual, été',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
              helperText: 'Ajoutez des mots-clés pour faciliter la recherche',
            ),
            onChanged: (value) {
              setState(() {
                _tags = value
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
              });
            },
          ),

          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tags sélectionnés:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppColors.primary),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                            _tagsController.text = _tags.join(', ');
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 40, color: AppColors.primary),
            SizedBox(height: 8),
            Text('Ajouter',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(File image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: FileImage(image), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() => _selectedImages.removeAt(index));
              },
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ÉTAPE 3 : Prix et stock
  Widget _buildStep3PriceStock() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prix et stock',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Prix de vente
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix de vente *',
              hintText: '10000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              suffixText: 'FCFA',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Prix original (optionnel)
          TextFormField(
            controller: _originalPriceController,
            decoration: const InputDecoration(
              labelText: 'Prix original (optionnel)',
              hintText: '15000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.money_off),
              suffixText: 'FCFA',
              helperText: 'Pour afficher une réduction',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Stock
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Quantité en stock *',
              hintText: '50',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
              suffixText: 'unités',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),

          // Statut du produit
          SwitchListTile(
            title: const Text('Produit actif'),
            subtitle: const Text('Le produit sera visible dans votre boutique'),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ÉTAPE 4 : Révision
  Widget _buildStep4Review() {
    double discountPercentage = 0;
    if (_originalPriceController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
      final currentPrice = double.tryParse(_priceController.text) ?? 0;
      if (originalPrice > 0) {
        discountPercentage = ((originalPrice - currentPrice) / originalPrice) * 100;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Révision finale',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez toutes les informations avant de publier',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Aperçu du produit
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImages.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImages.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCategory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedCategory,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _descriptionController.text,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${_priceController.text} FCFA',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_originalPriceController.text.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${_originalPriceController.text} FCFA',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${_stockController.text} unités',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(fontSize: 11),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Bouton Retour (si pas sur première étape)
            if (_currentStep > 0) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.textPrimary,
                  iconSize: 24,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Bouton Annuler (si sur première étape)
            if (_currentStep == 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.border, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Bouton principal (Suivant/Publier)
            Expanded(
              flex: _currentStep == 0 ? 2 : 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : (_currentStep < 3 ? _nextStep : _submitProduct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_currentStep == 3 ? Icons.publish : Icons.arrow_forward),
                  label: Text(
                    _currentStep == 3 ? 'Publier le produit' : 'Étape suivante',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    // ✅ CORRECTION: Valider l'étape ACTUELLE avant de passer à la suivante
    debugPrint('🔄 _nextStep called, current step: $_currentStep');

    if (_currentStep == 0 && !_validateStep1()) {
      debugPrint('❌ Step 1 validation failed');
      return;
    }
    if (_currentStep == 1 && !_validateStep2()) {
      debugPrint('❌ Step 2 validation failed');
      return;
    }
    if (_currentStep == 2 && !_validateStep3()) {
      debugPrint('❌ Step 3 validation failed');
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        debugPrint('✅ Moving to step: $_currentStep');
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        debugPrint('◀️ Going back to step: $_currentStep');
      });
    }
  }

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Veuillez saisir le nom du produit');
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Veuillez saisir une description');
      return false;
    }

    if (_selectedCategory.isEmpty) {
      _showError('Veuillez sélectionner une catégorie');
      return false;
    }

    if (_selectedSubcategory.isEmpty) {
      _showError('Veuillez sélectionner une sous-catégorie');
      return false;
    }

    if (_selectedSubcategory == 'Autre (à préciser)' && _otherSubcategory.trim().isEmpty) {
      _showError('Veuillez préciser la sous-catégorie');
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    if (_selectedImages.isEmpty) {
      _showError('Ajoutez au moins une image de votre produit');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final price = int.tryParse(_priceController.text);
    final stock = int.tryParse(_stockController.text);

    if (price == null || price <= 0) {
      _showError('Veuillez saisir un prix valide');
      return false;
    }

    if (stock == null || stock <= 0) {
      _showError('Veuillez saisir une quantité en stock valide');
      return false;
    }

    if (_originalPriceController.text.isNotEmpty) {
      final originalPrice = int.tryParse(_originalPriceController.text);
      if (originalPrice != null && originalPrice <= price) {
        _showError('Le prix original doit être supérieur au prix de vente');
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submitProduct() async {
    if (!_validateStep1() || !_validateStep2() || !_validateStep3()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final productData = CreateProductData(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        stock: int.parse(_stockController.text),
        category: _selectedCategory,
        subCategory: _selectedSubcategory == 'Autre (à préciser)'
            ? _otherSubcategory.trim()
            : _selectedSubcategory,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        tags: _tags,
        images: _selectedImages,
        isActive: _isActive,
        vendeurId: authProvider.user!.id,
        vendeurName: authProvider.user!.displayName,
      );

      final productService = ProductService();
      final productId = await productService.createProduct(productData);

      await AuditService.log(
        userId: authProvider.user!.id,
        userType: authProvider.user!.userType.name,
        userEmail: authProvider.user!.email,
        userName: authProvider.user!.displayName,
        action: 'product_created',
        actionLabel: 'Création de produit',
        category: AuditCategory.userAction,
        severity: AuditSeverity.low,
        description: 'Création du produit "${_nameController.text.trim()}"',
        targetType: 'product',
        targetId: productId,
        targetLabel: _nameController.text.trim(),
        metadata: {
          'productId': productId,
          'productName': _nameController.text.trim(),
          'category': _selectedCategory,
          'subCategory': _selectedSubcategory == 'Autre (à préciser)'
              ? _otherSubcategory.trim()
              : _selectedSubcategory,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Produit ajouté avec succès !'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      final navProvider = context.read<VendeurNavigationProvider>();
      navProvider.setIndex(1);
      context.go('/vendeur/products');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
