// ===== lib/screens/vendeur/sale_detail_screen.dart =====
// Écran de détail d'une vente - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/order_status_helper.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  OrderModel? _sale;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📄 Chargement détails vente: ${widget.saleId}');

      final doc = await _db.collection(FirebaseCollections.orders).doc(widget.saleId).get();

      if (!doc.exists) {
        throw Exception('Vente introuvable');
      }

      _sale = OrderModel.fromFirestore(doc);

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ Détails vente chargés');
    } catch (e) {
      debugPrint('❌ Erreur chargement détails: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Vérifier si la commande peut être annulée
  /// Une commande peut être annulée si elle n'a pas encore été assignée à un livreur
  bool _canCancelOrder() {
    if (_sale == null) return false;

    // La commande ne peut pas être annulée si elle est déjà livrée ou déjà annulée
    if (_sale!.status == 'livree' ||
        _sale!.status == 'delivered' ||
        _sale!.status == 'annulee' ||
        _sale!.status == 'cancelled') {
      return false;
    }

    // La commande peut être annulée si elle n'a pas de livreur assigné
    return _sale!.livreurId == null || _sale!.livreurId!.isEmpty;
  }

  /// Annuler la commande
  Future<void> _cancelOrder() async {
    if (_sale == null) return;

    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette commande ? '
          'Cette action libérera le stock réservé et ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🚫 Annulation commande: ${_sale!.id}');

      // Utiliser le OrderService pour annuler la commande
      // Cela libérera automatiquement le stock réservé
      await OrderService.cancelOrder(_sale!.id, _sale!.vendeurId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande annulée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );

        // Recharger les détails
        await _loadSaleDetails();
      }
    } catch (e) {
      debugPrint('❌ Erreur annulation commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Détails de la vente'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/vendeur-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaleDetails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
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
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSaleDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_sale == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête avec statut
          _buildHeader(),

          const SizedBox(height: 16),

          // Informations client
          _buildSection(
            'Informations Client',
            Icons.person,
            [
              _buildInfoRow('Nom', _sale!.buyerName),
              _buildInfoRow('Téléphone', _sale!.buyerPhone),
              if (_sale!.deliveryAddress.isNotEmpty)
                _buildInfoRow('Adresse', _sale!.deliveryAddress),
            ],
          ),

          const SizedBox(height: 16),

          // Informations boutique (ramassage)
          _buildSection(
            'Point de Ramassage',
            Icons.store,
            [
              if (_sale!.vendeurShopName != null)
                _buildInfoRow('Boutique', _sale!.vendeurShopName!),
              if (_sale!.vendeurPhone != null) _buildInfoRow('Téléphone', _sale!.vendeurPhone!),
              if (_sale!.pickupLatitude != null && _sale!.pickupLongitude != null)
                _buildInfoRow(
                  'GPS',
                  '${_sale!.pickupLatitude!.toStringAsFixed(4)}, ${_sale!.pickupLongitude!.toStringAsFixed(4)}',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Articles commandés
          _buildSection(
            'Articles Commandés',
            Icons.shopping_bag,
            [
              ..._sale!.items.map((item) => _buildItemCard(item)),
            ],
          ),

          const SizedBox(height: 16),

          // Résumé financier
          _buildFinancialSummary(),

          if (_sale!.notes != null && _sale!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              'Notes',
              Icons.note,
              [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _sale!.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Historique
          _buildTimelineSection(),

          // Bouton d'annulation (si applicable)
          if (_canCancelOrder()) ...[
            const SizedBox(height: 24),
            _buildCancelButton(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Commande ${_sale!.displayNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(_sale!.status),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(_sale!.createdAt),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItemModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Image produit
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.productImage != null && item.productImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: AppColors.textLight);
                      },
                    ),
                  )
                : const Icon(Icons.image, color: AppColors.textLight),
          ),

          const SizedBox(width: 12),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPriceWithCurrency(item.price, currency: 'FCFA')} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Prix total
          Text(
            formatPriceWithCurrency(item.price * item.quantity, currency: 'FCFA'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Sous-total', _sale!.subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Frais de livraison', _sale!.deliveryFee),
          if (_sale!.discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Réduction', -_sale!.discount, color: AppColors.success),
          ],
          const Divider(height: 24),
          _buildSummaryRow(
            'TOTAL',
            _sale!.totalAmount,
            isBold: true,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Flexible(
          child: Text(
            formatPriceWithCurrency(amount, currency: 'FCFA'),
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.timeline, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Historique',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildTimelineItem(
            'Commande créée',
            _sale!.createdAt,
            Icons.add_shopping_cart,
            AppColors.primary,
          ),
          if (_sale!.updatedAt != null)
            _buildTimelineItem(
              'Dernière mise à jour',
              _sale!.updatedAt!,
              Icons.update,
              AppColors.info,
            ),
          if (_sale!.deliveredAt != null && _sale!.status == 'livree')
            _buildTimelineItem(
              'Livrée',
              _sale!.deliveredAt!,
              Icons.check_circle,
              AppColors.success,
            ),
          if (_sale!.cancelledAt != null && _sale!.status == 'annulee')
            _buildTimelineItem(
              'Annulée',
              _sale!.cancelledAt!,
              Icons.cancel,
              AppColors.error,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime dateTime,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
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
                  DateFormat('dd/MM/yyyy à HH:mm').format(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cancelOrder,
        icon: const Icon(Icons.cancel_outlined),
        label: const Text(
          'Annuler cette commande',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    // ✅ Utiliser le helper centralisé pour les statuts
    return OrderStatusHelper.statusBadge(status);
  }
}
