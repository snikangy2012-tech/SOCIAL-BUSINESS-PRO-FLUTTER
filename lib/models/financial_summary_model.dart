// ===== lib/models/financial_summary_model.dart =====
// Modèle pour le résumé financier mensuel

import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialSummary {
  final String id; // Format: YYYY-MM (ex: '2025-11')
  final int month; // 1-12
  final int year; // 2025, etc.

  // Totaux par catégorie
  final double commissionsVente;
  final double commissionsLivraison;
  final double abonnementsVendeurs;
  final double abonnementsLivreurs;
  final double total;

  // Statistiques
  final int nbCommandesLivrees;
  final int nbLivraisons;
  final int nbAbonnementsVendeursActifs;
  final int nbAbonnementsLivreursActifs;

  // Répartition par tier
  final Map<String, int> vendeursParTier;
  final Map<String, int> livreursParTier;

  final DateTime updatedAt;

  FinancialSummary({
    required this.id,
    required this.month,
    required this.year,
    required this.commissionsVente,
    required this.commissionsLivraison,
    required this.abonnementsVendeurs,
    required this.abonnementsLivreurs,
    required this.total,
    required this.nbCommandesLivrees,
    required this.nbLivraisons,
    required this.nbAbonnementsVendeursActifs,
    required this.nbAbonnementsLivreursActifs,
    required this.vendeursParTier,
    required this.livreursParTier,
    required this.updatedAt,
  });

  // Conversion depuis Firestore
  factory FinancialSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FinancialSummary(
      id: doc.id,
      month: data['month'] as int,
      year: data['year'] as int,
      commissionsVente: (data['commissionsVente'] as num).toDouble(),
      commissionsLivraison: (data['commissionsLivraison'] as num).toDouble(),
      abonnementsVendeurs: (data['abonnementsVendeurs'] as num).toDouble(),
      abonnementsLivreurs: (data['abonnementsLivreurs'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      nbCommandesLivrees: data['nbCommandesLivrees'] as int,
      nbLivraisons: data['nbLivraisons'] as int,
      nbAbonnementsVendeursActifs: data['nbAbonnementsVendeursActifs'] as int,
      nbAbonnementsLivreursActifs: data['nbAbonnementsLivreursActifs'] as int,
      vendeursParTier: Map<String, int>.from(data['vendeursParTier'] as Map),
      livreursParTier: Map<String, int>.from(data['livreursParTier'] as Map),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'year': year,
      'commissionsVente': commissionsVente,
      'commissionsLivraison': commissionsLivraison,
      'abonnementsVendeurs': abonnementsVendeurs,
      'abonnementsLivreurs': abonnementsLivreurs,
      'total': total,
      'nbCommandesLivrees': nbCommandesLivrees,
      'nbLivraisons': nbLivraisons,
      'nbAbonnementsVendeursActifs': nbAbonnementsVendeursActifs,
      'nbAbonnementsLivreursActifs': nbAbonnementsLivreursActifs,
      'vendeursParTier': vendeursParTier,
      'livreursParTier': livreursParTier,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Créer un résumé vide pour un mois donné
  factory FinancialSummary.empty(int year, int month) {
    final monthStr = month.toString().padLeft(2, '0');
    return FinancialSummary(
      id: '$year-$monthStr',
      month: month,
      year: year,
      commissionsVente: 0.0,
      commissionsLivraison: 0.0,
      abonnementsVendeurs: 0.0,
      abonnementsLivreurs: 0.0,
      total: 0.0,
      nbCommandesLivrees: 0,
      nbLivraisons: 0,
      nbAbonnementsVendeursActifs: 0,
      nbAbonnementsLivreursActifs: 0,
      vendeursParTier: {'basique': 0, 'pro': 0, 'premium': 0},
      livreursParTier: {'starter': 0, 'pro': 0, 'premium': 0},
      updatedAt: DateTime.now(),
    );
  }

  // Helper pour le nom du mois
  String get monthName {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  // Helper pour le label complet
  String get label => '$monthName $year';
}
