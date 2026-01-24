// ===== lib/screens/acheteur/pickup_qr_screen.dart =====
// Écran d'affichage du QR code de retrait - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../services/firebase_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class PickupQRScreen extends StatefulWidget {
  final String orderId;

  const PickupQRScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PickupQRScreen> createState() => _PickupQRScreenState();
}

class _PickupQRScreenState extends State<PickupQRScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final orderDoc = await FirebaseService.getDocument(
        collection: FirebaseCollections.orders,
        docId: widget.orderId,
      );

      if (orderDoc == null) {
        setState(() {
          _errorMessage = 'Commande introuvable';
          _isLoading = false;
        });
        return;
      }

      // Vérifier que c'est bien une commande Click & Collect
      final deliveryMethod = orderDoc['deliveryMethod'] as String?;
      if (deliveryMethod != 'store_pickup') {
        setState(() {
          _errorMessage = 'Cette commande n\'est pas en mode Click & Collect';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _orderData = orderDoc;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement commande: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/acheteur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('QR Code de retrait'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _buildQRContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRContent() {
    final qrCode = _orderData!['pickupQRCode'] as String?;
    final displayNumber = _orderData!['displayNumber'] as int;
    final status = _orderData!['status'] as String;
    final totalAmount = (_orderData!['totalAmount'] as num).toDouble();
    final items = _orderData!['items'] as List<dynamic>;
    final pickedUpAt = _orderData!['pickedUpAt'] as Timestamp?;

    // Si déjà récupéré
    if (pickedUpAt != null) {
      return _buildAlreadyPickedUp(pickedUpAt);
    }

    // Si pas encore prêt
    if (status == 'pending' || status == 'confirmed') {
      return _buildNotReadyYet(status);
    }

    // Si pas de QR code
    if (qrCode == null) {
      return _buildNoQRCode();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Statut
          _buildStatusBadge(status),
          const SizedBox(height: 24),

          // QR Code
          Card(
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Commande #$displayNumber',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Présentez ce code au vendeur lors du retrait',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Détails de la commande
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text(
                        'Détails de la commande',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Articles
                  ...items.map((item) {
                    final itemMap = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${itemMap['quantity']}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              itemMap['productName'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            formatPriceWithCurrency(
                              (itemMap['price'] as num).toDouble() *
                                  (itemMap['quantity'] as int),
                              currency: 'FCFA',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 24),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatPriceWithCurrency(totalAmount, currency: 'FCFA'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Badge gratuit
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Retrait gratuit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;
    IconData icon;

    switch (status) {
      case 'ready':
        label = 'Prêt pour retrait';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'preparing':
        label = 'En préparation';
        color = AppColors.warning;
        icon = Icons.schedule;
        break;
      default:
        label = 'En attente';
        color = AppColors.info;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyPickedUp(Timestamp pickedUpAt) {
    final date = pickedUpAt.toDate();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Commande déjà récupérée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Le ${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotReadyYet(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                color: AppColors.warning,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Commande en préparation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Le vendeur n\'a pas encore confirmé votre commande.\n'
              'Vous recevrez une notification quand elle sera prête.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQRCode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code,
              color: AppColors.textLight,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Code non disponible',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

