// ===== lib/screens/admin/admin_livreur_detail_screen.dart =====
// Détails d'un livreur avec visualisation des documents - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/review_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class AdminLivreurDetailScreen extends StatefulWidget {
  final String livreurId;

  const AdminLivreurDetailScreen({
    super.key,
    required this.livreurId,
  });

  @override
  State<AdminLivreurDetailScreen> createState() => _AdminLivreurDetailScreenState();
}

class _AdminLivreurDetailScreenState extends State<AdminLivreurDetailScreen> {
  final ReviewService _reviewService = ReviewService();
  UserModel? _livreur;
  bool _isLoading = true;
  Map<String, dynamic>? _documents;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadLivreurDetails();
  }

  Future<void> _loadLivreurDetails() async {
    setState(() => _isLoading = true);

    try {
      // Charger les infos du livreur
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(widget.livreurId)
          .get();

      if (doc.exists) {
        _livreur = UserModel.fromFirestore(doc);
        _documents = _livreur!.profile['documents'] as Map<String, dynamic>?;

        // Charger les statistiques de livraison
        final deliveriesSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.deliveries)
            .where('livreurId', isEqualTo: widget.livreurId)
            .get();

        int totalDeliveries = deliveriesSnapshot.docs.length;
        int completedDeliveries =
            deliveriesSnapshot.docs.where((doc) => doc.data()['status'] == 'delivered').length;

        // Calculer les revenus (estimation basée sur les livraisons)
        double totalEarnings = completedDeliveries * 500.0; // 500 FCFA par livraison (exemple)

        // Charger la note moyenne réelle depuis ReviewService
        double averageRating = 0.0;
        try {
          averageRating = await _reviewService.getAverageRating(widget.livreurId, 'livreur');
          debugPrint('⭐ Note livreur chargée: $averageRating');
        } catch (e) {
          debugPrint('⚠️ Erreur chargement note: $e');
        }

        _statistics = {
          'totalDeliveries': totalDeliveries,
          'completedDeliveries': completedDeliveries,
          'totalEarnings': totalEarnings,
          'averageRating': averageRating,
        };
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erreur chargement détails livreur: $e');
      setState(() => _isLoading = false);
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: widget.livreurId,
        data: {'profile.status': newStatus},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _loadLivreurDetails();
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

  String _getStatusText(String? status) {
    switch (status?.toLowerCase() ?? 'pending') {
      case 'approved':
        return 'Approuvé';
      case 'pending':
        return 'En attente';
      case 'suspended':
        return 'Suspendu';
      default:
        return status ?? 'Inconnu';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? 'pending') {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        title: const Text('Détails Livreur'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_livreur == null) {
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
        title: const Text('Détails Livreur'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Text('Livreur introuvable'),
        ),
      );
    }

    final status = _livreur!.profile['status'] as String?;
    final vehicleType = _livreur!.profile['vehicleType'] as String? ?? 'Non spécifié';
    final vehicleNumber = _livreur!.profile['vehicleNumber'] as String? ?? 'Non spécifié';

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
        title: const Text('Détails Livreur'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              if (status != 'approved')
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Approuver'),
                    ],
                  ),
                ),
              if (status != 'suspended')
                const PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Suspendre'),
                    ],
                  ),
                ),
              if (status == 'suspended')
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Réactiver'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'approve':
                  _updateStatus('approved');
                  break;
                case 'suspend':
                  _updateStatus('suspended');
                  break;
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLivreurDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations personnelles
              _buildInfoCard(),
              const SizedBox(height: 16),

              // Statistiques
              if (_statistics != null) ...[
                _buildStatisticsCard(),
                const SizedBox(height: 16),
              ],

              // Documents
              _buildDocumentsSection(),
              const SizedBox(height: 16),

              // Actions rapides
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final status = _livreur!.profile['status'] as String?;
    final vehicleType = _livreur!.profile['vehicleType'] as String? ?? 'Non spécifié';
    final vehicleNumber = _livreur!.profile['vehicleNumber'] as String? ?? 'Non spécifié';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _livreur!.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(status)),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', _livreur!.email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Téléphone', _livreur!.phoneNumber ?? 'Non renseigné'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.motorcycle, 'Type de véhicule', vehicleType),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.confirmation_number, 'Immatriculation', vehicleNumber),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Inscrit le',
              '${_livreur!.createdAt.day}/${_livreur!.createdAt.month}/${_livreur!.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Livraisons totales',
                    _statistics!['totalDeliveries'].toString(),
                    Icons.local_shipping,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Complétées',
                    _statistics!['completedDeliveries'].toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Revenus estimés',
                    '${_statistics!['totalEarnings'].toStringAsFixed(0)} FCFA',
                    Icons.account_balance_wallet,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Note moyenne',
                    '${_statistics!['averageRating'].toStringAsFixed(1)}/5.0',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_documents == null || _documents!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.file_copy_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun document fourni',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildDocumentItem(
                'Permis de conduire',
                'drivingLicense',
                Icons.credit_card,
              ),
              const SizedBox(height: 12),
              _buildDocumentItem(
                'Carte grise',
                'vehicleRegistration',
                Icons.description,
              ),
              const SizedBox(height: 12),
              _buildDocumentItem(
                'Assurance',
                'insurance',
                Icons.verified_user,
              ),
              const SizedBox(height: 12),
              _buildDocumentItem(
                'Pièce d\'identité',
                'idCard',
                Icons.badge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String label, String key, IconData icon) {
    final documentUrl = _documents?[key] as String?;
    final hasDocument = documentUrl != null && documentUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDocument
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDocument
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasDocument ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDocument ? 'Document fourni' : 'Document manquant',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasDocument ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          if (hasDocument)
            IconButton(
              icon: const Icon(Icons.visibility, color: AppColors.primary),
              onPressed: () {
                // TODO: Ouvrir le document (Firebase Storage URL ou autre)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ouverture du document: $documentUrl'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final status = _livreur!.profile['status'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('approved'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approuver le livreur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            if (status == 'approved') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('suspended'),
                  icon: const Icon(Icons.block),
                  label: const Text('Suspendre le livreur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
            if (status == 'suspended')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('approved'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Réactiver le livreur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

