// ===== lib/models/user_model.dart =====
// Modèle utilisateur pour SOCIAL BUSINESS Pro - Flutter
// Équivalent de vos types TypeScript user.types.ts

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_business_pro/config/constants.dart'; // ✅ Import pour utiliser le UserType des constants

// ===== HELPER FUNCTIONS =====
/// Parse une date depuis Firestore - supporte Timestamp ET String
DateTime? _parseDateField(dynamic value) {
  if (value == null) return null;

  // Cas 1: C'est déjà un Timestamp Firestore
  if (value is Timestamp) {
    return value.toDate();
  }

  // Cas 2: C'est une String (format ISO ou autre)
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      // Si le parsing échoue, retourner null
      return null;
    }
  }

  // Cas 3: Type inconnu
  return null;
}

/// Parse une liste de String depuis Firestore - protection contre String unique
List<String> _parseStringList(dynamic value) {
  if (value == null) return [];

  // Cas 1: C'est déjà une List
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  // Cas 2: C'est une String unique (erreur de format)
  if (value is String) {
    return value.isEmpty ? [] : [value];
  }

  // Cas 3: Type inconnu
  return [];
}

// ===== MODÈLE UTILISATEUR PRINCIPAL =====
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final UserType userType;
  final bool isVerified;
  final VerificationStatus verificationStatus;
  final bool isActive;
  final bool isSuperAdmin; // Super administrateur avec tous les privilèges
  final List<String> deviceTokens;
  final UserPreferences preferences;
  final Map<String, dynamic> profile;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    required this.userType,
    this.isVerified = false,
    this.verificationStatus = VerificationStatus.notVerified,
    this.isActive = true,
    this.isSuperAdmin = false,
    this.deviceTokens = const [],
    required this.preferences,
    required this.profile,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  // Factory constructor depuis Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      userType: UserType.values.firstWhere(
        (type) => type.toString().split('.').last == data['userType'],
        orElse: () => UserType.acheteur,
      ),
      isVerified: data['isVerified'] ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['verificationStatus'],
        orElse: () => VerificationStatus.notVerified,
      ),
      isActive: data['isActive'] ?? true,
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      deviceTokens: _parseStringList(data['deviceTokens']),
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      profile: Map<String, dynamic>.from(data['profile'] ?? {}),
      createdAt: _parseDateField(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateField(data['updatedAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateField(data['lastLoginAt']),
    );
  }

  // Factory constructor depuis Map
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      userType: UserType.values.firstWhere(
        (type) => type.toString().split('.').last == data['userType'],
        orElse: () => UserType.acheteur,
      ),
      isVerified: data['isVerified'] ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['verificationStatus'],
        orElse: () => VerificationStatus.notVerified,
      ),
      isActive: data['isActive'] ?? true,
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      deviceTokens: _parseStringList(data['deviceTokens']),
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      profile: Map<String, dynamic>.from(data['profile'] ?? {}),
      createdAt: _parseDateField(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateField(data['updatedAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateField(data['lastLoginAt']),
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'userType': userType.toString().split('.').last,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus.toString().split('.').last,
      'isActive': isActive,
      'isSuperAdmin': isSuperAdmin,
      'deviceTokens': deviceTokens,
      'preferences': preferences.toMap(),
      'profile': profile,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    UserType? userType,
    bool? isVerified,
    VerificationStatus? verificationStatus,
    bool? isActive,
    List<String>? deviceTokens,
    UserPreferences? preferences,
    Map<String, dynamic>? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      deviceTokens: deviceTokens ?? this.deviceTokens,
      preferences: preferences ?? this.preferences,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

// ===== PRÉFÉRENCES UTILISATEUR =====
class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'fr', 'en'
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool marketingEmails;
  final String currency; // 'XOF', 'EUR', 'USD'

  UserPreferences({
    this.theme = 'light',
    this.language = 'fr',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.marketingEmails = false,
    this.currency = 'XOF',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      theme: data['theme'] ?? 'light',
      language: data['language'] ?? 'fr',
      emailNotifications: data['emailNotifications'] ?? true,
      pushNotifications: data['pushNotifications'] ?? true,
      smsNotifications: data['smsNotifications'] ?? false,
      marketingEmails: data['marketingEmails'] ?? false,
      currency: data['currency'] ?? 'XOF',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'marketingEmails': marketingEmails,
      'currency': currency,
    };
  }
}

// ===== PROFIL VENDEUR =====
class VendeurProfile {
  final String businessName;
  final String businessType; // 'individual', 'company'
  final String? businessDescription;
  final String businessCategory;
  final String? businessAddress;
  final String? businessPhone;     // 📞 Téléphone de la boutique
  final double? businessLatitude;  // 📍 Coordonnées GPS de la boutique
  final double? businessLongitude; // 📍 Coordonnées GPS de la boutique
  final String? shopImageUrl;      // 🖼️ Image de la boutique
  final List<String> deliveryZones;
  final double deliveryPrice;
  final double? freeDeliveryThreshold;
  final bool acceptsCashOnDelivery;
  final bool acceptsOnlinePayment;
  final String? whatsappNumber;
  final String? facebookPage;
  final String? instagramHandle;
  final String? tiktokHandle;
  final PaymentInfo paymentInfo;
  final BusinessStats stats;
  final DeliverySettings deliverySettings;

  VendeurProfile({
    required this.businessName,
    this.businessType = 'individual',
    this.businessDescription,
    required this.businessCategory,
    this.businessAddress,
    this.businessPhone,
    this.businessLatitude,
    this.businessLongitude,
    this.shopImageUrl,
    this.deliveryZones = const [],
    this.deliveryPrice = 0,
    this.freeDeliveryThreshold,
    this.acceptsCashOnDelivery = true,
    this.acceptsOnlinePayment = false,
    this.whatsappNumber,
    this.facebookPage,
    this.instagramHandle,
    this.tiktokHandle,
    required this.paymentInfo,
    required this.stats,
    required this.deliverySettings,
  });

  factory VendeurProfile.fromMap(Map<String, dynamic> data) {
    return VendeurProfile(
      businessName: data['businessName'] ?? '',
      businessType: data['businessType'] ?? 'individual',
      businessDescription: data['businessDescription'],
      businessCategory: data['businessCategory'] ?? '',
      businessAddress: data['businessAddress'],
      businessPhone: data['businessPhone'],
      businessLatitude: data['businessLatitude']?.toDouble(),
      businessLongitude: data['businessLongitude']?.toDouble(),
      shopImageUrl: data['shopImageUrl'],
      deliveryZones: _parseStringList(data['deliveryZones']),
      deliveryPrice: (data['deliveryPrice'] ?? 0).toDouble(),
      freeDeliveryThreshold: data['freeDeliveryThreshold']?.toDouble(),
      acceptsCashOnDelivery: data['acceptsCashOnDelivery'] ?? true,
      acceptsOnlinePayment: data['acceptsOnlinePayment'] ?? false,
      whatsappNumber: data['whatsappNumber'],
      facebookPage: data['facebookPage'],
      instagramHandle: data['instagramHandle'],
      tiktokHandle: data['tiktokHandle'],
      paymentInfo: PaymentInfo.fromMap(data['paymentInfo'] ?? {}),
      stats: BusinessStats.fromMap(data['stats'] ?? {}),
      deliverySettings: DeliverySettings.fromMap(data['deliverySettings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessType': businessType,
      'businessDescription': businessDescription,
      'businessCategory': businessCategory,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessLatitude': businessLatitude,
      'businessLongitude': businessLongitude,
      'shopImageUrl': shopImageUrl,
      'deliveryZones': deliveryZones,
      'deliveryPrice': deliveryPrice,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'acceptsCashOnDelivery': acceptsCashOnDelivery,
      'acceptsOnlinePayment': acceptsOnlinePayment,
      'whatsappNumber': whatsappNumber,
      'facebookPage': facebookPage,
      'instagramHandle': instagramHandle,
      'tiktokHandle': tiktokHandle,
      'paymentInfo': paymentInfo.toMap(),
      'stats': stats.toMap(),
      'deliverySettings': deliverySettings.toMap(),
    };
  }
}

// ===== PROFIL ACHETEUR =====
class AcheteurProfile {
  final List<Address> addresses;
  final List<String> favorites;
  final int totalPurchases;
  final double totalSpent;
  final int totalOrders;
  final String preferredPaymentMethod;
  final DeliveryPreferences deliveryPreferences;
  final int loyaltyPoints;

  AcheteurProfile({
    this.addresses = const [],
    this.favorites = const [],
    this.totalPurchases = 0,
    this.totalSpent = 0,
    this.totalOrders = 0,
    this.preferredPaymentMethod = 'orange_money',
    required this.deliveryPreferences,
    this.loyaltyPoints = 0,
  });

  factory AcheteurProfile.fromMap(Map<String, dynamic> data) {
    return AcheteurProfile(
      addresses: (data['addresses'] as List?)
          ?.map((addr) => Address.fromMap(addr))
          .toList() ?? [],
      favorites: _parseStringList(data['favorites']),
      totalPurchases: data['totalPurchases'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      preferredPaymentMethod: data['preferredPaymentMethod'] ?? 'orange_money',
      deliveryPreferences: DeliveryPreferences.fromMap(data['deliveryPreferences'] ?? {}),
      loyaltyPoints: data['loyaltyPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'favorites': favorites,
      'totalPurchases': totalPurchases,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'preferredPaymentMethod': preferredPaymentMethod,
      'deliveryPreferences': deliveryPreferences.toMap(),
      'loyaltyPoints': loyaltyPoints,
    };
  }
}

// ===== PROFIL LIVREUR =====
class LivreurProfile {
  final String vehicleType; // 'moto', 'voiture', 'velo'
  final String? licenseNumber;
  final String deliveryZone;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewsCount;
  final int totalDeliveries;
  final double totalEarnings;
  final LocationCoords? currentLocation;
  final DateTime? lastLocationUpdate;
  final DeliveryRates deliveryRates;
  final WorkingHours workingHours;
  final Map<String, String> documents;

  LivreurProfile({
    required this.vehicleType,
    this.licenseNumber,
    required this.deliveryZone,
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.currentLocation,
    this.lastLocationUpdate,
    required this.deliveryRates,
    required this.workingHours,
    this.documents = const {},
  });

  factory LivreurProfile.fromMap(Map<String, dynamic> data) {
    return LivreurProfile(
      vehicleType: data['vehicleType'] ?? 'moto',
      licenseNumber: data['licenseNumber'],
      deliveryZone: data['deliveryZone'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      totalDeliveries: data['totalDeliveries'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      currentLocation: data['currentLocation'] != null
          ? LocationCoords.fromMap(data['currentLocation'])
          : null,
      lastLocationUpdate: _parseDateField(data['lastLocationUpdate']),
      deliveryRates: DeliveryRates.fromMap(data['deliveryRates'] ?? {}),
      workingHours: WorkingHours.fromMap(data['workingHours'] ?? {}),
      documents: Map<String, String>.from(data['documents'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'deliveryZone': deliveryZone,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'currentLocation': currentLocation?.toMap(),
      'lastLocationUpdate': lastLocationUpdate != null 
          ? Timestamp.fromDate(lastLocationUpdate!) 
          : null,
      'deliveryRates': deliveryRates.toMap(),
      'workingHours': workingHours.toMap(),
      'documents': documents,
    };
  }
}

// ===== CLASSES UTILITAIRES =====

// Adresse
class Address {
  final String id;
  final String label; // 'Domicile', 'Bureau', etc.
  final String street;
  final String commune;
  final String city;
  final String? postalCode;
  final LocationCoords? coordinates;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.commune,
    required this.city,
    this.postalCode,
    this.coordinates,
    this.isDefault = false,
  });

  factory Address.fromMap(Map<String, dynamic> data) {
    return Address(
      id: data['id'] ?? '',
      label: data['label'] ?? '',
      street: data['street'] ?? '',
      commune: data['commune'] ?? '',
      city: data['city'] ?? '',
      postalCode: data['postalCode'],
      coordinates: data['coordinates'] != null 
          ? LocationCoords.fromMap(data['coordinates']) 
          : null,
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'commune': commune,
      'city': city,
      'postalCode': postalCode,
      'coordinates': coordinates?.toMap(),
      'isDefault': isDefault,
    };
  }
}

// Coordonnées GPS
class LocationCoords {
  final double latitude;
  final double longitude;

  LocationCoords({
    required this.latitude,
    required this.longitude,
  });

  factory LocationCoords.fromMap(Map<String, dynamic> data) {
    return LocationCoords(
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Informations de paiement
class PaymentInfo {
  final Map<String, String> mobileMoney;
  final Map<String, String> bankDetails;

  PaymentInfo({
    this.mobileMoney = const {},
    this.bankDetails = const {},
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> data) {
    return PaymentInfo(
      mobileMoney: Map<String, String>.from(data['mobileMoney'] ?? {}),
      bankDetails: Map<String, String>.from(data['bankDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mobileMoney': mobileMoney,
      'bankDetails': bankDetails,
    };
  }
}

// Statistiques business
class BusinessStats {
  final int totalSales;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final String responseTime;

  BusinessStats({
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.responseTime = '0h',
  });

  factory BusinessStats.fromMap(Map<String, dynamic> data) {
    return BusinessStats(
      totalSales: data['totalSales'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalOrders: data['totalOrders'] ?? 0,
      completedOrders: data['completedOrders'] ?? 0,
      cancelledOrders: data['cancelledOrders'] ?? 0,
      responseTime: data['responseTime'] ?? '0h',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'responseTime': responseTime,
    };
  }
}

// Paramètres de livraison
class DeliverySettings {
  final double freeShippingMinimum;
  final double standardShippingCost;
  final double expressShippingCost;

  DeliverySettings({
    this.freeShippingMinimum = 0,
    this.standardShippingCost = 0,
    this.expressShippingCost = 0,
  });

  factory DeliverySettings.fromMap(Map<String, dynamic> data) {
    return DeliverySettings(
      freeShippingMinimum: (data['freeShippingMinimum'] ?? 0).toDouble(),
      standardShippingCost: (data['standardShippingCost'] ?? 0).toDouble(),
      expressShippingCost: (data['expressShippingCost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'freeShippingMinimum': freeShippingMinimum,
      'standardShippingCost': standardShippingCost,
      'expressShippingCost': expressShippingCost,
    };
  }
}

// Préférences de livraison
class DeliveryPreferences {
  final String preferredTimeSlot; // 'morning', 'afternoon', 'evening'
  final bool allowCallsForDelivery;
  final bool allowSMSNotifications;

  DeliveryPreferences({
    this.preferredTimeSlot = 'morning',
    this.allowCallsForDelivery = true,
    this.allowSMSNotifications = true,
  });

  factory DeliveryPreferences.fromMap(Map<String, dynamic> data) {
    return DeliveryPreferences(
      preferredTimeSlot: data['preferredTimeSlot'] ?? 'morning',
      allowCallsForDelivery: data['allowCallsForDelivery'] ?? true,
      allowSMSNotifications: data['allowSMSNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredTimeSlot': preferredTimeSlot,
      'allowCallsForDelivery': allowCallsForDelivery,
      'allowSMSNotifications': allowSMSNotifications,
    };
  }
}

// Tarifs de livraison
class DeliveryRates {
  final double standard;
  final double express;

  DeliveryRates({
    this.standard = 0,
    this.express = 0,
  });

  factory DeliveryRates.fromMap(Map<String, dynamic> data) {
    return DeliveryRates(
      standard: (data['standard'] ?? 0).toDouble(),
      express: (data['express'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'standard': standard,
      'express': express,
    };
  }
}

// Heures de travail
class WorkingHours {
  final String start;
  final String end;

  WorkingHours({
    this.start = '08:00',
    this.end = '20:00',
  });

  factory WorkingHours.fromMap(Map<String, dynamic> data) {
    return WorkingHours(
      start: data['start'] ?? '08:00',
      end: data['end'] ?? '20:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }
}