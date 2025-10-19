// ===== lib/services/mobile_money_service.dart =====
// Service de paiement Mobile Money pour la Côte d'Ivoire - SOCIAL BUSINESS Pro

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../models/payment_model.dart';

// ===== ENUMS ET TYPES =====

/// Statuts de paiement
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  expired,
}

// ===== CLASSES DE DONNÉES =====

/// Résultat d'une opération de paiement
class PaymentResult {
  final bool success;
  final String? transactionId;
  final PaymentStatus status;
  final String message;
  final double? amount;
  final double? fees;
  final String? ussdCode;
  final DateTime? expiresAt;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.status,
    required this.message,
    this.amount,
    this.fees,
    this.ussdCode,
    this.expiresAt,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, status: $status, message: $message)';
  }
}

/// Exception personnalisée pour les erreurs de paiement
class PaymentException implements Exception {
  final String message;
  final String? code;

  PaymentException(this.message, {this.code});

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Configuration d'un provider de paiement
class ProviderConfig {
  final String name;
  final String code;
  final List<String> prefixes;
  final int minAmount;
  final int maxAmount;
  final double feeRate;
  final String color;

  ProviderConfig({
    required this.name,
    required this.code,
    required this.prefixes,
    required this.minAmount,
    required this.maxAmount,
    required this.feeRate,
    required this.color,
  });
}

// ===== SERVICE PRINCIPAL =====

/// Service de paiement Mobile Money intégrant Orange Money, MTN MoMo et Wave
class MobileMoneyService {
  static const String _baseUrl = 'https://api.socialbusinesspro.ci/v1';
  
  // Configuration des providers (données réelles pour la Côte d'Ivoire)
  static final Map<String, ProviderConfig> _providers = {
    'orange_money': ProviderConfig(
      name: 'Orange Money',
      code: 'OM',
      prefixes: ['07', '08', '09'],
      minAmount: 100,
      maxAmount: 1500000,
      feeRate: 0.02, // 2%
      color: '#FF6600',
    ),
    'mtn_momo': ProviderConfig(
      name: 'MTN Mobile Money',
      code: 'MTN',
      prefixes: ['05', '06'],
      minAmount: 100,
      maxAmount: 1000000,
      feeRate: 0.015, // 1.5%
      color: '#FFCC00',
    ),
    'wave': ProviderConfig(
      name: 'Wave',
      code: 'WAVE',
      prefixes: ['01'],
      minAmount: 50,
      maxAmount: 2000000,
      feeRate: 0.01, // 1%
      color: '#00D4AA',
    ),
  };

  // ===== MÉTHODES PUBLIQUES =====

  /// Détecter automatiquement le provider selon le numéro
  static String? detectProvider(String phoneNumber) {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    
    if (cleanPhone.length != 8) return null;

    final prefix = cleanPhone.substring(0, 2);
    
    for (final entry in _providers.entries) {
      if (entry.value.prefixes.contains(prefix)) {
        return entry.key;
      }
    }
    
    return null;
  }

  /// Obtenir la configuration d'un provider
  static ProviderConfig? getProviderConfig(String providerId) {
    return _providers[providerId];
  }

