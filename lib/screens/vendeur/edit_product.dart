// ===== lib/screens/vendeur/edit_product.dart =====
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/product_service.dart';
import '../../services/audit_service.dart';
import '../../models/audit_log_model.dart';
import '../../config/product_categories.dart';
import '../../config/product_subcategories.dart';
import '../../widgets/system_ui_scaffold.dart';

class EditProduct extends StatefulWidget {
  final String productId;

  const EditProduct({
    super.key,
    required this.productId,
  });

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final _formKey = GlobalKey<FormState>();

  final ProductService _productService = ProductService();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _tagsController = TextEditingController();

  // État
  String _selectedCategory = 'electronique'; // ✅ ID par défaut
  String _selectedSubcategory = '';
  String _otherSubcategory = '';
  final _otherSubcategoryController = TextEditingController();
  List<String> _existingImages = [];
  List<File> _newImages = []; // Nouvelles images à uploader
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _tags = [];
  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
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

  // Charger les données du produit
  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    try {
      final product = await _productService.getProduct(widget.productId).timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );

      if (product == null) {
        debugPrint('⚠️ Produit non trouvé, utilisation de données mock');
        _loadMockData();
        return;
      }

      // Vérifier propriétaire
      final authProvider = context.read<AuthProvider>();
      if (product.vendeurId != authProvider.user?.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'êtes pas autorisé à modifier ce produit'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
        return;
      }

