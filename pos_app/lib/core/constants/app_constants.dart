class AppConstants {
  // App Identity
  static const String appName = 'POS Kasir';
  static const String appVersion = '1.0.0';
  static const String appType = 'CASHIER'; // IMPORTANT: Used in API headers
  static const String companyName = 'Your Company';

  // API Configuration (POS-specific endpoints)
  static const String baseUrl = 'http://localhost:3001/api/v1/pos';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Database (SQLite Local)
  static const String localDatabaseName = 'pos_cashier.db';
  static const int localDatabaseVersion = 1;
  static const String hiveBoxName = 'pos_cashier_cache';

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const int batchSyncSize = 50;
  static const int maxOfflineDays = 7;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedProducts = 1000;
  static const int maxCachedCustomers = 500;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI Configuration
  static const int searchDebounceMs = 500;
  static const int itemsPerPage = 50;

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

  // Permission Levels (POS App only supports CASHIER)
  static const String roleCashier = 'CASHIER';

  // Transaction Status
  static const String statusPending = 'PENDING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

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

  // Offline Mode Messages
  static const String offlineMessage =
      '⚠️ Mode Offline - Menggunakan data cache';
  static const String syncingMessage = '🔄 Menyinkronkan data...';
  static const String syncSuccessMessage = '✅ Sinkronisasi berhasil';
  static const String syncFailedMessage = '❌ Sinkronisasi gagal';
}
