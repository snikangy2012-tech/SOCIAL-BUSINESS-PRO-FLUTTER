// ===== lib/screens/admin/vendor_management_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../services/firebase_service.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ReviewService _reviewService = ReviewService();

  List<UserModel> _allVendors = [];
  List<UserModel> _filteredVendors = [];
  Map<String, double> _vendorRatings = {}; // Map vendorId -> rating
  bool _isLoading = false;
  String _selectedStatus = 'all'; // all, pending, approved, suspended
  String _sortBy = 'date'; // 'date', 'rating'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadVendors();
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
      _filterVendors();
    }
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer tous les utilisateurs de type vendeur depuis Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'vendeur')
          .get();

      final vendors = querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Charger les notes de chaque vendeur
      final ratings = <String, double>{};
      for (final vendor in vendors) {
        try {
          final rating = await _reviewService.getAverageRating(vendor.id, 'vendor');
          ratings[vendor.id] = rating;
        } catch (e) {
          debugPrint('⚠️ Erreur chargement note vendeur ${vendor.id}: $e');
          ratings[vendor.id] = 0.0;
        }
      }

      setState(() {
        _allVendors = vendors;
        _vendorRatings = ratings;
        _isLoading = false;
      });

      _filterVendors();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterVendors() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredVendors = _allVendors.where((vendor) {
        // Filter by search query
        final matchesQuery = query.isEmpty ||
            vendor.displayName.toLowerCase().contains(query) ||
            vendor.email.toLowerCase().contains(query) ||
            (vendor.phoneNumber?.toLowerCase().contains(query) ?? false);

        // Filter by status
        final vendorStatus = vendor.profile['status'] as String?;
        final matchesStatus = _selectedStatus == 'all' ||
            (vendorStatus?.toLowerCase() ?? 'pending') == _selectedStatus;

        return matchesQuery && matchesStatus;
      }).toList();

      // Trier selon le critère sélectionné
      if (_sortBy == 'rating') {
        _filteredVendors.sort((a, b) {
          final ratingA = _vendorRatings[a.id] ?? 0.0;
          final ratingB = _vendorRatings[b.id] ?? 0.0;
          return ratingB.compareTo(ratingA); // Décroissant
        });
      } else {
        _filteredVendors.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  Future<void> _updateVendorStatus(UserModel vendor, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Mettre à jour le statut dans Firestore
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: vendor.id,
        data: {
          'profile.status': newStatus,
        },
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Vendeur ${newStatus == 'approved' ? 'approuvé' : newStatus == 'suspended' ? 'suspendu' : 'mis à jour'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.orange,
          ),
        );
      }

      _loadVendors();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showVendorDetails(UserModel vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VendorDetailsSheet(
        vendor: vendor,
        onStatusUpdate: (newStatus) {
          Navigator.pop(context);
          _updateVendorStatus(vendor, newStatus);
        },
      ),
    );
  }

  Widget _buildVendorCard(UserModel vendor) {
    final vendorStatus = vendor.profile['status'] as String?;
    final status = vendorStatus?.toLowerCase() ?? 'pending';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showVendorDetails(vendor),
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
                    backgroundImage: vendor.profile['photoUrl'] != null
                        ? NetworkImage(vendor.profile['photoUrl'] as String)
                        : null,
                    child: vendor.profile['photoUrl'] == null
                        ? Text(
                            vendor.displayName.isNotEmpty
                                ? vendor.displayName[0].toUpperCase()
                                : 'V',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (vendor.phoneNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vendor.phoneNumber!,
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
              // Affichage de la note
              _buildRatingRow(vendor.id),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inscrit le ${_formatDate(vendor.createdAt)}',
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
                          onPressed: () => _updateVendorStatus(vendor, 'approved'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approuver'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _updateVendorStatus(vendor, 'suspended'),
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
                      onPressed: () => _updateVendorStatus(vendor, 'suspended'),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspendre'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  if (status == 'suspended')
                    TextButton.icon(
                      onPressed: () => _updateVendorStatus(vendor, 'approved'),
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

  Widget _buildRatingRow(String vendorId) {
    final rating = _vendorRatings[vendorId] ?? 0.0;
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

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allVendors.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'pending';
    }).length;
    final approvedCount = _allVendors.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'approved';
    }).length;
    final suspendedCount = _allVendors.where((v) {
      final status = v.profile['status'] as String?;
      return (status?.toLowerCase() ?? 'pending') == 'suspended';
    }).length;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Gestion Vendeurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _filterVendors();
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
            onPressed: _loadVendors,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Tous (${_allVendors.length})'),
            Tab(text: 'En attente ($pendingCount)'),
            Tab(text: 'Approuvés ($approvedCount)'),
            Tab(text: 'Suspendus ($suspendedCount)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
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
                          _filterVendors();
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
                _filterVendors();
              },
            ),
          ),

          // Vendor list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun vendeur trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVendors,
                        child: ListView.builder(
                          itemCount: _filteredVendors.length,
                          itemBuilder: (context, index) {
                            return _buildVendorCard(_filteredVendors[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ===== Vendor Details Sheet =====
class _VendorDetailsSheet extends StatefulWidget {
  final UserModel vendor;
  final Function(String) onStatusUpdate;

  const _VendorDetailsSheet({
    required this.vendor,
    required this.onStatusUpdate,
  });

  @override
  State<_VendorDetailsSheet> createState() => _VendorDetailsSheetState();
}

class _VendorDetailsSheetState extends State<_VendorDetailsSheet> {
  final ProductService _productService = ProductService();

  List<ProductModel> _vendorProducts = [];
  List<OrderModel> _vendorOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() => _isLoading = true);

    try {
      final products = await _productService.getVendorProducts(widget.vendor.id);
      final orders = await OrderService.getVendorOrders(widget.vendor.id);

      setState(() {
        _vendorProducts = products;
        _vendorOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _vendorOrders
        .where((o) => o.status == 'delivered' || o.status == 'completed')
        .fold<double>(0, (total, order) => total + order.totalAmount);

    final vendorStatus = widget.vendor.profile['status'] as String?;
    final status = vendorStatus?.toLowerCase() ?? 'pending';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: widget.vendor.profile['photoUrl'] != null
                      ? NetworkImage(widget.vendor.profile['photoUrl'] as String)
                      : null,
                  child: widget.vendor.profile['photoUrl'] == null
                      ? Text(
                          widget.vendor.displayName.isNotEmpty
                              ? widget.vendor.displayName[0].toUpperCase()
                              : 'V',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vendor.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.vendor.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.vendor.phoneNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.vendor.phoneNumber!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics
                        const Text(
                          'Statistiques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Produits',
                                '${_vendorProducts.length}',
                                Icons.inventory,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Commandes',
                                '${_vendorOrders.length}',
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Chiffre d\'affaires total',
                          '${totalRevenue.toStringAsFixed(0)} FCFA',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        const SizedBox(height: 24),

                        // Recent products
                        const Text(
                          'Produits récents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_vendorProducts.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucun produit',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ..._vendorProducts.take(3).map(
                                (product) => ListTile(
                                  leading: product.images.isNotEmpty
                                      ? Image.network(
                                          product.images.first,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        ),
                                  title: Text(product.name),
                                  subtitle: Text('${product.price.toStringAsFixed(0)} FCFA'),
                                  trailing: Text(
                                    'Stock: ${product.stock}',
                                    style: TextStyle(
                                      color: product.stock > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                if (status == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onStatusUpdate('approved'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approuver ce vendeur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onStatusUpdate('suspended'),
                      icon: const Icon(Icons.block),
                      label: const Text('Refuser ce vendeur'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (status == 'approved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onStatusUpdate('suspended'),
                      icon: const Icon(Icons.block),
                      label: const Text('Suspendre ce vendeur'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (status == 'suspended')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onStatusUpdate('approved'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Réactiver ce vendeur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