      // Pré-remplir le formulaire
      if (mounted) {
        setState(() {
          _nameController.text = product.name;
          _descriptionController.text = product.description;
          _priceController.text = product.price.toString();
          _originalPriceController.text = product.originalPrice?.toString() ?? '';
          _stockController.text = product.stock.toString();
          _brandController.text = product.brand ?? '';

          // ✅ CRITIQUE : Utiliser l'ID, pas le nom
          _selectedCategory = _getCategoryIdFromName(product.category);

          // Charger la sous-catégorie
          _selectedSubcategory = product.subCategory ?? '';

          // Si c'est une sous-catégorie personnalisée (pas dans la liste prédéfinie)
          final predefinedSubs = ProductSubcategories.getSubcategories(_selectedCategory);
          if (_selectedSubcategory.isNotEmpty && !predefinedSubs.contains(_selectedSubcategory)) {
            _otherSubcategoryController.text = _selectedSubcategory;
            _selectedSubcategory = 'Autre (à préciser)';
            _otherSubcategory = _otherSubcategoryController.text;
          }

          // Filtrer les images valides (URLs Firebase Storage uniquement)
          _existingImages = product.images.where((url) {
            return url.contains('firebasestorage.googleapis.com') ||
                (url.startsWith('http://') || url.startsWith('https://'));
          }).toList();

          if (_existingImages.length != product.images.length) {
            debugPrint(
                '⚠️ ${product.images.length - _existingImages.length} image(s) invalide(s) ignorée(s)');
          }

          _tags = List.from(product.tags);
          _tagsController.text = _tags.join(', ');
          _isActive = product.isActive;
        });

        debugPrint('✅ Produit chargé depuis Firestore');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');
      debugPrint('📦 Utilisation de données mock');

      if (mounted) {
        _loadMockData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Mode démo - Données factices'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ HELPER : Trouver l'ID de catégorie depuis le nom
  String _getCategoryIdFromName(String categoryName) {
    final category = ProductCategories.allCategories.firstWhere(
      (cat) => cat.name == categoryName || cat.id == categoryName,
      orElse: () => ProductCategories.allCategories.first,
    );
    return category.id;
  }

  // Charger données mock
  void _loadMockData() {
    setState(() {
      _nameController.text = 'iPhone 15 Pro';
      _descriptionController.text = 'Smartphone Apple avec puce A17 Pro';
      _priceController.text = '850000';
      _originalPriceController.text = '950000';
      _stockController.text = '10';
      _brandController.text = 'Apple';
      _selectedCategory = 'electronique'; // ✅ ID
      _existingImages = ['https://via.placeholder.com/300'];
      _tags = ['smartphone', 'apple', 'iphone'];
      _tagsController.text = _tags.join(', ');
      _isActive = true;
    });
  }

  // Sélectionner des images
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection des images'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Supprimer une image existante
  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  // Supprimer une nouvelle image
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  // Sauvegarder le produit
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Récupérer authProvider avant les appels async
      final authProvider = context.read<AuthProvider>();

      // Préparer les updates sans les images
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'originalPrice': _originalPriceController.text.trim().isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory, // ✅ ID
        'subCategory': _selectedSubcategory == 'Autre (à préciser)'
            ? _otherSubcategory.trim()
            : _selectedSubcategory,
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'tags': _tags,
        'isActive': _isActive,
      };

      // Utiliser la nouvelle fonction avec upload d'images
      debugPrint('📦 Modification produit: ${widget.productId}');
      debugPrint('   - Images existantes: ${_existingImages.length}');
      debugPrint('   - Nouvelles images: ${_newImages.length}');

      await _productService
          .updateProductWithImages(
            productId: widget.productId,
            updates: updates,
            existingImageUrls: _existingImages,
            newImages: _newImages.isNotEmpty ? _newImages : null,
          )
          .timeout(
            const Duration(seconds: 30), // Timeout plus long pour l'upload
          );

      // Logger la modification du produit
      if (authProvider.user != null) {
        await AuditService.log(
          userId: authProvider.user!.id,
          userType: authProvider.user!.userType.value,
          userEmail: authProvider.user!.email,
          userName: authProvider.user!.displayName,
          action: 'product_updated',
          actionLabel: 'Modification de produit',
          category: AuditCategory.userAction,
          severity: AuditSeverity.low,
          description: 'Modification du produit "${_nameController.text.trim()}"',
          targetType: 'product',
          targetId: widget.productId,
          targetLabel: _nameController.text.trim(),
          metadata: {
            'productId': widget.productId,
            'productName': _nameController.text.trim(),
            'category': _selectedCategory,
            'subCategory': _selectedSubcategory == 'Autre (à préciser)'
                ? _otherSubcategory.trim()
                : _selectedSubcategory,
            'price': double.parse(_priceController.text),
            'stock': int.parse(_stockController.text),
            'isActive': _isActive,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Produit modifié avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde: $e');

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Mode démo - Modifications simulées'),
            backgroundColor: AppColors.warning,
          ),
        );
        context.pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Modifier le produit'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Modifier le produit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Catégorie - ✅ DROPDOWN CORRIGÉ
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ProductCategories.allCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id, // ✅ Utiliser l'ID
                    child: Text('${category.icon} ${category.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'electronique';
                    _selectedSubcategory = ''; // Reset sous-catégorie
                    _otherSubcategory = '';
                    _otherSubcategoryController.clear();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La catégorie est requise';
                  }
                  return null;
                },
              ),

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
                  items:
                      ProductSubcategories.getSubcategories(_selectedCategory).map((subcategory) {
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une sous-catégorie';
                    }
                    return null;
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
                    hintText: 'Ex: T-shirts pour homme...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  maxLength: 50,
                  onChanged: (value) {
                    setState(() {
                      _otherSubcategory = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedSubcategory == 'Autre (à préciser)') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez préciser la sous-catégorie';
                      }
                      if (value.trim().length < 3) {
                        return 'Au moins 3 caractères requis';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Section Images
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Images du produit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Images existantes
                    if (_existingImages.isNotEmpty) ...[
                      const Text('Images actuelles:',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_existingImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Nouvelles images
                    if (_newImages.isNotEmpty) ...[
                      const Text('Nouvelles images:',
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_newImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeNewImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    if (_existingImages.isEmpty && _newImages.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Aucune image. Cliquez sur "Ajouter" pour en sélectionner.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prix
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prix est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le stock est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marque (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),

              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (séparés par des virgules)',
                  hintText: 'smartphone, apple, promo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
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

              // Prévisualisation tags
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                          _tagsController.text = _tags.join(', ');
                        });
                      },
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Switch actif/inactif
              SwitchListTile(
                title: const Text('Produit actif'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                activeThumbColor: AppColors.success,
              ),

              const SizedBox(height: 24),

              // Bouton Sauvegarder
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),

              // Espace pour éviter que le bouton soit caché par la barre de navigation
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
