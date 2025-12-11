// ===== lib/screens/acheteur/payment_methods_screen.dart =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment_method_model.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider_firebase.dart';
import 'package:social_business_pro/config/constants.dart';
import '../widgets/system_ui_scaffold.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentService _paymentService = PaymentService();

  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null) {
        final methods = await _paymentService.getPaymentMethodsByUser(userId);
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(PaymentMethodModel method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Voulez-vous vraiment supprimer ${method.type == 'card' ? 'cette carte' : 'ce compte'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.deletePaymentMethod(method.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Moyen de paiement supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadPaymentMethods();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(PaymentMethodModel method) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null) {
        await _paymentService.setDefaultPaymentMethod(userId, method.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Moyen de paiement par défaut défini'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadPaymentMethods();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPaymentMethodSheet(
        onAdded: () {
          Navigator.pop(context);
          _loadPaymentMethods();
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodModel method) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (method.type) {
      case 'card':
        icon = Icons.credit_card;
        color = Colors.blue;
        title = method.cardBrand ?? 'Carte bancaire';
        subtitle = '**** **** **** ${method.lastFourDigits}';
        break;
      case 'mobile_money':
        icon = Icons.phone_android;
        color = Colors.orange;
        title = method.provider ?? 'Mobile Money';
        subtitle = method.phoneNumber ?? '';
        break;
      case 'bank_transfer':
        icon = Icons.account_balance;
        color = Colors.green;
        title = 'Virement bancaire';
        subtitle = method.accountNumber ?? '';
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
        title = method.type;
        subtitle = '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (method.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Par défaut',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            if (method.expiryDate != null)
              Text(
                'Expire: ${method.expiryDate}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'default') {
              _setDefaultPaymentMethod(method);
            } else if (value == 'delete') {
              _deletePaymentMethod(method);
            }
          },
          itemBuilder: (context) => [
            if (!method.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Définir par défaut'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Moyens de paiement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun moyen de paiement',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez votre première méthode de paiement',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddPaymentMethodSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un moyen de paiement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPaymentMethods,
                  child: Column(
                    children: [
                      // Info banner
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Vos informations de paiement sont sécurisées et cryptées',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Payment methods list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            return _buildPaymentMethodCard(_paymentMethods[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _paymentMethods.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddPaymentMethodSheet,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}

// ===== Add Payment Method Sheet =====
class _AddPaymentMethodSheet extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddPaymentMethodSheet({required this.onAdded});

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Card fields
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Mobile money fields
  final _mobileNumberController = TextEditingController();
  String _selectedProvider = 'orange_money';

  // Bank transfer fields
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _mobileNumberController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) throw Exception('Utilisateur non connecté');

      final paymentService = PaymentService();
      PaymentMethodModel paymentMethod;

      switch (_tabController.index) {
        case 0: // Card
          paymentMethod = PaymentMethodModel(
            id: '',
            userId: userId,
            type: 'card',
            cardBrand: _detectCardBrand(_cardNumberController.text),
            lastFourDigits: _cardNumberController.text.replaceAll(' ', '').substring(
                  _cardNumberController.text.replaceAll(' ', '').length - 4,
                ),
            cardHolderName: _cardHolderController.text.trim(),
            expiryDate: _expiryDateController.text.trim(),
            isDefault: false,
            createdAt: DateTime.now(),
          );
          break;

        case 1: // Mobile Money
          paymentMethod = PaymentMethodModel(
            id: '',
            userId: userId,
            type: 'mobile_money',
            provider: _selectedProvider,
            phoneNumber: _mobileNumberController.text.trim(),
            isDefault: false,
            createdAt: DateTime.now(),
          );
          break;

        case 2: // Bank Transfer
          paymentMethod = PaymentMethodModel(
            id: '',
            userId: userId,
            type: 'bank_transfer',
            accountNumber: _accountNumberController.text.trim(),
            accountName: _accountNameController.text.trim(),
            bankName: _bankNameController.text.trim(),
            isDefault: false,
            createdAt: DateTime.now(),
          );
          break;

        default:
          throw Exception('Type de paiement non supporté');
      }

      await paymentService.addPaymentMethod(paymentMethod);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moyen de paiement ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _detectCardBrand(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'American Express';
    return 'Autre';
  }

  Widget _buildCardForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Numéro de carte',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro de carte est requis';
              }
              if (value.replaceAll(' ', '').length < 13) {
                return 'Numéro de carte invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              labelText: 'Nom sur la carte',
              hintText: 'JEAN DUPONT',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Date d\'expiration',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Format: MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    if (value.length < 3) {
                      return 'CVV invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisir le fournisseur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedProvider,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'orange_money',
                child: Text('Orange Money'),
              ),
              DropdownMenuItem(
                value: 'mtn_money',
                child: Text('MTN Money'),
              ),
              DropdownMenuItem(
                value: 'moov_money',
                child: Text('Moov Money'),
              ),
              DropdownMenuItem(
                value: 'wave',
                child: Text('Wave'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedProvider = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mobileNumberController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '+225 XX XX XX XX XX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: 'Nom de la banque',
              hintText: 'Ex: Bank of Africa',
              prefixIcon: const Icon(Icons.account_balance),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom de la banque est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Numéro de compte',
              hintText: 'XXXX XXXX XXXX XXXX',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro de compte est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNameController,
            decoration: InputDecoration(
              labelText: 'Nom du titulaire',
              hintText: 'JEAN DUPONT',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom du titulaire est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ajouter un moyen de paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Carte', icon: Icon(Icons.credit_card, size: 20)),
              Tab(text: 'Mobile Money', icon: Icon(Icons.phone_android, size: 20)),
              Tab(text: 'Virement', icon: Icon(Icons.account_balance, size: 20)),
            ],
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: _buildCardForm()),
                  SingleChildScrollView(child: _buildMobileMoneyForm()),
                  SingleChildScrollView(child: _buildBankTransferForm()),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}