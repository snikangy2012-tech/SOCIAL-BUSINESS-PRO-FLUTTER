# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SOCIAL BUSINESS Pro** is a Flutter e-commerce platform for informal vendors in Côte d'Ivoire, supporting 4 user roles: buyers (acheteur), sellers (vendeur), delivery persons (livreur), and administrators (admin). The app features real-time GPS delivery tracking, mobile money payments, subscription-based vendor/delivery tiers, and comprehensive audit logging.

**Tech Stack**: Flutter 3.24+, Dart 3.5+, Firebase (Auth, Firestore, Storage, Messaging), Google Maps, Provider (state management), go_router (navigation)

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run app (development)
flutter run

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>         # Run on specific device
flutter run -d chrome              # Web
flutter run -d windows             # Windows desktop

# Hot reload: Press 'r' in terminal during run
# Hot restart: Press 'R' in terminal during run
```

### Code Quality
```bash
# Analyze entire codebase
flutter analyze

# Analyze specific file
flutter analyze lib/path/to/file.dart

# Format code
flutter format lib/

# Check for outdated dependencies
flutter pub outdated
```

### Build
```bash
# Clean build artifacts
flutter clean

# Build APK (Android)
flutter build apk --release

# Build app bundle (Android - for Play Store)
flutter build appbundle --release

# Build Windows desktop
flutter build windows --release

# Build web
flutter build web --release
```

### Firebase
```bash
# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

## Architecture Overview

### Directory Structure
```
lib/
├── config/          # App-wide constants, Firebase config, payment methods
├── models/          # Data models (16 models)
├── providers/       # State management (8 providers)
├── routes/          # Navigation (go_router)
├── screens/         # UI organized by role (acheteur, vendeur, livreur, admin)
├── services/        # Business logic (29 services)
├── utils/           # Utility functions
└── widgets/         # Reusable UI components
```

### Multi-Role System

**4 User Roles** (UserType enum):
- `vendeur` (Seller): Manage products, orders, shop, subscriptions
- `acheteur` (Buyer): Browse, purchase, track orders, reviews
- `livreur` (Delivery): Accept deliveries, GPS tracking, earnings
- `admin` (Administrator): User management, KYC, reports, audit logs

**Role Detection**:
- Email `admin@socialbusiness.ci` → auto-assigned admin role
- All others → userType from Firestore `users/{uid}` document
- Role stored in `UserModel.userType`

**Route Protection**:
- Router redirects enforce role-based access (`/vendeur/*`, `/acheteur/*`, `/livreur/*`, `/admin/*`)
- Vendors must complete shop setup before accessing dashboard
- See `lib/routes/app_router.dart` for full routing logic

### State Management (Provider Pattern)

**Main Providers**:
- **AuthProvider**: User authentication state, login/logout, profile updates
- **CartProvider**: Shopping cart (depends on AuthProvider)
- **FavoriteProvider**: Favorite products (depends on AuthProvider)
- **SubscriptionProvider**: Vendor/delivery subscription state
- **NotificationProvider**: FCM notifications (depends on AuthProvider)

