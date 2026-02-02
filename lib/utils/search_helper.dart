// ===== lib/utils/search_helper.dart =====
// Utilitaires pour la recherche intelligente de produits

import '../models/product_model.dart';

/// Résultat de recherche avec score de pertinence
class SearchResult {
  final ProductModel product;
  final double score;
  final List<String> matchedFields;

  SearchResult({
    required this.product,
    required this.score,
    required this.matchedFields,
  });
}

/// Service de recherche intelligente
class SearchHelper {
  /// Normalise une chaîne pour la recherche (minuscules, sans accents)
  static String normalize(String text) {
    return _removeAccents(text.toLowerCase().trim());
  }

  /// Supprime les accents d'une chaîne
  static String _removeAccents(String text) {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçœæ';
    const withoutAccents = 'aaaaaaeeeeiiiiooooouuuuyyncoea';

    String result = text;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Extrait les mots d'une requête (ignore les mots courts < 2 caractères)
  static List<String> tokenize(String query) {
    return normalize(query)
        .split(RegExp(r'[\s,;.\-_]+'))
        .where((word) => word.length >= 2)
        .toList();
  }

  /// Calcule la similarité entre deux chaînes (0.0 à 1.0)
  /// Utilise une version simplifiée de la distance de Levenshtein
  static double similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Si l'un contient l'autre, bonne similarité
    if (a.contains(b) || b.contains(a)) {
      return 0.8 + (0.2 * (b.length / a.length).clamp(0.0, 1.0));
    }

    // Vérifier si c'est un préfixe (début de mot)
    if (a.startsWith(b) || b.startsWith(a)) {
      return 0.7;
    }

    // Calcul de distance de Levenshtein simplifiée
    final distance = _levenshteinDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return (1.0 - (distance / maxLen)).clamp(0.0, 1.0);
  }

