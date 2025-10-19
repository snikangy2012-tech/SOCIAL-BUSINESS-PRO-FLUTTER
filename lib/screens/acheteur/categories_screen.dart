// ===== lib/screens/acheteur/categories_screen.dart =====
// Écran catégories style Jumia - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/product_categories.dart';
import '../../services/product_service.dart';
import '../../services/analytics_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ProductService _productService = ProductService();
  final AnalyticsService _analytics = AnalyticsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCategory = 'mode';
  bool _isLoading = false;
  String _searchQuery = '';

  // Sous-catégories par catégorie principale
  final Map<String, List<SubCategory>> _subCategories = {
    'mode': [
      SubCategory(
        id: 'robes',
        name: 'Robes',
        image: 'https://picsum.photos/200/200?random=1',
        productCount: 145,
      ),
      SubCategory(
        id: 'chemises',
        name: 'Chemises',
        image: 'https://picsum.photos/200/200?random=2',
        productCount: 89,
      ),
      SubCategory(
        id: 'pantalons',
        name: 'Pantalons',
        image: 'https://picsum.photos/200/200?random=3',
        productCount: 67,
      ),
      SubCategory(
        id: 'chaussures',
        name: 'Chaussures',
        image: 'https://picsum.photos/200/200?random=4',
        productCount: 123,
      ),
      SubCategory(
        id: 'accessoires',
        name: 'Accessoires',
        image: 'https://picsum.photos/200/200?random=5',
        productCount: 234,
      ),
      SubCategory(
        id: 'sacs',
        name: 'Sacs',
        image: 'https://picsum.photos/200/200?random=6',
        productCount: 78,
      ),
    ],
    'electronique': [
      SubCategory(
        id: 'smartphones',
        name: 'Smartphones',
        image: 'https://picsum.photos/200/200?random=10',
        productCount: 234,
      ),
      SubCategory(
        id: 'tablettes',
        name: 'Tablettes',
        image: 'https://picsum.photos/200/200?random=11',
        productCount: 56,
      ),
      SubCategory(
        id: 'ordinateurs',
        name: 'Ordinateurs',
        image: 'https://picsum.photos/200/200?random=12',
        productCount: 89,
      ),
      SubCategory(
        id: 'accessoires-tech',
        name: 'Accessoires',
        image: 'https://picsum.photos/200/200?random=13',
        productCount: 345,
      ),
      SubCategory(
        id: 'tv',
        name: 'Télévisions',
        image: 'https://picsum.photos/200/200?random=14',
        productCount: 67,
      ),
      SubCategory(
        id: 'audio',
        name: 'Audio & Son',
        image: 'https://picsum.photos/200/200?random=15',
        productCount: 123,
      ),
    ],
    'alimentation': [
      SubCategory(
        id: 'epicerie',
        name: 'Épicerie',
        image: 'https://picsum.photos/200/200?random=20',
        productCount: 456,
      ),
      SubCategory(
        id: 'boissons',
        name: 'Boissons',
        image: 'https://picsum.photos/200/200?random=21',
        productCount: 234,
      ),
      SubCategory(
        id: 'snacks',
        name: 'Snacks',
        image: 'https://picsum.photos/200/200?random=22',
        productCount: 178,
      ),
      SubCategory(
        id: 'conserves',
        name: 'Conserves',
        image: 'https://picsum.photos/200/200?random=23',
        productCount: 89,
      ),
      SubCategory(
        id: 'condiments',
        name: 'Condiments',
        image: 'https://picsum.photos/200/200?random=24',
        productCount: 145,
      ),
      SubCategory(
        id: 'surgeles',
        name: 'Surgelés',
        image: 'https://picsum.photos/200/200?random=25',
        productCount: 67,
      ),
    ],
    'maison': [
      SubCategory(
        id: 'meubles',
        name: 'Meubles',
        image: 'https://picsum.photos/200/200?random=30',
        productCount: 123,
      ),
      SubCategory(
        id: 'decoration',
        name: 'Décoration',
        image: 'https://picsum.photos/200/200?random=31',
        productCount: 267,
      ),
      SubCategory(
        id: 'cuisine',
        name: 'Cuisine',
        image: 'https://picsum.photos/200/200?random=32',
        productCount: 189,
      ),
      SubCategory(
        id: 'linge',
        name: 'Linge de maison',
        image: 'https://picsum.photos/200/200?random=33',
        productCount: 145,
      ),
      SubCategory(
        id: 'jardin',
        name: 'Jardin',
        image: 'https://picsum.photos/200/200?random=34',
        productCount: 78,
      ),
      SubCategory(
        id: 'bricolage',
        name: 'Bricolage',
        image: 'https://picsum.photos/200/200?random=35',
        productCount: 234,
      ),
    ],
    'beaute': [
      SubCategory(
        id: 'parfums',
        name: 'Parfums',
        image: 'https://picsum.photos/200/200?random=40',
        productCount: 156,
      ),
      SubCategory(
        id: 'maquillage',
        name: 'Maquillage',
        image: 'https://picsum.photos/200/200?random=41',
        productCount: 234,
      ),
      SubCategory(
        id: 'soins-peau',
        name: 'Soins de la peau',
        image: 'https://picsum.photos/200/200?random=42',
        productCount: 189,
      ),
      SubCategory(
        id: 'soins-cheveux',
        name: 'Soins des cheveux',
        image: 'https://picsum.photos/200/200?random=43',
        productCount: 167,
      ),
      SubCategory(
        id: 'hygiene',
        name: 'Hygiène',
        image: 'https://picsum.photos/200/200?random=44',
        productCount: 123,
      ),
      SubCategory(
        id: 'accessoires-beaute',
        name: 'Accessoires',
        image: 'https://picsum.photos/200/200?random=45',
        productCount: 89,
      ),
    ],
    'sport': [
      SubCategory(
        id: 'vetements-sport',
        name: 'Vêtements',
        image: 'https://picsum.photos/200/200?random=50',
        productCount: 145,
      ),
      SubCategory(
        id: 'chaussures-sport',
        name: 'Chaussures',
        image: 'https://picsum.photos/200/200?random=51',
        productCount: 123,
      ),
      SubCategory(
        id: 'equipement-gym',
        name: 'Équipement gym',
        image: 'https://picsum.photos/200/200?random=52',
        productCount: 78,
      ),
      SubCategory(
        id: 'football',
        name: 'Football',
        image: 'https://picsum.photos/200/200?random=53',
        productCount: 234,
      ),
      SubCategory(
        id: 'basketball',
        name: 'Basketball',
        image: 'https://picsum.photos/200/200?random=54',
        productCount: 89,
      ),
      SubCategory(
        id: 'accessoires-sport',
        name: 'Accessoires',
        image: 'https://picsum.photos/200/200?random=55',
        productCount: 167,
      ),
    ],
    'auto': [
      SubCategory(
        id: 'pieces-auto',
        name: 'Pièces auto',
        image: 'https://picsum.photos/200/200?random=60',
        productCount: 345,
      ),
      SubCategory(
        id: 'accessoires-auto',
        name: 'Accessoires',
        image: 'https://picsum.photos/200/200?random=61',
        productCount: 234,
      ),
      SubCategory(
        id: 'entretien-auto',
        name: 'Entretien',
        image: 'https://picsum.photos/200/200?random=62',
        productCount: 156,
      ),
      SubCategory(
        id: 'moto',
        name: 'Moto',
        image: 'https://picsum.photos/200/200?random=63',
        productCount: 89,
      ),
      SubCategory(
        id: 'pneus',
        name: 'Pneus',
        image: 'https://picsum.photos/200/200?random=64',
        productCount: 123,
      ),
      SubCategory(
        id: 'gps-auto',
        name: 'GPS & Navigation',
        image: 'https://picsum.photos/200/200?random=65',
        productCount: 67,
      ),
    ],
    'services': [
      SubCategory(
        id: 'nettoyage',
        name: 'Nettoyage',
        image: 'https://picsum.photos/200/200?random=70',
        productCount: 45,
      ),
      SubCategory(
        id: 'reparation',
        name: 'Réparation',
        image: 'https://picsum.photos/200/200?random=71',
        productCount: 67,
      ),
      SubCategory(
        id: 'livraison',
        name: 'Livraison',
        image: 'https://picsum.photos/200/200?random=72',
        productCount: 123,
      ),
      SubCategory(
        id: 'evenements',
        name: 'Événements',
        image: 'https://picsum.photos/200/200?random=73',
        productCount: 34,
      ),
      SubCategory(
        id: 'beaute-services',
        name: 'Beauté à domicile',
        image: 'https://picsum.photos/200/200?random=74',
        productCount: 56,
      ),
      SubCategory(
        id: 'autres',
        name: 'Autres services',
        image: 'https://picsum.photos/200/200?random=75',
        productCount: 89,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildCategoryDrawer(),
      body: Column(
        children: [
          _buildSearchBar(), // ✅ AJOUTER
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ===== APP BAR =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        'Catégories',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implémenter la recherche
          },
        ),
      ],
    );
  }

  // ===== BARRE DE RECHERCHE =====
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  // ===== DRAWER - MENU LATÉRAL =====
  Widget _buildCategoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            color: AppColors.primary,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.category, color: Colors.white, size: 32),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Toutes les catégories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Liste des catégories
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: ProductCategories.allCategories.map((category) {
                final isSelected = _selectedCategory == category.id;
                return ListTile(
                  leading: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primaryLight.withValues(alpha:0.3),
                  onTap: () {
                    setState(() => _selectedCategory = category.id);
                    Navigator.pop(context); // Fermer le drawer
                    _analytics.logSearch(category.name, category.id);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CORPS DE LA PAGE =====
  Widget _buildBody() {
    if (_isLoading) {  // ✅ AJOUTER
      return const Center(child: CircularProgressIndicator());
    }

    final selectedCategoryData = ProductCategories.allCategories
        .firstWhere((cat) => cat.id == _selectedCategory);
    final allSubCategories = _subCategories[_selectedCategory] ?? [];
    final subCategories = _searchQuery.isEmpty
        ? allSubCategories
        : allSubCategories
            .where((sub) => sub.name.toLowerCase().contains(_searchQuery))
            .toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        // Charger les vraies données
        await _productService.getProducts();
        setState(() => _isLoading = false);
      },
      child: CustomScrollView(
        slivers: [
          // En-tête de la catégorie sélectionnée
          SliverToBoxAdapter(
            child: _buildCategoryHeader(selectedCategoryData),
          ),

          // Titre de la section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Explorez ${selectedCategoryData.name}',
              'VOIR TOUS',
              () {
                context.push('/products/category/$_selectedCategory');
              },
            ),
          ),

          // Grille de sous-catégories
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildSubCategoryCard(subCategories[index]),
                childCount: subCategories.length,
              ),
            ),
          ),

          // Section promotionnelle (optionnel)
          SliverToBoxAdapter(
            child: _buildPromotionalSection(),
          ),

          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  // ===== EN-TÊTE DE CATÉGORIE =====
  Widget _buildCategoryHeader(ProductCategory category) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha:0.7),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_subCategories[category.id]?.length ?? 0} sous-catégories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== TITRE DE SECTION =====
  Widget _buildSectionHeader(String title, String actionText, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // ===== CARTE SOUS-CATÉGORIE =====
  Widget _buildSubCategoryCard(SubCategory subCategory) {
    return GestureDetector(
      onTap: () {
        _analytics.logSearch(subCategory.name, _selectedCategory);
        context.push('/products/subcategory/${subCategory.id}');
      },
      child: Column(
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(subCategory.image),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Nom
          Text(
            subCategory.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Nombre de produits
          Text(
            '${subCategory.productCount} produits',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===== SECTION PROMOTIONNELLE =====
  Widget _buildPromotionalSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha:0.2),
            AppColors.warning.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha:0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.warning, size: 40),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres spéciales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jusqu\'à -50% sur une sélection de produits',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/promotions');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }
}

// ===== MODÈLE SOUS-CATÉGORIE =====
class SubCategory {
  final String id;
  final String name;
  final String image;
  final int productCount;

  SubCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.productCount,
  });
}