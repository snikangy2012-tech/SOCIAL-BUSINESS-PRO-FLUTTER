// ===== lib/services/unified_mobile_money_service.dart =====
// Service unifié pour gérer tous les paiements Mobile Money en Côte d'Ivoire
// IMPORTANT: Ce fichier nécessite des comptes marchands et API keys pour être fonctionnel

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Opérateurs Mobile Money disponibles en Côte d'Ivoire
enum MobileMoneyProvider {
  orange,    // Orange Money
  mtn,       // MTN Mobile Money
  moov,      // Moov Money (Flooz)
  wave,      // Wave
}

/// Résultat d'une tentative de paiement Mobile Money
class MobileMoneyPaymentResult {
  final bool success;
  final String? paymentUrl;
  final String? reference;
  final String? ussdCode;
  final String? error;

  MobileMoneyPaymentResult({
    required this.success,
    this.paymentUrl,
    this.reference,
    this.ussdCode,
    this.error,
  });
}

class UnifiedMobileMoneyService {
  static final _firestore = FirebaseFirestore.instance;
  static final _uuid = const Uuid();

  // ⚠️ CONFIGURATION REQUISE: Comptes marchands plateforme
  // TODO: Remplacer par vos vrais numéros de compte marchand
  static const Map<MobileMoneyProvider, String> platformAccounts = {
    MobileMoneyProvider.orange: '+225XXXXXXXX', // Compte Orange Money marchand
    MobileMoneyProvider.mtn: '+225YYYYYYYY',    // Compte MTN MoMo marchand
    MobileMoneyProvider.moov: '+225ZZZZZZZZ',   // Compte Moov Money marchand
    MobileMoneyProvider.wave: '+225WWWWWWWW',   // Compte Wave marchand
  };

  // ⚠️ CONFIGURATION REQUISE: Clés API
  // TODO: Ajouter vos vraies clés API dans un fichier .env sécurisé
  static const _orangeMerchantKey = 'VOTRE_MERCHANT_KEY_ORANGE';
  static const _mtnSubscriptionKey = 'VOTRE_SUBSCRIPTION_KEY_MTN';
  static const _fedapayApiKey = 'VOTRE_API_KEY_FEDAPAY';
  static const _waveApiKey = 'VOTRE_API_KEY_WAVE';

  /// Détecte automatiquement l'opérateur Mobile Money depuis un numéro de téléphone
  static MobileMoneyProvider detectProvider(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Préfixes téléphoniques Côte d'Ivoire
    if (cleanNumber.startsWith('225') && cleanNumber.length >= 5) {
      final prefix = cleanNumber.substring(3, 5);

      switch (prefix) {
        // Orange Money: 07, 08, 09
        case '07':
        case '08':
        case '09':
          return MobileMoneyProvider.orange;

        // MTN Mobile Money: 05, 06, 15, 16
        case '05':
        case '06':
        case '15':
        case '16':
          return MobileMoneyProvider.mtn;

        // Moov Money (Flooz): 01, 02, 03, 04
        case '01':
        case '02':
        case '03':
        case '04':
          return MobileMoneyProvider.moov;

        default:
          return MobileMoneyProvider.orange; // Défaut
      }
    }

    return MobileMoneyProvider.orange; // Défaut
  }

