// ===== lib/utils/image_helper.dart =====
// Helper pour gérer les images produits
// Fournit des placeholders et URLs valides

class ImageHelper {
  // URLs d'images placeholder par catégorie
  static const Map<String, List<String>> categoryPlaceholders = {
    'alimentation': [
      'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400',
      'https://images.unsplash.com/photo-1506617420156-8e4536971650?w=400',
      'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400',
      'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?w=400',
    ],
    'mode': [
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400',
      'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
      'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400',
    ],
    'electronique': [
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
      'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400',
      'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=400',
    ],
    'maison': [
      'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=400',
      'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
      'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=400',
      'https://images.unsplash.com/photo-1556912173-3bb406ef7e77?w=400',
    ],
    'beaute': [
      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400',
      'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=400',
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400',
      'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=400',
    ],
    'sport': [
      'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400',
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
      'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=400',
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
    ],
    'auto': [
      'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400',
      'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=400',
      'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=400',
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400',
    ],
    'services': [
      'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=400',
      'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?w=400',
      'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=400',
      'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=400',
    ],
  };

  /// Récupère une URL d'image placeholder pour une catégorie
  /// Si aucune image n'est disponible pour la catégorie, retourne une image générique
  static String getPlaceholderForCategory(String category, {int index = 0}) {
    final categoryLower = category.toLowerCase();

    // Chercher dans les placeholders
    for (var entry in categoryPlaceholders.entries) {
      if (categoryLower.contains(entry.key)) {
        final images = entry.value;
        // Utiliser modulo pour cycler dans les images disponibles
        return images[index % images.length];
      }
    }

    // Image générique si aucune catégorie ne correspond
    return getGenericPlaceholder(index);
  }

  /// Récupère une image générique (quand catégorie inconnue)
  static String getGenericPlaceholder(int index) {
    final genericImages = [
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400',
      'https://images.unsplash.com/photo-1560393464-5c69a73c5770?w=400',
      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400',
    ];

    return genericImages[index % genericImages.length];
  }

  /// Récupère une URL d'image valide pour un produit
  /// Si imageUrl est vide/null, retourne un placeholder basé sur la catégorie
  static String getValidImageUrl({
    String? imageUrl,
    String? category,
    int index = 0,
  }) {
    // Si l'URL existe et est valide
    if (imageUrl != null && imageUrl.isNotEmpty && _isValidUrl(imageUrl)) {
      return imageUrl;
    }

    // Sinon, retourner un placeholder
    if (category != null && category.isNotEmpty) {
      return getPlaceholderForCategory(category, index: index);
    }

    return getGenericPlaceholder(index);
  }

  /// Vérifie si une URL est valide
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Récupère la première image valide d'une liste
  static String? getFirstValidImage(List<String>? images, {String? category, int index = 0}) {
    if (images == null || images.isEmpty) {
      return getValidImageUrl(category: category, index: index);
    }

    // Chercher la première URL valide
    for (var imageUrl in images) {
      if (_isValidUrl(imageUrl)) {
        return imageUrl;
      }
    }

    // Aucune URL valide, retourner placeholder
    return getValidImageUrl(category: category, index: index);
  }
}
