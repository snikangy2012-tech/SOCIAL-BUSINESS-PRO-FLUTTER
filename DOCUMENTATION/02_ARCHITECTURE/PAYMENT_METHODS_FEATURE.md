# Payment Methods Feature - SOCIAL BUSINESS Pro

## Date: 2025-10-16

Complete payment methods management system for Acheteurs (Buyers).

---

## ✅ Files Created

### 1. **Payment Methods Screen**
**File**: `lib/screens/acheteur/payment_methods_screen.dart`

**Features**:
- List all saved payment methods
- Add new payment methods (Card, Mobile Money, Bank Transfer)
- Set default payment method
- Delete payment methods with confirmation
- Security banner (encryption notice)
- Empty state with call-to-action
- Pull-to-refresh functionality

**Three Payment Types**:

#### a) **Card Payment**
- Card number (with auto-detection: Visa, Mastercard, Amex)
- Card holder name
- Expiry date (MM/YY format)
- CVV (3-4 digits, masked)
- Last 4 digits display for security

#### b) **Mobile Money**
- Provider selection dropdown:
  - Orange Money
  - MTN Money
  - Moov Money
  - Wave
- Phone number

#### c) **Bank Transfer**
- Bank name
- Account number
- Account holder name

**UI Components**:
- Tab-based add form (3 tabs for each payment type)
- Card-based list with icons and status
- Default badge indicator
- Popup menu for actions (Set default, Delete)
- Floating action button when list not empty

---

### 2. **Payment Method Model**
**File**: `lib/models/payment_method_model.dart`

**Fields**:
```dart
class PaymentMethodModel {
  final String id;
  final String userId;
  final String type; // 'card', 'mobile_money', 'bank_transfer'

  // Card fields
  final String? cardBrand;
  final String? lastFourDigits;
  final String? cardHolderName;
  final String? expiryDate;

  // Mobile money fields
  final String? provider;
  final String? phoneNumber;

  // Bank transfer fields
  final String? accountNumber;
  final String? accountName;
  final String? bankName;

  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Methods**:
- `fromFirestore()` - Parse Firestore document
- `toFirestore()` - Convert to Firestore format
- `copyWith()` - Immutable updates

---

### 3. **Payment Service**
**File**: `lib/services/payment_service.dart`

**Methods**:
- `getPaymentMethodsByUser(String userId)` - Get all user's payment methods
- `getDefaultPaymentMethod(String userId)` - Get default method
- `addPaymentMethod(PaymentMethodModel)` - Add new method (auto-set default if first)
- `updatePaymentMethod(String id, Map updates)` - Update existing method
- `setDefaultPaymentMethod(String userId, String id)` - Set default (batch update)
- `deletePaymentMethod(String id)` - Delete method (auto-reassign default)
- `getPaymentMethodById(String id)` - Get single method
- `isPaymentMethodValid(PaymentMethodModel)` - Validate expiry date
- `getPaymentMethodStats(String userId)` - Get statistics

**Features**:
- Offline-first with Web graceful fallback
- Batch operations for default switching
- Auto-validation of card expiry dates
- Comprehensive error handling
- Debug logging with emojis

---

### 4. **Firebase Collections Config**
**File**: `lib/config/firebase_collections.dart`

**New Collection**:
```dart
static const String paymentMethods = 'payment_methods';
```

**All Collections Defined**:
- users, sessions
- products, categories
- orders, order_items
- deliveries, delivery_tracking
- payment_methods, transactions
- addresses
- reviews
- notifications, fcm_tokens
- favorites
- analytics, activity_logs
- _connection_test

---

## 🔥 Firestore Security Rules

Add to `firestore.rules`:

```javascript
// Payment methods collection
match /payment_methods/{methodId} {
  allow read: if isAuthenticated() &&
              (resource.data.userId == request.auth.uid || isAdmin());
  allow create: if isAuthenticated() &&
                request.resource.data.userId == request.auth.uid;
  allow update: if isAuthenticated() &&
                resource.data.userId == request.auth.uid;
  allow delete: if isAuthenticated() &&
                (resource.data.userId == request.auth.uid || isAdmin());
}
```

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

---

## 📱 Integration with Profile Screen

The payment methods screen is already integrated in `acheteur_profile_screen.dart` (line 316-321):

```dart
_buildMenuTile(
  icon: Icons.payment,
  title: 'Moyens de paiement',
  subtitle: 'Gérer vos cartes et comptes',
  onTap: () => context.push('/acheteur/payment-methods'),
),
```

---

## 🚀 Next Steps

### 1. Add Route
Add to `lib/config/app_router.dart`:

```dart
GoRoute(
  path: '/acheteur/payment-methods',
  builder: (context, state) => const PaymentMethodsScreen(),
),
```

### 2. Test the Feature

**Test Cases**:
- [ ] Add card payment method
- [ ] Add mobile money payment method
- [ ] Add bank transfer payment method
- [ ] Set default payment method
- [ ] Delete payment method
- [ ] Delete default method (should auto-reassign)
- [ ] Validate card expiry date
- [ ] Test offline mode (Web)

### 3. Firestore Indexes (Optional)

If you get index errors, add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "payment_methods",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "payment_methods",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isDefault", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy:
```bash
firebase deploy --only firestore:indexes
```

---

## 💳 Payment Provider Integration (Future)

This feature provides the UI/UX for managing payment methods. For actual payment processing, you'll need to integrate:

### Popular Payment Gateways for Côte d'Ivoire:

1. **CinetPay** (Ivorian, supports Mobile Money)
   - Orange Money, MTN Money, Moov Money, Wave
   - Cards: Visa, Mastercard
   - Website: https://cinetpay.com

2. **PayDunya** (West African)
   - Mobile Money providers
   - Cards
   - Website: https://paydunya.com

3. **Stripe** (International)
   - Cards
   - Bank transfers
   - Website: https://stripe.com

4. **Paystack** (African markets)
   - Mobile Money
   - Cards
   - Website: https://paystack.com

### Integration Steps:

1. Choose a payment gateway
2. Sign up for an account
3. Get API keys (test + production)
4. Install SDK/package
5. Implement payment processing:
   - Create payment intent
   - Process payment
   - Handle webhooks
   - Update order status

### Example with CinetPay:

```yaml
dependencies:
  cinetpay_flutter: ^1.0.0  # Example package
