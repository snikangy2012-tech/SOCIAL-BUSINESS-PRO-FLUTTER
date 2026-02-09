// ===== lib/widgets/ai_action_confirmation_dialog.dart =====
// Dialogue de confirmation pour les actions exécutées via l'assistant IA

import 'package:flutter/material.dart';
import '../models/ai_action_models.dart';
import '../utils/number_formatter.dart';

/// Dialogue de confirmation pour les actions IA
class AIActionConfirmationDialog extends StatefulWidget {
  final AIExecutableAction action;
  final AIActionContext context;
  final ConfirmationData data;
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  const AIActionConfirmationDialog({
    super.key,
    required this.action,
    required this.context,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AIActionConfirmationDialog> createState() => _AIActionConfirmationDialogState();
}

class _AIActionConfirmationDialogState extends State<AIActionConfirmationDialog> {
  bool _isExecuting = false;

  Color get _riskColor {
    switch (widget.data.riskLevel) {
      case ActionRiskLevel.low:
        return Colors.green;
      case ActionRiskLevel.medium:
        return Colors.orange;
      case ActionRiskLevel.high:
        return Colors.red;
    }
  }

  IconData get _riskIcon {
    switch (widget.data.riskLevel) {
      case ActionRiskLevel.low:
        return Icons.check_circle_outline;
      case ActionRiskLevel.medium:
        return Icons.warning_amber_outlined;
      case ActionRiskLevel.high:
        return Icons.error_outline;
    }
  }

  String get _riskLabel {
    switch (widget.data.riskLevel) {
      case ActionRiskLevel.low:
        return 'Action sécurisée';
      case ActionRiskLevel.medium:
        return 'Attention requise';
      case ActionRiskLevel.high:
        return 'Action critique';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec indicateur de risque
              _buildHeader(),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message principal
                    Text(
                      widget.data.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    // Détails si disponibles
                    if (widget.data.details.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetails(),
                    ],

                    // Total si disponible
                    if (widget.data.totalAmount != null) ...[
                      const SizedBox(height: 16),
                      _buildTotalAmount(),
                    ],

                    // Avertissement si présent
                    if (widget.data.warningMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildWarning(),
                    ],
                  ],
                ),
              ),

              // Boutons d'action
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _riskColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Icône de risque
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _riskIcon,
              color: _riskColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),

          // Titre
          Text(
            widget.data.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _riskColor,
            ),
            textAlign: TextAlign.center,
          ),

          // Badge de risque
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _riskLabel,
              style: TextStyle(
                fontSize: 12,
                color: _riskColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.data.details.map((detail) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.icon != null) ...[
                  Text(detail.icon!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        detail.label,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detail.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                widget.data.itemCount != null
                    ? 'Total (${widget.data.itemCount} article(s))'
                    : 'Montant total',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          Text(
            formatPriceWithCurrency(widget.data.totalAmount!, currency: 'FCFA'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.data.warningMessage!,
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Bouton Annuler
          Expanded(
            child: OutlinedButton(
              onPressed: _isExecuting ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(widget.data.cancelButtonText),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton Confirmer
          Expanded(
            child: ElevatedButton(
              onPressed: _isExecuting ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _riskColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isExecuting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.data.confirmButtonText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isExecuting = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) {
        setState(() => _isExecuting = false);
      }
    }
  }
}

/// Affiche le dialogue de confirmation d'action IA
Future<bool> showAIActionConfirmationDialog({
  required BuildContext context,
  required AIExecutableAction action,
  required AIActionContext actionContext,
  required ConfirmationData data,
  required Future<void> Function() onConfirm,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AIActionConfirmationDialog(
      action: action,
      context: actionContext,
      data: data,
      onConfirm: () async {
        await onConfirm();
        if (ctx.mounted) {
          Navigator.of(ctx).pop(true);
        }
      },
      onCancel: () {
        Navigator.of(ctx).pop(false);
      },
    ),
  ) ?? false;
}
