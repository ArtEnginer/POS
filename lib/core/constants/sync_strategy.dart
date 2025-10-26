/// Sync Strategy for POS Application
///
/// Defines which features require online connection and which can work offline
///
/// **MANAGEMENT Features (Online-Only):**
/// - Product Management (Create, Update, Delete)
/// - Customer Management
/// - Supplier Management
/// - User Management
/// - Branch Management
/// - Category Management
/// - Settings & Configuration
///
/// **POS Features (Hybrid Online/Offline):**
/// - Sales Transactions
/// - Product Search (from local cache)
/// - Payment Processing
/// - Receipt Printing
///
/// **Background Sync:**
/// - Sales data will sync to server when online
/// - Management data updates are cached locally for POS operations

class SyncStrategy {
  // Feature flags
  static const bool productManagementOnlineOnly = true;
  static const bool customerManagementOnlineOnly = true;
  static const bool supplierManagementOnlineOnly = true;
  static const bool userManagementOnlineOnly = true;
  static const bool branchManagementOnlineOnly = true;
  static const bool categoryManagementOnlineOnly = true;

  static const bool salesHybrid = true;
  static const bool posHybrid = true;

  // Error messages
  static const String onlineRequiredMessage =
      'Koneksi internet diperlukan untuk fitur management data.';

  static const String onlineRequiredProductMessage =
      'Tidak dapat mengubah data produk. Koneksi internet diperlukan.';

  static const String onlineRequiredCustomerMessage =
      'Tidak dapat mengubah data customer. Koneksi internet diperlukan.';

  static const String onlineRequiredSupplierMessage =
      'Tidak dapat mengubah data supplier. Koneksi internet diperlukan.';

  // Success messages
  static const String dataWillSyncMessage =
      'Data transaksi akan disinkronkan saat online.';

  static const String offlineModeMessage =
      'Mode Offline: Transaksi tetap dapat dilakukan.';
}