  /// Distance de Levenshtein entre deux chaînes
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List.generate(b.length + 1, (i) => i);
    List<int> currentRow = List.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[b.length];
  }

  /// Vérifie si un mot de recherche correspond à un texte cible
  /// Retourne un score de 0.0 à 1.0
  static double matchWord(String searchWord, String targetText) {
    final normalizedTarget = normalize(targetText);
    final normalizedSearch = normalize(searchWord);

    // Correspondance exacte
    if (normalizedTarget.contains(normalizedSearch)) {
      return 1.0;
    }

    // Recherche de chaque mot dans le texte cible
    final targetWords = tokenize(targetText);
    double bestScore = 0.0;

    for (final targetWord in targetWords) {
      final score = similarity(normalizedSearch, targetWord);
      if (score > bestScore) {
        bestScore = score;
      }
    }

    return bestScore;
  }

  /// Recherche intelligente dans les produits
  /// Retourne les résultats triés par pertinence
  static List<SearchResult> searchProducts(
    List<ProductModel> products,
    String query, {
    double minScore = 0.3, // Score minimum pour inclure un résultat
  }) {
    if (query.trim().isEmpty) {
      return products
          .map((p) => SearchResult(product: p, score: 1.0, matchedFields: []))
          .toList();
    }

    final searchWords = tokenize(query);
    if (searchWords.isEmpty) {
      return products
          .map((p) => SearchResult(product: p, score: 1.0, matchedFields: []))
          .toList();
    }

    final List<SearchResult> results = [];

    for (final product in products) {
      double totalScore = 0.0;
      final List<String> matchedFields = [];

      // Pondération des champs (plus important = plus de poids)
      final fields = <String, double>{
        'name': 3.0,
        'category': 2.0,
        'subCategory': 1.5,
        'brand': 1.5,
        'tags': 2.0,
        'description': 1.0,
        'vendeurName': 1.0,
      };

      // Pour chaque mot de recherche
      for (final searchWord in searchWords) {
        double wordScore = 0.0;

        // Nom du produit (priorité haute)
        final nameScore = matchWord(searchWord, product.name);
        if (nameScore > 0.5) {
          wordScore += nameScore * fields['name']!;
          if (!matchedFields.contains('name')) matchedFields.add('name');
        }

        // Catégorie
        final catScore = matchWord(searchWord, product.category);
        if (catScore > 0.5) {
          wordScore += catScore * fields['category']!;
          if (!matchedFields.contains('category')) matchedFields.add('category');
        }

        // Sous-catégorie
        if (product.subCategory != null) {
          final subCatScore = matchWord(searchWord, product.subCategory!);
          if (subCatScore > 0.5) {
            wordScore += subCatScore * fields['subCategory']!;
            if (!matchedFields.contains('subCategory')) {
              matchedFields.add('subCategory');
            }
          }
        }

        // Marque
        if (product.brand != null) {
          final brandScore = matchWord(searchWord, product.brand!);
          if (brandScore > 0.5) {
            wordScore += brandScore * fields['brand']!;
            if (!matchedFields.contains('brand')) matchedFields.add('brand');
          }
        }

        // Tags (mots-clés)
        for (final tag in product.tags) {
          final tagScore = matchWord(searchWord, tag);
          if (tagScore > 0.5) {
            wordScore += tagScore * fields['tags']!;
            if (!matchedFields.contains('tags')) matchedFields.add('tags');
            break; // Un seul tag suffit
          }
        }

        // Description (moins prioritaire)
        final descScore = matchWord(searchWord, product.description);
        if (descScore > 0.6) {
          wordScore += descScore * fields['description']!;
          if (!matchedFields.contains('description')) {
            matchedFields.add('description');
          }
        }

        // Nom du vendeur
        final vendorScore = matchWord(searchWord, product.vendeurName);
        if (vendorScore > 0.6) {
          wordScore += vendorScore * fields['vendeurName']!;
          if (!matchedFields.contains('vendeurName')) {
            matchedFields.add('vendeurName');
          }
        }

        totalScore += wordScore;
      }

      // Normaliser le score par le nombre de mots recherchés
      final normalizedScore = totalScore / searchWords.length;

      if (normalizedScore >= minScore) {
        results.add(SearchResult(
          product: product,
          score: normalizedScore,
          matchedFields: matchedFields,
        ));
      }
    }

    // Trier par score décroissant
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// Suggestions de recherche basées sur les produits disponibles
  static List<String> getSuggestions(
    List<ProductModel> products,
    String partialQuery, {
    int maxSuggestions = 5,
  }) {
    if (partialQuery.length < 2) return [];

    final normalizedQuery = normalize(partialQuery);
    final Set<String> suggestions = {};

    // Collecter les termes pertinents
    for (final product in products) {
      // Noms de produits
      if (normalize(product.name).contains(normalizedQuery)) {
        suggestions.add(product.name);
      }

      // Catégories
      if (normalize(product.category).contains(normalizedQuery)) {
        suggestions.add(product.category);
      }

      // Tags
      for (final tag in product.tags) {
        if (normalize(tag).contains(normalizedQuery)) {
          suggestions.add(tag);
        }
      }

      // Marques
      if (product.brand != null &&
          normalize(product.brand!).contains(normalizedQuery)) {
        suggestions.add(product.brand!);
      }

      if (suggestions.length >= maxSuggestions * 2) break;
    }

    // Trier par pertinence (ceux qui commencent par la requête en premier)
    final sortedSuggestions = suggestions.toList()
      ..sort((a, b) {
        final aStarts = normalize(a).startsWith(normalizedQuery);
        final bStarts = normalize(b).startsWith(normalizedQuery);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.length.compareTo(b.length);
      });

    return sortedSuggestions.take(maxSuggestions).toList();
  }

  /// Synonymes courants pour améliorer la recherche
  static final Map<String, List<String>> _synonyms = {
    'telephone': ['portable', 'mobile', 'smartphone', 'tel', 'phone', 'iphone', 'samsung', 'android'],
    'portable': ['telephone', 'mobile', 'smartphone'],
    'chaussure': ['basket', 'tennis', 'sneaker', 'sandale', 'mocassin', 'botte', 'escarpin'],
    'basket': ['chaussure', 'tennis', 'sneaker'],
    'vetement': ['habit', 'tenue', 'fringue', 'mode'],
    'pantalon': ['jean', 'jeans', 'pantalons'],
    'tshirt': ['t-shirt', 'tee-shirt', 'haut', 'maillot'],
    'robe': ['robes', 'dress'],
    'sac': ['sacoche', 'sacs', 'bag', 'pochette'],
    'montre': ['montres', 'watch'],
    'bijou': ['bijoux', 'collier', 'bracelet', 'bague'],
    'ordinateur': ['pc', 'laptop', 'ordi', 'computer', 'macbook'],
    'pc': ['ordinateur', 'laptop', 'ordi'],
    'ecouteur': ['ecouteurs', 'airpods', 'casque', 'earbuds'],
    'casque': ['ecouteur', 'headphone', 'headphones'],
    'parfum': ['parfums', 'fragrance', 'eau de toilette', 'cologne'],
    'creme': ['cremes', 'lotion', 'soin'],
    'maquillage': ['make-up', 'makeup', 'cosmetique'],
    'meuble': ['meubles', 'mobilier', 'furniture'],
    'cuisine': ['cuisines', 'kitchen'],
    'enfant': ['enfants', 'kid', 'kids', 'bebe', 'junior'],
    'homme': ['hommes', 'masculin', 'garcon', 'men', 'man'],
    'femme': ['femmes', 'feminin', 'fille', 'women', 'woman', 'dame'],
  };

  /// Étend une requête avec des synonymes
  static List<String> expandWithSynonyms(List<String> words) {
    final Set<String> expanded = {};

    for (final word in words) {
      expanded.add(word);
      final normalizedWord = normalize(word);

      // Chercher des synonymes
      for (final entry in _synonyms.entries) {
        if (normalize(entry.key) == normalizedWord ||
            entry.value.any((syn) => normalize(syn) == normalizedWord)) {
          expanded.add(entry.key);
          expanded.addAll(entry.value);
        }
      }
    }

    return expanded.toList();
  }

  /// Recherche avancée avec synonymes
  static List<SearchResult> searchProductsAdvanced(
    List<ProductModel> products,
    String query, {
    double minScore = 0.25,
    bool useSynonyms = true,
  }) {
    if (query.trim().isEmpty) {
      return products
          .map((p) => SearchResult(product: p, score: 1.0, matchedFields: []))
          .toList();
    }

    List<String> searchWords = tokenize(query);
    if (searchWords.isEmpty) {
      return products
          .map((p) => SearchResult(product: p, score: 1.0, matchedFields: []))
          .toList();
    }

    // Étendre avec synonymes si activé
    if (useSynonyms) {
      searchWords = expandWithSynonyms(searchWords);
    }

    final List<SearchResult> results = [];

    for (final product in products) {
      double bestScore = 0.0;
      final List<String> matchedFields = [];

      // Créer un texte combiné pour la recherche
      final searchableText = [
        product.name,
        product.name, // Double poids pour le nom
        product.category,
        product.subCategory ?? '',
        product.brand ?? '',
        ...product.tags,
        product.description,
        product.vendeurName,
      ].join(' ');

      final normalizedSearchable = normalize(searchableText);

      // Vérifier chaque mot de recherche
      int matchedWords = 0;
      for (final word in searchWords) {
        final normalizedWord = normalize(word);
        if (normalizedSearchable.contains(normalizedWord)) {
          matchedWords++;

          // Déterminer quel champ correspond
          if (normalize(product.name).contains(normalizedWord)) {
            if (!matchedFields.contains('name')) matchedFields.add('name');
          }
          if (normalize(product.category).contains(normalizedWord)) {
            if (!matchedFields.contains('category')) matchedFields.add('category');
          }
          if (product.tags.any((t) => normalize(t).contains(normalizedWord))) {
            if (!matchedFields.contains('tags')) matchedFields.add('tags');
          }
        }
      }

      if (matchedWords > 0) {
        // Score basé sur le pourcentage de mots trouvés
        bestScore = matchedWords / tokenize(query).length;

        // Bonus si le nom contient la requête exacte
        if (normalize(product.name).contains(normalize(query))) {
          bestScore += 0.5;
        }

        // Bonus pour correspondance dans le nom
        if (matchedFields.contains('name')) {
          bestScore += 0.3;
        }
      }

      if (bestScore >= minScore) {
        results.add(SearchResult(
          product: product,
          score: bestScore.clamp(0.0, 2.0),
          matchedFields: matchedFields,
        ));
      }
    }

    // Trier par score décroissant
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
