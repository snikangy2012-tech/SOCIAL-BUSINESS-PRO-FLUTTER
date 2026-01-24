import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/product_categories.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({super.key});

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  RangeValues _priceRange = const RangeValues(0, 500000);
  String? _selectedCategory;
  double _minRating = 0;
  List<String> _selectedConditions = [];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Prix
                  _buildSection(
                    title: 'Fourchette de prix',
                    child: Column(
                      children: [
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 500000,
                          divisions: 50,
                          activeColor: AppColors.primary,
                          labels: RangeLabels(
                            '${_priceRange.start.toInt()} FCFA',
                            '${_priceRange.end.toInt()} FCFA',
                          ),
                          onChanged: (values) {
                            setState(() => _priceRange = values);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_priceRange.start.toInt()} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${_priceRange.end.toInt()} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Catégories
                  _buildSection(
                    title: 'Catégorie',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProductCategories.allCategories.map((cat) {
                        final isSelected = _selectedCategory == cat.id;
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 16),
                              const SizedBox(width: 6),
                              Text(cat.name),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? cat.id : null;
                            });
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Note minimum
                  _buildSection(
                    title: 'Note minimum',
                    child: Column(
                      children: [
                        Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          label: _minRating == 0 ? 'Toutes' : '${_minRating.toInt()} ⭐',
                          onChanged: (value) {
                            setState(() => _minRating = value);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Toutes', style: TextStyle(fontSize: 12)),
                            Row(
                              children: [
                                Text(
                                  _minRating == 0 ? 'Aucun filtre' : '${_minRating.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (_minRating > 0) const Text(' ⭐', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // État du produit
                  _buildSection(
                    title: 'État du produit',
                    child: Column(
                      children: [
                        _buildCheckbox('Neuf', 'new'),
                        _buildCheckbox('Comme neuf', 'like_new'),
                        _buildCheckbox('Bon état', 'good'),
                        _buildCheckbox('Occasion', 'used'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Appliquer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildCheckbox(String label, String value) {
    final isSelected = _selectedConditions.contains(value);
    return CheckboxListTile(
      title: Text(label),
      value: isSelected,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedConditions.add(value);
          } else {
            _selectedConditions.remove(value);
          }
        });
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 500000);
      _selectedCategory = null;
      _minRating = 0;
      _selectedConditions.clear();
    });
  }

  void _applyFilters() {
    // TODO: Appliquer les filtres et retourner les résultats
    Navigator.pop(context, {
      'priceRange': _priceRange,
      'category': _selectedCategory,
      'minRating': _minRating,
      'conditions': _selectedConditions,
    });
  }
}
