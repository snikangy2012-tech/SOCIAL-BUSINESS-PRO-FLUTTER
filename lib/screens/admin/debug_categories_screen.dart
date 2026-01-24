// ===== lib/screens/admin/debug_categories_screen.dart =====
// Écran de debug pour nettoyer les catégories vendeur

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../scripts/clean_vendor_categories.dart';

class DebugCategoriesScreen extends StatefulWidget {
  const DebugCategoriesScreen({super.key});

  @override
  State<DebugCategoriesScreen> createState() => _DebugCategoriesScreenState();
}

class _DebugCategoriesScreenState extends State<DebugCategoriesScreen> {
  bool _isLoading = false;
  String _result = '';
  List<Map<String, dynamic>> _problematicVendors = [];

  Future<void> _cleanCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      setState(() {
        _result = '❌ Aucun utilisateur connecté';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Nettoyage en cours...';
    });

    try {
      final result = await cleanVendorCategories(user.id);

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          if (result['cleaned'] == true) {
            _result = '✅ Catégories nettoyées avec succès!\n\n'
                'Anciennes catégories: ${result['oldCategories']}\n'
                'Catégories invalides: ${result['invalidCategories']}\n'
                'Nouvelles catégories: ${result['newCategories']}';
          } else {
            _result = '✅ ${result['message']}\n\n'
                'Catégories actuelles: ${result['categories']}';
          }
        } else {
          _result = '❌ Erreur: ${result['error']}';
        }
      });

      // Recharger le profil utilisateur
      if (result['success'] == true && result['cleaned'] == true) {
        await authProvider.refreshUser();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '❌ Erreur: $e';
      });
    }
  }

  Future<void> _checkAllVendors() async {
    setState(() {
      _isLoading = true;
      _result = 'Vérification de tous les vendeurs...';
    });

    try {
      final vendors = await checkAllVendorsCategories();

      setState(() {
        _isLoading = false;
        _problematicVendors = vendors;
        if (vendors.isEmpty) {
          _result = '✅ Aucun vendeur avec des catégories invalides';
        } else {
          _result = '⚠️  ${vendors.length} vendeur(s) avec catégories invalides';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '❌ Erreur: $e';
      });
    }
  }

  Future<void> _cleanVendor(String userId) async {
    setState(() {
      _isLoading = true;
      _result = 'Nettoyage de $userId...';
    });

    try {
      final result = await cleanVendorCategories(userId);

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _result = '✅ Vendeur $userId nettoyé avec succès!';
          // Retirer de la liste
          _problematicVendors.removeWhere((v) => v['userId'] == userId);
        } else {
          _result = '❌ Erreur: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = '❌ Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Catégories'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Infos utilisateur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Utilisateur connecté',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (user != null) ...[
                      Text('ID: ${user.id}'),
                      Text('Email: ${user.email}'),
                      Text('Type: ${user.userType}'),
                    ] else
                      const Text('Aucun utilisateur connecté'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Catégories valides
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories valides',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...validCategories.map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $cat'),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cleanCurrentUser,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Nettoyer mes catégories'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            if (user?.isSuperAdmin == true) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkAllVendors,
                icon: const Icon(Icons.search),
                label: const Text('Vérifier tous les vendeurs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Résultat
            if (_result.isNotEmpty)
              Card(
                color: AppColors.backgroundSecondary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Résultat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Text(
                          _result,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                    ],
                  ),
                ),
              ),

            // Liste des vendeurs problématiques
            if (_problematicVendors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vendeurs avec catégories invalides',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._problematicVendors.map((vendor) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: AppColors.backgroundSecondary,
                            child: ListTile(
                              title: Text(vendor['businessName'] ?? 'N/A'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${vendor['email']}'),
                                  Text('Invalides: ${vendor['invalidCategories']}'),
                                  Text('Actuelles: ${vendor['currentCategories']}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.cleaning_services, color: AppColors.primary),
                                onPressed: _isLoading
                                    ? null
                                    : () => _cleanVendor(vendor['userId']),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