```

```dart
// Process payment
final payment = await CinetPay.processPayment(
  amount: orderTotal,
  paymentMethod: selectedMethod,
  transactionId: orderId,
);

if (payment.success) {
  // Update order status
  await _orderService.updateOrderStatus(orderId, 'paid');
}
```

---

## 🔒 Security Best Practices

### ✅ Implemented:
- ✅ Only store last 4 digits of cards
- ✅ Never store CVV
- ✅ User-specific access control
- ✅ Firestore security rules
- ✅ Validation before saving

### ⚠️ To Implement (Production):
- Tokenization via payment gateway
- PCI-DSS compliance (use gateway's tokenization)
- HTTPS only
- Data encryption at rest
- Regular security audits
- Fraud detection
- 2FA for sensitive operations

### 🚨 Important Notes:
1. **Never store full card numbers** - Current implementation stores last 4 digits only ✅
2. **Never store CVV** - Current implementation only uses CVV for validation, doesn't store ✅
3. **Use tokenization** - Integrate with payment gateway for actual card processing
4. **Comply with PCI-DSS** - Use certified payment processors

---

## 📊 Data Structure

### Firestore Document Example:

```json
{
  "userId": "abc123",
  "type": "card",
  "cardBrand": "Visa",
  "lastFourDigits": "1234",
  "cardHolderName": "JEAN DUPONT",
  "expiryDate": "12/25",
  "isDefault": true,
  "createdAt": "2025-10-16T10:30:00Z",
  "updatedAt": "2025-10-16T11:00:00Z"
}
```

### Mobile Money Example:

```json
{
  "userId": "abc123",
  "type": "mobile_money",
  "provider": "orange_money",
  "phoneNumber": "+225 07 XX XX XX XX",
  "isDefault": false,
  "createdAt": "2025-10-16T10:30:00Z"
}
```

---

## 🎨 UI/UX Features

### Visual Design:
- Material Design 3 components
- Color-coded payment types:
  - Card: Blue
  - Mobile Money: Orange
  - Bank Transfer: Green
- Default badge with primary color
- Responsive layout
- Loading states
- Error handling

### User Experience:
- Tab-based payment type selection
- Form validation with helpful error messages
- Confirmation dialogs for destructive actions
- Success feedback (SnackBar)
- Empty state with illustration
- Pull-to-refresh
- Auto-set first method as default
- Auto-reassign default when deleted

---

## 📝 Usage Examples

### Navigate to Payment Methods:
```dart
context.push('/acheteur/payment-methods');
```

### Get Default Payment Method:
```dart
final paymentService = PaymentService();
final defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

if (defaultMethod != null) {
  print('Payer avec: ${defaultMethod.type}');
}
```

### Add Payment Method:
```dart
final newCard = PaymentMethodModel(
  id: '',
  userId: currentUserId,
  type: 'card',
  cardBrand: 'Visa',
  lastFourDigits: '1234',
  cardHolderName: 'JEAN DUPONT',
  expiryDate: '12/25',
  isDefault: false,
  createdAt: DateTime.now(),
);

await paymentService.addPaymentMethod(newCard);
```

---

## ✅ Completion Checklist

- [x] Payment Methods Screen created
- [x] Payment Method Model created
- [x] Payment Service created
- [x] Firebase Collections config created
- [x] Security rules documented
- [x] Integration with profile screen verified
- [ ] Route added to app_router.dart
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed (optional)
- [ ] Payment gateway integration (future)
- [ ] Full testing completed

---

## 💡 Tips

### For Development:
- Use test card numbers during development
- Mobile Money: Use test phone numbers
- Validate expiry dates automatically
- Show helpful error messages

### For Production:
- Integrate with real payment gateway
- Add transaction history
- Send payment receipts via email
- Add payment retry logic
- Monitor failed payments
- Add fraud detection

---

**Status**: Feature complete, ready for testing and payment gateway integration.

**Lines of Code**: ~800 (screen + model + service)

**Next Priority**: Add route to app_router.dart and test the feature.