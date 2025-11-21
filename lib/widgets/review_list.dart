// ===== lib/widgets/review_list.dart =====
// Widget pour afficher une liste d'avis avec possibilité de réponse

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/review_model.dart';
import 'rating_stars.dart';

class ReviewList extends StatelessWidget {
  final List<ReviewModel> reviews;
  final bool showResponseField;
  final Function(ReviewModel)? onRespond;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const ReviewList({
    super.key,
    required this.reviews,
    this.showResponseField = false,
    this.onRespond,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty && !isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Aucun avis pour le moment',
                style: TextStyle(
                  fontSize: AppFontSizes.lg,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length + (isLoading ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= reviews.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final review = reviews[index];
        return ReviewCard(
          review: review,
          showResponseField: showResponseField,
          onRespond: onRespond != null ? () => onRespond!(review) : null,
        );
      },
    );
  }
}

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool showResponseField;
  final VoidCallback? onRespond;

  const ReviewCard({
    super.key,
    required this.review,
    this.showResponseField = false,
    this.onRespond,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête: nom utilisateur et date
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSizes.md,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.xs,
                      ),
                    ),
                  ],
                ),
              ),
              // Note
              RatingStarsDisplay(
                rating: review.rating.toDouble(),
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Commentaire
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              height: 1.5,
            ),
          ),

          // Images (si présentes)
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      review.images[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: AppColors.border,
                          child: const Icon(Icons.image),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          // Réponse du vendeur
          if (review.response != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.store,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Réponse du vendeur',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSizes.sm,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.response!,
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bouton pour répondre (vendeurs uniquement)
          if (showResponseField && review.response == null && onRespond != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRespond,
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Répondre'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget affichant un résumé des statistiques d'avis
class ReviewSummary extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  const ReviewSummary({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Note globale
            Row(
              children: [
                // Note numérique
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    RatingStarsDisplay(
                      rating: averageRating,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews avis',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: AppSpacing.xl),

                // Distribution
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final count = distribution[stars] ?? 0;
                      final percentage = totalReviews > 0
                          ? (count / totalReviews * 100)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: const TextStyle(
                                fontSize: AppFontSizes.sm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor:
                                      AppColors.border.withValues(alpha: 0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.warning,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.xs,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
