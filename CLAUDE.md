# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SOCIAL BUSINESS Pro** is a Flutter e-commerce platform for informal vendors in Côte d'Ivoire. It supports four user types (Acheteur/Buyer, Vendeur/Seller, Livreur/Delivery, Admin) with Firebase backend integration.

- **Platform**: Flutter Web + Mobile (iOS, Android)
- **Flutter Version**: 3.35.4
- **Dart Version**: 3.9.2
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **State Management**: Provider
- **Navigation**: go_router
- **Language**: French (primary), with French variable/comment conventions

## Development Commands

### Build & Run
```bash
# Web development
flutter run -d chrome

# Build for web production
flutter build web --release

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for linting issues
flutter analyze --no-pub
```

### Firebase Deployment
```bash
# Deploy to Firebase Hosting
flutter build web --release
firebase deploy --only hosting

# Deploy functions (if any)
firebase deploy --only functions
```

### Dependency Management
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build cache
flutter clean
```

## Architecture

### Multi-User Type System

The app is architected around **four distinct user types**, each with dedicated screens, routing, and business logic:

1. **Acheteur** (Buyer): Browse products, manage cart, place orders
2. **Vendeur** (Seller): Manage products, view orders, track statistics
3. **Livreur** (Delivery): View assigned deliveries, update delivery status
4. **Admin**: User management, platform oversight

**Critical**: User type determines routing, permissions, and available features. The `UserType` enum in `lib/config/constants.dart` is the source of truth.

### Authentication Flow

Authentication uses a **dual-service pattern** to handle Web vs Mobile differences:

- **`lib/services/firebase_service.dart`**: Primary service for Mobile (uses Firestore extensively)
- **`lib/services/auth_service_web.dart`**: Optimized for Web (minimal Firestore dependency due to localhost connection issues)
- **`lib/providers/auth_provider_firebase.dart`**: State management layer that wraps both services

**Web-specific workaround**: Due to Firestore connectivity issues on localhost, the app uses a temporary email-to-userType mapping in `lib/config/user_type_config.dart`. This is **not production-ready** and should be replaced when deploying to Firebase Hosting.

**Important Login Detection**:
- Admin accounts are detected by email pattern (`admin@socialbusiness.ci` or emails containing `admin@`)
- This detection happens in both `auth_service_web.dart:139-165` and `auth_provider_firebase.dart:246-275`

### Routing Architecture

The app uses `go_router` with **role-based access control**:

- **Router creation**: `lib/routes/app_router.dart` - Creates router with `AuthProvider` for state-aware redirects
- **Redirect logic**: Lines 40-108 in `app_router.dart` handle user type-based navigation
- **Route protection**: Routes starting with `/vendeur`, `/admin`, `/livreur`, `/acheteur` are protected by user type
- **Public routes**: `/`, `/login`, `/register`, `/product/:id` are accessible without authentication

**Navigation patterns**:
- Authenticated users are automatically redirected to their role-specific dashboard
- Each user type has a dedicated main screen (e.g., `VendeurMainScreen`, `AcheteurHome`)
- Bottom navigation is user type-specific (see `lib/screens/main_scaffold.dart`)

### State Management Pattern

Uses **Provider** with a specific hierarchy:

```
MultiProvider
├── AuthProvider (root-level, independent)
├── VendeurNavigationProvider (independent)
└── CartProvider (depends on AuthProvider via ChangeNotifierProxyProvider)
```

**Key pattern**: `CartProvider` uses `ChangeNotifierProxyProvider` to react to auth changes and set the user ID automatically.

### Firebase Integration

**Configuration**:
- Platform-specific configs in `lib/config/firebase_options.dart`
- Collections defined in `lib/config/constants.dart` (`FirebaseCollections` class)

**Services**:
- **`lib/services/firebase_service.dart`**: Core CRUD operations with retry logic
- **`lib/services/firestore_service.dart`**: Additional Firestore helpers
- **`lib/services/product_service.dart`**: Product-specific operations
- **`lib/services/order_service.dart`**: Order management
- **`lib/services/delivery_service.dart`**: Delivery tracking
- **`lib/services/notification_service.dart`**: Push notifications
- **`lib/services/analytics_service.dart`**: Firebase Analytics

**Web-specific concerns**:
- Firestore persistence is disabled on Web (`persistenceEnabled: false` in `main.dart:48`)
- Connection tests with 5-30 second timeouts (see `main.dart:54-78`)
- Automatic fallback to local config if Firestore is unreachable

### Data Models

All models follow a consistent pattern with `fromMap`, `toMap`, `fromFirestore`, and `copyWith` methods:

- **`lib/models/user_model.dart`**: `UserModel` with role-specific profiles (VendeurProfile, AcheteurProfile, LivreurProfile)
- **`lib/models/product_model.dart`**: Products with inventory, pricing, and vendor info
- **`lib/models/order_model.dart`**: Order lifecycle management
- **`lib/models/delivery_model.dart`**: Delivery tracking
- **`lib/models/notification_model.dart`**: Notifications
- **`lib/models/payment_model.dart`**: Payment processing
- **`lib/models/statistics_model.dart`**: Business analytics

### Screen Organization

Screens are organized by user type:

```
lib/screens/
├── auth/              # Login, registration, OTP
├── acheteur/          # Buyer screens (home, cart, checkout, orders)
├── vendeur/           # Seller screens (dashboard, products, orders, stats)
├── livreur/           # Delivery screens (dashboard, deliveries)
├── admin/             # Admin screens (dashboard, user management)
├── common/            # Shared screens (notifications)
├── main_scaffold.dart # Bottom nav wrapper
└── temp_screens.dart  # Placeholder for unimplemented screens
```

**Navigation within screens**: Use `context.push('/route')` or `context.go('/route')` from go_router.

## Important Implementation Notes

### Firestore Connection Handling

**Problem**: Firestore may timeout or fail on localhost Web development.

**Solutions implemented**:
1. Automatic retry logic with exponential backoff in `firebase_service.dart:186-223`
2. Connection status checks before operations (`checkFirestoreConnection()`)
3. Fallback to `UserTypeConfig` email mapping for Web auth
4. Extended timeouts for Web (30-120 seconds vs 5-10 for mobile)

**When adding new Firestore operations**:
- Always check connection first (or assume true on Web)
- Use `.timeout()` for mobile, but allow longer/no timeout for Web
- Implement graceful fallbacks for read failures

### User Type Detection

User type is determined in this order:
1. Firestore document `userType` field
2. Email pattern matching for admin (`admin@` prefix)
3. Local config map in `UserTypeConfig.emailToUserType`
4. Default to `acheteur`

**Never hardcode user types in UI logic** - always check `authProvider.user?.userType`.

### Product Categories

Categories are defined in `lib/config/product_categories.dart`. When adding products, use these predefined categories for consistency.

### Payment Integration

Mobile Money providers (Orange Money, MTN Money, Moov Money) are integrated via `lib/services/mobile_money_service.dart`. This is specific to West African markets.

### Geolocation Features

The app includes geolocation for:
- Delivery tracking (`geolocator`, `location` packages)
- Google Maps integration (`google_maps_flutter`)
- Proximity-based vendor discovery

**Permissions**: Location permissions are managed via `permission_handler` package.

### Image Handling

Images are managed through:
- Selection: `image_picker` package
- Storage: Firebase Storage
- Display: `CachedNetworkImage` pattern (implement as needed)

### Notifications

Two-tier notification system:
- **Push**: Firebase Cloud Messaging (`firebase_messaging`)
- **Local**: `flutter_local_notifications`

## Known Issues & Workarounds

### 1. Firestore on Localhost

**Issue**: Firestore cannot connect from `localhost` on some networks/firewalls.

**Current workaround**: `UserTypeConfig` email mapping (see `SOLUTION_PRODUCTION.md`)

**Permanent solution**: Deploy to Firebase Hosting or configure a user type selector in registration.

### 2. Admin Account Creation

**Issue**: No UI to designate admin users during registration.

**Workaround**: Admin detection by email pattern (`admin@socialbusiness.ci`).

**Better solution**: Create an admin panel for user role management (see `/admin/users` route).

### 3. Missing Screens

Some routes point to `TempScreen` placeholders. Priority missing screens (see `ROUTES_DOCUMENTATION.md`):
- Delivery detail (`/livreur/delivery/:id`)
- Admin vendor management (`/admin/vendors`)
- Admin livreur management (`/admin/livreurs`)
- Address management (`/acheteur/addresses`)
- Settings (`/settings`)

## Code Style & Conventions

- **Language**: French for user-facing text, comments, and variable names
- **Naming**: Use descriptive French names (e.g., `vendeurId`, `acheteurProfile`)
- **Comments**: Write in French to match existing codebase
- **Constants**: Define in `lib/config/constants.dart` (colors, collections, enums)
- **Error messages**: Use French with emoji for better UX (e.g., `'✅ Connexion réussie'`)

## Testing Strategy

Currently minimal test coverage. When adding tests:
- Unit tests for services (`lib/services/`)
- Widget tests for reusable components
- Integration tests for critical flows (auth, checkout)

## Firebase Collections Structure

```
users/
  {userId}/
    - email, displayName, phoneNumber, userType
    - profile: { role-specific data }
    - preferences: { theme, notifications }

products/
  {productId}/
    - name, price, stock, category
    - vendeurId, vendeurName
    - images[], createdAt

orders/
  {orderId}/
    - buyerId, vendeurId, deliveryId
    - items[], total, status
    - deliveryAddress, paymentMethod

deliveries/
  {deliveryId}/
    - orderId, livreurId
    - pickupLocation, deliveryLocation
    - status, estimatedTime
```

## References

- **Routes**: See `ROUTES_DOCUMENTATION.md` for complete route map
- **Production deployment**: See `SOLUTION_PRODUCTION.md` for Firebase Hosting setup
- **Android config**: See `CONFIGURATION_ANDROID.md` for platform-specific setup

## Getting Help

For Firebase-related issues, check the logs with:
```dart
debugPrint('🔥 Firebase: ...');  // Firebase operations
debugPrint('✅ Success: ...');    // Successful operations
debugPrint('❌ Error: ...');      // Errors
debugPrint('⚠️ Warning: ...');    // Warnings
```

All services use consistent emoji logging for easier debugging.