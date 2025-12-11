// ===== lib/screens/common/user_settings_screen.dart =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/models/user_model.dart';
import 'package:social_business_pro/providers/auth_provider_firebase.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/system_ui_scaffold.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _isLoading = false;

  // Préférences locales (seront initialisées depuis le user)
  late bool _pushNotifications;
  late bool _emailNotifications;
  late bool _smsNotifications;
  late bool _marketingEmails;
  late String _theme;
  late String _language;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final authProvider = context.read<auth.AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      setState(() {
        _pushNotifications = user.preferences.pushNotifications;
        _emailNotifications = user.preferences.emailNotifications;
        _smsNotifications = user.preferences.smsNotifications;
        _marketingEmails = user.preferences.marketingEmails;
        _theme = user.preferences.theme;
        _language = user.preferences.language;
      });
    }
  }

  Future<void> _savePreferences() async {
    final authProvider = context.read<auth.AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final newPreferences = UserPreferences(
        theme: _theme,
        language: _language,
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
        smsNotifications: _smsNotifications,
        marketingEmails: _marketingEmails,
        currency: user.preferences.currency,
      );

      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.id)
          .update({
        'preferences': newPreferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recharger l'utilisateur dans le provider
      await authProvider.loadUserFromFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences enregistrées avec succès'),
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
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
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
                    'Notifications',
                    Icons.notifications_outlined,
                    [
                      _buildSwitchTile(
                        'Notifications Push',
                        'Recevoir des notifications sur votre appareil',
                        _pushNotifications,
                        (value) => setState(() => _pushNotifications = value),
                      ),
                      _buildSwitchTile(
                        'Notifications Email',
                        'Recevoir des notifications par email',
                        _emailNotifications,
                        (value) => setState(() => _emailNotifications = value),
                      ),
                      _buildSwitchTile(
                        'Notifications SMS',
                        'Recevoir des notifications par SMS',
                        _smsNotifications,
                        (value) => setState(() => _smsNotifications = value),
                      ),
                      _buildSwitchTile(
                        'Emails Marketing',
                        'Recevoir les offres promotionnelles',
                        _marketingEmails,
                        (value) => setState(() => _marketingEmails = value),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _buildSection(
                    'Apparence',
                    Icons.palette_outlined,
                    [
                      _buildDropdownTile(
                        'Thème',
                        'Choisir le thème de l\'application',
                        _theme,
                        ['light', 'dark', 'system'],
                        {
                          'light': 'Clair',
                          'dark': 'Sombre',
                          'system': 'Système',
                        },
                        (value) => setState(() => _theme = value ?? 'light'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _buildSection(
                    'Langue',
                    Icons.language_outlined,
                    [
                      _buildDropdownTile(
                        'Langue de l\'application',
                        'Choisir la langue d\'affichage',
                        _language,
                        ['fr', 'en'],
                        {
                          'fr': 'Français',
                          'en': 'English',
                        },
                        (value) => setState(() => _language = value ?? 'fr'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savePreferences,
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
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

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: AppFontSizes.sm),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      activeThumbColor: Colors.white,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String currentValue,
    List<String> options,
    Map<String, String> labels,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(fontSize: AppFontSizes.sm),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              isDense: true,
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(labels[option] ?? option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
