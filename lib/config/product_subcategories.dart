// ===== lib/config/product_subcategories.dart =====
// Configuration des sous-catégories de produits - SOCIAL BUSINESS Pro

class ProductSubcategories {
  // Sous-catégories par catégorie principale
  static const Map<String, List<String>> subcategories = {
    'mode': [
      'Vêtements Homme',
      'Vêtements Femme',
      'Vêtements Enfant',
      'Chaussures',
      'Sacs & Accessoires',
      'Montres & Bijoux',
      'Autre (à préciser)',
    ],
    'electronique': [
      'Smartphones & Tablettes',
      'Ordinateurs',
      'TV & Audio',
      'Accessoires High-Tech',
      'Appareils Photo',
      'Consoles & Jeux Vidéo',
      'Autre (à préciser)',
    ],
    'electromenager': [
      'Réfrigérateurs & Congélateurs',
      'Cuisinières & Fours',
      'Lave-linge & Sèche-linge',
      'Climatiseurs & Ventilateurs',
      'Micro-ondes',
      'Fers à repasser',
      'Aspirateurs',
      'Petits électroménagers',
      'Autre (à préciser)',
    ],
    'cuisine': [
      'Batterie de cuisine',
      'Vaisselle & Couverts',
      'Ustensiles de cuisine',
      'Robots & Mixeurs',
      'Cafetières & Bouilloires',
      'Conservation & Rangement',
      'Accessoires cuisine',
      'Autre (à préciser)',
    ],
    'meubles': [
      'Canapés & Salons',
      'Chambres à coucher',
      'Salles à manger',
      'Bureaux & Rangements',
      'Meubles TV',
      'Décorations murales',
      'Tapis & Rideaux',
      'Luminaires',
      'Miroirs',
      'Autre (à préciser)',
    ],
    'alimentation': [
      'Supermarché',
      'Poissonnerie',
      'Boucherie',
      'Épicerie',
      'Boissons',
      'Snacks',
      'Conserves',
      'Condiments',
      'Surgelés',
      'Autre (à préciser)',
    ],
    'maison': [
      'Meubles',
      'Décoration',
      'Cuisine',
      'Linge de maison',
      'Jardin',
      'Bricolage',
      'Autre (à préciser)',
    ],
    'beaute': [
      'Parfums',
      'Maquillage',
      'Soins de la peau',
      'Soins des cheveux',
      'Hygiène',
      'Accessoires',
      'Autre (à préciser)',
    ],
    'sport': [
      'Vêtements',
      'Chaussures',
      'Équipement gym',
      'Football',
      'Basketball',
      'Accessoires',
      'Autre (à préciser)',
    ],
    'auto': [
      'Pièces auto',
      'Accessoires',
      'Entretien',
      'Moto',
      'Pneus',
      'GPS & Navigation',
      'Autre (à préciser)',
    ],
    'services': [
      'Nettoyage',
      'Réparation',
      'Livraison',
      'Événements',
      'Beauté à domicile',
      'Autres services',
      'Autre (à préciser)',
    ],
  };

  /// Obtenir les sous-catégories pour une catégorie donnée
  static List<String> getSubcategories(String categoryId) {
    return subcategories[categoryId.toLowerCase()] ?? ['Autre (à préciser)'];
  }

  /// Vérifier si une sous-catégorie existe
  static bool hasSubcategory(String categoryId, String subcategory) {
    final subs = subcategories[categoryId.toLowerCase()] ?? [];
    return subs.contains(subcategory);
  }

  /// Obtenir toutes les catégories qui ont des sous-catégories
  static List<String> getAllCategories() {
    return subcategories.keys.toList();
  }
}
