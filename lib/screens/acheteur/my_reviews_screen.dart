// ===== lib/screens/acheteur/my_reviews_screen.dart =====
// Écran des avis laissés par l'acheteur - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _productReviews = [];
  List<ReviewModel> _vendorReviews = [];
  List<ReviewModel> _livreurReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Charger tous les avis de l'utilisateur
      // ✅ FIX: Pas de orderBy pour éviter erreur index composite Firestore
      // On tri en mémoire après le chargement
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.reviews)
          .where('reviewerId', isEqualTo: userId)
          .get();

      final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();

      // Tri en mémoire par date décroissante
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _productReviews = reviews.where((r) => r.targetType == 'product').toList();
          _vendorReviews = reviews.where((r) => r.targetType == 'vendor').toList();
          _livreurReviews = reviews.where((r) => r.targetType == 'livreur').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement avis: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/acheteur-home');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mes avis'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white, // Indicateur blanc sur fond orange
          labelColor: Colors.white, // Texte blanc quand actif
          unselectedLabelColor: Colors.white70, // Texte blanc semi-transparent quand inactif
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: 'Tous (${_allReviews.length})'),
            Tab(text: 'Produits (${_productReviews.length})'),
            Tab(text: 'Vendeurs (${_vendorReviews.length})'),
            Tab(text: 'Livreurs (${_livreurReviews.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsList(_allReviews),
                _buildReviewsList(_productReviews),
                _buildReviewsList(_vendorReviews),
                _buildReviewsList(_livreurReviews),
              ],
            ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos avis apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type + Date
            Row(
              children: [
                _buildTypeChip(review.targetType),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target info (product/vendor/livreur)
            FutureBuilder(
              future: _getTargetInfo(review.targetId, review.targetType),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildTargetInfo(snapshot.data as Map<String, dynamic>, review.targetType);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 12),

            // Rating
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${review.rating}/5',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comment
            if (review.comment.isNotEmpty) ...[
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Response from vendor (if any)
            if (review.response != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Réponse du vendeur',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.response!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
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

  Widget _buildTypeChip(String type) {
    IconData icon;
    String label;
    Color color;

    switch (type) {
      case 'product':
        icon = Icons.shopping_bag;
        label = 'Produit';
        color = AppColors.primary;
        break;
      case 'vendor':
        icon = Icons.store;
        label = 'Vendeur';
        color = AppColors.success;
        break;
      case 'livreur':
        icon = Icons.delivery_dining;
        label = 'Livreur';
        color = AppColors.info;
        break;
      default:
        icon = Icons.help_outline;
        label = 'Autre';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(Map<String, dynamic> info, String targetType) {
    return InkWell(
      onTap: () {
        if (targetType == 'product') {
          context.push('/acheteur/product/${info['id']}');
        } else if (targetType == 'vendor') {
          context.push('/acheteur/vendor/${info['id']}');
        }
      },
      child: Row(
        children: [
          // Image/Icon
          if (info['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                info['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      targetType == 'product' ? Icons.shopping_bag : Icons.store,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                targetType == 'product' ? Icons.shopping_bag : Icons.store,
                color: Colors.grey[400],
              ),
            ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              info['name'] ?? 'Inconnu',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Arrow
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getTargetInfo(String targetId, String targetType) async {
    try {
      if (targetType == 'product') {
        final doc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.products)
            .doc(targetId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'id': targetId,
            'name': data['name'] ?? 'Produit inconnu',
            'imageUrl': (data['images'] as List?)?.isNotEmpty == true ? data['images'][0] : null,
          };
        }
      } else if (targetType == 'vendor') {
        final doc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(targetId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'id': targetId,
            'name': data['profile']?['vendeurProfile']?['businessName'] ?? 'Vendeur inconnu',
            'imageUrl': data['photoURL'],
          };
        }
      } else if (targetType == 'livreur') {
        final doc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(targetId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'id': targetId,
            'name': data['displayName'] ?? 'Livreur inconnu',
            'imageUrl': data['photoURL'],
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération info: $e');
    }

    return {
      'id': targetId,
      'name': 'Inconnu',
      'imageUrl': null,
    };
  }
}

