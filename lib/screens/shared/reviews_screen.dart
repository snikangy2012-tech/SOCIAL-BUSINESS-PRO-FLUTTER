// ===== lib/screens/shared/reviews_screen.dart =====
import 'package:flutter/material.dart';

import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../config/constants.dart';

class ReviewsScreen extends StatefulWidget {
  final String targetId; // Product ID, Vendor ID, or Livreur ID
  final String targetType; // 'product', 'vendor', 'livreur'

  const ReviewsScreen({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();

  late TabController _tabController;

  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _filteredReviews = [];
  bool _isLoading = true;

  double _averageRating = 0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _filterReviews(_tabController.index);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      List<ReviewModel> reviews;

      switch (widget.targetType) {
        case 'product':
          reviews = await _reviewService.getReviewsByProduct(widget.targetId);
          break;
        case 'vendor':
          reviews = await _reviewService.getReviewsByVendor(widget.targetId);
          break;
        case 'livreur':
          reviews = await _reviewService.getReviewsByLivreur(widget.targetId);
          break;
        default:
          reviews = [];
      }

      setState(() {
        _allReviews = reviews;
        _isLoading = false;
      });

      _calculateStatistics();
      _filterReviews(_tabController.index);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _calculateStatistics() {
    if (_allReviews.isEmpty) {
      _averageRating = 0;
      _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    // Calculate average rating
    final totalRating = _allReviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    _averageRating = totalRating / _allReviews.length;

    // Calculate rating distribution
    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _allReviews) {
      _ratingDistribution[review.rating] = (_ratingDistribution[review.rating] ?? 0) + 1;
    }

    setState(() {});
  }

  void _filterReviews(int tabIndex) {
    setState(() {
      if (tabIndex == 0) {
        // All reviews
        _filteredReviews = List.from(_allReviews);
      } else {
        // Filter by star rating (5, 4, 3, 2, 1)
        final starRating = 6 - tabIndex;
        _filteredReviews = _allReviews.where((r) => r.rating == starRating).toList();
      }

      // Sort by date (newest first)
      _filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Widget _buildRatingOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Average rating
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _averageRating.floor()
                            ? Icons.star
                            : index < _averageRating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_allReviews.length} avis',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Rating distribution
            Expanded(
              flex: 3,
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = _ratingDistribution[star] ?? 0;
                  final percentage = _allReviews.isEmpty
                      ? 0.0
                      : count / _allReviews.length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$count',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(review.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (review.response != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.store,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.targetType == 'product'
                              ? 'Réponse du vendeur'
                              : 'Réponse',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.response!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.targetType == 'product'
              ? 'Avis produit'
              : widget.targetType == 'vendor'
                  ? 'Avis vendeur'
                  : 'Avis livreur',
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Tous (${_allReviews.length})'),
            Tab(text: '5⭐ (${_ratingDistribution[5]})'),
            Tab(text: '4⭐ (${_ratingDistribution[4]})'),
            Tab(text: '3⭐ (${_ratingDistribution[3]})'),
            Tab(text: '2⭐ (${_ratingDistribution[2]})'),
            Tab(text: '1⭐ (${_ratingDistribution[1]})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Rating overview
                _buildRatingOverview(),

                // Reviews list
                Expanded(
                  child: _filteredReviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun avis',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReviews,
                          child: ListView.builder(
                            itemCount: _filteredReviews.length,
                            itemBuilder: (context, index) {
                              return _buildReviewCard(_filteredReviews[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}