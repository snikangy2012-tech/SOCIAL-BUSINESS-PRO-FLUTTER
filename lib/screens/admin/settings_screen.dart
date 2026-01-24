// ===== lib/screens/admin/settings_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../widgets/system_ui_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  // Paramètres de la plateforme
  bool _maintenanceMode = false;
  bool _allowRegistrations = true;
  bool _requireEmailVerification = true;
  bool _enableNotifications = true;
  int _maxProductsPerVendor = 100;
  double _commissionRate = 5.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('platform').get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _allowRegistrations = data['allowRegistrations'] ?? true;
          _requireEmailVerification = data['requireEmailVerification'] ?? true;
          _enableNotifications = data['enableNotifications'] ?? true;
          _maxProductsPerVendor = data['maxProductsPerVendor'] ?? 100;
          _commissionRate = (data['commissionRate'] ?? 5.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement paramètres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('settings').doc('platform').set({
        'maintenanceMode': _maintenanceMode,
        'allowRegistrations': _allowRegistrations,
        'requireEmailVerification': _requireEmailVerification,
        'enableNotifications': _enableNotifications,
        'maxProductsPerVendor': _maxProductsPerVendor,
        'commissionRate': _commissionRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Paramètres de la plateforme'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Paramètres généraux',
                    [
                      _buildSwitchTile(
                        'Mode maintenance',
                        'Désactiver temporairement la plateforme',
                        _maintenanceMode,
                        (value) => setState(() => _maintenanceMode = value),
                      ),
                      _buildSwitchTile(
                        'Autoriser les inscriptions',
                        'Permettre aux nouveaux utilisateurs de s\'inscrire',
                        _allowRegistrations,
                        (value) => setState(() => _allowRegistrations = value),
                      ),
                      _buildSwitchTile(
                        'Vérification email obligatoire',
                        'Exiger la vérification de l\'email à l\'inscription',
                        _requireEmailVerification,
                        (value) => setState(() => _requireEmailVerification = value),
                      ),
                      _buildSwitchTile(
                        'Notifications activées',
                        'Envoyer des notifications push aux utilisateurs',
                        _enableNotifications,
                        (value) => setState(() => _enableNotifications = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSection(
                    'Limites et restrictions',
                    [
                      _buildNumberTile(
                        'Produits max par vendeur',
                        'Nombre maximum de produits qu\'un vendeur peut publier',
                        _maxProductsPerVendor,
                        (value) => setState(() => _maxProductsPerVendor = value.toInt()),
                      ),
                      _buildNumberTile(
                        'Taux de commission (%)',
                        'Commission prélevée sur chaque vente',
                        _commissionRate,
                        (value) => setState(() => _commissionRate = value.toDouble()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section Gestion des données
                  _buildSection(
                    'Gestion des données',
                    [
                      ListTile(
                        leading: const Icon(Icons.category, color: AppColors.secondary),
                        title: const Text('Gestion des catégories'),
                        subtitle: const Text('Gérer les catégories et sous-catégories de produits'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.go('/admin/categories-management'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer les modifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: AppFontSizes.sm)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildNumberTile(String title, String subtitle, num value, ValueChanged<num> onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: AppFontSizes.sm)),
      trailing: SizedBox(
        width: 100,
        child: TextFormField(
          initialValue: value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null) onChanged(parsed);
          },
        ),
      ),
    );
  }
}

