// ===== lib/models/statistics_model.dart =====
// Modèles de données pour les statistiques - SOCIAL BUSINESS Pro

/// Réponse complète des statistiques vendeur
class VendorStatsResponse {
  final StatsOverview overview;
  final List<ChartDataPoint> chartData;
  final List<ProductStat> productStats;
  final SocialMediaStats socialStats;
  final CustomerStats customerStats;

  VendorStatsResponse({
    required this.overview,
    required this.chartData,
    required this.productStats,
    required this.socialStats,
    required this.customerStats,
  });

  factory VendorStatsResponse.fromJson(Map<String, dynamic> json) {
    return VendorStatsResponse(
      overview: StatsOverview.fromJson(json['overview'] ?? {}),
      chartData: (json['chartData'] as List<dynamic>? ?? [])
          .map((item) => ChartDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      productStats: (json['productStats'] as List<dynamic>? ?? [])
          .map((item) => ProductStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      socialStats: SocialMediaStats.fromJson(json['socialStats'] ?? {}),
      customerStats: CustomerStats.fromJson(json['customerStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': overview.toJson(),
      'chartData': chartData.map((item) => item.toJson()).toList(),
      'productStats': productStats.map((item) => item.toJson()).toList(),
      'socialStats': socialStats.toJson(),
      'customerStats': customerStats.toJson(),
    };
  }
}

/// Vue d'ensemble des statistiques principales
class StatsOverview {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double conversionRate;
  final String topProduct;
  final double growthRate;
  final int totalProducts;
  final int activeProducts;
  final int viewsThisMonth;
  final double averageRating;

  StatsOverview({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.topProduct,
    required this.growthRate,
    required this.totalProducts,
    required this.activeProducts,
    required this.viewsThisMonth,
    required this.averageRating,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) {
    return StatsOverview(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      topProduct: json['topProduct'] ?? 'Aucun',
      growthRate: (json['growthRate'] ?? 0).toDouble(),
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      viewsThisMonth: json['viewsThisMonth'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'conversionRate': conversionRate,
      'topProduct': topProduct,
      'growthRate': growthRate,
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'viewsThisMonth': viewsThisMonth,
      'averageRating': averageRating,
    };
  }
}

/// Point de données pour les graphiques
class ChartDataPoint {
  final String date;
  final double revenue;
  final int orders;
  final int views;
  final DateTime timestamp;

  ChartDataPoint({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.views,
    required this.timestamp,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      views: json['views'] ?? 0,
      timestamp: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'revenue': revenue,
      'orders': orders,
      'views': views,
    };
  }
}

/// Statistiques des réseaux sociaux
class SocialMediaStats {
  final Map<String, dynamic> whatsapp;
  final SocialMediaStat instagram;
  final SocialMediaStat tiktok;
  final SocialMediaStat facebook;

  SocialMediaStats({
    required this.whatsapp,
    required this.instagram,
    required this.tiktok,
    required this.facebook,

  });

  factory SocialMediaStats.fromJson(Map<String, dynamic> json) {
    return SocialMediaStats(
      whatsapp: json['whatsapp'] ?? {'contacts': 0, 'messagesSent': 0, 'responses': 0},
      facebook: json['facebookShares'] ?? 0,
      instagram: json['instagramMentions'] ?? 0,
      tiktok: json['tiktokShares'] ?? 0,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'whatsappShares': whatsapp,
      'facebookShares': facebook,
      'instagramMentions': instagram,
      'tiktokShares' : tiktok,
      'socialEngagementRate': socialEngagementRate,
      'totalSocialViews': totalSocialViews,
      'socialConversions': socialConversions,
    };
  }

  // Getters de compatibilité
  int get instagramMentions => instagram.followers;
  int get tiktokShares => tiktok.followers;
  int get facebookShares => facebook.followers;
  double get socialEngagementRate => (instagram.engagement + tiktok.engagement + facebook.engagement) / 3;
  int get totalSocialViews => instagram.clicks + tiktok.clicks + facebook.clicks;
  int get socialConversions => (totalSocialViews * 0.05).round();
}


/// Statistique d'une plateforme sociale individuelle
class SocialMediaStat {
  final int followers;
  final double engagement;
  final int clicks;

  SocialMediaStat({
    required this.followers,
    required this.engagement,
    required this.clicks,
  });

  factory SocialMediaStat.fromJson(Map<String, dynamic> json) {
    return SocialMediaStat(
      followers: json['followers'] ?? 0,
      engagement: (json['engagement'] ?? 0).toDouble(),
      clicks: json['clicks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers,
      'engagement': engagement,
      'clicks': clicks,
    };
  }
}

/// Statistiques des clients
class CustomerStats {
  final int newCustomers;
  final int returningCustomers;
  final double customerRetentionRate;
  final double averageLifetimeValue;
  final int totalCustomers;
  final double averageOrdersPerCustomer;
  final int newCustomersThisPeriod;

  CustomerStats({
    required this.newCustomers,
    required this.returningCustomers,
    required this.customerRetentionRate,
    required this.averageLifetimeValue,
    required this.totalCustomers,
    required this.averageOrdersPerCustomer,
    required this.newCustomersThisPeriod,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      newCustomers: json['newCustomers'] ?? 0,
      returningCustomers: json['returningCustomers'] ?? 0,
      customerRetentionRate: (json['customerRetentionRate'] ?? 0).toDouble(),
      averageLifetimeValue: (json['averageLifetimeValue'] ?? 0).toDouble(),
      totalCustomers: json['totalCustomers'] ?? 0,
      averageOrdersPerCustomer: (json['averageOrdersPerCustomer'] ?? 0).toDouble(),
      newCustomersThisPeriod: (json['newCustomersThisPriod'] ?? 0)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'customerRetentionRate': customerRetentionRate,
      'averageLifetimeValue': averageLifetimeValue,
      'totalCustomers': totalCustomers,
      'averageOrdersPerCustomer': averageOrdersPerCustomer,
    };
  }
}

/// Statistiques par produit
class ProductStat {
  final String id;
  final String name;
  final String category;
  final int sales;
  final int views;
  final double revenue;
  final double conversionRate;
  final double averageRating;
  final int stockLevel;
  final bool isActive;

  ProductStat({
    required this.id,
    required this.name,
    required this.category,
    required this.sales,
    required this.views,
    required this.revenue,
    required this.conversionRate,
    required this.averageRating,
    required this.stockLevel,
    required this.isActive,
  });

  factory ProductStat.fromJson(Map<String, dynamic> json) {
    return ProductStat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      sales: json['sales'] ?? 0,
      views: json['views'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      stockLevel: json['stockLevel'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sales': sales,
      'views': views,
      'revenue': revenue,
      'conversionRate': conversionRate,
      'averageRating': averageRating,
      'stockLevel': stockLevel,
      'isActive': isActive,
    };
  }
}

/// Période de temps pour les statistiques
enum StatsPeriod {
  day('1d', 'Aujourd\'hui'),
  week('7d', 'Cette semaine'),
  month('30d', 'Ce mois'),
  quarter('90d', 'Ce trimestre'),
  year('365d', 'Cette année'),
  all('all', 'Tout le temps');

  const StatsPeriod(this.value, this.label);
  
  final String value;
  final String label;

  static StatsPeriod fromValue(String value) {
    return StatsPeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => StatsPeriod.month,
    );
  }
}

/// Type de métrique pour les graphiques
enum MetricType {
  revenue('revenue', 'Revenus', '€'),
  orders('orders', 'Commandes', ''),
  views('views', 'Vues', ''),
  conversion('conversion', 'Conversion', '%');

  const MetricType(this.value, this.label, this.unit);
  
  final String value;
  final String label;
  final String unit;

  static MetricType fromValue(String value) {
    return MetricType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MetricType.revenue,
    );
  }
}