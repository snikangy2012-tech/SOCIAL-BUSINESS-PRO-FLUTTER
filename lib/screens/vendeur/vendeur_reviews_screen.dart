// ===== lib/screens/vendeur/vendeur_reviews_screen.dart =====
// Écran de gestion des avis pour les vendeurs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_list.dart';
import '../../widgets/system_ui_scaffold.dart';

class VendeurReviewsScreen extends StatefulWidget {
  const VendeurReviewsScreen({super.key});

  @override
  State<VendeurReviewsScreen> createState() => _VendeurReviewsScreenState();
}

class _VendeurReviewsScreenState extends State<VendeurReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();

  late TabController _tabController;

  List<ReviewModel> _productReviews = [];
  List<ReviewModel> _vendorReviews = [];
  bool _isLoadingProducts = true;
  bool _isLoadingVendor = true;

  double _productAvgRating = 0.0;
  int _productTotalReviews = 0;
  Map<int, int> _productDistribution = {};

  double _vendorAvgRating = 0.0;
  int _vendorTotalReviews = 0;
  Map<int, int> _vendorDistribution = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id;

    if (vendorId == null) return;

    // Charger les avis vendeur
    _loadVendorReviews(vendorId);

    // Charger les avis produits (tous les produits du vendeur)
    _loadProductReviews(vendorId);
  }

  Future<void> _loadVendorReviews(String vendorId) async {
    try {
      setState(() => _isLoadingVendor = true);

      final reviews = await _reviewService.getReviewsByVendor(vendorId);
      final avgRating = await _reviewService.getAverageRating(vendorId, 'vendor');
      final distribution = await _reviewService.getRatingDistribution(vendorId, 'vendor');

      if (mounted) {
        setState(() {
          _vendorReviews = reviews;
          _vendorAvgRating = avgRating;
          _vendorTotalReviews = reviews.length;
          _vendorDistribution = distribution;
          _isLoadingVendor = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement avis vendeur: $e');
      if (mounted) {
        setState(() => _isLoadingVendor = false);
      }
    }
  }

  Future<void> _loadProductReviews(String vendorId) async {
    try {
      setState(() => _isLoadingProducts = true);

      // TODO: Implémenter la récupération des avis de tous les produits du vendeur
      // Pour l'instant, on simule avec une liste vide
      // Il faudrait :
      // 1. Récupérer tous les produits du vendeur
      // 2. Pour chaque produit, récupérer ses avis
      // 3. Agréger tous les avis

      if (mounted) {
        setState(() {
          _productReviews = [];
          _productAvgRating = 0.0;
          _productTotalReviews = 0;
          _productDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement avis produits: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  Future<void> _respondToReview(ReviewModel review) async {
    final responseController = TextEditingController();

    if (review.response != null) {
      responseController.text = review.response!;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          review.response != null ? 'Modifier la réponse' : 'Répondre à l\'avis',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Afficher l'avis original
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      RatingStarsDisplay(
                        rating: review.rating.toDouble(),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: const TextStyle(fontSize: AppFontSizes.sm),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: responseController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: 'Votre réponse',
                hintText: 'Merci pour votre avis...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(responseController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publier'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _reviewService.addResponse(review.id, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réponse publiée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          // Recharger les avis
          _loadReviews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendeur-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Avis clients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mon profil'),
            Tab(text: 'Mes produits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVendorReviewsTab(),
          _buildProductReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildVendorReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: _isLoadingVendor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé
                  if (_vendorTotalReviews > 0) ...[
                    ReviewSummary(
                      averageRating: _vendorAvgRating,
                      totalReviews: _vendorTotalReviews,
                      distribution: _vendorDistribution,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Liste des avis
                  if (_vendorReviews.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Aucun avis sur votre profil',
                              style: TextStyle(
                                fontSize: AppFontSizes.lg,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReviewList(
                      reviews: _vendorReviews,
                      showResponseField: true,
                      onRespond: _respondToReview,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé
                  if (_productTotalReviews > 0) ...[
                    ReviewSummary(
                      averageRating: _productAvgRating,
                      totalReviews: _productTotalReviews,
                      distribution: _productDistribution,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Liste des avis
                  if (_productReviews.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Aucun avis sur vos produits',
                              style: TextStyle(
                                fontSize: AppFontSizes.lg,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReviewList(
                      reviews: _productReviews,
                      showResponseField: true,
                      onRespond: _respondToReview,
                    ),
                ],
              ),
            ),
    );
  }
}
