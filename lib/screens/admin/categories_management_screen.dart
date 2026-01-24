// ===== lib/screens/admin/categories_management_screen.dart =====
// Gestion des catégories de produits (Admin)

import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../scripts/migrate_categories_to_firestore.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: const Text('Gestion des Catégories'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() => _showInactive = !_showInactive);
            },
            tooltip: _showInactive ? 'Masquer inactives' : 'Afficher inactives',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(),
            tooltip: 'Ajouter une catégorie',
          ),
        ],
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _showInactive
            ? CategoryService.watchAllCategories()
            : CategoryService.watchActiveCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Aucune catégorie'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _importDefaultCategories(),
                    icon: const Icon(Icons.download),
                    label: const Text('Importer catégories par défaut'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une catégorie manuellement'),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final items = List<CategoryModel>.from(categories);
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              await CategoryService.reorderCategories(items);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, key: ValueKey(category.id));
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: category.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade300,
          child: Icon(
            category.icon,
            color: category.isActive ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: category.isActive ? Colors.black : Colors.grey,
                  decoration: category.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (!category.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'INACTIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${category.subCategories.length} sous-catégories',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sous-catégories
                const Text(
                  'Sous-catégories:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (category.subCategories.isEmpty)
                  Text(
                    'Aucune sous-catégorie',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.subCategories.map((sub) {
                      return Chip(
                        label: Text(sub, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeSubCategory(category, sub),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddSubCategoryDialog(category),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter sous-catégorie'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditCategoryDialog(category),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleCategoryStatus(category),
                      icon: Icon(
                        category.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      label: Text(category.isActive ? 'Désactiver' : 'Activer'),
                      style: TextButton.styleFrom(
                        foregroundColor: category.isActive ? Colors.orange : AppColors.success,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteCategory(category),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialogue d'ajout de catégorie
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvelle Catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la catégorie',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Icône: '),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          child: Icon(selectedIcon),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final icon = await _showIconPicker(context);
                            if (icon != null) {
                              setDialogState(() => selectedIcon = icon);
                            }
                          },
                          child: const Text('Changer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    try {
                      await CategoryService.createCategory(
                        name: nameController.text.trim(),
                        icon: selectedIcon,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Catégorie créée avec succès'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Erreur: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialogue de modification de catégorie
  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    IconData selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier la Catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la catégorie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Icône: '),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          child: Icon(selectedIcon),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final icon = await _showIconPicker(context);
                            if (icon != null) {
                              setDialogState(() => selectedIcon = icon);
                            }
                          },
                          child: const Text('Changer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    try {
                      await CategoryService.updateCategory(
                        id: category.id,
                        name: nameController.text.trim(),
                        icon: selectedIcon,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Catégorie mise à jour'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Erreur: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialogue d'ajout de sous-catégorie
  void _showAddSubCategoryDialog(CategoryModel category) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter à "${category.name}"'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom de la sous-catégorie',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                try {
                  await CategoryService.addSubCategory(
                    category.id,
                    controller.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Sous-catégorie ajoutée'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Erreur: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  // Supprimer une sous-catégorie
  void _removeSubCategory(CategoryModel category, String subCategory) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "$subCategory" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CategoryService.removeSubCategory(category.id, subCategory);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sous-catégorie supprimée'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // Activer/Désactiver une catégorie
  void _toggleCategoryStatus(CategoryModel category) async {
    try {
      await CategoryService.updateCategory(
        id: category.id,
        isActive: !category.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category.isActive
                  ? '✅ Catégorie désactivée'
                  : '✅ Catégorie activée',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Supprimer une catégorie
  void _deleteCategory(CategoryModel category) async {
    // Vérifier si la catégorie est utilisée
    final count = await CategoryService.countProductsInCategory(category.id);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supprimer définitivement "${category.name}" ?'),
            if (count > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention: $count produit(s) utilisent cette catégorie',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CategoryService.hardDeleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Catégorie supprimée'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // Sélecteur d'icône simple
  Future<IconData?> _showIconPicker(BuildContext context) async {
    final icons = [
      Icons.category,
      Icons.checkroom_rounded,
      Icons.devices_rounded,
      Icons.kitchen_rounded,
      Icons.soup_kitchen_rounded,
      Icons.weekend_rounded,
      Icons.restaurant_rounded,
      Icons.home_rounded,
      Icons.spa_rounded,
      Icons.sports_soccer_rounded,
      Icons.directions_car_rounded,
      Icons.handyman_rounded,
      Icons.shopping_bag,
      Icons.local_grocery_store,
      Icons.storefront,
      Icons.inventory_2,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une icône'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => Navigator.pop(context, icons[index]),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(icons[index], color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Importer les catégories par défaut depuis product_categories.dart
  Future<void> _importDefaultCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer catégories par défaut'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette action va importer toutes les catégories prédéfinies dans Firestore.'),
            SizedBox(height: 12),
            Text(
              'Ceci inclut:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• 11 catégories principales'),
            Text('• Toutes les sous-catégories'),
            Text('• Icônes et ordre d\'affichage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download),
            label: const Text('Importer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un dialogue de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Import en cours...'),
          ],
        ),
      ),
    );

    try {
      // Exécuter la migration
      await CategoryMigrationScript.migrateCategories();

      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de progression

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Import réussi! 11 catégories importées'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de progression

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'import: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}
