// ===== lib/models/category_model.dart =====
// Modèle pour les catégories de produits gérées dynamiquement

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconCodePoint; // Stockage du code point de l'icône
  final String iconFontFamily; // Famille de police de l'icône
  final List<String> subCategories;
  final bool isActive; // Permet de désactiver une catégorie sans la supprimer
  final int displayOrder; // Ordre d'affichage
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    this.subCategories = const [],
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Obtenir l'IconData à partir des données stockées
  IconData get icon {
    return IconData(
      int.parse(iconCodePoint, radix: 16),
      fontFamily: iconFontFamily,
    );
  }

  /// Créer depuis Firestore
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 'e88a', // Default: category icon
      iconFontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      subCategories: List<String>.from(data['subCategories'] ?? []),
      isActive: data['isActive'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Créer depuis une Map
  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 'e88a',
      iconFontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      subCategories: List<String>.from(data['subCategories'] ?? []),
      isActive: data['isActive'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'subCategories': subCategories,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Créer une copie avec modifications
  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconCodePoint,
    String? iconFontFamily,
    List<String>? subCategories,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      subCategories: subCategories ?? this.subCategories,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Classe helper pour convertir IconData en code point
class IconHelper {
  /// Convertir IconData en code point hexadécimal
  static String iconToCodePoint(IconData icon) {
    return icon.codePoint.toRadixString(16);
  }

  /// Obtenir la famille de police d'une icône
  static String getIconFontFamily(IconData icon) {
    return icon.fontFamily ?? 'MaterialIcons';
  }

  /// Créer CategoryModel depuis IconData
  static Map<String, String> iconDataToMap(IconData icon) {
    return {
      'iconCodePoint': iconToCodePoint(icon),
      'iconFontFamily': getIconFontFamily(icon),
    };
  }
}
