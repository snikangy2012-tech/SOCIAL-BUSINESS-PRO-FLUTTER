// ===== lib/utils/permissions_helper.dart =====
// Helper pour gérer les permissions Android

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PermissionsHelper {
  /// Demander les permissions SMS pour auto-vérification OTP (Android uniquement)
  static Future<bool> requestSmsPermissions(BuildContext context) async {
    // Sur Web ou si déjà accordées, retourner true
    if (kIsWeb) return true;

    if (await Permission.sms.isGranted) {
      return true;
    }

    // Expliquer pourquoi on demande la permission
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sms, color: Colors.blue),
            SizedBox(width: 8),
            Text('Auto-vérification SMS'),
          ],
        ),
        content: const Text(
          'Pour remplir automatiquement le code de vérification, '
          'nous avons besoin d\'accéder à vos SMS.\n\n'
          'Vous pouvez refuser et entrer le code manuellement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return false;

    // Demander la permission
    final status = await Permission.sms.request();

    if (!status.isGranted && context.mounted) {
      // Informer l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission SMS refusée. Vous devrez entrer le code manuellement.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    return status.isGranted;
  }

  /// Demander permission phone state pour optimiser SMS OTP
  static Future<bool> requestPhoneStatePermission(BuildContext context) async {
    if (kIsWeb) return true;

    if (await Permission.phone.isGranted) {
      return true;
    }

    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Demander toutes les permissions SMS en une fois
  static Future<Map<String, bool>> requestAllSmsPermissions(BuildContext context) async {
    if (kIsWeb) {
      return {
        'sms': true,
        'phone': true,
      };
    }

    final smsGranted = await requestSmsPermissions(context);
    final phoneGranted = await requestPhoneStatePermission(context);

    return {
      'sms': smsGranted,
      'phone': phoneGranted,
    };
  }

  /// Vérifier si les permissions SMS sont accordées
  static Future<bool> hasSmsPermissions() async {
    if (kIsWeb) return true;

    final smsStatus = await Permission.sms.status;
    return smsStatus.isGranted;
  }

  /// Ouvrir les paramètres de l'app si permission définitivement refusée
  static Future<void> openSettings(BuildContext context) async {
    await openAppSettings();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez activer les permissions SMS dans les paramètres'),
        ),
      );
    }
  }
}
