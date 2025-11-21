// ===== lib/config/product_categories.dart =====
class ProductCategory {
  final String id;
  final String name;
  final String icon;
  final int count; // Sera mis à jour dynamiquement

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.count = 0,
  });
}

class ProductCategories {
  static const List<ProductCategory> allCategories = [
    ProductCategory(id: 'mode', name: 'Mode & Style', icon: '👗'),
    ProductCategory(id: 'electronique', name: 'Électronique', icon: '📱'),
    ProductCategory(id: 'alimentation', name: 'Alimentaire', icon: '🍽️'),
    ProductCategory(id: 'maison', name: 'Maison & Jardin', icon: '🏠'),
    ProductCategory(id: 'beaute', name: 'Beauté & Soins', icon: '💄'),
    ProductCategory(id: 'sport', name: 'Sport & Loisirs', icon: '⚽'),
    ProductCategory(id: 'auto', name: 'Auto & Moto', icon: '🚗'),
    ProductCategory(id: 'services', name: 'Services', icon: '🔧'),
  ];
}