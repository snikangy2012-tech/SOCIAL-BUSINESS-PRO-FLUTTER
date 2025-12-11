// ===== lib/screens/vendeur/refund_management_screen.dart =====
// Écran de gestion des remboursements - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/refund_model.dart';
import '../../services/refund_service.dart';
import '../../providers/auth_provider_firebase.dart';
import '../widgets/system_ui_scaffold.dart';

class RefundManagementScreen extends StatefulWidget {
  const RefundManagementScreen({super.key});

  @override
  State<RefundManagementScreen> createState() => _RefundManagementScreenState();
}

class _RefundManagementScreenState extends State<RefundManagementScreen> {
  String _selectedTab = 'all';
  final List<String> _tabs = [
    'all',
    'demande_envoyee',
    'approuvee',
    'produit_retourne',
    'rembourse',
    'refusee',
  ];

  String _getTabLabel(String tab) {
    switch (tab) {
      case 'all':
        return 'Toutes';
      case 'demande_envoyee':
        return 'En attente';
      case 'approuvee':
        return 'Approuvées';
      case 'produit_retourne':
        return 'Retournées';
      case 'rembourse':
        return 'Remboursées';
      case 'refusee':
        return 'Refusées';
      default:
        return tab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vendeurId = authProvider.user?.id;

    if (vendeurId == null) {
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Gestion des retours'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Onglets de filtrage
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: _tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(_getTabLabel(tab)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTab = tab);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Liste des remboursements
          Expanded(
            child: StreamBuilder<List<RefundModel>>(
              stream: RefundService.getRefundsForUser(
                userId: vendeurId,
                userType: 'vendeur',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_return,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Aucune demande de retour',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer selon l'onglet sélectionné
                final allRefunds = snapshot.data!;
                final filteredRefunds = _selectedTab == 'all'
                    ? allRefunds
                    : allRefunds.where((r) => r.status == _selectedTab).toList();

                if (filteredRefunds.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune demande dans cette catégorie',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filteredRefunds.length,
                  itemBuilder: (context, index) {
                    final refund = filteredRefunds[index];
                    return _buildRefundCard(refund);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundCard(RefundModel refund) {
    final statusEnum = RefundStatus.values.firstWhere(
      (s) => s.value == refund.status,
      orElse: () => RefundStatus.demandeEnvoyee,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showRefundDetails(refund),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${refund.orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          refund.buyerName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusEnum.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusEnum.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusEnum.icon,
                          size: 14,
                          color: statusEnum.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusEnum.label,
                          style: TextStyle(
                            color: statusEnum.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Raison
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      RefundReasons.getLabel(refund.reason),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Remboursement: ${refund.productAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Date
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(refund.requestedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Actions selon le statut
              if (refund.isPendingVendeurAction) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _refuseRefund(refund),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveRefund(refund),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        child: const Text('Approuver'),
                      ),
                    ),
                  ],
                ),
              ] else if (refund.isReturned) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markRefundCompleted(refund),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marquer comme remboursé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundDetails(RefundModel refund) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Détails du retour',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Informations client
                _buildDetailSection(
                  title: 'Client',
                  items: [
                    _buildDetailItem('Nom', refund.buyerName),
                    _buildDetailItem(
                      'Date de demande',
                      DateFormat('dd/MM/yyyy à HH:mm').format(refund.requestedAt),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Informations commande
                _buildDetailSection(
                  title: 'Commande',
                  items: [
                    _buildDetailItem(
                      'Numéro',
                      '#${refund.orderId.substring(0, 8)}',
                    ),
                    _buildDetailItem(
                      'Montant produit',
                      '${refund.productAmount.toStringAsFixed(0)} FCFA',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Raison du retour
                _buildDetailSection(
                  title: 'Raison du retour',
                  items: [
                    _buildDetailItem('Motif', RefundReasons.getLabel(refund.reason)),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  refund.description,
                  style: const TextStyle(fontSize: 14),
                ),

                // Images si disponibles
                if (refund.images.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Photos du produit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: refund.images.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          refund.images[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Frais de livraison
                _buildDetailSection(
                  title: 'Frais de livraison retour',
                  items: [
                    _buildDetailItem(
                      'Total aller-retour',
                      '${refund.deliveryFee.toStringAsFixed(0)} FCFA',
                    ),
                    _buildDetailItem(
                      'Votre part (50%)',
                      '${refund.vendeurDeliveryCharge.toStringAsFixed(0)} FCFA',
                    ),
                    _buildDetailItem(
                      'Part livreur (50%)',
                      '${refund.livreurDeliveryCharge.toStringAsFixed(0)} FCFA',
                    ),
                  ],
                ),

                // Note vendeur si refusé
                if (refund.vendeurNote != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailSection(
                    title: 'Votre note',
                    items: [],
                  ),
                  Text(
                    refund.vendeurNote!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRefund(RefundModel refund) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approuver le retour'),
        content: const Text(
          'Êtes-vous sûr de vouloir approuver cette demande de retour ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RefundService.approveRefund(refundId: refund.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Demande de retour approuvée'
                  : '❌ Erreur lors de l\'approbation',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refuseRefund(RefundModel refund) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le retour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du refus:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Raison du refus...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RefundService.refuseRefund(
        refundId: refund.id,
        vendeurNote: noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Demande de retour refusée'
                  : '❌ Erreur lors du refus',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markRefundCompleted(RefundModel refund) async {
    final referenceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le remboursement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant à rembourser: ${refund.productAmount.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Veuillez saisir la référence de transaction du remboursement:',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                hintText: 'Référence de transaction...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && referenceController.text.trim().isNotEmpty) {
      final success = await RefundService.markRefundCompleted(
        refundId: refund.id,
        refundReference: referenceController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Remboursement enregistré avec succès'
                  : '❌ Erreur lors de l\'enregistrement',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