**Setup in main.dart**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, CartProvider>(...),
    // ... other providers
  ],
  child: MaterialApp.router(routerConfig: AppRouter.createRouter(authProvider))
)
```

### Firebase Firestore Structure

**Key Collections**:
```
users/                      # User profiles with role-specific data in 'profile' field
products/                   # Product catalog (stock, reservedStock critical for inventory)
orders/                     # Customer orders (status: en_attente | en_cours | livree | annulee)
deliveries/                 # Delivery tracking (status: available | assigned | picked_up | in_transit | delivered)
vendeur_subscriptions/      # Seller tiers (BASIQUE free, PRO 5k/mo, PREMIUM 10k/mo)
livreur_subscriptions/      # Delivery tiers (hybrid performance + payment model)
refunds/                    # Refund requests
notifications/              # Push notifications
audit_logs/                 # Security and activity logs
```

**User Profile Structure**:
- Common fields: id, email, displayName, phoneNumber, userType
- Role-specific data in `profile` map field:
  - **Vendeur**: `profile['businessName']`, `profile['addresses']`, `profile['paymentSettings']`
  - **Acheteur**: `profile['addresses']`, `profile['favorites']`, `profile['loyaltyPoints']`
  - **Livreur**: `profile['vehicleType']`, `profile['deliveryZone']`, `profile['currentLocation']`
  - **Admin**: Simple profile, relies on `isSuperAdmin` boolean

**CRITICAL**: Addresses stored at `user.profile['addresses']` NOT `user.profile['acheteurProfile']['addresses']`

### Core Services

**OrderService** (`lib/services/order_service.dart`):
- CRUD operations for orders
- `updateOrderStatus()` - handles stock deduction/release based on status
- `cancelOrder()` - releases reserved stock
- Integrates with StockManagementService

**DeliveryService** (`lib/services/delivery_service.dart`):
- `createDeliveryFromOrder()` - creates delivery document with GPS coordinates
- `autoAssignDeliveryToOrder()` - auto-assigns best available driver (distance + workload + rating scoring)
- `findBestAvailableLivreur()` - driver selection algorithm
- GPS distance calculation using Haversine formula
- Tiered delivery fee calculation (0-10km: 1000 FCFA, 10-20km: 1500 FCFA, etc.)

**StockManagementService** (`lib/services/stock_management_service.dart`):
- **CRITICAL FOR INVENTORY**: Prevents overselling
- `reserveStockBatch()` - reserves stock when order created (updates `reservedStock` field)
- `deductStockBatch()` - deducts from `stock` when order delivered
- `releaseStockBatch()` - releases `reservedStock` when order cancelled
- Always use batch operations for multi-item orders

**SubscriptionService** (`lib/services/subscription_service.dart`):
- Vendor tiers: BASIQUE (free, 20 products), PRO (5k/mo, 100 products), PREMIUM (10k/mo, unlimited)
- Delivery tiers (hybrid): STARTER (free, 25% commission) → PRO (50 deliveries + 4.0★, 10k/mo, 20%) → PREMIUM (200 deliveries + 4.5★, 30k/mo, 15%)
- `checkProductLimit()` - enforce vendor product limits
- `getVendeurCommissionRate()`, `getLivreurCommissionRate()` - calculate platform fees

**MobileMoneyService** (`lib/services/mobile_money_service.dart`):
- Supports 4 providers: Orange Money, MTN MoMo, Moov Money, Wave
- Auto-detects provider from phone prefix (07/08/09 = Orange, 05/06 = MTN, etc.)
- `initiatePayment()` - calls backend API with JWT auth
- Returns USSD code for user confirmation

**GeolocationService** (`lib/services/geolocation_service.dart`):
- GPS coordinate capture, address geocoding/reverse geocoding
- Distance calculations (Haversine formula)

**AuditService** (`lib/services/audit_service.dart`):
- Logs all security events, user actions, system events
- Categories: security | userAction | systemEvent | dataChange
- Severity: low | medium | high | critical

### Key Models

**UserModel** (`lib/models/user_model.dart`):
- Base fields + polymorphic `profile` map (VendeurProfile | AcheteurProfile | LivreurProfile)
- Auth fields: isVerified, isActive, isSuperAdmin

**OrderModel** (`lib/models/order_model.dart`):
- Items, pricing (subtotal, deliveryFee, totalAmount)
- Status: en_attente | en_cours | livree | annulee
- GPS coordinates: pickupLatitude/Longitude, deliveryLatitude/Longitude
- Refund tracking: refundId, refundStatus

**ProductModel** (`lib/models/product_model.dart`):
- **CRITICAL**: `stock` and `reservedStock` fields for inventory management
- Helpers: `availableStock`, `isOutOfStock`

**DeliveryModel** (`lib/models/delivery_model.dart`):
- Status: available | assigned | picked_up | in_transit | delivered | cancelled
- Real-time tracking: currentLocation, lastLocationUpdate
- Proof of delivery: proofOfDelivery[] (image URLs)

## Critical Development Patterns

### Stock Management
**ALWAYS** use StockManagementService for inventory operations:
```dart
// Reserve stock when order created
await StockManagementService.reserveStockBatch(productsQuantities: {...});

// Deduct stock when delivered
await StockManagementService.deductStockBatch(productsQuantities: {...});

// Release stock on cancellation
await StockManagementService.releaseStockBatch(productsQuantities: {...});
```
**Never** directly update `product.stock` or `product.reservedStock` in order/checkout code.

### GPS Coordinates
All orders and deliveries REQUIRE GPS coordinates:
- Pickup: `pickupLatitude`, `pickupLongitude` (vendor shop location)
- Delivery: `deliveryLatitude`, `deliveryLongitude` (customer address)
- Validation: Check `coordinates != null` before confirming orders
- Address selection: Use `_selectedAddress` from AddressPickerScreen (contains GPS from user selection)

### Price Formatting
Use `formatPriceWithCurrency()` from `lib/utils/number_formatter.dart`:
```dart
import '../../utils/number_formatter.dart';

