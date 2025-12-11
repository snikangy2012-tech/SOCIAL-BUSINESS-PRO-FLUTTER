// lib/services/admin_creation_service.dart
// Service pour créer des administrateurs via le backend sécurisé

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AdminCreationService {
  // URL du backend (à ajuster selon votre environnement)
  static const String _baseUrl = 'http://localhost:3001';

  /// Créer un nouvel administrateur
  /// Retourne le mot de passe temporaire généré
  static Future<Map<String, dynamic>> createAdmin({
    required String email,
    required String displayName,
    required String adminRole,
  }) async {
    try {
      // Récupérer le token Firebase du super admin connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final token = await currentUser.getIdToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      // Appeler l'API backend
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'displayName': displayName,
          'adminRole': adminRole,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Délai dépassé. Vérifiez que le serveur backend est démarré (node admin_backend_server.js)',
          );
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Succès
        return {
          'success': true,
          'uid': data['admin']['uid'],
          'email': data['admin']['email'],
          'displayName': data['admin']['displayName'],
          'temporaryPassword': data['admin']['temporaryPassword'],
        };
      } else {
        // Erreur
        throw Exception(data['error'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur création admin: $e');
    }
  }

  /// Réinitialiser le mot de passe d'un admin
  static Future<String> resetAdminPassword({required String adminUid}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final token = await currentUser.getIdToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'adminUid': adminUid,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['temporaryPassword'] as String;
      } else {
        throw Exception(data['error'] ?? 'Erreur lors de la réinitialisation');
      }
    } catch (e) {
      throw Exception('Erreur réinitialisation: $e');
    }
  }

  /// Vérifier que le serveur backend est accessible
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
