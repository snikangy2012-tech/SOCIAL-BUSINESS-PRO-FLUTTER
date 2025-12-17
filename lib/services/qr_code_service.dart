// ===== lib/services/qr_code_service.dart =====
// Service de génération et validation de QR codes pour Click & Collect

import 'dart:math';
import 'package:flutter/foundation.dart';

class QRCodeService {
  /// Générer un QR code unique pour une commande
  /// Format: ORDER_{orderId}_{buyerId}_{timestamp}_{randomCode}
  static String generatePickupQRCode({
    required String orderId,
    required String buyerId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomCode = _generateRandomCode(6);

    final qrCode = 'ORDER_${orderId}_${buyerId}_${timestamp}_$randomCode';

    debugPrint('✅ QR Code généré: $qrCode');
    return qrCode;
  }

  /// Valider un QR code scanné
  /// Retourne un Map avec les informations extraites ou null si invalide
  static Map<String, String>? validateAndParseQRCode(String qrCode) {
    try {
      // Format attendu: ORDER_{orderId}_{buyerId}_{timestamp}_{randomCode}
      if (!qrCode.startsWith('ORDER_')) {
        debugPrint('❌ QR Code invalide: ne commence pas par ORDER_');
        return null;
      }

      final parts = qrCode.split('_');

      if (parts.length != 5) {
        debugPrint('❌ QR Code invalide: format incorrect (${parts.length} parties au lieu de 5)');
        return null;
      }

      final orderId = parts[1];
      final buyerId = parts[2];
      final timestamp = parts[3];
      final randomCode = parts[4];

      // Vérifier que l'orderId et buyerId ne sont pas vides
      if (orderId.isEmpty || buyerId.isEmpty) {
        debugPrint('❌ QR Code invalide: orderId ou buyerId vide');
        return null;
      }

      // Vérifier que le timestamp est un nombre valide
      final timestampInt = int.tryParse(timestamp);
      if (timestampInt == null) {
        debugPrint('❌ QR Code invalide: timestamp invalide');
        return null;
      }

      // Vérifier que le QR code n'est pas trop vieux (ex: max 30 jours)
      final qrCodeDate = DateTime.fromMillisecondsSinceEpoch(timestampInt);
      final daysSinceGeneration = DateTime.now().difference(qrCodeDate).inDays;

      if (daysSinceGeneration > 30) {
        debugPrint('⚠️ QR Code expiré: généré il y a $daysSinceGeneration jours');
        return null;
      }

      debugPrint('✅ QR Code valide pour commande: $orderId');

      return {
        'orderId': orderId,
        'buyerId': buyerId,
        'timestamp': timestamp,
        'randomCode': randomCode,
        'generatedAt': qrCodeDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation du QR code: $e');
      return null;
    }
  }

  /// Générer un code alphanumérique aléatoire
  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Vérifier si un QR code correspond à une commande spécifique
  static bool verifyQRCodeForOrder({
    required String qrCode,
    required String orderId,
    required String buyerId,
  }) {
    final parsed = validateAndParseQRCode(qrCode);

    if (parsed == null) return false;

    final matches = parsed['orderId'] == orderId && parsed['buyerId'] == buyerId;

    if (matches) {
      debugPrint('✅ QR Code vérifié pour commande $orderId');
    } else {
      debugPrint('❌ QR Code ne correspond pas à la commande');
    }

    return matches;
  }

  /// Obtenir un QR code de démonstration (pour testing)
  static String getDemoQRCode() {
    return generatePickupQRCode(
      orderId: 'DEMO123',
      buyerId: 'BUYER456',
    );
  }
}
