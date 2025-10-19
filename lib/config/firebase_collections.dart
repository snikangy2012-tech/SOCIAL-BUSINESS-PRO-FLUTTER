// ===== lib/config/firebase_collections.dart =====

/// Firebase Firestore collection names
///
/// This class contains all the collection names used in the app
/// to avoid typos and maintain consistency.
class FirebaseCollections {
  // Users and authentication
  static const String users = 'users';
  static const String sessions = 'sessions';

  // Products and inventory
  static const String products = 'products';
  static const String categories = 'categories';

  // Orders and transactions
  static const String orders = 'orders';
  static const String orderItems = 'order_items';

  // Deliveries
  static const String deliveries = 'deliveries';
  static const String deliveryTracking = 'delivery_tracking';

  // Payments
  static const String paymentMethods = 'payment_methods';
  static const String transactions = 'transactions';

  // Addresses
  static const String addresses = 'addresses';

  // Reviews and ratings
  static const String reviews = 'reviews';

  // Notifications
  static const String notifications = 'notifications';
  static const String fcmTokens = 'fcm_tokens';

  // Favorites and wishlists
  static const String favorites = 'favorites';

  // Analytics and logs
  static const String analytics = 'analytics';
  static const String activityLogs = 'activity_logs';

  // Test collection (for connectivity checks)
  static const String connectionTest = '_connection_test';
}