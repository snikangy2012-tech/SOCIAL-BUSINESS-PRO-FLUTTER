// lib/screens/livreur/livreur_earnings_screen.dart
// Écran de gestion des gains pour les livreurs - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/subscription_provider.dart';
import '../../services/delivery_service.dart';
import '../../models/delivery_model.dart';

class LivreurEarningsScreen extends StatefulWidget {
  const LivreurEarningsScreen({super.key});

  @override
  State<LivreurEarningsScreen> createState() => _LivreurEarningsScreenState();
}

class _LivreurEarningsScreenState extends State<LivreurEarningsScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  // Période sélectionnée
  String _selectedPeriod = 'today'; // today, week, month, all

  // Données chargées
  bool _isLoading = true;
  List<DeliveryModel> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<auth.AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Charger toutes les livraisons
      _deliveries = await _deliveryService.getLivreurDeliveries(
        livreurId: userId,
        limit: 1000,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement gains: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Filtre les livraisons selon la période sélectionnée
  List<DeliveryModel> _getFilteredDeliveries() {
    final now = DateTime.now();

    return _deliveries.where((delivery) {
      if (delivery.status != 'delivered') return false;

      switch (_selectedPeriod) {
        case 'today':
          return delivery.deliveredAt != null &&
                 delivery.deliveredAt!.year == now.year &&
                 delivery.deliveredAt!.month == now.month &&
                 delivery.deliveredAt!.day == now.day;

        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return delivery.deliveredAt != null &&
                 delivery.deliveredAt!.isAfter(weekStart);

        case 'month':
          return delivery.deliveredAt != null &&
                 delivery.deliveredAt!.year == now.year &&
                 delivery.deliveredAt!.month == now.month;

        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  /// Calcule les gains pour la période sélectionnée
  Map<String, dynamic> _calculatePeriodEarnings() {
    final filtered = _getFilteredDeliveries();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final commissionRate = subscriptionProvider.livreurCommissionRate;

    double totalFees = 0;
    double totalCommission = 0;
    double netEarnings = 0;

    for (var delivery in filtered) {
      final fee = delivery.deliveryFee;
      final commission = fee * commissionRate;
      final net = fee - commission;

      totalFees += fee;
      totalCommission += commission;
      netEarnings += net;
    }

    return {
      'deliveryCount': filtered.length,
      'totalFees': totalFees,
      'totalCommission': totalCommission,
      'netEarnings': netEarnings,
      'commissionRate': commissionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Mes Gains'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildEarningsSummaryCard(),
                    const SizedBox(height: 20),
                    _buildCommissionInfoCard(),
                    const SizedBox(height: 20),
                    _buildDeliveriesHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Sélecteur de période
  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Aujourd\'hui')),
                  ButtonSegment(value: 'week', label: Text('Semaine')),
                  ButtonSegment(value: 'month', label: Text('Mois')),
                  ButtonSegment(value: 'all', label: Text('Tout')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte récapitulatif des gains
  Widget _buildEarningsSummaryCard() {
    final data = _calculatePeriodEarnings();
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gains nets',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data['deliveryCount']} livraisons',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormat.format(data['netEarnings']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEarningsDetail(
                  'Frais totaux',
                  currencyFormat.format(data['totalFees']),
                  Icons.attach_money,
                ),
                _buildEarningsDetail(
                  'Commission',
                  currencyFormat.format(data['totalCommission']),
                  Icons.trending_down,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Carte information sur la commission
  Widget _buildCommissionInfoCard() {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final commissionRate = subscriptionProvider.livreurCommissionRate;
    final tier = subscriptionProvider.livreurTierName;
    final commissionPercent = (commissionRate * 100).toStringAsFixed(0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abonnement $tier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Commission: $commissionPercent%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigation vers l'écran d'abonnement
                    context.push('/livreur/subscription');
                  },
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Améliorer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passez au niveau PRO pour réduire votre commission à 20% !',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section historique des livraisons
  Widget _buildDeliveriesHistorySection() {
    final filtered = _getFilteredDeliveries();

    if (filtered.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucune livraison pour cette période',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des livraisons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildDeliveryHistoryItem(filtered[index]);
          },
        ),
      ],
    );
  }

  /// Item d'historique de livraison
  Widget _buildDeliveryHistoryItem(DeliveryModel delivery) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final commissionRate = subscriptionProvider.livreurCommissionRate;

    final fee = delivery.deliveryFee;
    final commission = fee * commissionRate;
    final netEarning = fee - commission;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.delivery_dining, color: AppColors.primary),
        ),
        title: Text(
          '${delivery.deliveryAddress['city'] ?? 'Destination'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dateFormat.format(delivery.deliveredAt ?? delivery.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${currencyFormat.format(netEarning)} FCFA',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${delivery.distance.toStringAsFixed(1)} km',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigation vers détails de la livraison
          context.push('/livreur/delivery-detail/${delivery.id}');
        },
      ),
    );
  }
}
