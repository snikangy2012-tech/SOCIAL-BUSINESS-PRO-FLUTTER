// ===== lib/widgets/category_banner.dart =====
// Widget de bannière colorée pour les catégories - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import '../config/constants.dart';

class CategoryBanner extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final String? imagePath;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const CategoryBanner({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.imagePath,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fond coloré uni (sans gradient)
              Container(
                decoration: BoxDecoration(
                  color: gradientColors.first,
                ),
              ),

              // Image de la catégorie positionnée à droite
              if (imagePath != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    width: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),

              // Texte de la catégorie à gauche
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Shop Now >>',
                        style: TextStyle(
                          color: gradientColors.first,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Configuration des couleurs et images par catégorie
class CategoryBannerConfig {
  static const Map<String, List<Color>> categoryGradients = {
    'mode': [Color(0xFFFF6B9D), Color(0xFFC239B3)], // Rose/Violet
    'electronique': [Color(0xFF4A90E2), Color(0xFF50C9FF)], // Bleu clair
    'electromenager': [Color(0xFFFF6B35), Color(0xFFF7931E)], // Orange
    'cuisine': [Color(0xFFE74C3C), Color(0xFFC0392B)], // Rouge
    'meubles': [Color(0xFF8E44AD), Color(0xFF9B59B6)], // Violet
    'alimentation': [Color(0xFF27AE60), Color(0xFF2ECC71)], // Vert
    'maison': [Color(0xFF3498DB), Color(0xFF2980B9)], // Bleu
    'beaute': [Color(0xFFE91E63), Color(0xFFF06292)], // Rose
    'sport': [Color(0xFFFF5722), Color(0xFFFF7043)], // Orange rouge
    'auto': [Color(0xFF607D8B), Color(0xFF455A64)], // Gris bleu
    'services': [Color(0xFF00BCD4), Color(0xFF00ACC1)], // Cyan
  };

  static const Map<String, String> categoryImages = {
    'mode': 'assets/BANNIERE ET CATEGORIE/MODE ET STYLE1.jpg',
    'electronique': 'assets/BANNIERE ET CATEGORIE/ELECTRONIQUE.jpg',
    'alimentation': 'assets/BANNIERE ET CATEGORIE/ALIMENTAIRE.jpg',
    'beaute': 'assets/BANNIERE ET CATEGORIE/BEAUTE ET SOINS.jpg',
    'maison': 'assets/BANNIERE ET CATEGORIE/MAISON ET JARDIN.jpg',
  };

  static List<Color> getGradient(String categoryId) {
    return categoryGradients[categoryId] ??
           [AppColors.primary, AppColors.primaryDark];
  }

  static String? getImage(String categoryId) {
    return categoryImages[categoryId];
  }
}
