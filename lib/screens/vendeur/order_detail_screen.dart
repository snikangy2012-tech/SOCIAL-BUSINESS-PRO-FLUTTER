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
import '../../utils/order_status_helper.dart';
import '../../utils/number_formatter.dart';
import 'assign_livreur_screen.dart';
import '../../widgets/system_ui_scaffold.dart';

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

      // 🚴 Si le nouveau statut est "ready", déclencher l'auto-assignment du livreur
      if (newStatus == 'ready') {
        debugPrint('🚀 Déclenchement auto-assignment livreur pour commande ${widget.orderId}');

        // Lancer l'auto-assignment en arrière-plan (ne pas bloquer l'UI)
        DeliveryService().autoAssignDeliveryToOrder(widget.orderId).then((success) {
          if (success) {
            debugPrint('✅ Auto-assignment livreur réussi');
            // Recharger la commande pour afficher les infos du livreur
            _loadOrder();
          } else {
            debugPrint('⚠️ Auto-assignment livreur échoué ou aucun livreur disponible');
          }
        }).catchError((error) {
          debugPrint('❌ Erreur auto-assignment: $error');
        });
      }

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

  // Naviguer vers l'écran d'assignation manuelle de livreur
  Future<void> _navigateToAssignLivreur() async {
    if (_order == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AssignLivreurScreen(
          orderIds: [widget.orderId],
        ),
      ),
    );

    // Si l'assignation a réussi, recharger la commande
    if (result == true && mounted) {
      _loadOrder();
    }
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
    return StatusInfo(
      OrderStatusHelper.getStatusLabel(status),
      OrderStatusHelper.getStatusColor(status),
    );
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
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Détail de la commande'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return SystemUIScaffold(
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

    return SystemUIScaffold(
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

            // Informations livreur (si livreur assigné)
            if (_order!.livreurId != null) _buildLivreurSection(),

            if (_order!.livreurId != null) const SizedBox(height: AppSpacing.md),

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
                        subtitle: Text(
                            '${item.quantity} x ${formatPriceWithCurrency(item.price, currency: 'FCFA')}'),
                        trailing: Flexible(
                          child: Text(
                            formatPriceWithCurrency(item.price * item.quantity, currency: 'FCFA'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSizes.lg,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
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
                  _buildSummaryRow(
                      'Sous-total', formatPriceWithCurrency(_order!.subtotal, currency: 'FCFA')),
                  _buildSummaryRow('Frais de livraison',
                      formatPriceWithCurrency(_order!.deliveryFee, currency: 'FCFA')),
                  const Divider(thickness: 2),
                  _buildSummaryRow(
                    'Total',
                    formatPriceWithCurrency(_order!.totalAmount, currency: 'FCFA'),
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

  // Section informations livreur
  Widget _buildLivreurSection() {
    return _buildSection(
      'Informations livreur',
      Column(
        children: [
          _buildInfoRow(
            Icons.delivery_dining,
            'Livreur',
            _order!.livreurName ?? 'Non disponible',
          ),
          if (_order!.livreurPhone != null) ...[
            const Divider(),
            _buildInfoRow(
              Icons.phone,
              'Téléphone',
              _order!.livreurPhone!,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                    onPressed: () async {
                      final uri = Uri.parse('tel:${_order!.livreurPhone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    tooltip: 'Appeler',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, color: AppColors.success),
                    onPressed: () async {
                      final phone = _order!.livreurPhone!.replaceAll(RegExp(r'\s+'), '');
                      final uri = Uri.parse(
                        'https://wa.me/$phone?text=Bonjour, concernant la livraison de la commande ${_order!.displayNumber}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    tooltip: 'WhatsApp',
                  ),
                ],
              ),
            ),
          ],
          const Divider(),
          _buildInfoRow(
            Icons.badge,
            'Statut livraison',
            _getDeliveryStatusLabel(),
          ),
        ],
      ),
    );
  }

  String _getDeliveryStatusLabel() {
    if (_delivery == null) return 'En préparation';
    switch (_delivery!.status.toLowerCase()) {
      case 'assigned':
        return 'Assignée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En cours';
      case 'delivered':
        return 'Livrée';
      default:
        return _delivery!.status;
    }
  }

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

  // Boutons d'action rapide selon le statut
  Widget _buildQuickActionButtons(String status) {
    switch (status) {
      case 'pending':
      case 'en_attente':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GROS bouton vert "Confirmer la commande"
            ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('confirmed'),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle, size: 28),
              label: const Text(
                '✅ Confirmer la commande',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton secondaire "Refuser"
            OutlinedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('cancelled'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Refuser la commande'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        );

      case 'confirmed':
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _updateStatus('preparing'),
          icon: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.inventory_2, size: 28),
          label: const Text(
            '📦 Commencer la préparation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );

      case 'preparing':
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _updateStatus('ready'),
          icon: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.done_all, size: 28),
          label: const Text(
            '✓ Produit prêt pour livraison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );

      case 'ready':
        // Commande prête, en attente d'assignation livreur
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning),
          ),
          child: Column(
            children: [
              const Icon(Icons.delivery_dining, size: 48, color: AppColors.warning),
              const SizedBox(height: 12),
              const Text(
                '🚴 Recherche d\'un livreur en cours...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande est prête et sera assignée automatiquement au livreur le plus proche',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Bouton pour assignation manuelle
              OutlinedButton.icon(
                onPressed: () => _navigateToAssignLivreur(),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Assigner manuellement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        );

      case 'en_cours':
      case 'in_delivery':
        // Commande en livraison
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.info),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, size: 40, color: AppColors.info),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚚 Commande en cours de livraison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Le livreur est en route',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'livree':
      case 'delivered':
        // Commande livrée
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.success),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 40, color: AppColors.success),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Commande livrée avec succès',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cette commande a été livrée au client',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'cancelled':
      case 'annulee':
        // Commande annulée
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.error),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel, size: 40, color: AppColors.error),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '❌ Commande annulée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cette commande a été annulée',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        // Autres statuts ou fallback
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : _showStatusChangeDialog,
          icon: const Icon(Icons.edit),
          label: const Text('Modifier le statut'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
    }
  }

  // Actions du bas
  Widget _buildBottomActions() {
    if (_order == null) return const SizedBox.shrink();

    final status = _order!.status.toLowerCase();

    // Actions rapides selon le statut
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
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
        bottom: true, // ✅ Force le respect de la barre système en bas
        minimum: const EdgeInsets.only(bottom: 16), // ✅ Minimum 16px en bas
        child: _buildQuickActionButtons(status),
      ),
    );
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
