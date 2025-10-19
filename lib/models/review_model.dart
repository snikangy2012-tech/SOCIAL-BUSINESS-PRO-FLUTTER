// ===== lib/models/review_model.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String targetId; // Product ID, Vendor ID, or Livreur ID
  final String targetType; // 'product', 'vendor', 'livreur'
  final String reviewerId;
  final String reviewerName;
  final int rating; // 1-5 stars
  final String comment;
  final List<String> images;
  final String? response; // Vendor/seller response
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.images = const [],
    this.response,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Utilisateur',
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      response: data['response'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'targetId': targetId,
      'targetType': targetType,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (response != null) data['response'] = response;
    if (updatedAt != null) data['updatedAt'] = Timestamp.fromDate(updatedAt!);

    return data;
  }

  // Copy with method
  ReviewModel copyWith({
    String? id,
    String? targetId,
    String? targetType,
    String? reviewerId,
    String? reviewerName,
    int? rating,
    String? comment,
    List<String>? images,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}