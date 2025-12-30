// ===== lib/config/product_categories.dart =====
import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final IconData icon;
  final int count; // Sera mis à jour dynamiquement
  final List<String>? subCategories; // ✅ Sous-catégories optionnelles

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.count = 0,
    this.subCategories,
  });
}

class ProductCategories {
  static const List<ProductCategory> allCategories = [
    ProductCategory(
      id: 'mode',
      name: 'Mode & Style',
      icon: Icons.checkroom_rounded,
      subCategories: [
        'Vêtements Homme',
        'Vêtements Femme',
        'Vêtements Enfant',
        'Chaussures',
        'Sacs & Accessoires',
        'Montres & Bijoux',
      ],
    ),
    ProductCategory(
      id: 'electronique',
      name: 'Électronique',
      icon: Icons.devices_rounded,
      subCategories: [
        'Smartphones & Tablettes',
        'Ordinateurs',
        'TV & Audio',
        'Accessoires High-Tech',
        'Appareils Photo',
        'Consoles & Jeux Vidéo',
      ],
    ),
    ProductCategory(
      id: 'electromenager',
      name: 'Électroménager',
      icon: Icons.kitchen_rounded,
      subCategories: [
        'Réfrigérateurs & Congélateurs',
        'Cuisinières & Fours',
        'Lave-linge & Sèche-linge',
        'Climatiseurs & Ventilateurs',
        'Micro-ondes',
        'Fers à repasser',
        'Aspirateurs',
        'Petits électroménagers',
      ],
    ),
    ProductCategory(
      id: 'cuisine',
      name: 'Cuisine & Ustensiles',
      icon: Icons.soup_kitchen_rounded,
      subCategories: [
        'Batterie de cuisine',
        'Vaisselle & Couverts',
        'Ustensiles de cuisine',
        'Robots & Mixeurs',
        'Cafetières & Bouilloires',
        'Conservation & Rangement',
        'Accessoires cuisine',
      ],
    ),
    ProductCategory(
      id: 'meubles',
      name: 'Meubles & Déco',
      icon: Icons.weekend_rounded,
      subCategories: [
        'Canapés & Salons',
        'Chambres à coucher',
        'Salles à manger',
        'Bureaux & Rangements',
        'Meubles TV',
        'Décorations murales',
        'Tapis & Rideaux',
        'Luminaires',
        'Miroirs',
      ],
    ),
    ProductCategory(
      id: 'alimentation',
      name: 'Alimentaire',
      icon: Icons.restaurant_rounded,
      subCategories: [
        'Fruits & Légumes',
        'Viandes & Poissons',
        'Produits laitiers',
        'Épicerie',
        'Boissons',
        'Boulangerie & Pâtisserie',
      ],
    ),
    ProductCategory(
      id: 'maison',
      name: 'Maison & Jardin',
      icon: Icons.home_rounded,
      subCategories: [
        'Literie & Linge',
        'Salle de bain',
        'Jardinage & Plantes',
        'Outils & Bricolage',
        'Nettoyage & Entretien',
      ],
    ),
    ProductCategory(
      id: 'beaute',
      name: 'Beauté & Soins',
      icon: Icons.spa_rounded,
      subCategories: [
        'Parfums',
        'Maquillage',
        'Soins visage',
        'Soins cheveux',
        'Hygiène & Santé',
        'Produits naturels',
      ],
    ),
    ProductCategory(
      id: 'sport',
      name: 'Sport & Loisirs',
      icon: Icons.sports_soccer_rounded,
      subCategories: [
        'Vêtements de sport',
        'Chaussures de sport',
        'Équipements fitness',
        'Sports collectifs',
        'Cyclisme',
        'Camping & Outdoor',
      ],
    ),
    ProductCategory(
      id: 'auto',
      name: 'Auto & Moto',
      icon: Icons.directions_car_rounded,
      subCategories: [
        'Pièces détachées',
        'Accessoires auto',
        'Entretien & Nettoyage',
        'GPS & Électronique',
        'Motos & Scooters',
      ],
    ),
    ProductCategory(
      id: 'services',
      name: 'Services',
      icon: Icons.handyman_rounded,
      subCategories: [
        'Réparation & Dépannage',
        'Livraison',
        'Services ménagers',
        'Cours & Formation',
        'Événementiel',
      ],
    ),
  ];

  /// Obtenir une catégorie par son ID
  static ProductCategory? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir toutes les sous-catégories d'une catégorie
  static List<String> getSubCategories(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.subCategories ?? [];
  }

  /// Vérifier si une sous-catégorie existe dans une catégorie
  static bool isValidSubCategory(String categoryId, String subCategory) {
    final subCategories = getSubCategories(categoryId);
    return subCategories.contains(subCategory);
  }
}