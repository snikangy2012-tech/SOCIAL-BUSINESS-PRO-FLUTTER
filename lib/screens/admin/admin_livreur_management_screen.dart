// ===== lib/screens/admin/admin_livreur_management_screen.dart =====
// Gestion des livreurs avec documents - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/review_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';

class AdminLivreurManagementScreen extends StatefulWidget {
  const AdminLivreurManagementScreen({super.key});

  @override
  State<AdminLivreurManagementScreen> createState() => _AdminLivreurManagementScreenState();
}

class _AdminLivreurManagementScreenState extends State<AdminLivreurManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ReviewService _reviewService = ReviewService();

  List<UserModel> _allLivreurs = [];
  List<UserModel> _filteredLivreurs = [];
  Map<String, double> _livreurRatings = {}; // Map livreurId -> rating
  bool _isLoading = false;
  String _selectedStatus = 'all';
  String _sortBy = 'date'; // 'date', 'rating'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLivreurs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = 'all';
            break;
          case 1:
            _selectedStatus = 'pending';
            break;
          case 2:
            _selectedStatus = 'approved';
            break;
          case 3:
            _selectedStatus = 'suspended';
            break;
        }
      });
      _filterLivreurs();
    }
  }

  Future<void> _loadLivreurs() async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'livreur')
          .get();

      final livreurs = querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Charger les notes de chaque livreur
      final ratings = <String, double>{};
      for (final livreur in livreurs) {
        try {
          final rating = await _reviewService.getAverageRating(livreur.id, 'livreur');
          ratings[livreur.id] = rating;
        } catch (e) {
          debugPrint('⚠️ Erreur chargement note livreur ${livreur.id}: $e');
          ratings[livreur.id] = 0.0;
        }
      }

      setState(() {
        _allLivreurs = livreurs;
        _livreurRatings = ratings;
        _isLoading = false;
      });

      _filterLivreurs();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterLivreurs() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredLivreurs = _allLivreurs.where((livreur) {
        final matchesQuery = query.isEmpty ||
            livreur.displayName.toLowerCase().contains(query) ||
            livreur.email.toLowerCase().contains(query) ||
            (livreur.phoneNumber?.toLowerCase().contains(query) ?? false);

        final livreurStatus = livreur.profile['status'] as String?;
        final matchesStatus = _selectedStatus == 'all' ||
            (livreurStatus?.toLowerCase() ?? 'pending') == _selectedStatus;

        return matchesQuery && matchesStatus;
      }).toList();

      // Trier selon le critère sélectionné
      if (_sortBy == 'rating') {
        _filteredLivreurs.sort((a, b) {
          final ratingA = _livreurRatings[a.id] ?? 0.0;
          final ratingB = _livreurRatings[b.id] ?? 0.0;
          return ratingB.compareTo(ratingA); // Décroissant
        });
      } else {
        _filteredLivreurs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  Future<void> _updateLivreurStatus(UserModel livreur, String newStatus) async {
    try {
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: livreur.id,
        data: {'profile.status': newStatus},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Livreur ${newStatus == 'approved' ? 'approuvé' : newStatus == 'suspended' ? 'suspendu' : 'mis à jour'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.orange,
          ),
        );
      }

      _loadLivreurs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showLivreurDetails(UserModel livreur) {
    context.push('/admin/livreur-detail/${livreur.id}');
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allLivreurs.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'pending';
    }).length;
    final approvedCount = _allLivreurs.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'approved';
    }).length;
    final suspendedCount = _allLivreurs.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'suspended';
    }).length;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Gestion Livreurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _filterLivreurs();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: _sortBy == 'date' ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Date d\'inscription'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 20,
                      color: _sortBy == 'rating' ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Note moyenne'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLivreurs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Tous (${_allLivreurs.length})'),
            Tab(text: 'En attente ($pendingCount)'),
            Tab(text: 'Approuvés ($approvedCount)'),
            Tab(text: 'Suspendus ($suspendedCount)'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email, téléphone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLivreurs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                setState(() {});
                _filterLivreurs();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLivreurs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delivery_dining_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun livreur trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLivreurs,
                        child: ListView.builder(
                          itemCount: _filteredLivreurs.length,
                          itemBuilder: (context, index) {
                            return _buildLivreurCard(_filteredLivreurs[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurCard(UserModel livreur) {
    final livreurStatus = livreur.profile['status'] as String?;
    final status = livreurStatus?.toLowerCase() ?? 'pending';
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approuvé';
        statusIcon = Icons.check_circle;
        break;
      case 'suspended':
        statusColor = Colors.red;
        statusText = 'Suspendu';
        statusIcon = Icons.block;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = status;
        statusIcon = Icons.help;
    }

    final vehicleType = livreur.profile['vehicleType'] as String? ?? 'Non spécifié';
    final hasDocuments = livreur.profile['documents'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showLivreurDetails(livreur),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          livreur.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          livreur.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (livreur.phoneNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            livreur.phoneNumber!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.motorcycle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Véhicule: $vehicleType',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(
                    hasDocuments ? Icons.file_present : Icons.file_copy_outlined,
                    size: 16,
                    color: hasDocuments ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasDocuments ? 'Documents fournis' : 'Documents manquants',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasDocuments ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Affichage de la note
              _buildRatingRow(livreur.id),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inscrit le ${_formatDate(livreur.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (status == 'pending')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateLivreurStatus(livreur, 'approved'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approuver'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _updateLivreurStatus(livreur, 'suspended'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Refuser'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  if (status == 'approved')
                    TextButton.icon(
                      onPressed: () => _updateLivreurStatus(livreur, 'suspended'),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspendre'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  if (status == 'suspended')
                    TextButton.icon(
                      onPressed: () => _updateLivreurStatus(livreur, 'approved'),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Réactiver'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRatingRow(String livreurId) {
    final rating = _livreurRatings[livreurId] ?? 0.0;
    final hasRating = rating > 0;

    Color ratingColor;
    String ratingLabel;
    if (rating >= 4.5) {
      ratingColor = AppColors.success;
      ratingLabel = 'Excellent';
    } else if (rating >= 4.0) {
      ratingColor = AppColors.info;
      ratingLabel = 'Bon';
    } else if (rating >= 3.5) {
      ratingColor = AppColors.warning;
      ratingLabel = 'Correct';
    } else if (rating >= 3.0) {
      ratingColor = Colors.orange;
      ratingLabel = 'À améliorer';
    } else if (hasRating) {
      ratingColor = AppColors.error;
      ratingLabel = 'Non recommandé';
    } else {
      ratingColor = AppColors.textSecondary;
      ratingLabel = 'Aucun avis';
    }

    return Row(
      children: [
        Icon(Icons.star, size: 16, color: ratingColor),
        const SizedBox(width: 8),
        Text(
          hasRating ? '${rating.toStringAsFixed(1)}/5.0' : 'Aucune note',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ratingColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ratingColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ratingColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            ratingLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ratingColor,
            ),
          ),
        ),
      ],
    );
  }
}

