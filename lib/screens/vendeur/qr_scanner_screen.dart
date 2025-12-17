// ===== lib/screens/vendeur/qr_scanner_screen.dart =====
// Écran de scan QR pour le retrait Click & Collect - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../services/qr_code_service.dart';
import '../../services/firebase_service.dart';
import '../../services/audit_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../models/audit_log_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Gérer le scan d'un QR code
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      // Valider et parser le QR code
      final parsedData = QRCodeService.validateAndParseQRCode(code);

      if (parsedData == null) {
        _showError('QR Code invalide ou expiré');
        return;
      }

      final orderId = parsedData['orderId']!;
      final buyerId = parsedData['buyerId']!;

      debugPrint('📱 QR Code scanné: Order=$orderId, Buyer=$buyerId');

      // Récupérer la commande depuis Firestore
      final orderDoc = await FirebaseService.getDocument(
        collection: FirebaseCollections.orders,
        docId: orderId,
      );

      if (orderDoc == null) {
        _showError('Commande introuvable');
        return;
      }

      // Vérifier que c'est bien une commande Click & Collect
      final deliveryMethod = orderDoc['deliveryMethod'] as String?;
      if (deliveryMethod != 'store_pickup') {
        _showError('Cette commande n\'est pas en mode Click & Collect');
        return;
      }

      // Vérifier que la commande n'a pas déjà été récupérée
      if (orderDoc['pickedUpAt'] != null) {
        _showError('Cette commande a déjà été récupérée');
        return;
      }

      // Vérifier que le QR code correspond bien à cette commande
      final storedQRCode = orderDoc['pickupQRCode'] as String?;
      if (storedQRCode != code) {
        _showError('QR Code non valide pour cette commande');
        return;
      }

      // Vérifier que la commande est prête pour le retrait
      final status = orderDoc['status'] as String;
      if (status != 'ready' && status != 'confirmed' && status != 'preparing') {
        _showError('Commande non prête pour le retrait (statut: $status)');
        return;
      }

      // Arrêter le scanner
      await _scannerController.stop();

      // Afficher confirmation et détails de la commande
      if (mounted) {
        _showOrderConfirmation(orderId, orderDoc);
      }
    } catch (e) {
      debugPrint('❌ Erreur scan QR: $e');
      _showError('Erreur lors du scan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Afficher la confirmation de retrait
  void _showOrderConfirmation(String orderId, Map<String, dynamic> orderData) {
    final displayNumber = orderData['displayNumber'] as int;
    final buyerName = orderData['buyerName'] as String;
    final totalAmount = (orderData['totalAmount'] as num).toDouble();
    final items = orderData['items'] as List<dynamic>;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Commande validée',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('N° Commande', '#$displayNumber'),
              const SizedBox(height: 8),
              _buildInfoRow('Client', buyerName),
              const SizedBox(height: 8),
              _buildInfoRow('Montant', '${totalAmount.toStringAsFixed(0)} FCFA'),
              const SizedBox(height: 16),
              const Text(
                'Articles:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                final itemMap = item as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${itemMap['quantity']}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemMap['productName'] as String,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Redémarrer le scanner
              await _scannerController.start();
              setState(() {
                _lastScannedCode = null;
              });
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _confirmPickup(orderId, orderData),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer retrait'),
          ),
        ],
      ),
    );
  }

  // Confirmer le retrait de la commande
  Future<void> _confirmPickup(String orderId, Map<String, dynamic> orderData) async {
    try {
      // Mettre à jour la commande
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'pickedUpAt': FieldValue.serverTimestamp(),
        'status': 'delivered', // Marquer comme livrée
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Commande #${orderData['displayNumber']} marquée comme récupérée');

      // 📱 NOTIFICATION RETRAIT CONFIRMÉ
      try {
        await NotificationService().createNotification(
          userId: orderData['buyerId'] as String,
          type: 'pickup_completed',
          title: '✅ Commande récupérée',
          body: 'Commande #${orderData['displayNumber']} - Merci pour votre achat !',
          data: {
            'orderId': orderId,
            'displayNumber': orderData['displayNumber'],
            'route': '/acheteur/orders',
            'action': 'view_orders',
          },
        );
        debugPrint('✅ Notification retrait confirmé envoyée à l\'acheteur');
      } catch (e) {
        debugPrint('❌ Erreur envoi notification retrait: $e');
        // L'erreur n'empêche pas la confirmation du retrait
      }

      // 💰 TRACKING COMMISSION VENDEUR (Click & Collect)
      try {
        final vendorId = orderData['vendeurId'] as String;
        final totalAmount = (orderData['totalAmount'] as num).toDouble();
        final deliveryFee = (orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
        final productAmount = totalAmount - deliveryFee;

        // Récupérer le taux de commission du vendeur
        final subscriptionService = SubscriptionService();
        final commissionRate = await subscriptionService.getVendeurCommissionRate(vendorId);
        final commissionAmount = productAmount * commissionRate;

        debugPrint('💰 Commission Click & Collect:');
        debugPrint('   - Montant produits: ${productAmount.toStringAsFixed(0)} FCFA');
        debugPrint('   - Taux commission: ${(commissionRate * 100).toStringAsFixed(0)}%');
        debugPrint('   - Commission due: ${commissionAmount.toStringAsFixed(0)} FCFA');

        // Incrémenter le solde impayé du vendeur
        await FirebaseFirestore.instance
            .collection('users')
            .doc(vendorId)
            .update({
          'profile.unpaidCommissions': FieldValue.increment(commissionAmount),
          'profile.lastCommissionDate': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Commission enregistrée pour vendeur $vendorId');
      } catch (e) {
        debugPrint('❌ Erreur tracking commission vendeur: $e');
        // L'erreur n'empêche pas la confirmation du retrait
      }

      // Logger dans l'audit
      await AuditService.log(
        userId: orderData['vendeurId'] as String,
        userType: 'vendeur',
        userEmail: '',
        userName: 'Vendeur',
        action: 'order_pickup_confirmed',
        actionLabel: 'Confirmation retrait Click & Collect',
        category: AuditCategory.userAction,
        severity: AuditSeverity.low,
        description: 'Retrait confirmé pour commande #${orderData['displayNumber']}',
        targetType: 'order',
        targetId: orderId,
        targetLabel: 'Commande #${orderData['displayNumber']}',
        metadata: {
          'orderId': orderId,
          'buyerId': orderData['buyerId'],
          'totalAmount': orderData['totalAmount'],
        },
      );

      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue

        // Afficher succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commande #${orderData['displayNumber']} retirée avec succès',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Retourner à l'écran précédent après 1 seconde
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur confirmation retrait: $e');
      if (mounted) {
        Navigator.pop(context);
        _showError('Erreur lors de la confirmation: $e');
        // Redémarrer le scanner
        await _scannerController.start();
        setState(() {
          _lastScannedCode = null;
        });
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // Afficher une erreur
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );

    // Réinitialiser après l'erreur
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastScannedCode = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(
              _scannerController.torchEnabled == TorchState.on
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Activer/Désactiver flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
            tooltip: 'Changer de caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner QR
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Overlay avec instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Click & Collect',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scannez le QR code du client',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de traitement
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Vérification...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
