class AppConstants {
  // App Info
  static const String appName = 'SuperPOS Management';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Your Company';
  static const String appType = 'MANAGEMENT'; // Used for backend validation

  // ========== MANAGEMENT APP: ONLINE-ONLY ==========
  // NO LOCAL DATABASE - All operations require internet
  static const bool offlineEnabled = false;
  static const String hiveBoxName = 'pos_management_cache';

  // API Configuration (Backend V2 - Node.js + PostgreSQL)
  static const String baseUrl = 'http://localhost:3000/api/v1';
  static const String apiBaseUrl =
      'http://localhost:3000/api/v1'; // Alias untuk consistency
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Real-time Updates (Socket.IO)
  static const String socketUrl = 'http://localhost:3000';
  static const bool socketEnabled = true;
  static const Duration socketReconnectDelay = Duration(seconds: 5);
  static const int socketMaxReconnectAttempts = 5;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Settings (Memory cache only, not persistent)
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const int maxCacheSize = 1000; // items

  // Session
  static const Duration sessionTimeout = Duration(hours: 8);
  static const Duration inactivityTimeout = Duration(minutes: 30);
  static const Duration tokenRefreshInterval = Duration(minutes: 50);

  // Currency
  static const String currency = 'Rp';
  static const String currencySymbol = 'IDR';
  static const String currencyLocale = 'id_ID';

  // Tax
  static const double defaultTaxRate = 0.11; // 11% PPN
  static const bool taxIncluded = false;

  // Receipt
  static const int receiptPrintWidth = 48; // characters
  static const String receiptHeader = 'STRUK BELANJA';
  static const int receiptCopies = 2; // Customer + Merchant

  // Product
  static const String defaultProductImage = 'assets/images/no_product.png';
  static const int maxProductNameLength = 100;
  static const int maxBarcodeLength = 50;
  static const int lowStockThreshold = 10;

  // Image Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const int imageQuality = 85; // compression quality

  // Permission Levels
  static const String roleAdmin = 'ADMIN';
  static const String roleManager = 'MANAGER';
  static const String roleInventory = 'INVENTORY';
  static const String roleAccountant = 'ACCOUNTANT';
  static const String roleOwner = 'OWNER';

  // Transaction Status
  static const String statusPending = 'PENDING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusRefunded = 'REFUNDED';
  static const String statusPartialRefund = 'PARTIAL_REFUND';

  // Payment Methods
  static const String paymentCash = 'CASH';
  static const String paymentCard = 'CARD';
  static const String paymentQRIS = 'QRIS';
  static const String paymentTransfer = 'TRANSFER';
  static const String paymentEWallet = 'E_WALLET';
  static const String paymentDebit = 'DEBIT';
  static const String paymentCredit = 'CREDIT';

  // Purchase Order Status
  static const String poStatusDraft = 'DRAFT';
  static const String poStatusSubmitted = 'SUBMITTED';
  static const String poStatusApproved = 'APPROVED';
  static const String poStatusPartialReceived = 'PARTIAL_RECEIVED';
  static const String poStatusFullyReceived = 'FULLY_RECEIVED';
  static const String poStatusCancelled = 'CANCELLED';

  // Report Types
  static const String reportDailySales = 'DAILY_SALES';
  static const String reportMonthlySales = 'MONTHLY_SALES';
  static const String reportProductPerformance = 'PRODUCT_PERFORMANCE';
  static const String reportInventory = 'INVENTORY';
  static const String reportPurchase = 'PURCHASE';
  static const String reportCustomer = 'CUSTOMER';

  // Export Formats
  static const String exportPDF = 'PDF';
  static const String exportExcel = 'EXCEL';
  static const String exportCSV = 'CSV';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const String passwordPattern =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';

  // File Paths
  static const String logoPath = 'assets/logos/company_logo.png';
  static const String iconPath = 'assets/icons/';
  static const String imagePath = 'assets/images/';

  // Error Messages
  static const String errorNoInternet =
      'Tidak ada koneksi internet. Management App memerlukan koneksi untuk beroperasi.';
  static const String errorServerUnavailable = 'Server tidak tersedia';
  static const String errorUnauthorized = 'Sesi Anda telah berakhir';
  static const String errorForbidden = 'Akses ditolak';
  static const String errorNotFound = 'Data tidak ditemukan';
  static const String errorBadRequest = 'Permintaan tidak valid';
  static const String errorInternalServer = 'Terjadi kesalahan server';

  // Success Messages
  static const String successSaved = 'Data berhasil disimpan';
  static const String successUpdated = 'Data berhasil diperbarui';
  static const String successDeleted = 'Data berhasil dihapus';
  static const String successSynced = 'Data berhasil disinkronkan';

  // Feature Flags (Management App has all features)
  static const bool enableInventoryManagement = true;
  static const bool enablePurchaseManagement = true;
  static const bool enableCustomerManagement = true;
  static const bool enableSupplierManagement = true;
  static const bool enableReporting = true;
  static const bool enableMultiBranch = true;
  static const bool enableUserManagement = true;
  static const bool enableAuditLog = true;
  static const bool enableExport = true;
  static const bool enableImport = true;
  static const bool enableBackup = true;

  // Dashboard Refresh
  static const Duration dashboardRefreshInterval = Duration(seconds: 30);

  // Notification
  static const bool enableNotifications = true;
  static const Duration notificationDuration = Duration(seconds: 5);
}