  /// Initie un paiement client → plateforme
  static Future<MobileMoneyPaymentResult> initiateClientPayment({
    required String orderId,
    required double amount,
    required String customerPhone,
    required MobileMoneyProvider provider,
  }) async {
    try {
      debugPrint('💳 Initiation paiement $amount FCFA via ${provider.name}');

      switch (provider) {
        case MobileMoneyProvider.orange:
          return await _initiateOrangeMoneyPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.mtn:
          return await _initiateMTNMoMoPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.moov:
          return await _initiateMoovMoneyPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.wave:
          return await _initiateWavePayment(orderId, amount, customerPhone);
      }
    } catch (e) {
      debugPrint('❌ Erreur paiement: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Orange Money - Paiement client → plateforme
  static Future<MobileMoneyPaymentResult> _initiateOrangeMoneyPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    try {
      // 1. Appel API Orange Money Web Payment
      final response = await http.post(
        Uri.parse('https://api.orange.com/orange-money-webpay/dev/v1/webpayment'),
        headers: {
          'Authorization': 'Bearer ${await _getOrangeAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'merchant_key': _orangeMerchantKey,
          'currency': 'XOF', // FCFA
          'order_id': orderId,
          'amount': amount.toInt(),
          'return_url': 'https://socialbusinesspro.ci/payment/callback',
          'cancel_url': 'https://socialbusinesspro.ci/payment/cancel',
          'notif_url': 'https://socialbusinesspro.ci/payment/notify',
          'lang': 'fr',
          'reference': 'CMD-$orderId',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 2. Enregistrer dans Firestore
        await _firestore.collection('mobile_money_payments').add({
          'orderId': orderId,
          'provider': 'orange',
          'amount': amount,
          'customerPhone': customerPhone,
          'paymentUrl': data['payment_url'],
          'paymentToken': data['pay_token'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return MobileMoneyPaymentResult(
          success: true,
          paymentUrl: data['payment_url'],
          reference: data['pay_token'],
          ussdCode: _generateOrangeUSSD(amount, data['pay_token']),
        );
      }

      return MobileMoneyPaymentResult(
        success: false,
        error: 'Orange Money API error: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ Erreur Orange Money: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: 'Erreur Orange Money: $e',
      );
    }
  }

  /// MTN Mobile Money - Paiement client → plateforme
  static Future<MobileMoneyPaymentResult> _initiateMTNMoMoPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    try {
      // 1. Générer UUID pour transaction
      final uuid = _uuid.v4();

      // 2. Appel API MTN MoMo Collection
      final response = await http.post(
        Uri.parse('https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer ${await _getMTNAccessToken()}',
          'X-Reference-Id': uuid,
          'X-Target-Environment': 'mtncotedivoire',
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _mtnSubscriptionKey,
        },
        body: jsonEncode({
          'amount': amount.toInt().toString(),
          'currency': 'XOF',
          'externalId': orderId,
          'payer': {
            'partyIdType': 'MSISDN',
            'partyId': customerPhone,
          },
          'payerMessage': 'Paiement commande #$orderId',
          'payeeNote': 'SOCIAL BUSINESS Pro',
        }),
      );

      if (response.statusCode == 202) {
        // 3. Enregistrer transaction
        await _firestore.collection('mobile_money_payments').add({
          'orderId': orderId,
          'provider': 'mtn',
          'amount': amount,
          'customerPhone': customerPhone,
          'referenceId': uuid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return MobileMoneyPaymentResult(
          success: true,
          reference: uuid,
          ussdCode: _generateMTNUSSD(amount, customerPhone),
        );
      }

      return MobileMoneyPaymentResult(
        success: false,
        error: 'MTN MoMo API error: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ Erreur MTN MoMo: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: 'Erreur MTN MoMo: $e',
      );
    }
  }

  /// Moov Money - Via agrégateur Fedapay
  static Future<MobileMoneyPaymentResult> _initiateMoovMoneyPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.fedapay.com/v1/transactions'),
        headers: {
          'Authorization': 'Bearer $_fedapayApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': 'Commande #$orderId',
          'amount': amount.toInt(),
          'currency': {'iso': 'XOF'},
          'callback_url': 'https://socialbusinesspro.ci/payment/callback',
          'customer': {
            'firstname': 'Client',
            'lastname': 'SocialBusiness',
            'email': 'client@socialbusinesspro.ci',
            'phone_number': {'number': customerPhone, 'country': 'ci'},
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _firestore.collection('mobile_money_payments').add({
          'orderId': orderId,
          'provider': 'moov',
          'amount': amount,
          'customerPhone': customerPhone,
          'transactionId': data['v1']['transaction']['id'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return MobileMoneyPaymentResult(
          success: true,
          paymentUrl: data['v1']['transaction']['url'],
          reference: data['v1']['transaction']['reference'],
        );
      }

      return MobileMoneyPaymentResult(
        success: false,
        error: 'Fedapay error: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ Erreur Moov Money: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: 'Erreur Moov Money: $e',
      );
    }
  }

  /// WAVE - Paiement client → plateforme (GRATUIT - 0% de frais!)
  static Future<MobileMoneyPaymentResult> _initiateWavePayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.wave.com/v1/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer $_waveApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.toInt(),
          'currency': 'XOF',
          'error_url': 'https://socialbusinesspro.ci/payment/error',
          'success_url': 'https://socialbusinesspro.ci/payment/success',
          'metadata': {
            'order_id': orderId,
            'customer_phone': customerPhone,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _firestore.collection('mobile_money_payments').add({
          'orderId': orderId,
          'provider': 'wave',
          'amount': amount,
          'customerPhone': customerPhone,
          'waveUrl': data['wave_launch_url'],
          'checkoutId': data['id'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return MobileMoneyPaymentResult(
          success: true,
          paymentUrl: data['wave_launch_url'],
          reference: data['id'],
        );
      }

      return MobileMoneyPaymentResult(
        success: false,
        error: 'Wave API error: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ Erreur Wave: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: 'Erreur Wave: $e',
      );
    }
  }

  /// Vérifier le statut d'un paiement
  static Future<bool> verifyPaymentStatus(
    String reference,
    MobileMoneyProvider provider,
  ) async {
    switch (provider) {
      case MobileMoneyProvider.orange:
        return await _verifyOrangePayment(reference);
      case MobileMoneyProvider.mtn:
        return await _verifyMTNPayment(reference);
      case MobileMoneyProvider.moov:
        return await _verifyFedapayPayment(reference);
      case MobileMoneyProvider.wave:
        return await _verifyWavePayment(reference);
    }
  }

  /// Envoyer un paiement plateforme → vendeur/livreur
  static Future<bool> sendPayment({
    required MobileMoneyProvider provider,
    required String recipientPhone,
    required double amount,
    required String description,
  }) async {
    try {
      debugPrint('💸 Envoi $amount FCFA à $recipientPhone via ${provider.name}');

      switch (provider) {
        case MobileMoneyProvider.orange:
          return await _sendOrangeMoneyPayment(recipientPhone, amount, description);
        case MobileMoneyProvider.mtn:
          return await _sendMTNMoMoPayment(recipientPhone, amount, description);
        case MobileMoneyProvider.moov:
          return await _sendMoovMoneyPayment(recipientPhone, amount, description);
        case MobileMoneyProvider.wave:
          return await _sendWavePayment(recipientPhone, amount, description);
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi paiement: $e');
      return false;
    }
  }

  // ========== MÉTHODES PRIVÉES (STUBS - À IMPLÉMENTER) ==========

  static Future<String> _getOrangeAccessToken() async {
    // TODO: Implémenter l'authentification Orange Money OAuth
    return 'ORANGE_ACCESS_TOKEN';
  }

  static Future<String> _getMTNAccessToken() async {
    // TODO: Implémenter l'authentification MTN MoMo
    return 'MTN_ACCESS_TOKEN';
  }

  static String _generateOrangeUSSD(double amount, String token) {
    return '#144#${amount.toInt()}#$token#';
  }

  static String _generateMTNUSSD(double amount, String phone) {
    return '*133#'; // Code MTN MoMo générique
  }

  static Future<bool> _verifyOrangePayment(String reference) async {
    // TODO: Vérifier le statut via API Orange Money
    debugPrint('⏳ Vérification paiement Orange: $reference');
    return false;
  }

  static Future<bool> _verifyMTNPayment(String reference) async {
    // TODO: Vérifier le statut via API MTN MoMo
    debugPrint('⏳ Vérification paiement MTN: $reference');
    return false;
  }

  static Future<bool> _verifyFedapayPayment(String reference) async {
    // TODO: Vérifier le statut via API Fedapay
    debugPrint('⏳ Vérification paiement Fedapay: $reference');
    return false;
  }

  static Future<bool> _verifyWavePayment(String reference) async {
    // TODO: Vérifier le statut via API Wave
    debugPrint('⏳ Vérification paiement Wave: $reference');
    return false;
  }

  static Future<bool> _sendOrangeMoneyPayment(
    String recipientPhone,
    double amount,
    String description,
  ) async {
    // TODO: Implémenter transfert sortant Orange Money
    debugPrint('💸 Envoi Orange Money: $amount FCFA à $recipientPhone');
    return false;
  }

  static Future<bool> _sendMTNMoMoPayment(
    String recipientPhone,
    double amount,
    String description,
  ) async {
    // TODO: Implémenter transfert sortant MTN MoMo
    debugPrint('💸 Envoi MTN MoMo: $amount FCFA à $recipientPhone');
    return false;
  }

  static Future<bool> _sendMoovMoneyPayment(
    String recipientPhone,
    double amount,
    String description,
  ) async {
    // TODO: Implémenter transfert sortant Moov Money
    debugPrint('💸 Envoi Moov Money: $amount FCFA à $recipientPhone');
    return false;
  }

  static Future<bool> _sendWavePayment(
    String recipientPhone,
    double amount,
    String description,
  ) async {
    // TODO: Implémenter transfert sortant Wave
    debugPrint('💸 Envoi Wave: $amount FCFA à $recipientPhone');
    return false;
  }
}
