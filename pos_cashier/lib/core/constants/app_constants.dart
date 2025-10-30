class AppConstants {
  // App Info
  static const String appName = 'POS Kasir';
  static const String appVersion = '1.0.0';

  // Database
  static const String hiveBoxName = 'pos_cashier_box';
  static const String productsBox = 'products';
  static const String salesBox = 'sales';
  static const String customersBox = 'customers';
  static const String categoriesBox = 'categories';
  static const String settingsBox = 'settings';
  static const String authBox = 'auth';
  static const String pendingSalesBox = 'pending_sales';

  // API Configuration (Backend V2)
  static const String baseUrl = 'http://localhost:3001/api/v2';
  static const String socketUrl = 'http://localhost:3001';

  // API Endpoints (tanpa /api/v2 prefix, sudah di baseUrl)
  static const String loginEndpoint = '/auth/login';
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String salesEndpoint = '/sales';
  static const String customersEndpoint = '/customers';
  static const String syncEndpoint = '/sync';

  // Timeouts
  static const int connectTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 10000;

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const int syncBatchSize = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;

  // Transaction
  static const String currency = 'Rp';
  static const String currencySymbol = 'IDR';

  // Default Branch ID (get from login or settings)
  static String? currentBranchId;
  static String? currentCashierId;
  static String? currentCashierName;
  static String? authToken;
}
