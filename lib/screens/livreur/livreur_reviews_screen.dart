// ===== lib/screens/livreur/livreur_reviews_screen.dart =====
// Écran de visualisation des avis pour les livreurs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_list.dart';
import '../../widgets/system_ui_scaffold.dart';

class LivreurReviewsScreen extends StatefulWidget {
  const LivreurReviewsScreen({super.key});

  @override
  State<LivreurReviewsScreen> createState() => _LivreurReviewsScreenState();
}

class _LivreurReviewsScreenState extends State<LivreurReviewsScreen> {
  final ReviewService _reviewService = ReviewService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final authProvider = context.read<AuthProvider>();
    final livreurId = authProvider.user?.id;

    if (livreurId == null) return;

    try {
      setState(() => _isLoading = true);

      final reviews = await _reviewService.getReviewsByLivreur(livreurId);
      final avgRating = await _reviewService.getAverageRating(livreurId, 'livreur');
      final distribution = await _reviewService.getRatingDistribution(livreurId, 'livreur');

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avgRating;
          _totalReviews = reviews.length;
          _ratingDistribution = distribution;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement avis livreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTrustLevelLabel() {
    if (_totalReviews == 0) return 'Nouveau livreur';
    if (_averageRating >= 4.5) return 'Livreur de confiance ⭐';
    if (_averageRating >= 4.0) return 'Bon livreur';
    if (_averageRating >= 3.5) return 'Livreur correct';
    if (_averageRating >= 3.0) return 'À améliorer';
    return 'Non recommandé';
  }

  Color _getTrustLevelColor() {
    if (_totalReviews == 0) return AppColors.textSecondary;
    if (_averageRating >= 4.5) return AppColors.success;
    if (_averageRating >= 4.0) return AppColors.info;
    if (_averageRating >= 3.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Mes avis clients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de niveau de confiance
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _getTrustLevelColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: _getTrustLevelColor(),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 48,
                              color: _getTrustLevelColor(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _getTrustLevelLabel(),
                              style: TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: FontWeight.bold,
                                color: _getTrustLevelColor(),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_totalReviews > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Basé sur $_totalReviews ${_totalReviews > 1 ? "avis" : "avis"}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Message d'explication
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.info),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Importance de vos avis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Les livreurs avec une note moyenne ≥ 4.5 sont prioritaires pour les nouvelles livraisons.',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.sm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Résumé statistique
                    if (_totalReviews > 0) ...[
                      ReviewSummary(
                        averageRating: _averageRating,
                        totalReviews: _totalReviews,
                        distribution: _ratingDistribution,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Liste des avis
                    if (_reviews.isEmpty)
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
                                'Aucun avis reçu pour le moment',
                                style: TextStyle(
                                  fontSize: AppFontSizes.lg,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Effectuez des livraisons pour recevoir vos premiers avis',
                                style: TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ReviewList(
                        reviews: _reviews,
                        showResponseField: false, // Les livreurs ne peuvent pas répondre
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
