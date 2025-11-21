// ===== lib/models/product_model.dart =====
// Modèle de données pour les produits - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de produit
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // Prix avant promo
  final String category;
  final String? subCategory;
  final String? brand;
  final List<String> images;
  final int stock;
  final int reservedStock; // Stock réservé par commandes en cours
  final String? sku; // Référence produit
  final List<String> tags;
  final bool isActive;
  final bool isFeatured; // Produit en vedette
  final String vendeurId;
  final String vendeurName;
  final Map<String, String>? specifications; // Caractéristiques techniques
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFlashSale; // ✅ AJOUT : Produit en promotion flash
  final bool isNew; // ✅ AJOUT : Produit nouveau
  final int shareCount; // Nombre de partages (viralité)
  final int viewCount; // Nombre de vues
  final DateTime? discountEndDate; // Date de fin de la promotion

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.subCategory,
    this.brand,
    required this.images,
    required this.stock,
    this.reservedStock = 0,
    this.sku,
    this.tags = const [],
    required this.isActive,
    this.isFeatured = false,
    required this.vendeurId,
    required this.vendeurName,
    this.specifications,
    required this.createdAt,
    required this.updatedAt,
    required this.isFlashSale, // ✅ AJOUT : Initialisation
    required this.isNew, // ✅ AJOUT : Initialisation
    this.shareCount = 0,
    this.viewCount = 0,
    this.discountEndDate,
  });

  /// Créer depuis Firestore
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      category: data['category'] ?? '',
      subCategory: data['subCategory'],
      brand: data['brand'],
      images: List<String>.from(data['images'] ?? []),
      stock: data['stock'] ?? 0,
      reservedStock: data['reservedStock'] ?? 0,
      sku: data['sku'],
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      vendeurId: data['vendeurId'] ?? '',
      vendeurName: data['vendeurName'] ?? '',
      specifications: data['specifications'] != null
          ? Map<String, String>.from(data['specifications'])
          : null,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      isFlashSale: data['isFlashSale'] ?? false, // ✅ AJOUT : Initialisation
      isNew: data['isNew'] ?? false, // ✅ AJOUT : Initialisation
      shareCount: data['shareCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      discountEndDate: data['discountEndDate']?.toDate(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'subCategory': subCategory,
      'brand': brand,
      'images': images,
      'stock': stock,
      'reservedStock': reservedStock,
      'sku': sku,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'vendeurId': vendeurId,
      'vendeurName': vendeurName,
      'specifications': specifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFlashSale': isFlashSale,
      'isNew': isNew,
      'shareCount': shareCount,
      'viewCount': viewCount,
      'discountEndDate': discountEndDate != null ? Timestamp.fromDate(discountEndDate!) : null,
    };
  }

  /// Copier avec modifications
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? subCategory,
    String? brand,
    List<String>? images,
    int? stock,
    int? reservedStock,
    String? sku,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    String? vendeurId,
    String? vendeurName,
    Map<String, String>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFlashSale,
    bool? isNew,
    int? shareCount,
    int? viewCount,
    DateTime? discountEndDate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      reservedStock: reservedStock ?? this.reservedStock,
      sku: sku ?? this.sku,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      vendeurId: vendeurId ?? this.vendeurId,
      vendeurName: vendeurName ?? this.vendeurName,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      isNew: isNew ?? this.isNew,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      discountEndDate: discountEndDate ?? this.discountEndDate,
    );
  }

  /// Vérifier si le produit est en promotion
  bool get hasPromotion {
    return originalPrice != null && originalPrice! > price;
  }

  /// Calculer le pourcentage de réduction
  int get discountPercentage {
    if (!hasPromotion) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  /// Vérifier si la promotion est encore valide
  bool get isDiscountActive {
    if (!hasPromotion) return false;
    if (discountEndDate == null) return true; // Promo sans limite de temps
    return DateTime.now().isBefore(discountEndDate!);
  }

  /// Stock disponible (stock total - stock réservé)
  int get availableStock {
    return stock - reservedStock;
  }

  /// Vérifier si le produit est en rupture de stock
  bool get isOutOfStock {
    return availableStock <= 0;
  }

  /// Vérifier si le stock est faible
  bool get isLowStock {
    return availableStock > 0 && availableStock <= 5;
  }

  /// Obtenir le statut du stock en texte
  String get stockStatus {
    if (isOutOfStock) return 'Rupture de stock';
    if (isLowStock) return 'Stock faible ($availableStock disponibles)';
    return 'En stock ($availableStock disponibles)';
  }

  /// Obtenir la couleur du statut du stock
  String get stockStatusColor {
    if (isOutOfStock) return 'error';
    if (isLowStock) return 'warning';
    return 'success';
  }

}