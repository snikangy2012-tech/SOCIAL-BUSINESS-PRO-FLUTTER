# Solution Paiement 100% Mobile Money (Bootstrapped)
## Pour entrepreneur solo - ZÉRO infrastructure physique

---

## 🎯 PRINCIPE DE BASE

### ÉLIMINER COMPLÈTEMENT LE CASH

**Pourquoi c'est possible en Côte d'Ivoire (2025)?**
- ✅ 75% des Ivoiriens ont Mobile Money
- ✅ Wave a explosé (transferts GRATUITS)
- ✅ Orange Money, MTN, Moov très répandus
- ✅ Culture digitale en forte croissance

**Votre avantage compétitif:**
> "Première plateforme 100% digitale - Livraison 2x plus rapide car pas d'attente cash!"

---

## 📱 LES 4 OPÉRATEURS À INTÉGRER

### 1. **Orange Money** (Leader - 60% marché)
- API: [Orange Money API](https://developer.orange.com/apis/orange-money-webpay/)
- Compte marchand: GRATUIT
- Frais: 1.5% par transaction
- Temps intégration: 2-3 jours

### 2. **MTN Mobile Money** (25% marché)
- API: [MTN MoMo API](https://momodeveloper.mtn.com/)
- Compte marchand: GRATUIT
- Frais: 1.5% par transaction
- Temps intégration: 2-3 jours

### 3. **Moov Money (Flooz)** (10% marché)
- API: Via agrégateurs (Fedapay, CinetPay)
- Frais: 2% par transaction
- Temps intégration: 1 jour

### 4. **WAVE** (5% marché - CROISSANCE RAPIDE) ⭐
- **GROS AVANTAGE**: Transferts GRATUITS entre comptes Wave
- API: [Wave API](https://developer.wave.com/)
- Compte marchand: GRATUIT
- Frais: 1% (le plus bas!)
- Clientèle jeune, tech-savvy (votre cible!)

---

## 💡 VOTRE NOUVEAU SYSTÈME

### Architecture 100% Digital

```
CLIENT COMMANDE (100,000 FCFA + 1,500 livraison)
├─ App détecte automatiquement opérateur du client
│   (via numéro de téléphone: 07/08/09 = Orange, etc.)
│
├─ PAIEMENT IMMÉDIAT (avant même qu'un livreur accepte):
│   ├─> Option A: Orange Money → Compte marchand plateforme Orange
│   ├─> Option B: MTN MoMo → Compte marchand plateforme MTN
│   ├─> Option C: Moov Money → Compte marchand plateforme Moov
│   └─> Option D: Wave → Compte marchand plateforme Wave ⭐
│
├─ Argent va dans COMPTE ESCROW DIGITAL
│   (bloqué jusqu'à livraison confirmée)
│
└─ APRÈS LIVRAISON CONFIRMÉE:
    ├─ J+2: Plateforme paie vendeur via Mobile Money
    ├─ J+7: Plateforme paie livreur via Mobile Money
    └─> Commissions restent sur compte plateforme
```

### ZÉRO CASH - Comment gérer résistance?

#### **Stratégie "Carotte + Bâton"**

**CAROTTES (Incitations):**
```
Pour les CLIENTS:
├─ Livraison GRATUITE sur 1ère commande Mobile Money
├─ Réduction -10% si paiement immédiat
├─> Cashback 2% en crédit app (pour prochaine commande)
└─> Livraison EXPRESS (priorité livreur)

Pour les VENDEURS:
├─ Règlement J+2 (au lieu J+7 pour cash chez concurrents)
├─> Commission réduite: 7% au lieu de 10%
└─> Visibilité premium dans app (badge "Paiement rapide")

Pour les LIVREURS:
├─ Bonus 1,000 FCFA/jour si 100% commandes digitales
├─> Commission +2% pour livraisons digitales
└─> Paiement QUOTIDIEN possible (au lieu hebdomadaire)
```

**BÂTONS (Si vous DEVEZ garder option cash):**
```
Cash à la livraison:
├─ Frais supplémentaires +20%
├─> Commandes <50,000 FCFA uniquement
├─> Délai livraison +2h (pas prioritaire)
└─> Commission vendeur 15% au lieu 10%

Résultat: 95% choisiront Mobile Money!
```

---

## 🔧 IMPLÉMENTATION TECHNIQUE

### Service Mobile Money Unifié (4 opérateurs)

```dart
// lib/services/unified_mobile_money_service.dart

enum MobileMoneyProvider {
  orange,    // Orange Money
  mtn,       // MTN Mobile Money
  moov,      // Moov Money (Flooz)
  wave,      // Wave
}

class UnifiedMobileMoneyService {
  static final _firestore = FirebaseFirestore.instance;

  // Comptes marchands plateforme (à créer)
  static const Map<MobileMoneyProvider, String> platformAccounts = {
    MobileMoneyProvider.orange: '+225XXXXXXXX', // Votre compte Orange Money marchand
    MobileMoneyProvider.mtn: '+225YYYYYYYY',    // Votre compte MTN MoMo marchand
    MobileMoneyProvider.moov: '+225ZZZZZZZZ',   // Votre compte Moov Money marchand
    MobileMoneyProvider.wave: '+225WWWWWWWW',   // Votre compte Wave marchand
  };

  /// Détecte automatiquement l'opérateur depuis le numéro
  static MobileMoneyProvider detectProvider(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Préfixes Côte d'Ivoire
    if (cleanNumber.startsWith('225')) {
      final prefix = cleanNumber.substring(3, 5);

      switch (prefix) {
        case '07':
        case '08':
        case '09':
          return MobileMoneyProvider.orange;

        case '05':
        case '06':
        case '15':
        case '16':
          return MobileMoneyProvider.mtn;

        case '01':
        case '02':
        case '03':
          // Wave et Moov utilisent tous les 01/02/03
          // Demander à l'utilisateur de choisir
          return MobileMoneyProvider.moov; // Défaut

        case '04':
          return MobileMoneyProvider.moov;

        default:
          return MobileMoneyProvider.orange; // Défaut
      }
    }

    return MobileMoneyProvider.orange; // Défaut
  }

  /// Initie un paiement client → plateforme
  static Future<MobileMoneyPaymentResult> initiateClientPayment({
    required String orderId,
    required double amount,
    required String customerPhone,
    required MobileMoneyProvider provider,
  }) async {
    try {
      debugPrint('💳 Initiation paiement $amount FCFA via ${provider.name}');

      switch (provider) {
        case MobileMoneyProvider.orange:
          return await _initiateOrangeMoneyPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.mtn:
          return await _initiateMTNMoMoPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.moov:
          return await _initiateMoovMoneyPayment(orderId, amount, customerPhone);

        case MobileMoneyProvider.wave:
          return await _initiateWavePayment(orderId, amount, customerPhone);
      }
    } catch (e) {
      debugPrint('❌ Erreur paiement: $e');
      return MobileMoneyPaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Orange Money - Paiement client → plateforme
  static Future<MobileMoneyPaymentResult> _initiateOrangeMoneyPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    // 1. Appel API Orange Money Web Payment
    final response = await http.post(
      Uri.parse('https://api.orange.com/orange-money-webpay/dev/v1/webpayment'),
      headers: {
        'Authorization': 'Bearer ${await _getOrangeAccessToken()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'merchant_key': 'VOTRE_MERCHANT_KEY_ORANGE',
        'currency': 'XOF', // FCFA
        'order_id': orderId,
        'amount': amount.toInt(),
        'return_url': 'https://socialbusinesspro.ci/payment/callback',
        'cancel_url': 'https://socialbusinesspro.ci/payment/cancel',
        'notif_url': 'https://socialbusinesspro.ci/payment/notify',
        'lang': 'fr',
        'reference': 'CMD-$orderId',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // 2. Enregistrer dans Firestore
      await _firestore.collection('mobile_money_payments').add({
        'orderId': orderId,
        'provider': 'orange',
        'amount': amount,
        'customerPhone': customerPhone,
        'paymentUrl': data['payment_url'],
        'paymentToken': data['pay_token'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MobileMoneyPaymentResult(
        success: true,
        paymentUrl: data['payment_url'],
        reference: data['pay_token'],
        ussdCode: _generateOrangeUSSD(amount, data['pay_token']),
      );
    }

    return MobileMoneyPaymentResult(
      success: false,
      error: 'Orange Money API error: ${response.statusCode}',
    );
  }

  /// MTN Mobile Money - Paiement client → plateforme
  static Future<MobileMoneyPaymentResult> _initiateMTNMoMoPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    // 1. Générer UUID pour transaction
    final uuid = Uuid().v4();

    // 2. Appel API MTN MoMo Collection
    final response = await http.post(
      Uri.parse('https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay'),
      headers: {
        'Authorization': 'Bearer ${await _getMTNAccessToken()}',
        'X-Reference-Id': uuid,
        'X-Target-Environment': 'mtncotedivoire', // Production
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': 'VOTRE_SUBSCRIPTION_KEY_MTN',
      },
      body: jsonEncode({
        'amount': amount.toInt().toString(),
        'currency': 'XOF',
        'externalId': orderId,
        'payer': {
          'partyIdType': 'MSISDN',
          'partyId': customerPhone,
        },
        'payerMessage': 'Paiement commande #$orderId',
        'payeeNote': 'SOCIAL BUSINESS Pro',
      }),
    );

    if (response.statusCode == 202) {
      // 3. Enregistrer transaction
      await _firestore.collection('mobile_money_payments').add({
        'orderId': orderId,
        'provider': 'mtn',
        'amount': amount,
        'customerPhone': customerPhone,
        'referenceId': uuid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MobileMoneyPaymentResult(
        success: true,
        reference: uuid,
        ussdCode: _generateMTNUSSD(amount, customerPhone),
      );
    }

    return MobileMoneyPaymentResult(
      success: false,
      error: 'MTN MoMo API error: ${response.statusCode}',
    );
  }

  /// Moov Money - Via agrégateur (Fedapay/CinetPay)
  static Future<MobileMoneyPaymentResult> _initiateMoovMoneyPayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    // Utiliser Fedapay ou CinetPay comme agrégateur
    // Simplifie l'intégration Moov Money

    final response = await http.post(
      Uri.parse('https://api.fedapay.com/v1/transactions'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY_FEDAPAY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': 'Commande #$orderId',
        'amount': amount.toInt(),
        'currency': {'iso': 'XOF'},
        'callback_url': 'https://socialbusinesspro.ci/payment/callback',
        'customer': {
          'firstname': 'Client',
          'lastname': 'SocialBusiness',
          'email': 'client@socialbusinesspro.ci',
          'phone_number': {'number': customerPhone, 'country': 'ci'},
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await _firestore.collection('mobile_money_payments').add({
        'orderId': orderId,
        'provider': 'moov',
        'amount': amount,
        'customerPhone': customerPhone,
        'transactionId': data['v1']['transaction']['id'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MobileMoneyPaymentResult(
        success: true,
        paymentUrl: data['v1']['transaction']['url'],
        reference: data['v1']['transaction']['reference'],
      );
    }

    return MobileMoneyPaymentResult(
      success: false,
      error: 'Fedapay error: ${response.statusCode}',
    );
  }

  /// WAVE - Paiement client → plateforme (GRATUIT!)
  static Future<MobileMoneyPaymentResult> _initiateWavePayment(
    String orderId,
    double amount,
    String customerPhone,
  ) async {
    // 1. Appel API Wave Payment
    final response = await http.post(
      Uri.parse('https://api.wave.com/v1/checkout/sessions'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY_WAVE',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount.toInt(),
        'currency': 'XOF',
        'error_url': 'https://socialbusinesspro.ci/payment/error',
        'success_url': 'https://socialbusinesspro.ci/payment/success',
        'metadata': {
          'order_id': orderId,
          'customer_phone': customerPhone,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await _firestore.collection('mobile_money_payments').add({
        'orderId': orderId,
        'provider': 'wave',
        'amount': amount,
        'customerPhone': customerPhone,
        'waveUrl': data['wave_launch_url'],
        'checkoutId': data['id'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MobileMoneyPaymentResult(
        success: true,
        paymentUrl: data['wave_launch_url'],
        reference: data['id'],
        ussdCode: null, // Wave utilise uniquement app mobile ou web
      );
    }

    return MobileMoneyPaymentResult(
      success: false,
      error: 'Wave API error: ${response.statusCode}',
    );
  }

  /// Vérifier statut d'un paiement
  static Future<bool> verifyPaymentStatus(String reference, MobileMoneyProvider provider) async {
    switch (provider) {
      case MobileMoneyProvider.orange:
        return await _verifyOrangePayment(reference);
      case MobileMoneyProvider.mtn:
        return await _verifyMTNPayment(reference);
      case MobileMoneyProvider.moov:
        return await _verifyFedapayPayment(reference);
      case MobileMoneyProvider.wave:
        return await _verifyWavePayment(reference);
    }
  }

  /// Envoyer paiement plateforme → vendeur/livreur
  static Future<bool> sendPayment({
    required MobileMoneyProvider provider,
    required String recipientPhone,
    required double amount,
    required String description,
  }) async {
    try {
      debugPrint('💸 Envoi $amount FCFA à $recipientPhone via ${provider.name}');

      switch (provider) {
        case MobileMoneyProvider.orange:
          return await _sendOrangeMoneyPayment(recipientPhone, amount, description);

        case MobileMoneyProvider.mtn:
          return await _sendMTNMoMoPayment(recipientPhone, amount, description);

        case MobileMoneyProvider.moov:
          return await _sendMoovMoneyPayment(recipientPhone, amount, description);

        case MobileMoneyProvider.wave:
          return await _sendWavePayment(recipientPhone, amount, description);
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi paiement: $e');
      return false;
    }
  }

  // Helpers pour générer codes USSD
  static String _generateOrangeUSSD(double amount, String token) {
    return '#144#${amount.toInt()}#$token#';
  }

  static String _generateMTNUSSD(double amount, String phone) {
    return '*133#'; // Code MTN MoMo générique
  }

  // ... Méthodes privées pour access tokens, vérifications, etc.
}

class MobileMoneyPaymentResult {
  final bool success;
  final String? paymentUrl;
  final String? reference;
  final String? ussdCode;
  final String? error;

  MobileMoneyPaymentResult({
    required this.success,
    this.paymentUrl,
    this.reference,
    this.ussdCode,
    this.error,
  });
}
```

---

## 🎨 ÉCRAN PAIEMENT CLIENT (UX Optimisée)

```dart
// lib/screens/acheteur/payment_selection_screen.dart

class PaymentSelectionScreen extends StatefulWidget {
  final OrderModel order;

  @override
  _PaymentSelectionScreenState createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  MobileMoneyProvider? _selectedProvider;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Auto-détecte l'opérateur du client
    final user = Provider.of<auth.AuthProvider>(context, listen: false).user;
    if (user?.phoneNumber != null) {
      _selectedProvider = UnifiedMobileMoneyService.detectProvider(user!.phoneNumber!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payer ma commande')),
      body: Column(
        children: [
          // Résumé commande
          _buildOrderSummary(),

          SizedBox(height: 20),

          // Sélection opérateur
          _buildProviderSelection(),

          SizedBox(height: 30),

          // Bouton payer
          _buildPayButton(),

          SizedBox(height: 20),

          // Avantages paiement digital
          _buildDigitalBenefits(),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      children: [
        Text(
          'Choisissez votre méthode de paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15),

        // Orange Money
        _buildProviderCard(
          provider: MobileMoneyProvider.orange,
          logo: 'assets/Mobile Money LOGO/orange_money.png',
          name: 'Orange Money',
          description: 'Leader Mobile Money Côte d\'Ivoire',
          recommended: _selectedProvider == MobileMoneyProvider.orange,
        ),

        // MTN Mobile Money
        _buildProviderCard(
          provider: MobileMoneyProvider.mtn,
          logo: 'assets/Mobile Money LOGO/mtn_momo.png',
          name: 'MTN Mobile Money',
          description: 'Paiement rapide et sécurisé',
        ),

        // Moov Money
        _buildProviderCard(
          provider: MobileMoneyProvider.moov,
          logo: 'assets/Mobile Money LOGO/moov_money.png',
          name: 'Moov Money',
          description: 'Flooz - Simple et efficace',
        ),

        // Wave (NOUVEAU - Mettre en avant!)
        _buildProviderCard(
          provider: MobileMoneyProvider.wave,
          logo: 'assets/Mobile Money LOGO/wave.png',
          name: 'Wave',
          description: '🎉 GRATUIT - Aucun frais!',
          badge: 'NOUVEAU',
          isSpecial: true,
        ),
      ],
    );
  }

  Widget _buildProviderCard({
    required MobileMoneyProvider provider,
    required String logo,
    required String name,
    required String description,
    bool recommended = false,
    String? badge,
    bool isSpecial = false,
  }) {
    final isSelected = _selectedProvider == provider;

    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isSpecial ? Colors.green : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Logo
            Image.asset(logo, width: 50, height: 50),

            SizedBox(width: 15),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (recommended) ...[
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.orange, size: 18),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Radio
            Radio<MobileMoneyProvider>(
              value: provider,
              groupValue: _selectedProvider,
              onChanged: (val) => setState(() => _selectedProvider = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _selectedProvider == null || _isProcessing
            ? null
            : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 15),
          minimumSize: Size(double.infinity, 50),
        ),
        child: _isProcessing
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Payer ${formatPriceWithCurrency(widget.order.totalAmount, currency: "FCFA")}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildDigitalBenefits() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paiement sécurisé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text('Livraison prioritaire (2x plus rapide)'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.money_off, color: Colors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text('Réduction -10% sur cette commande'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Initier paiement
      final result = await UnifiedMobileMoneyService.initiateClientPayment(
        orderId: widget.order.id,
        amount: widget.order.totalAmount,
        customerPhone: Provider.of<auth.AuthProvider>(context, listen: false)
            .user!
            .phoneNumber!,
        provider: _selectedProvider!,
      );

      if (result.success) {
        // 2. Afficher instructions paiement
        _showPaymentInstructions(result);
      } else {
        _showError(result.error);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showPaymentInstructions(MobileMoneyPaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Finaliser le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.ussdCode != null) ...[
              Text('Composez ce code sur votre téléphone:'),
              SizedBox(height: 10),
              SelectableText(
                result.ussdCode!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.ussdCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code USSD copié!')),
                  );
                },
                icon: Icon(Icons.copy),
                label: Text('Copier le code'),
              ),
            ] else if (result.paymentUrl != null) ...[
              Text('Cliquez pour ouvrir votre application Mobile Money:'),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _launchPaymentUrl(result.paymentUrl!),
                child: Text('Ouvrir ${_selectedProvider!.name.toUpperCase()}'),
              ),
            ],
            SizedBox(height: 20),
            Text(
              'Nous vérifions automatiquement votre paiement...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus(result.reference!);
            },
            child: Text('J\'ai payé'),
          ),
        ],
      ),
    );

    // Vérifier automatiquement toutes les 5 secondes
    _startPaymentPolling(result.reference!);
  }

  void _startPaymentPolling(String reference) async {
    for (var i = 0; i < 24; i++) {
      // 2 minutes max
      await Future.delayed(Duration(seconds: 5));

      final isPaid = await UnifiedMobileMoneyService.verifyPaymentStatus(
        reference,
        _selectedProvider!,
      );

      if (isPaid) {
        Navigator.pop(context); // Fermer dialog
        _onPaymentSuccess();
        break;
      }
    }
  }

  void _onPaymentSuccess() {
    // Afficher succès et rediriger
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Paiement réussi!'),
          ],
        ),
        content: Text(
          'Votre commande est confirmée. Un livreur va bientôt l\'accepter!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer dialog
              context.go('/acheteur/orders'); // Aller à mes commandes
            },
            child: Text('Voir ma commande'),
          ),
        ],
      ),
    );
  }
}
```

---

## 💰 COÛTS RÉELS (Bootstrapped)

### Coûts d'Intégration: **GRATUIT**

```
Ouvrir comptes marchands:
├─ Orange Money: GRATUIT
├─ MTN Mobile Money: GRATUIT
├─ Moov Money: GRATUIT
└─> Wave: GRATUIT

Intégration technique:
├─ API Orange: GRATUIT (documentation publique)
├─ API MTN: GRATUIT (sandbox + production)
├─ API Moov (via Fedapay): Inscription GRATUITE
└─> API Wave: GRATUIT

TOTAL INITIAL: 0 FCFA ✅
```

### Coûts par Transaction (Variables)

```
Par commande de 100,000 FCFA:

Client → Plateforme:
├─ Orange Money: 1,500 FCFA (1.5%)
├─ MTN MoMo: 1,500 FCFA (1.5%)
├─ Moov Money: 2,000 FCFA (2%)
└─> Wave: 1,000 FCFA (1%) ⭐

Plateforme → Vendeur (J+2):
├─ Orange Money: 1,350 FCFA (1.5% de 90k)
└─> Wave: 0 FCFA (GRATUIT entre comptes Wave!) ⭐⭐⭐

Plateforme → Livreur (J+7):
├─ Orange Money: ~20 FCFA (1.5% de 1,125)
└─> Wave: 0 FCFA (GRATUIT!) ⭐

TOTAL FRAIS (pire cas - Orange):
└─> 2,870 FCFA par commande

TOTAL FRAIS (meilleur cas - Wave):
└─> 1,000 FCFA par commande (uniquement collecte)

Commission plateforme: 10,375 FCFA
PROFIT NET: 7,505 FCFA à 9,375 FCFA ✅
```

### STRATÉGIE: **Pousser vers Wave**

```
Inciter clients Wave:
├─ "Payez avec Wave: -15% supplémentaires!"
├─> Votre coût: 1,000 FCFA au lieu 2,870 FCFA
└─> Économies: 1,870 FCFA × 1,000 commandes = 1,870,000 FCFA/mois!

Payer vendeurs en Wave:
├─ Transferts GRATUITS
├─> Économie: 1,350 FCFA par commande
└─> 1,000 commandes = 1,350,000 FCFA/mois économisés!
```

---

## 📝 CHECKLIST IMPLÉMENTATION

### Phase 1: Comptes Marchands (Semaine 1)

```
☐ Ouvrir Orange Money Marchand
  └─> Docs: RCCM, DFE, CNI dirigeant
  └─> Bureau Orange Money Business: Plateau, Abidjan

☐ Ouvrir MTN Mobile Money Marchand
  └─> Même docs
  └─> Agence MTN Business

☐ Ouvrir Moov Money Marchand
  └─> Même docs
  └─> Agence Moov Money

☐ Créer compte Wave Business
  └─> 100% en ligne: https://www.wave.com/business
  └─> Vérification 24-48h

☐ Inscription Fedapay (agrégateur Moov)
  └─> https://fedapay.com
  └─> Gratuit, validation 1-2 jours
```

### Phase 2: Intégration API (Semaine 2)

```
☐ Implémenter UnifiedMobileMoneyService
☐ Tester paiements sandbox (Orange, MTN, Wave)
☐ Implémenter vérification automatique paiements
☐ Créer écran PaymentSelectionScreen
☐ Webhook pour callbacks paiements
```

### Phase 3: Tests & Lancement (Semaine 3)

```
☐ Tester 10 paiements réels (petits montants)
☐ Vérifier distribution automatique J+2, J+7
☐ Campagne communication "100% Digital - Pas de cash!"
☐ Offre lancement: -20% sur 1ère commande Mobile Money
```

---

## 🚀 VOTRE AVANTAGE COMPÉTITIF

### Vs Glovo/Yango (qui acceptent cash):

**VOUS:**
```
✅ Livraison 2x plus rapide (pas d'attente argent)
✅ Zéro fraude cash
✅ Paiement sécurisé garanti
✅ Cashback 2% pour clients fidèles
✅ Règlement vendeur J+2 (vs J+7 concurrents)
✅ Commission vendeur 7% (vs 15-25% Glovo)
```

**Message Marketing:**
> "Social Business Pro - La première plateforme 100% digitale d'Abidjan.
> Paiement en 10 secondes. Livraison en 30 minutes. Sans cash, sans stress!"

---

## 🎯 PROCHAINES ÉTAPES

Voulez-vous que je:

1. ✅ **Implémente `UnifiedMobileMoneyService`** complet
   - Les 4 opérateurs (Orange, MTN, Moov, Wave)
   - Détection automatique
   - Paiement + Vérification

2. ✅ **Crée l'écran paiement** optimisé
   - UX simple et rapide
   - Instructions USSD claires
   - Vérification automatique

3. ✅ **Configure les webhooks** de callback
   - Pour Orange Money, MTN, Wave
   - Mise à jour automatique commandes

4. ✅ **Système escrow + distribution**
   - Bloquer fonds après paiement
   - Distribuer J+2 et J+7 automatiquement

**Par quoi commencer?**
