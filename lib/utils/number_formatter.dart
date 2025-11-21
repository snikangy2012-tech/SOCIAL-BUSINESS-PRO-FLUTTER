/// Utilitaire pour formater les numéros d'affichage des livraisons et commandes
///
/// Ce fichier fournit des fonctions helper pour convertir les IDs Firestore
/// en numéros d'affichage incrémentaux lisibles pour l'utilisateur.
///
/// Exemples:
/// - Livraison: "abc123xyz" → "LIV-001"
/// - Commande: "def456uvw" → "CMD-001"
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Cache pour stocker les mappings ID → numéro d'affichage
/// Format: { 'deliveries': { 'id1': 1, 'id2': 2 }, 'orders': { 'id1': 1, 'id2': 2 } }
final Map<String, Map<String, int>> _displayNumberCache = {
  'deliveries': {},
  'orders': {},
};

/// Formate un ID de livraison en numéro d'affichage (LIV-XXX)
///
/// Paramètres:
/// - deliveryId: L'ID Firestore de la livraison
/// - allDeliveries: Liste optionnelle de toutes les livraisons pour établir l'ordre
///
/// Retourne: String formaté (ex: "LIV-001", "LIV-042")
String formatDeliveryNumber(String deliveryId, {List<dynamic>? allDeliveries}) {
  // Vérifier si le numéro est déjà en cache
  if (_displayNumberCache['deliveries']!.containsKey(deliveryId)) {
    final number = _displayNumberCache['deliveries']![deliveryId]!;
    return 'LIV-${number.toString().padLeft(3, '0')}';
  }

  // Si on a la liste complète, calculer l'index
  if (allDeliveries != null && allDeliveries.isNotEmpty) {
    // Trier par date de création (du plus ancien au plus récent)
    final sorted = List.from(allDeliveries);
    sorted.sort((a, b) {
      final aCreated = _getCreatedAt(a);
      final bCreated = _getCreatedAt(b);
      return aCreated.compareTo(bCreated);
    });

    // Assigner les numéros dans l'ordre
    for (var i = 0; i < sorted.length; i++) {
      final id = _getId(sorted[i]);
      if (id != null && !_displayNumberCache['deliveries']!.containsKey(id)) {
        _displayNumberCache['deliveries']![id] = i + 1;
      }
    }

    // Récupérer le numéro assigné
    if (_displayNumberCache['deliveries']!.containsKey(deliveryId)) {
      final number = _displayNumberCache['deliveries']![deliveryId]!;
      return 'LIV-${number.toString().padLeft(3, '0')}';
    }
  }

  // Fallback: utiliser un hash du début de l'ID
  final hash = deliveryId.hashCode.abs() % 999 + 1;
  return 'LIV-${hash.toString().padLeft(3, '0')}';
}

/// Formate un ID de commande en numéro d'affichage (CMD-XXX)
///
/// Paramètres:
/// - orderId: L'ID Firestore de la commande
/// - allOrders: Liste optionnelle de toutes les commandes pour établir l'ordre
///
/// Retourne: String formaté (ex: "CMD-001", "CMD-042")
String formatOrderNumber(String orderId, {List<dynamic>? allOrders}) {
  // Vérifier si le numéro est déjà en cache
  if (_displayNumberCache['orders']!.containsKey(orderId)) {
    final number = _displayNumberCache['orders']![orderId]!;
    return 'CMD-${number.toString().padLeft(3, '0')}';
  }

  // Si on a la liste complète, calculer l'index
  if (allOrders != null && allOrders.isNotEmpty) {
    // Trier par date de création (du plus ancien au plus récent)
    final sorted = List.from(allOrders);
    sorted.sort((a, b) {
      final aCreated = _getCreatedAt(a);
      final bCreated = _getCreatedAt(b);
      return aCreated.compareTo(bCreated);
    });

    // Assigner les numéros dans l'ordre
    for (var i = 0; i < sorted.length; i++) {
      final id = _getId(sorted[i]);
      if (id != null && !_displayNumberCache['orders']!.containsKey(id)) {
        _displayNumberCache['orders']![id] = i + 1;
      }
    }

    // Récupérer le numéro assigné
    if (_displayNumberCache['orders']!.containsKey(orderId)) {
      final number = _displayNumberCache['orders']![orderId]!;
      return 'CMD-${number.toString().padLeft(3, '0')}';
    }
  }

  // Fallback: utiliser un hash du début de l'ID
  final hash = orderId.hashCode.abs() % 999 + 1;
  return 'CMD-${hash.toString().padLeft(3, '0')}';
}

/// Efface le cache des numéros d'affichage
///
/// Utile quand de nouvelles livraisons/commandes sont créées
/// et qu'on veut recalculer les numéros
void clearDisplayNumberCache() {
  _displayNumberCache['deliveries']!.clear();
  _displayNumberCache['orders']!.clear();
}

/// Efface seulement le cache des livraisons
void clearDeliveryNumberCache() {
  _displayNumberCache['deliveries']!.clear();
}

/// Efface seulement le cache des commandes
void clearOrderNumberCache() {
  _displayNumberCache['orders']!.clear();
}

// --- Fonctions helper privées ---

/// Extrait la date de création d'un objet (Map ou objet avec propriété createdAt)
DateTime _getCreatedAt(dynamic item) {
  if (item is Map<String, dynamic>) {
    final createdAt = item['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    } else if (createdAt is DateTime) {
      return createdAt;
    } else if (createdAt is String) {
      return DateTime.tryParse(createdAt) ?? DateTime.now();
    }
  } else {
    // Tenter d'accéder à une propriété createdAt
    try {
      final createdAt = (item as dynamic).createdAt;
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is DateTime) {
        return createdAt;
      }
    } catch (e) {
      // Ignorer l'erreur
    }
  }
  return DateTime.now();
}

/// Extrait l'ID d'un objet (Map ou objet avec propriété id)
String? _getId(dynamic item) {
  if (item is Map<String, dynamic>) {
    return item['id'] as String?;
  } else {
    // Tenter d'accéder à une propriété id
    try {
      return (item as dynamic).id as String?;
    } catch (e) {
      return null;
    }
  }
}
