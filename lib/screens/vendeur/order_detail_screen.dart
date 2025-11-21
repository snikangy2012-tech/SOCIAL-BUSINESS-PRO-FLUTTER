// ===== lib/screens/vendeur/order_detail.dart =====
// Détail d'une commande vendeur - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/order_model.dart';
import '../../models/delivery_model.dart';
import '../../services/order_service.dart';
import '../../services/delivery_service.dart';
import '../../services/review_service.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/review_dialog.dart';

class OrderDetail extends StatefulWidget {
  final String orderId;

  const OrderDetail({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  OrderModel? _order;
  DeliveryModel? _delivery;
  bool _isLoading = true;
  bool _isLoadingDelivery = false;
  bool _isUpdating = false;
  String? _selectedNewStatus;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  // Charger la commande
  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      final order = await OrderService.getOrderById(widget.orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });

      // Charger la livraison si la commande est en livraison ou livrée
      if (_order!.status.toLowerCase() == 'in_delivery' ||
          _order!.status.toLowerCase() == 'delivered') {
        _loadDelivery();
      }
    } catch (e) {
      debugPrint('Erreur chargement commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Charger la livraison associée à la commande
  Future<void> _loadDelivery() async {
    setState(() => _isLoadingDelivery = true);

    try {
      final delivery = await DeliveryService.getDeliveryByOrderId(widget.orderId);
      if (mounted) {
        setState(() {
          _delivery = delivery;
          _isLoadingDelivery = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement livraison: $e');
      if (mounted) {
        setState(() => _isLoadingDelivery = false);
      }
    }
  }

  // Mettre à jour le statut
  Future<void> _updateStatus(String newStatus) async {
    if (_order == null) return;

    setState(() => _isUpdating = true);

    try {
      await OrderService.updateOrderStatus(
        widget.orderId,
        newStatus,
      );

      // ✅ Recharger complètement la commande depuis Firestore pour avoir les données à jour
      await _loadOrder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Statut mis à jour avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur mise à jour statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isUpdating = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // Afficher le dialogue de changement de statut
  void _showStatusChangeDialog() {
    final availableStatuses = _getAvailableStatuses();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) {
            final statusInfo = _getStatusInfo(status);
            return RadioListTile<String>(
              title: Text(statusInfo.label),
              value: status,
              groupValue: _selectedNewStatus,
              activeColor: statusInfo.color,
              onChanged: (value) {
                setState(() => _selectedNewStatus = value);
                Navigator.pop(context);
                _confirmStatusChange(value!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  // Confirmer le changement de statut
  void _confirmStatusChange(String newStatus) {
    final statusInfo = _getStatusInfo(newStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Passer la commande à "${statusInfo.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: statusInfo.color,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // Obtenir les statuts disponibles selon le statut actuel
  List<String> _getAvailableStatuses() {
    if (_order == null) return [];

    switch (_order!.status.toLowerCase()) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['preparing', 'cancelled'];
      case 'preparing':
        return ['ready', 'cancelled'];
      case 'ready':
        return ['in_delivery', 'cancelled'];
      case 'in_delivery':
        return ['delivered', 'cancelled'];
      default:
        return [];
    }
  }

  // Obtenir les informations de statut
  StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusInfo('En attente', AppColors.warning);
      case 'confirmed':
        return StatusInfo('Confirmée', AppColors.info);
      case 'preparing':
        return StatusInfo('En préparation', AppColors.primary);
      case 'ready':
        return StatusInfo('Prêt', AppColors.success);
      case 'in_delivery':
        return StatusInfo('En livraison', AppColors.secondary);
      case 'delivered':
        return StatusInfo('Livrée', AppColors.success);
      case 'cancelled':
        return StatusInfo('Annulée', AppColors.error);
      default:
        return StatusInfo(status, AppColors.textSecondary);
    }
  }

  // Appeler le client
  Future<void> _callCustomer() async {
    if (_order?.buyerPhone == null) return;

    final uri = Uri.parse('tel:${_order!.buyerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Envoyer un WhatsApp
  Future<void> _whatsappCustomer() async {
    if (_order?.buyerPhone == null) return;

    final phone = _order!.buyerPhone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse(
      'https://wa.me/$phone?text=Bonjour, concernant votre commande ${_order!.displayNumber}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Copier le numéro de commande
  void _copyOrderNumber() {
    if (_order == null) return;

    Clipboard.setData(ClipboardData(text: _order!.orderNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Numéro de commande copié')),
    );
  }

  // Noter le livreur
  Future<void> _rateLivreur() async {
    if (_delivery == null || _delivery!.livreurId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorId = authProvider.user?.id;

    if (vendorId == null) return;

    // Vérifier si le vendeur a déjà noté ce livreur pour cette livraison
    final reviewService = ReviewService();
    final hasReviewed = await reviewService.hasUserReviewed(
      vendorId,
      _delivery!.livreurId!,
      'livreur',
    );

    if (!mounted) return;

    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà noté ce livreur'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    // Afficher le dialog de notation
    final result = await ReviewDialog.show(
      context,
      targetId: _delivery!.livreurId!,
      targetType: 'livreur',
      targetName: 'Livreur',
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre évaluation !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de la commande'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail de la commande'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Commande introuvable'),
        ),
      );
    }

    final statusInfo = _getStatusInfo(_order!.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Détail de la commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyOrderNumber,
            tooltip: 'Copier le numéro',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro et statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commande ${_order!.displayNumber}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.xl,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatDate(_order!.createdAt),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: statusInfo.color),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            color: statusInfo.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Informations client
            _buildSection(
              'Informations client',
              Column(
                children: [
                  _buildInfoRow(
                    Icons.person,
                    'Nom',
                    _order!.buyerName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.phone,
                    'Téléphone',
                    _order!.buyerPhone,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, color: AppColors.primary),
                          onPressed: _callCustomer,
                          tooltip: 'Appeler',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: AppColors.success),
                          onPressed: _whatsappCustomer,
                          tooltip: 'WhatsApp',
                        ),
                      ],
                    ),
                  ),
                  if (_order!.deliveryAddress.isNotEmpty) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.location_on,
                      'Adresse',
                      _order!.deliveryAddress,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Noter le livreur (si commande livrée et livreur assigné)
            if (_order!.status.toLowerCase() == 'delivered' &&
                _delivery != null &&
                _delivery!.livreurId != null)
              _buildRateLivreurSection(),

            if (_order!.status.toLowerCase() == 'delivered' &&
                _delivery != null &&
                _delivery!.livreurId != null)
              const SizedBox(height: AppSpacing.md),

            // Articles commandés
            _buildSection(
              'Articles (${_order!.items.length})',
              Column(
                children: _order!.items.map((item) {
                  return Column(
                    children: [
                      ListTile(
                        leading: item.productImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Image.network(
                                  item.productImage!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.image),
                              ),
                        title: Text(item.productName),
                        subtitle: Text('${item.quantity} x ${_formatPrice(item.price)}'),
                        trailing: Text(
                          _formatPrice(item.price * item.quantity),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppFontSizes.lg,
                          ),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Résumé financier
            _buildSection(
              'Résumé',
              Column(
                children: [
                  _buildSummaryRow('Sous-total', _formatPrice(_order!.subtotal)),
                  _buildSummaryRow('Frais de livraison', _formatPrice(_order!.deliveryFee)),
                  const Divider(thickness: 2),
                  _buildSummaryRow(
                    'Total',
                    _formatPrice(_order!.totalAmount),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                'Notes',
                Text(_order!.notes!),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // Section
  // Section pour noter le livreur
  Widget _buildRateLivreurSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évaluation de la livraison',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Votre avis sur le livreur aide à améliorer la qualité du service',
                    style: TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _rateLivreur,
              icon: const Icon(Icons.star),
              label: const Text('Noter le livreur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          content,
        ],
      ),
    );
  }

  // Ligne d'information
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Ligne de résumé
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? AppFontSizes.lg : AppFontSizes.md,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? AppFontSizes.xl : AppFontSizes.md,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Actions du bas
  Widget _buildBottomActions() {
    final availableStatuses = _getAvailableStatuses();

    if (availableStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: _isUpdating ? null : _showStatusChangeDialog,
          icon: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.edit),
          label: const Text('Modifier le statut'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }

  // Formater le prix
  String _formatPrice(num price) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // Formater la date
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }
}

// Classe pour les informations de statut
class StatusInfo {
  final String label;
  final Color color;

  StatusInfo(this.label, this.color);
}