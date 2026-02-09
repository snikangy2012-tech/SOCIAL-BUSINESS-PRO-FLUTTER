// ===== lib/models/ai_assistant_models.dart =====
// Modèles pour l'assistant IA

/// Message dans la conversation
class AIMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AIMessageType type;
  final Map<String, dynamic>? metadata;

  AIMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = AIMessageType.text,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'metadata': metadata,
  };

  factory AIMessage.fromMap(Map<String, dynamic> map) => AIMessage(
    id: map['id'] ?? '',
    content: map['content'] ?? '',
    isUser: map['isUser'] ?? false,
    timestamp: DateTime.parse(map['timestamp']),
    type: AIMessageType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => AIMessageType.text,
    ),
    metadata: map['metadata'],
  );
}

enum AIMessageType {
  text,
  quickReplies,
  action,
  tutorial,
  actionPending,    // Action en attente de confirmation
  actionExecuting,  // Action en cours d'exécution
  actionResult,     // Résultat d'une action exécutée
}

/// Question FAQ prédéfinie
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final List<String> keywords;
  final String category;
  final List<String>? relatedQuestions;
  final String? actionRoute; // Route à ouvrir si applicable

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.category,
    this.relatedQuestions,
    this.actionRoute,
  });
}

/// Étape d'onboarding
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String? targetKey; // GlobalKey pour highlight
  final String? route;
  final int order;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetKey,
    this.route,
    required this.order,
  });
}

/// Niveau d'accès IA selon abonnement
enum AIAccessLevel {
  none,      // Pas d'IA (BASIQUE sans abonnement)
  basic,     // FAQ offline uniquement (BASIQUE, Acheteur)
  pro,       // FAQ + IA online limitée (PRO)
  premium,   // FAQ + IA online illimitée (PREMIUM)
}

/// Type d'alerte
enum AlertType {
  urgent,    // Rouge - action immédiate requise
  warning,   // Orange - attention
  info,      // Bleu - information
  success,   // Vert - opportunité
}

/// Alerte intelligente pour l'utilisateur
class SmartAlert {
  final AlertType type;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;

  const SmartAlert({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });
}

/// Statut du quota LLM
class QuotaStatus {
  final bool allowed;
  final int remaining; // -1 = illimité
  final int limit;     // -1 = illimité
  final String? reason;

  const QuotaStatus({
    required this.allowed,
    required this.remaining,
    required this.limit,
    this.reason,
  });

  bool get isUnlimited => limit == -1;

  String get displayRemaining {
    if (isUnlimited) return 'Illimité';
    return '$remaining/$limit';
  }
}
