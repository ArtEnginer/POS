class AppConstants {
  // App Info
  static const String appName = 'SuperPOS';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Your Company';

  // Database
  static const String localDatabaseName = 'pos_local.db';
  static const int localDatabaseVersion =
      6; // Updated untuk purchase_returns table
  static const String hiveBoxName = 'pos_cache';

  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const int batchSyncSize = 50;

  // API
  static const String baseUrl = 'https://your-api.com/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);

  // Currency
  static const String currency = 'Rp';
  static const String currencySymbol = 'IDR';

  // Tax
  static const double defaultTaxRate = 0.11; // 11% PPN

  // Receipt
  static const int receiptPrintWidth = 48; // characters
  static const String receiptHeader = 'STRUK BELANJA';

  // Session
  static const Duration sessionTimeout = Duration(hours: 8);
  static const Duration inactivityTimeout = Duration(minutes: 15);

  // Product
  static const String defaultProductImage = 'assets/images/no_product.png';
  static const int maxProductNameLength = 100;
  static const int maxBarcodeLength = 50;

  // Permission Levels
  static const String roleAdmin = 'ADMIN';
  static const String roleCashier = 'CASHIER';
  static const String roleManager = 'MANAGER';
  static const String roleInventory = 'INVENTORY';

  // Transaction Status
  static const String statusPending = 'PENDING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusRefunded = 'REFUNDED';

  // Payment Methods
  static const String paymentCash = 'CASH';
  static const String paymentCard = 'CARD';
  static const String paymentQRIS = 'QRIS';
  static const String paymentTransfer = 'TRANSFER';
  static const String paymentEWallet = 'E_WALLET';

  // Sync Status
  static const String syncStatusPending = 'PENDING';
  static const String syncStatusSynced = 'SYNCED';
  static const String syncStatusFailed = 'FAILED';
  static const String syncStatusConflict = 'CONFLICT';
}
