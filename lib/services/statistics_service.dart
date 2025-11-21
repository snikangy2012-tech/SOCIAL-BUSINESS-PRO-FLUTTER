// ===== lib/services/statistics_service.dart (VERSION RÉELLE) =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/statistics_model.dart';
import 'package:social_business_pro/config/constants.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir les statistiques complètes d'un vendeur
  static Future<VendorStatsResponse> getVendorStats(String vendorId, String period) async {
    try {
      debugPrint('📊 Chargement statistiques RÉELLES vendeur $vendorId - période $period');

      // Calculer la plage de dates
      final now = DateTime.now();
      final startDate = _getStartDateForPeriod(period, now);
      
      // ✅ VRAIES REQUÊTES FIRESTORE (plus de mock!)
      final overview = await _fetchOverviewStats(vendorId, startDate, now);
      final chartData = await _fetchChartData(vendorId, startDate, now, period);
      final productStats = await _fetchProductStats(vendorId, startDate, now);
      final socialStats = await _fetchSocialStats(vendorId);
      final customerStats = await _fetchCustomerStats(vendorId, startDate, now);

      debugPrint('✅ Statistiques réelles chargées avec succès');

      return VendorStatsResponse(
        overview: overview,
        chartData: chartData,
        productStats: productStats,
        socialStats: socialStats,
        customerStats: customerStats,
      );
      
    } catch (e) {
      debugPrint('❌ Erreur chargement statistiques: $e');
      return _getDefaultStats();
    }
  }

  // ===== MÉTHODES PRIVÉES POUR REQUÊTES RÉELLES =====

  /// Récupérer les statistiques overview depuis Firestore
  static Future<StatsOverview> _fetchOverviewStats(
    String vendorId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      // 1. Récupérer toutes les commandes de la période
      final ordersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendorId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final orders = ordersSnapshot.docs;
      final totalOrders = orders.length;

      // 2. Calculer le revenu total (commandes livrées uniquement)
      double totalRevenue = 0;
      int deliveredCount = 0;

      for (var doc in orders) {
        final data = doc.data();
        if (data['status'] == 'delivered') {
          totalRevenue += (data['totalAmount'] ?? 0).toDouble();
          deliveredCount++;
        }
      }

      final averageOrderValue = deliveredCount > 0 
          ? totalRevenue / deliveredCount 
          : 0;

      // 3. Récupérer les produits du vendeur
      final productsSnapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where('vendeurId', isEqualTo: vendorId)
          .get();

      final totalProducts = productsSnapshot.docs.length;
      final activeProducts = productsSnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      // 4. Calculer les vues (depuis collection analytics)
      int viewsThisMonth = 0;
      try {
        final analyticsDoc = await _firestore
            .collection('analytics')
            .doc(vendorId)
            .get();
        
        if (analyticsDoc.exists) {
          viewsThisMonth = (analyticsDoc.data()?['viewsThisMonth'] ?? 0) as int;
        }
      } catch (e) {
        debugPrint('⚠️ Analytics non disponibles: $e');
      }

      // 5. Trouver le produit le plus vendu
      String topProduct = 'Aucun';
      if (orders.isNotEmpty) {
        final productSales = <String, int>{};
        
        for (var order in orders) {
          final items = order.data()['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final productName = item['productName'] as String;
            productSales[productName] = (productSales[productName] ?? 0) + 1;
          }
        }

        if (productSales.isNotEmpty) {
          topProduct = productSales.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }

      // 6. Calculer taux de conversion
      double conversionRate = 0;
      if (viewsThisMonth > 0) {
        conversionRate = (totalOrders / viewsThisMonth) * 100;
      }

      // 7. Calculer taux de croissance (comparer avec période précédente)
      final previousStartDate = startDate.subtract(
        endDate.difference(startDate)
      );
      
      final previousOrdersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendorId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousStartDate))
          .where('createdAt', isLessThan: Timestamp.fromDate(startDate))
          .get();

      double previousRevenue = 0;
      for (var doc in previousOrdersSnapshot.docs) {
        if (doc.data()['status'] == 'delivered') {
          previousRevenue += (doc.data()['totalAmount'] ?? 0).toDouble();
        }
      }

      double growthRate = 0;
      if (previousRevenue > 0) {
        growthRate = ((totalRevenue - previousRevenue) / previousRevenue) * 100;
      } else if (totalRevenue > 0) {
        growthRate = 100;
      }

      // 8. Calculer note moyenne
      double averageRating = 0;
      try {
        final vendorDoc = await _firestore
            .collection(FirebaseCollections.users)
            .doc(vendorId)
            .get();
        
        if (vendorDoc.exists) {
          final profile = vendorDoc.data()?['profile'] as Map<String, dynamic>?;
          final rating = profile?['rating'] as Map<String, dynamic>?;
          averageRating = (rating?['average'] ?? 0).toDouble();
        }
      } catch (e) {
        debugPrint('⚠️ Rating non disponible: $e');
      }

      return StatsOverview(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        averageOrderValue: averageOrderValue.toDouble(),
        conversionRate: conversionRate,
        topProduct: topProduct,
        growthRate: growthRate,
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        viewsThisMonth: viewsThisMonth,
        averageRating: averageRating,
      );
      
    } catch (e) {
      debugPrint('❌ Erreur fetch overview stats: $e');
      rethrow;
    }
  }

  /// Récupérer les données du graphique
  static Future<List<ChartDataPoint>> _fetchChartData(
    String vendorId,
    DateTime startDate,
    DateTime endDate,
    String period,
  ) async {
    try {
      final pointsCount = _getPointsCount(period);
      final interval = endDate.difference(startDate).inDays ~/ pointsCount;
      
      List<ChartDataPoint> chartData = [];

      for (int i = 0; i < pointsCount; i++) {
        final pointStart = startDate.add(Duration(days: i * interval));
        final pointEnd = pointStart.add(Duration(days: interval));

        // Requête pour cette période
        final ordersSnapshot = await _firestore
            .collection(FirebaseCollections.orders)
            .where('vendeurId', isEqualTo: vendorId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(pointStart))
            .where('createdAt', isLessThan: Timestamp.fromDate(pointEnd))
            .get();

        double revenue = 0;
        int orders = 0;
        int views = 0; // À implémenter depuis analytics

        for (var doc in ordersSnapshot.docs) {
          orders++;
          if (doc.data()['status'] == 'delivered') {
            revenue += (doc.data()['totalAmount'] ?? 0).toDouble();
          }
        }

        chartData.add(ChartDataPoint(
          date: _formatDateForPeriod(pointStart, period),
          revenue: revenue,
          orders: orders,
          views: views,
          timestamp: pointStart,
        ));
      }

      return chartData;
      
    } catch (e) {
      debugPrint('❌ Erreur fetch chart data: $e');
      return [];
    }
  }

  /// Récupérer les statistiques par produit
  static Future<List<ProductStat>> _fetchProductStats(
    String vendorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 1. Récupérer tous les produits du vendeur
      final productsSnapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where('vendeurId', isEqualTo: vendorId)
          .get();

      List<ProductStat> productStats = [];

      for (var productDoc in productsSnapshot.docs) {
        final productData = productDoc.data();
        final productId = productDoc.id;
        final productName = productData['name'] ?? 'Sans nom';

        // 2. Compter les ventes pour ce produit dans la période
        final ordersSnapshot = await _firestore
            .collection(FirebaseCollections.orders)
            .where('vendeurId', isEqualTo: vendorId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        int sales = 0;
        double revenue = 0;

        for (var orderDoc in ordersSnapshot.docs) {
          final items = orderDoc.data()['items'] as List<dynamic>? ?? [];
          
          for (var item in items) {
            if (item['productId'] == productId) {
              final quantity = item['quantity'] as int;
              final price = (item['price'] as num).toDouble();
              
              sales += quantity;
              revenue += quantity * price;
            }
          }
        }

        // 3. Récupérer les vues (depuis analytics si disponible)
        int views = productData['views'] ?? 0;
        double conversionRate = views > 0 ? (sales / views) * 100 : 0;

        productStats.add(ProductStat(
          id: productId,
          name: productName,
          category: productData['category'] ?? '',
          sales: sales,
          views: views,
          revenue: revenue,
          conversionRate: conversionRate,
          averageRating: (productData['rating']?['average'] ?? 0).toDouble(),
          stockLevel: productData['stock'] ?? 0,
          isActive: productData['isActive'] ?? false,
        ));
      }

      // Trier par revenus décroissants
      productStats.sort((a, b) => b.revenue.compareTo(a.revenue));
      
      // Limiter à 10 produits max
      return productStats.take(10).toList();
      
    } catch (e) {
      debugPrint('❌ Erreur fetch product stats: $e');
      return [];
    }
  }

  /// Récupérer les statistiques réseaux sociaux
  static Future<SocialMediaStats> _fetchSocialStats(String vendorId) async {
    try {
      final vendorDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(vendorId)
          .get();

      if (!vendorDoc.exists) {
        return _getDefaultSocialStats();
      }

      final profile = vendorDoc.data()?['profile'] as Map<String, dynamic>?;
      final socialStats = profile?['socialMediaStats'] as Map<String, dynamic>?;

      if (socialStats == null) {
        return _getDefaultSocialStats();
      }

      return SocialMediaStats.fromJson(socialStats);
      
    } catch (e) {
      debugPrint('❌ Erreur fetch social stats: $e');
      return _getDefaultSocialStats();
    }
  }

  /// Récupérer les statistiques clients
  static Future<CustomerStats> _fetchCustomerStats(
    String vendorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Récupérer toutes les commandes
      final ordersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendorId)
          .get();

      final uniqueCustomers = <String>{};
      final returningCustomers = <String, int>{};

      for (var doc in ordersSnapshot.docs) {
        final customerId = doc.data()['buyerId'] as String;
        uniqueCustomers.add(customerId);
        returningCustomers[customerId] = (returningCustomers[customerId] ?? 0) + 1;
      }

      final totalCustomers = uniqueCustomers.length;
      final returning = returningCustomers.values.where((count) => count > 1).length;
      final retentionRate = totalCustomers > 0 
          ? (returning / totalCustomers) * 100 
          : 0;

      // Nouveaux clients dans la période
      final newCustomersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendorId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final newCustomerIds = <String>{};
      for (var doc in newCustomersSnapshot.docs) {
        newCustomerIds.add(doc.data()['buyerId'] as String);
      }

      return CustomerStats(
        newCustomers: newCustomerIds.length,
        returningCustomers: returning,
        customerRetentionRate: retentionRate.toDouble(),
        averageLifetimeValue: 0, // À calculer si nécessaire
        totalCustomers: totalCustomers,
        averageOrdersPerCustomer: totalCustomers > 0 
            ? ordersSnapshot.docs.length / totalCustomers 
            : 0,
        newCustomersThisPeriod: newCustomerIds.length,
      );
      
    } catch (e) {
      debugPrint('❌ Erreur fetch customer stats: $e');
      return CustomerStats(
        newCustomers: 0,
        returningCustomers: 0,
        customerRetentionRate: 0,
        averageLifetimeValue: 0,
        totalCustomers: 0,
        averageOrdersPerCustomer: 0,
        newCustomersThisPeriod: 0,
      );
    }
  }

  // ===== MÉTHODES UTILITAIRES =====

  static DateTime _getStartDateForPeriod(String period, DateTime endDate) {
    switch (period) {
      case '7d':
        return endDate.subtract(const Duration(days: 7));
      case '30d':
        return endDate.subtract(const Duration(days: 30));
      case '90d':
        return endDate.subtract(const Duration(days: 90));
      case '1y':
        return endDate.subtract(const Duration(days: 365));
      default:
        return endDate.subtract(const Duration(days: 30));
    }
  }

  static int _getPointsCount(String period) {
    switch (period) {
      case '7d':
        return 7;
      case '30d':
        return 15;
      case '90d':
        return 18;
      case '1y':
        return 24;
      default:
        return 15;
    }
  }

  static String _formatDateForPeriod(DateTime date, String period) {
    if (period == '7d') {
      return '${date.day}/${date.month}';
    } else if (period == '1y') {
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return months[date.month - 1];
    }
    return '${date.day}/${date.month}';
  }

  static SocialMediaStats _getDefaultSocialStats() {
    return SocialMediaStats(
      instagram: SocialMediaStat(followers: 0, engagement: 0, clicks: 0),
      tiktok: SocialMediaStat(followers: 0, engagement: 0, clicks: 0),
      facebook: SocialMediaStat(followers: 0, engagement: 0, clicks: 0),
      whatsapp: {'contacts': 0, 'messagesSent': 0, 'responses': 0},
    );
  }

  static VendorStatsResponse _getDefaultStats() {
    return VendorStatsResponse(
      overview: StatsOverview(
        totalRevenue: 0,
        totalOrders: 0,
        averageOrderValue: 0,
        conversionRate: 0,
        topProduct: 'Aucun',
        growthRate: 0,
        totalProducts: 0,
        activeProducts: 0,
        viewsThisMonth: 0,
        averageRating: 0,
      ),
      chartData: [],
      productStats: [],
      socialStats: _getDefaultSocialStats(),
      customerStats: CustomerStats(
        newCustomers: 0,
        returningCustomers: 0,
        customerRetentionRate: 0,
        averageLifetimeValue: 0,
        totalCustomers: 0,
        averageOrdersPerCustomer: 0,
        newCustomersThisPeriod: 0,
      ),
    );
  }
}