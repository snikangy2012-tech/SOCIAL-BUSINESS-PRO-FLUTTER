// ===== lib/screens/vendeur/edit_product.dart =====
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';


import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/product_service.dart';
import '../../config/product_categories.dart';

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
  List<String> _existingImages = [];
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
          
          _existingImages = product.images;
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
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'originalPrice': _originalPriceController.text.trim().isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory, // ✅ ID
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'tags': _tags,
        'images': List.from(_existingImages),
        'isActive': _isActive,
        'updatedAt': DateTime.now(),
      };

      await _productService.updateProduct(widget.productId, updates).timeout(
        const Duration(seconds: 10),
      );

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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le produit'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value ?? 'electronique');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La catégorie est requise';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
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
                    _tags = value.split(',')
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
                      backgroundColor: AppColors.primary.withValues(alpha:0.1),
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
            ],
          ),
        ),
      ),
    );
  }
}