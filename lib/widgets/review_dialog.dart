// ===== lib/widgets/review_dialog.dart =====
// Dialog pour soumettre ou modifier un avis

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../providers/auth_provider_firebase.dart';
import 'rating_stars.dart';

class ReviewDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'product', 'vendor', 'livreur'
  final String targetName;
  final ReviewModel? existingReview; // Pour modification

  const ReviewDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    this.existingReview,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();

  /// Méthode statique pour afficher le dialog
  static Future<bool?> show(
    BuildContext context, {
    required String targetId,
    required String targetType,
    required String targetName,
    ReviewModel? existingReview,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReviewDialog(
        targetId: targetId,
        targetType: targetType,
        targetName: targetName,
        existingReview: existingReview,
      ),
    );
  }
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _commentController = TextEditingController();
  final _reviewService = ReviewService();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getTargetTypeLabel() {
    switch (widget.targetType) {
      case 'product':
        return 'le produit';
      case 'vendor':
        return 'le vendeur';
      case 'livreur':
        return 'le livreur';
      default:
        return 'cet élément';
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez écrire un commentaire'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      final userName = authProvider.user?.displayName ?? 'Utilisateur';

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (widget.existingReview != null) {
        // Mise à jour d'un avis existant
        await _reviewService.updateReview(
          widget.existingReview!.id,
          {
            'rating': _rating,
            'comment': _commentController.text.trim(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis modifié avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Création d'un nouvel avis
        final review = ReviewModel(
          id: '', // Sera généré par Firestore
          targetId: widget.targetId,
          targetType: widget.targetType,
          reviewerId: userId,
          reviewerName: userName,
          rating: _rating,
          comment: _commentController.text.trim(),
          createdAt: DateTime.now(),
        );

        await _reviewService.createReview(review);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis publié avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retourne true pour indiquer le succès
      }
    } catch (e) {
      debugPrint('❌ Erreur soumission avis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingReview != null
                              ? 'Modifier votre avis'
                              : 'Laisser un avis',
                          style: const TextStyle(
                            fontSize: AppFontSizes.xl,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.targetName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.sm,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Sélection de notation
              const Text(
                'Votre note',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: RatingStarsInput(
                  initialRating: _rating,
                  onRatingChanged: (rating) {
                    setState(() => _rating = rating);
                  },
                  size: 48,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Commentaire
              const Text(
                'Votre commentaire',
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience avec ${_getTargetTypeLabel()}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(widget.existingReview != null
                              ? 'Modifier'
                              : 'Publier'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
