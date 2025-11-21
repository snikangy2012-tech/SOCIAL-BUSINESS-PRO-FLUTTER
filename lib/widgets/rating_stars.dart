// ===== lib/widgets/rating_stars.dart =====
// Widget d'affichage et de sélection de notation par étoiles

import 'package:flutter/material.dart';
import '../config/constants.dart';

/// Widget d'affichage des étoiles (lecture seule)
class RatingStarsDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showRating;

  const RatingStarsDisplay({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.warning;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            // Étoile pleine
            return Icon(
              Icons.star,
              size: size,
              color: starColor,
            );
          } else if (index < rating) {
            // Étoile partielle
            return Icon(
              Icons.star_half,
              size: size,
              color: starColor,
            );
          } else {
            // Étoile vide
            return Icon(
              Icons.star_border,
              size: size,
              color: starColor.withValues(alpha: 0.3),
            );
          }
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget de sélection de notation par étoiles (interactif)
class RatingStarsInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const RatingStarsInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<RatingStarsInput> createState() => _RatingStarsInputState();
}

class _RatingStarsInputState extends State<RatingStarsInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= _currentRating;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starNumber;
            });
            widget.onRatingChanged(starNumber);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: widget.size,
              color: isFilled ? AppColors.warning : AppColors.border,
            ),
          ),
        );
      }),
    );
  }
}

/// Widget compact affichant la note moyenne avec nombre d'avis
class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final VoidCallback? onTap;

  const RatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '—',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (reviewCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($reviewCount)',
                style: const TextStyle(
                  fontSize: AppFontSizes.xs,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
