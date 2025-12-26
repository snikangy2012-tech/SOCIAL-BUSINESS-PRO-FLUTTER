import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../services/kyc_adaptive_service.dart';
import '../../services/blacklist_service.dart';
import '../../models/blacklist_entry_model.dart';

/// Écran admin de gestion KYC avancée
/// Permet de voir et gérer les tiers, blacklist, et validations KYC
class KYCManagementScreen extends StatefulWidget {
  const KYCManagementScreen({super.key});

  @override
  State<KYCManagementScreen> createState() => _KYCManagementScreenState();
}

class _KYCManagementScreenState extends State<KYCManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RiskTier? _selectedTierFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion KYC Adaptative'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Statistiques'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs par Tier'),
            Tab(icon: Icon(Icons.block), text: 'Blacklist'),
            Tab(icon: Icon(Icons.verified_user), text: 'Validations KYC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildUsersByTierTab(),
          _buildBlacklistTab(),
          _buildKYCValidationsTab(),
        ],
      ),
    );
  }

  /// Onglet Statistiques
  Widget _buildStatisticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('risk_assessments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assessments = snapshot.data!.docs;
        final tierCounts = <RiskTier, int>{};
        final tierRevenue = <RiskTier, double>{};

        // Initialiser les compteurs
        for (final tier in RiskTier.values) {
          tierCounts[tier] = 0;
          tierRevenue[tier] = 0.0;
        }

        // Compter les utilisateurs par tier
        for (final doc in assessments) {
          final data = doc.data() as Map<String, dynamic>;
          final tierName = data['tier'] as String?;
          if (tierName != null) {
            final tier = RiskTier.values.firstWhere(
              (t) => t.name == tierName,
              orElse: () => RiskTier.newUser,
            );
            tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Text(
                'Vue d\'ensemble du système KYC',
                style: TextStyle(
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Cartes de statistiques
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _buildStatCard(
                    'Total Utilisateurs',
                    assessments.length.toString(),
                    Icons.people,
                    AppColors.primary,
                  ),
                  _buildStatCard(
                    'TRUSTED',
                    tierCounts[RiskTier.trusted].toString(),
                    Icons.verified,
                    AppColors.success,
                  ),
                  _buildStatCard(
                    'VERIFIED',
                    tierCounts[RiskTier.verified].toString(),
                    Icons.check_circle,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'NEW USER',
                    tierCounts[RiskTier.newUser].toString(),
                    Icons.person_add,
                    Colors.grey,
                  ),
                  _buildStatCard(
                    'MODERATE RISK',
                    tierCounts[RiskTier.moderateRisk].toString(),
                    Icons.warning_amber,
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    'HIGH RISK',
                    tierCounts[RiskTier.highRisk].toString(),
                    Icons.error,
                    AppColors.error,
                  ),
                  _buildStatCard(
                    'BLACKLISTED',
                    tierCounts[RiskTier.blacklisted].toString(),
                    Icons.block,
                    Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Graphique de distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribution des tiers',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...RiskTier.values.map((tier) {
                        final count = tierCounts[tier] ?? 0;
                        final percentage = assessments.isEmpty
                            ? 0.0
                            : (count / assessments.length) * 100;
                        return _buildTierBar(tier, count, percentage);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppFontSizes.xxl,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierBar(RiskTier tier, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              tier.displayName,
              style: TextStyle(fontSize: AppFontSizes.sm),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getTierColor(tier),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: AppFontSizes.sm),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Utilisateurs par Tier
  Widget _buildUsersByTierTab() {
    return Column(
      children: [
        // Filtre par tier
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Filtrer par tier : ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButton<RiskTier?>(
                  value: _selectedTierFilter,
                  isExpanded: true,
                  hint: const Text('Tous les tiers'),
                  items: [
                    const DropdownMenuItem<RiskTier?>(
                      value: null,
                      child: Text('Tous les tiers'),
                    ),
                    ...RiskTier.values.map((tier) {
                      return DropdownMenuItem<RiskTier?>(
                        value: tier,
                        child: Row(
                          children: [
                            Icon(_getTierIcon(tier), size: 16, color: _getTierColor(tier)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(tier.displayName),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTierFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Liste des utilisateurs
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedTierFilter == null
                ? FirebaseFirestore.instance
                    .collection('risk_assessments')
                    .orderBy('lastUpdated', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('risk_assessments')
                    .where('tier', isEqualTo: _selectedTierFilter!.name)
                    .orderBy('lastUpdated', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final assessments = snapshot.data!.docs;

              if (assessments.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final doc = assessments[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildUserTierCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTierCard(String userId, Map<String, dynamic> data) {
    final tierName = data['tier'] as String? ?? 'newUser';
    final tier = RiskTier.values.firstWhere(
      (t) => t.name == tierName,
      orElse: () => RiskTier.newUser,
    );
    final riskScore = (data['riskScore'] ?? 0) as int;
    final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ExpansionTile(
        leading: Icon(
          _getTierIcon(tier),
          color: _getTierColor(tier),
          size: 32,
        ),
        title: Text(
          'User: ${userId.substring(0, 8)}...',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getTierColor(tier).withOpacity(0.1),
                border: Border.all(color: _getTierColor(tier)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tier.displayName,
                style: TextStyle(
                  fontSize: AppFontSizes.xs,
                  color: _getTierColor(tier),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Score: $riskScore/100',
              style: TextStyle(fontSize: AppFontSizes.sm),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: $userId'),
                if (lastUpdated != null)
                  Text(
                    'Dernière MAJ: ${DateFormat('dd/MM/yyyy HH:mm').format(lastUpdated)}',
                  ),
                const SizedBox(height: AppSpacing.md),

                // Actions
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _upgradeTier(userId, tier),
                      icon: const Icon(Icons.upgrade, size: 16),
                      label: const Text('Upgrade Tier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _downgradeTier(userId, tier),
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Downgrade Tier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addToBlacklist(userId),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Blacklister'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Blacklist
  Widget _buildBlacklistTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Utilisateurs blacklistés',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddBlacklistDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blacklist')
                .where('status', isEqualTo: 'active')
                .orderBy('addedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final blacklistEntries = snapshot.data!.docs;

              if (blacklistEntries.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune entrée dans la blacklist',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: blacklistEntries.length,
                itemBuilder: (context, index) {
                  final doc = blacklistEntries[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildBlacklistCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBlacklistCard(String entryId, Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final reason = data['reason'] as String? ?? 'Non spécifié';
    final cniNumber = data['cniNumber'] as String?;
    final phoneNumber = data['phoneNumber'] as String?;
    final addedAt = (data['addedAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.error.withOpacity(0.05),
      child: ListTile(
        leading: Icon(Icons.block, color: AppColors.error),
        title: Text(userId ?? 'ID inconnu'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cniNumber != null) Text('CNI: $cniNumber'),
            if (phoneNumber != null) Text('Tél: $phoneNumber'),
            Text('Raison: $reason'),
            if (addedAt != null)
              Text(
                'Ajouté: ${DateFormat('dd/MM/yyyy').format(addedAt)}',
                style: TextStyle(fontSize: AppFontSizes.xs),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: AppColors.error),
          onPressed: () => _removeFromBlacklist(entryId, userId),
        ),
      ),
    );
  }

  /// Onglet Validations KYC
  Widget _buildKYCValidationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kyc_verifications')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final verifications = snapshot.data!.docs;

        if (verifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucune validation KYC en attente',
                  style: TextStyle(
                    fontSize: AppFontSizes.lg,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: verifications.length,
          itemBuilder: (context, index) {
            final doc = verifications[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildKYCValidationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildKYCValidationCard(String verificationId, Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
    final documentType = data['documentType'] as String? ?? 'CNI';
    final documentUrls = (data['documentUrls'] as List?)?.cast<String>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Vérification KYC',
                    style: TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (submittedAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(submittedAt),
                    style: TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('User ID: $userId'),
            Text('Type: $documentType'),
            const SizedBox(height: AppSpacing.md),

            // Documents
            if (documentUrls.isNotEmpty) ...[
              Text(
                'Documents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: documentUrls.map((url) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      // Ouvrir le document
                      // TODO: Implémenter l'ouverture du document
                    },
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('Voir'),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectKYC(verificationId, userId),
                  child: const Text('Rejeter'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => _approveKYC(verificationId, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approuver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== ACTIONS =====

  Future<void> _upgradeTier(String userId, RiskTier currentTier) async {
    final tierIndex = RiskTier.values.indexOf(currentTier);
    if (tierIndex <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déjà au tier maximum')),
      );
      return;
    }

    final newTier = RiskTier.values[tierIndex - 1];

    try {
      await FirebaseFirestore.instance
          .collection('risk_assessments')
          .doc(userId)
          .update({
        'tier': newTier.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tier upgradé vers ${newTier.displayName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _downgradeTier(String userId, RiskTier currentTier) async {
    final tierIndex = RiskTier.values.indexOf(currentTier);
    if (tierIndex >= RiskTier.values.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déjà au tier minimum')),
      );
      return;
    }

    final newTier = RiskTier.values[tierIndex + 1];

    try {
      await FirebaseFirestore.instance
          .collection('risk_assessments')
          .doc(userId)
          .update({
        'tier': newTier.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tier dégradé vers ${newTier.displayName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _addToBlacklist(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Êtes-vous sûr de vouloir ajouter cet utilisateur à la blacklist ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Blacklister'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Récupérer les infos utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.data();

      await BlacklistService.addToBlacklist(
        reason: 'Ajout manuel par admin',
        userId: userId,
        userName: userData?['displayName'] as String? ?? 'Inconnu',
        userType: userData?['userType'] as String? ?? 'unknown',
        adminId: 'admin',
        severity: BlacklistSeverity.high,
        type: BlacklistType.fraud,
        amountDue: 0,
        cniNumber: userData?['cniNumber'] as String?,
        phoneNumber: userData?['phoneNumber'] as String?,
      );

      // Mettre à jour le tier
      await FirebaseFirestore.instance
          .collection('risk_assessments')
          .doc(userId)
          .update({
        'tier': RiskTier.blacklisted.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur ajouté à la blacklist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _removeFromBlacklist(String entryId, String? userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('blacklist')
          .doc(entryId)
          .update({'status': 'removed'});

      // Si on a l'userId, remettre en moderate risk
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('risk_assessments')
            .doc(userId)
            .update({
          'tier': RiskTier.moderateRisk.name,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiré de la blacklist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _approveKYC(String verificationId, String? userId) async {
    if (userId == null) return;

    try {
      // Mettre à jour la vérification
      await FirebaseFirestore.instance
          .collection('kyc_verifications')
          .doc(verificationId)
          .update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Upgrade le tier vers VERIFIED
      await FirebaseFirestore.instance
          .collection('risk_assessments')
          .doc(userId)
          .update({
        'tier': RiskTier.verified.name,
        'riskScore': 80,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC approuvé - Tier upgradé vers VERIFIED')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _rejectKYC(String verificationId, String? userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('kyc_verifications')
          .doc(verificationId)
          .update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC rejeté')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showAddBlacklistDialog() {
    final cniController = TextEditingController();
    final phoneController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter à la blacklist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cniController,
                decoration: const InputDecoration(
                  labelText: 'Numéro CNI',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cniController.text.isEmpty && phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez renseigner au moins un identifiant'),
                  ),
                );
                return;
              }

              try {
                await BlacklistService.addToBlacklist(
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Ajout manuel',
                  userId: 'unknown',
                  userName: 'Inconnu',
                  userType: 'unknown',
                  adminId: 'admin',
                  severity: BlacklistSeverity.high,
                  type: BlacklistType.other,
                  amountDue: 0,
                  cniNumber: cniController.text.isNotEmpty
                      ? cniController.text
                      : null,
                  phoneNumber: phoneController.text.isNotEmpty
                      ? phoneController.text
                      : null,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ajouté à la blacklist')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // ===== HELPERS =====

  Color _getTierColor(RiskTier tier) {
    switch (tier) {
      case RiskTier.trusted:
        return AppColors.success;
      case RiskTier.verified:
        return Colors.blue;
      case RiskTier.newUser:
        return Colors.grey;
      case RiskTier.moderateRisk:
        return AppColors.warning;
      case RiskTier.highRisk:
      case RiskTier.blacklisted:
        return AppColors.error;
    }
  }

  IconData _getTierIcon(RiskTier tier) {
    switch (tier) {
      case RiskTier.trusted:
        return Icons.verified;
      case RiskTier.verified:
        return Icons.check_circle;
      case RiskTier.newUser:
        return Icons.person_add;
      case RiskTier.moderateRisk:
        return Icons.warning_amber;
      case RiskTier.highRisk:
      case RiskTier.blacklisted:
        return Icons.block;
    }
  }
}
