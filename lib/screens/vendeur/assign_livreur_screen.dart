// ===== lib/screens/vendeur/assign_livreur_screen.dart =====
// �cran d'assignation manuelle de livreur par le vendeur

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/livreur_selection_service.dart';
import '../../services/order_assignment_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class AssignLivreurScreen extends StatefulWidget {
  final List<String> orderIds; // Liste des commandes à assigner

  const AssignLivreurScreen({
    super.key,
    required this.orderIds,
  });

  @override
  State<AssignLivreurScreen> createState() => _AssignLivreurScreenState();
}

class _AssignLivreurScreenState extends State<AssignLivreurScreen> {
  final LivreurSelectionService _selectionService = LivreurSelectionService();
  List<LivreurCandidate> _livreurs = [];
  LivreurCandidate? _selectedLivreur;
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;

  // Coordonn�es du vendeur (point de collecte)
  double? _pickupLat;
  double? _pickupLng;

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
  }

  Future<void> _loadLivreurs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connect�');
      }

      // Récupérer le profil vendeur pour obtenir les coordonnées
      final userDoc =
          await FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(userId).get();
      final userData = userDoc.data();
      final profile = userData?['profile'] as Map<String, dynamic>?;
      final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;
      final shopLocation = vendeurProfile?['shopLocation'] as Map<String, dynamic>?;

      if (shopLocation != null) {
        _pickupLat = (shopLocation['latitude'] as num?)?.toDouble();
        _pickupLng = (shopLocation['longitude'] as num?)?.toDouble();
      }

      // Si pas de coordonn�es, utiliser une position par d�faut (Abidjan)
      _pickupLat ??= 5.3167;
      _pickupLng ??= -4.0333;

      debugPrint('=� Position vendeur: $_pickupLat, $_pickupLng');

      // R�cup�rer tous les livreurs disponibles
      final livreurs = await _selectionService.getAvailableLivreurs(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        criteria: const LivreurSelectionCriteria(
          minRating: 0.0, // Afficher tous les livreurs
          minDeliveries: 0,
          maxDistance: 100.0, // Rayon large
        ),
      );

      setState(() {
        _livreurs = livreurs;
        _isLoading = false;
      });

      debugPrint(' ${_livreurs.length} livreur(s) charg�(s)');
    } catch (e) {
      debugPrint('L Erreur chargement livreurs: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _assignToLivreur() async {
    if (_selectedLivreur == null) {
      _showErrorSnackBar('Veuillez s�lectionner un livreur');
      return;
    }

    setState(() => _isAssigning = true);

    try {
      if (widget.orderIds.length == 1) {
        // Assignation simple
        await OrderAssignmentService.assignOrderToLivreur(
          orderId: widget.orderIds.first,
          livreurId: _selectedLivreur!.id,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Commande assign�e avec succ�s'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context, true);
      } else {
        // Assignation multiple
        final result = await OrderAssignmentService.assignMultipleOrdersToLivreur(
          orderIds: widget.orderIds,
          livreurId: _selectedLivreur!.id,
        );

        if (!mounted) return;

        final successCount = (result['success'] as List).length;
        final failedCount = (result['failed'] as List).length;

        if (failedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' $successCount commande(s) assign�e(s) avec succ�s'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          // Afficher un dialogue avec les d�tails
          _showAssignmentResults(result);
        }
      }
    } catch (e) {
      debugPrint('L Erreur assignation: $e');
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  void _showAssignmentResults(Map<String, dynamic> result) {
    final successCount = (result['success'] as List).length;
    final failedList = result['failed'] as List;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('R�sultat de l\'assignation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(' $successCount commande(s) assign�e(s)'),
            const SizedBox(height: 8),
            Text('L ${failedList.length} commande(s) �chou�e(s):'),
            const SizedBox(height: 8),
            ...failedList.map((failed) {
              final orderId = failed['orderId'] as String;
              final reason = failed['reason'] as String;
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '" ${orderId.substring(0, 8)}: $reason',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context, true); // Retourner � l'�cran pr�c�dent
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
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
              context.go('/vendeur-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: Text(
          widget.orderIds.length == 1
              ? 'Assigner un livreur'
              : 'Assigner ${widget.orderIds.length} commandes',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLivreurs,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _livreurs.isEmpty
                  ? _buildEmptyView()
                  : _buildLivreursList(),
      bottomNavigationBar: _selectedLivreur != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isAssigning ? null : _assignToLivreur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isAssigning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.orderIds.length == 1
                              ? 'Assigner la commande'
                              : 'Assigner ${widget.orderIds.length} commandes',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLivreurs,
              icon: const Icon(Icons.refresh),
              label: const Text('R�essayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun livreur disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Il n\'y a aucun livreur disponible pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLivreurs,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivreursList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _livreurs.length,
      itemBuilder: (context, index) {
        final livreur = _livreurs[index];
        final isSelected = _selectedLivreur?.id == livreur.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedLivreur = isSelected ? null : livreur;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Photo ou ic�ne
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        livreur.photoUrl != null ? NetworkImage(livreur.photoUrl!) : null,
                    child: livreur.photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                  ),
                  const SizedBox(width: 12),

                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom + Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                livreur.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (livreur.isTrusted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Fiable',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Note
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${livreur.rating.toStringAsFixed(1)} (${livreur.totalDeliveries} livraisons)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Distance
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              livreur.formattedDistance,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Disponibilit�
                        Row(
                          children: [
                            Icon(
                              livreur.canAcceptMore ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: livreur.canAcceptMore ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              livreur.availabilityStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: livreur.canAcceptMore ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Score
                        Row(
                          children: [
                            const Text(
                              'Score: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${livreur.score.toStringAsFixed(0)}/100',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '" ${livreur.trustLevel}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Checkbox
                  Radio<String>(
                    value: livreur.id,
                    groupValue: _selectedLivreur?.id,
                    onChanged: (value) {
                      setState(() {
                        _selectedLivreur = livreur;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

