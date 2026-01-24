// ===== lib/screens/acheteur/request_refund_screen.dart =====
// Écran de demande de retour/remboursement - SOCIAL BUSINESS Pro

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/order_model.dart';
import '../../models/audit_log_model.dart';
import '../../services/refund_service.dart';
import '../../services/audit_service.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';

class RequestRefundScreen extends StatefulWidget {
  final OrderModel order;

  const RequestRefundScreen({
    super.key,
    required this.order,
  });

  @override
  State<RequestRefundScreen> createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends State<RequestRefundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedReason;
  List<String> _imagePaths = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          _imagePaths = pickedImages.map((img) => img.path).take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitRefundRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une raison'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final buyerId = authProvider.user?.id;
      final buyerName = authProvider.user?.displayName ?? 'Acheteur';

      if (buyerId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Upload des images vers Firebase Storage
      List<String> imageUrls = [];
      for (int i = 0; i < _imagePaths.length; i++) {
        final file = File(_imagePaths[i]);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('refund_images')
            .child('${widget.order.id}_$i.jpg');

        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        imageUrls.add(url);
      }

      // Créer la demande de remboursement
      final refundId = await RefundService.createRefundRequest(
        order: widget.order,
        buyerId: buyerId,
        buyerName: buyerName,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        images: imageUrls,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (refundId != null) {
          // Logger la demande de remboursement
          await AuditService.log(
            userId: buyerId,
            userType: authProvider.user!.userType.value,
            userEmail: authProvider.user!.email,
            userName: buyerName,
            action: 'refund_requested',
            actionLabel: 'Demande de remboursement',
            category: AuditCategory.financial,
            severity: AuditSeverity.medium,
            description: 'Demande de remboursement pour commande #${widget.order.displayNumber}',
            targetType: 'order',
            targetId: widget.order.id,
            targetLabel: 'Commande #${widget.order.displayNumber}',
            metadata: {
              'orderId': widget.order.id,
              'refundId': refundId,
              'reason': _selectedReason,
              'description': _descriptionController.text.trim(),
              'imageCount': imageUrls.length,
              'orderAmount': widget.order.totalAmount,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Demande de retour envoyée avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible de créer la demande de retour'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur création demande retour: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/acheteur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Demander un retour'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations commande
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Commande',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Commande ${widget.order.displayNumber}'),
                            Text(
                              'Montant produit: ${widget.order.totalAmount - widget.order.deliveryFee} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Frais de livraison non remboursables',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Raison du retour
                    const Text(
                      'Raison du retour *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    ...RefundReasons.getAllReasons().map((reason) {
                      return RadioListTile<String>(
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (value) {
                          setState(() => _selectedReason = value);
                        },
                        title: Text(RefundReasons.getLabel(reason)),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Description
                    const Text(
                      'Description détaillée *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Expliquez en détail le problème...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La description est requise';
                        }
                        if (value.trim().length < 20) {
                          return 'Veuillez fournir plus de détails (min 20 caractères)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Photos
                    const Text(
                      'Photos du produit (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Ajoutez des photos montrant le défaut ou le problème (max 5)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    if (_imagePaths.isEmpty)
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Ajouter des photos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                            ),
                            itemCount: _imagePaths.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: Image.file(
                                      File(_imagePaths[index]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 12),
                                        color: Colors.white,
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_imagePaths.length < 5)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: TextButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter plus de photos'),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Informations importantes
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Informations importantes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            '• Les frais de livraison ne sont pas remboursables\n'
                            '• Les frais de livraison retour seront partagés entre vous et le vendeur\n'
                            '• Le vendeur examinera votre demande sous 48h\n'
                            '• Si approuvée, le produit devra être retourné dans son état original',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRefundRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Envoyer la demande',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