  /// Obtenir tous les providers disponibles
  static List<Map<String, dynamic>> getAvailableProviders() {
    return _providers.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value.name,
      'code': entry.value.code,
      'prefixes': entry.value.prefixes,
      'minAmount': entry.value.minAmount,
      'maxAmount': entry.value.maxAmount,
      'color': entry.value.color,
    }).toList();
  }

  /// Valider un numéro de téléphone pour un provider
  static bool validatePhoneNumber(String phoneNumber, String providerId) {
    final detected = detectProvider(phoneNumber);
    return detected == providerId;
  }

  /// Calculer les frais de transaction
  static double calculateFees(double amount, String providerId) {
    final config = _providers[providerId];
    if (config == null) return 0;
    
    return amount * config.feeRate;
  }

  /// Vérifier si le montant est valide pour un provider
  static bool validateAmount(double amount, String providerId) {
    final config = _providers[providerId];
    if (config == null) return false;
    
    return amount >= config.minAmount && amount <= config.maxAmount;
  }

  /// Formater un numéro au format ivoirien (+225)
  static String formatPhoneNumber(String phoneNumber) {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    
    if (cleanPhone.length == 8) {
      return '+225$cleanPhone';
    }
    
    return phoneNumber;
  }

  /// Initier un paiement
  static Future<PaymentResult> initiatePayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
    required String providerId,
    required String description,
    String? vendeurId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validation des paramètres
      if (!validatePhoneNumber(phoneNumber, providerId)) {
        throw PaymentException('Numéro de téléphone invalide pour ce provider');
      }

      if (!validateAmount(amount, providerId)) {
        final config = _providers[providerId]!;
        throw PaymentException(
          'Montant invalide. Min: ${config.minAmount}, Max: ${config.maxAmount} FCFA'
        );
      }

      // Préparer les données
      final paymentData = {
        'orderId': orderId,
        'amount': amount,
        'phoneNumber': formatPhoneNumber(phoneNumber),
        'providerId': providerId,
        'description': description,
        'vendeurId': vendeurId,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Appel API
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(paymentData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return PaymentResult(
          success: true,
          transactionId: responseData['transactionId'],
          status: PaymentStatus.pending,
          message: responseData['message'] ?? 'Paiement initié avec succès',
          amount: amount,
          fees: calculateFees(amount, providerId),
          ussdCode: responseData['ussdCode'],
          expiresAt: responseData['expiresAt'] != null 
              ? DateTime.parse(responseData['expiresAt'])
              : DateTime.now().add(const Duration(minutes: 10)),
        );
      } else {
        throw PaymentException(
          responseData['message'] ?? 'Erreur lors de l\'initiation du paiement',
          code: responseData['code'],
        );
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      
      debugPrint('❌ Erreur initiation paiement: $e');
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        message: 'Erreur technique: ${e.toString()}',
      );
    }
  }

  /// Vérifier le statut d'un paiement
  static Future<PaymentResult> checkPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$transactionId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final statusString = responseData['status'] as String;
        PaymentStatus status;
        
        switch (statusString.toLowerCase()) {
          case 'success':
          case 'completed':
            status = PaymentStatus.success;
            break;
          case 'failed':
          case 'error':
            status = PaymentStatus.failed;
            break;
          case 'cancelled':
            status = PaymentStatus.cancelled;
            break;
          case 'expired':
            status = PaymentStatus.expired;
            break;
          case 'processing':
            status = PaymentStatus.processing;
            break;
          default:
            status = PaymentStatus.pending;
        }

        return PaymentResult(
          success: status == PaymentStatus.success,
          transactionId: transactionId,
          status: status,
          message: responseData['message'] ?? 'Statut récupéré',
          amount: responseData['amount']?.toDouble(),
        );
      } else {
        throw PaymentException(
          responseData['message'] ?? 'Impossible de vérifier le statut',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification statut: $e');
      return PaymentResult(
        success: false,
        transactionId: transactionId,
        status: PaymentStatus.failed,
        message: 'Erreur de vérification: ${e.toString()}',
      );
    }
  }

  /// Annuler un paiement
  static Future<PaymentResult> cancelPayment(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/$transactionId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      final responseData = jsonDecode(response.body);

      return PaymentResult(
        success: responseData['success'] ?? false,
        transactionId: transactionId,
        status: PaymentStatus.cancelled,
        message: responseData['message'] ?? 'Paiement annulé',
      );
    } catch (e) {
      debugPrint('❌ Erreur annulation paiement: $e');
      
      return PaymentResult(
        success: false,
        transactionId: transactionId,
        status: PaymentStatus.failed,
        message: 'Erreur lors de l\'annulation: ${e.toString()}',
      );
    }
  }

  /// Obtenir l'historique des paiements
  static Future<List<PaymentModel>> getPaymentHistory({
    required String userId,
    String? providerId,
    PaymentStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'userId': userId,
        'limit': limit.toString(),
      };

      if (providerId != null) queryParams['providerId'] = providerId;
      if (status != null) queryParams['status'] = status.toString().split('.').last;
      if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/payments/history').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final payments = responseData['payments'] as List;
        
        return payments.map((payment) => PaymentModel.fromJson(payment)).toList();
      } else {
        throw PaymentException('Impossible de récupérer l\'historique');
      }
    } catch (e) {
      debugPrint('❌ Erreur historique paiements: $e');
      return [];
    }
  }

  // ===== MÉTHODES PRIVÉES =====

  /// Nettoyer un numéro de téléphone
  static String _cleanPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Normaliser le numéro (retirer 225 si présent)
    if (cleanPhone.startsWith('225')) {
      return cleanPhone.substring(3);
    } else if (cleanPhone.length == 8) {
      return cleanPhone;
    }
    
    return cleanPhone;
  }

  /// Obtenir le token d'authentification
  static Future<String> _getAuthToken() async {
    // TODO: Implémenter la récupération du token JWT depuis le stockage local
    // ou depuis votre AuthProvider
    return 'mock-token-for-development';
  }
}