import 'package:flutter/material.dart';
import '../config/constants.dart';

class CategoryFilterChips extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool showAllOption;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = true,
  });

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Tout"
          if (widget.showAllOption)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('Tout'),
                selected: widget.selectedCategory == null,
                onSelected: (selected) {
                  widget.onCategorySelected(null);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: widget.selectedCategory == null
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Chips des catégories
          ...widget.categories.map((category) {
            final isSelected = widget.selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  widget.onCategorySelected(selected ? category : null);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                avatar: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