// Display price with thousand separators
Text(formatPriceWithCurrency(425000, currency: 'FCFA'))  // "425 000 FCFA"
```
Apply to ALL price displays to prevent overflow on 7+ digit amounts.

### Timeout Pattern (Web Compatibility)
All Firestore operations should have timeout for offline handling:
```dart
final doc = await _firestore
  .collection('users')
  .doc(uid)
  .get()
  .timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      // Fallback to local/default data
      return /* snapshot with local data */;
    },
  );
```

### Email Verification (Development Mode)
Currently DISABLED for development in `lib/services/auth_service_extended.dart`:
- Lines 162-172 (registration): Email verification commented out
- Lines 191-203 (login): Email verification check commented out
- **TODO**: Re-enable for production by uncommenting these sections

### Error Handling
Use try-catch with debug logging:
```dart
try {
  await someOperation();
} catch (e) {
  debugPrint('❌ Error in operationName: $e');
  // Show user-friendly error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

### Audit Logging
Log important actions:
```dart
await AuditService.logAction(
  userId: user.id,
  userEmail: user.email,
  userName: user.displayName ?? 'Unknown',
  userType: user.userType,
  action: 'order_created',
  actionLabel: 'Order Created',
  category: AuditCategory.userAction,
  severity: AuditSeverity.low,
  targetType: 'order',
  targetId: orderId,
  metadata: {'orderTotal': totalAmount},
);
```

## Common Tasks

### Adding a New Screen
1. Create screen file in appropriate role directory (`lib/screens/[role]/`)
2. Add route in `lib/routes/app_router.dart`
3. Add navigation guard if role-specific
4. Update navigation provider if adding to bottom nav

### Modifying User Profiles
- **Read**: `user.profile['fieldName']` from UserModel
- **Write**: Use `AuthProvider.updateProfile()` or `FirebaseService.updateUserProfile()`
- Remember: Profile structure varies by role (vendeur, acheteur, livreur)

### Working with Orders
1. Create order → reserve stock (`StockManagementService.reserveStockBatch()`)
2. Auto-assign delivery → `DeliveryService.autoAssignDeliveryToOrder()`
3. Update status → `OrderService.updateOrderStatus()` (handles stock logic)
4. Cancel → `OrderService.cancelOrder()` (releases reserved stock)

### Subscription Checks
Before features requiring subscriptions:
```dart
// Check vendor product limit
final canAdd = await SubscriptionService.checkProductLimit(vendorId);
if (!canAdd) {
  // Show upgrade prompt
}

// Get commission rate
final rate = await SubscriptionService.getVendeurCommissionRate(vendorId);
```

### KYC Verification Gates
For delivery persons accepting deliveries:
```dart
final isVerified = await KYCVerificationService.isUserVerified(userId);
if (!isVerified) {
  // Redirect to /verification-required
}
```

## Git Workflow

### Commit Messages
Follow pattern used in recent commits:
- `Fix: [Description]` - Bug fixes
- `Feature: [Description]` - New features
- `Chore: [Description]` - Maintenance, docs
- `Merge: [Description]` - Merge commits

Example: `Fix: Correction crash connexion vendeur (DropdownButton businessCategory)`

### Creating Pull Requests
- Use `gh pr create` via Claude Code's Bash tool
- Include summary of changes and test plan
- Reference related issues if applicable

## Important Notes

### Development Environment
- **Platform**: Windows (uses `cmd /c` for some commands)
- **IDE**: VSCode with Flutter extension
- **Git**: Configured with main branch as default

### Firebase Configuration
- Firebase project config: `lib/config/firebase_options.dart`
- Firestore indexes: `firestore.indexes.json` (deploy before querying)
- Storage rules: `storage.rules`

### Mobile Money API
- Backend: `https://api.socialbusinesspro.ci/v1/payments/`
- Auth: JWT token from `FirebaseAuth.currentUser.getIdToken()`
- Test mode: Check if API is in sandbox vs production

### Internationalization
- Default locale: French (Côte d'Ivoire)
- Currency: FCFA (West African CFA franc)
- Date/number formatting: Use `intl` package with French locale

### Known Issues
- MySQL warning in flutter analyze (ignore - not used, likely PATH pollution)
- Some deprecation warnings for `withOpacity()` → use `withValues()` instead
- Radio button deprecations in checkout_screen.dart (Flutter 3.32+ - consider RadioGroup migration)

## File Paths (Absolute)

### Configuration
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\config\constants.dart`
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\config\firebase_options.dart`

### Entry Point
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\main.dart`

### Routing
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\routes\app_router.dart`

### Core Services
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\services\order_service.dart`
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\services\delivery_service.dart`
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\services\stock_management_service.dart`
- `c:\Users\ALLAH-PC\social_media_business_pro\lib\services\subscription_service.dart`

### Dependencies
- `c:\Users\ALLAH-PC\social_media_business_pro\pubspec.yaml`
