// ===== lib/widgets/ai_action_result_widget.dart =====
// Widget pour afficher le résultat d'une action exécutée via l'assistant IA

import 'package:flutter/material.dart';
import '../models/ai_action_models.dart';
import 'package:intl/intl.dart';

/// Widget pour afficher le résultat d'une action IA dans le chat
class AIActionResultWidget extends StatelessWidget {
  final AIActionResult result;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const AIActionResultWidget({
    super.key,
    required this.result,
    this.onDismiss,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: result.success
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.success
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec statut
          _buildHeader(context),

          // Message principal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              result.message,
              style: TextStyle(
                fontSize: 14,
                color: result.success ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),

          // Détails des items (pour actions en lot)
          if (result.items != null && result.items!.isNotEmpty)
            _buildItemsList(context),

          // Timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              DateFormat('HH:mm').format(result.executedAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ),

          // Boutons d'action
          if (onDismiss != null || onViewDetails != null)
            _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icône de statut
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: result.success
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.success ? Icons.check : Icons.close,
              color: result.success ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.success ? 'Action réussie' : 'Action échouée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: result.success ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                if (result.data != null && result.data!['orderNumber'] != null)
                  Text(
                    'Commande #${result.data!['orderNumber']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Badge de compteur si action en lot
          if (result.items != null && result.items!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: result.success ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${result.items!.where((i) => i.success).length}/${result.items!.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    final items = result.items!;
    final showAll = items.length <= 5;
    final displayItems = showAll ? items : items.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  item.success ? Icons.check_circle : Icons.cancel,
                  color: item.success ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (!item.success && item.error != null)
                  Tooltip(
                    message: item.error!,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.red[300],
                    ),
                  ),
              ],
            ),
          )),
          if (!showAll)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${items.length - 3} autre(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onViewDetails != null)
            TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Voir détails'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onDismiss,
              child: const Text('OK'),
              style: TextButton.styleFrom(
                foregroundColor: result.success ? Colors.green : Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Version compacte du widget de résultat pour le chat
class AIActionResultCompact extends StatelessWidget {
  final AIActionResult result;

  const AIActionResultCompact({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                color: result.success ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget indicateur d'exécution en cours
class AIActionExecutingIndicator extends StatelessWidget {
  final String? message;

  const AIActionExecutingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? 'Exécution en cours...',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une action en attente de confirmation
class AIActionPendingWidget extends StatelessWidget {
  final AIExecutableAction action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AIActionPendingWidget({
    super.key,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  });

  Color get _riskColor {
    switch (action.riskLevel) {
      case ActionRiskLevel.low:
        return Colors.green;
      case ActionRiskLevel.medium:
        return Colors.orange;
      case ActionRiskLevel.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _riskColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: _riskColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Action détectée: ${action.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _riskColor,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action.riskIcon,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          if (action.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              action.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _riskColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exécuter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
