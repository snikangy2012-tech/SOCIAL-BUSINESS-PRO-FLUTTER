// ===== lib/screens/vendeur/add_product.dart =====
// Formulaire d'ajout de produits - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/product_service.dart';
import '../../config/product_categories.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  
  // Controllers pour tous les champs
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _tagsController = TextEditingController();

  // État du formulaire
  int _currentStep = 0;
  String _selectedCategory = '';
  // ignore: prefer_final_fields
  List<File> _selectedImages = [];
  List<String> _tags = [];
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _tagsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text(
                'Précédent',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu de l'étape
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(), // Informations de base
                _buildStep2(), // Images et détails
                _buildStep3(), // Prix et stock
                _buildStep4(), // Révision finale
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // Indicateur de progression
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? AppColors.success
                        : isActive 
                            ? AppColors.primary 
                            : AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      color: index < _currentStep ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Étape 1 : Informations de base
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de base',
              style: TextStyle(
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom du produit est requis';
                }
                if (value.trim().length < 3) {
                  return 'Le nom doit contenir au moins 3 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Catégorie
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ProductCategories.allCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une catégorie';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Décrivez votre produit en détail...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                if (value.trim().length < 10) {
                  return 'La description doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Marque (optionnel)
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marque (optionnel)',
                hintText: 'Ex: Nike, Adidas...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
              ),
              maxLength: 50,
            ),
          ],
        ),
      ),
    );
  }

  // Étape 2 : Images et détails
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images du produit',
            style: TextStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          const Text(
            'Ajoutez jusqu\'à ${AppLimits.maxProductImages} images pour présenter votre produit',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppFontSizes.sm,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Grille d'images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Bouton d'ajout
                return _buildAddImageButton();
              }
              return _buildImageItem(_selectedImages[index], index);
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
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
                _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
              });
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Aperçu des tags
          if (_tags.isNotEmpty) ...[
            const Text(
              'Tags sélectionnés:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: AppColors.primary.withValues(alpha:0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                    _tagsController.text = _tags.join(', ');
                  });
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Étape 3 : Prix et stock
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prix et inventaire',
            style: TextStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Prix de vente
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix de vente (FCFA) *',
              hintText: '0',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              suffixText: 'FCFA',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le prix est requis';
              }
              final price = int.tryParse(value);
              if (price == null || price <= 0) {
                return 'Veuillez saisir un prix valide';
              }
              if (price < AppLimits.minProductPrice) {
                return 'Prix minimum: ${AppLimits.minProductPrice} FCFA';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Prix original (pour les promotions)
          TextFormField(
            controller: _originalPriceController,
            decoration: const InputDecoration(
              labelText: 'Prix original (optionnel)',
              hintText: 'Laissez vide si pas de promotion',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_offer),
              suffixText: 'FCFA',
              helperText: 'Prix barré pour montrer la remise',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final originalPrice = int.tryParse(value);
                final currentPrice = int.tryParse(_priceController.text);
                if (originalPrice == null || originalPrice <= 0) {
                  return 'Prix original invalide';
                }
                if (currentPrice != null && originalPrice <= currentPrice) {
                  return 'Le prix original doit être supérieur au prix de vente';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Quantité en stock
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Quantité en stock *',
              hintText: '0',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
              helperText: 'Nombre d\'unités disponibles',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La quantité en stock est requise';
              }
              final stock = int.tryParse(value);
              if (stock == null || stock < 0) {
                return 'Veuillez saisir une quantité valide';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Options du produit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Options du produit',
                    style: TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Produit actif
                  SwitchListTile(
                    title: const Text('Produit actif'),
                    subtitle: const Text('Le produit sera visible dans votre boutique'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Étape 4 : Révision finale
  Widget _buildStep4() {
    // Calculer le pourcentage de remise si applicable
    double discountPercentage = 0;
    if (_originalPriceController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
      final currentPrice = double.tryParse(_priceController.text) ?? 0;
      if (originalPrice > currentPrice && currentPrice > 0) {
        discountPercentage = ((originalPrice - currentPrice) / originalPrice) * 100;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Révision du produit',
            style: TextStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Aperçu du produit
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Images
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  
                  // Informations produit
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Catégorie
                  if (_selectedCategory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        ProductCategories.allCategories
                            .firstWhere(
                              (cat) => cat.id == _selectedCategory,
                              orElse: () => ProductCategories.allCategories.first,
                            )
                            .name,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: AppFontSizes.sm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Description
                  Text(
                    _descriptionController.text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.sm,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Prix
                  Row(
                    children: [
                      Text(
                        '${_priceController.text} FCFA',
                        style: const TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_originalPriceController.text.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${_originalPriceController.text} FCFA',
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '-${discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSizes.xs,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Stock et statut
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Stock: ${_stockController.text}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSizes.sm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Icon(
                        _isActive ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        color: _isActive ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _isActive ? 'Visible' : 'Masqué',
                        style: TextStyle(
                          color: _isActive ? AppColors.success : AppColors.textSecondary,
                          fontSize: AppFontSizes.sm,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.secondary.withValues(alpha:0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: AppFontSizes.xs,
                        ),
                      )).toList(),
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

  // Bouton d'ajout d'image
  Widget _buildAddImageButton() {
    final canAddMore = _selectedImages.length < AppLimits.maxProductImages;
    
    return GestureDetector(
      onTap: canAddMore ? _pickImage : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: canAddMore ? AppColors.primary : AppColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: canAddMore ? AppColors.primary.withValues(alpha:0.1) : AppColors.backgroundSecondary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: canAddMore ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              canAddMore ? 'Ajouter' : 'Max ${AppLimits.maxProductImages}',
              style: TextStyle(
                color: canAddMore ? AppColors.primary : AppColors.textSecondary,
                fontSize: AppFontSizes.xs,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Item d'image avec option de suppression
  Widget _buildImageItem(File image, int index) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSizes.xs,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep < 3) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentStep == 2 ? 'Réviser' : 'Suivant',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Publier le produit',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Méthodes de navigation
  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Validations par étape
  bool _validateStep1() {
    if (_formKey.currentState?.validate() != true) {
      return false;
    }
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une image de votre produit'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final price = int.tryParse(_priceController.text);
    final stock = int.tryParse(_stockController.text);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un prix valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une quantité en stock valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }

    return true;
  }

  // Gestion des images
  Future<void> _pickImage() async {
    if (_selectedImages.length >= AppLimits.maxProductImages) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Vérifier la taille du fichier (5MB max)
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB > AppLimits.maxImageSizeMB) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image trop lourde. Maximum ${AppLimits.maxImageSizeMB}MB'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        setState(() {
          _selectedImages.add(imageFile);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Sauvegarde du produit
  Future<void> _saveProduct() async {
    if (!_validateAllSteps()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préparer les données du produit
      final productData = CreateProductData(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? double.parse(_originalPriceController.text)
            : null,
        stock: int.parse(_stockController.text),
        category: _selectedCategory,
        brand: _brandController.text.trim().isNotEmpty 
            ? _brandController.text.trim()
            : null,
        tags: _tags,
        images: _selectedImages,
        isActive: _isActive,
        vendeurId: authProvider.user!.id, vendeurName: '',
      );

      // Appeler le service pour créer le produit
      final productService = ProductService();
      final productId = await productService.createProduct(productData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Produit ajouté avec succès ! ID: $productId'),
          backgroundColor: AppColors.success,
        ),
      );

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Produit ajouté avec succès !'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      // Retourner à la liste des produits
      context.go('/vendeur/products');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Validation globale
  bool _validateAllSteps() {
    return _validateStep1() && _validateStep2() && _validateStep3();
  }
}

