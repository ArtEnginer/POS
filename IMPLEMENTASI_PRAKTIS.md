# 🛠️ Implementasi Praktis: Online-Offline Sync

## 📋 Overview

Dokumen ini berisi **contoh implementasi praktis** dan **code snippets** untuk menerapkan strategi online-offline yang fleksibel di aplikasi POS kasir Anda.

---

## 🎯 Skenario Praktis

### Skenario 1: Setup Awal Aplikasi (First Install)

**Situasi:**
- User install aplikasi pertama kali
- Belum ada data lokal
- Perlu download 20,000 produk dari server

**Implementasi:**

```dart
// lib/features/auth/presentation/pages/login_page.dart

Future<void> _performFirstTimeSetup() async {
  // 1. Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => FirstTimeSetupDialog(),
  );

  try {
    // 2. Connect to server
    await socketService.connect();

    // 3. Full sync all master data
    bool success = await syncService.forceFullSync(
      onProgress: (current, total) {
        // Update progress in dialog
        setupProgressNotifier.value = current / total;
        setupMessageNotifier.value = 
          'Mengunduh produk: $current dari $total';
      },
    );

    if (success) {
      // 4. Mark setup as complete
      await _hiveService.settingsBox.put('first_setup_complete', true);

      // 5. Navigate to main page
      Navigator.of(context).pushReplacementNamed('/cashier');
    } else {
      throw Exception('Setup failed');
    }
  } catch (e) {
    // Show error dialog
    _showErrorDialog('Setup gagal: $e');
  }
}

// Widget for setup dialog
class FirstTimeSetupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Setup Awal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: setupMessageNotifier,
            builder: (context, message, _) => Text(message),
          ),
          SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: setupProgressNotifier,
            builder: (context, progress, _) {
              return Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  SizedBox(height: 4),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

**⏱️ Waktu:** ~2-3 menit untuk 20,000 produk
**🎯 Result:** User siap pakai aplikasi dengan data lengkap

---

### Skenario 2: Transaksi Saat Online

**Situasi:**
- Kasir scan barcode produk
- Tambah ke keranjang
- Proses pembayaran
- Server online

**Implementasi:**

```dart
// lib/features/cashier/presentation/pages/cashier_page.dart

Future<void> _processPayment() async {
  // 1. Validate cart
  if (_cartItems.isEmpty) {
    _showSnackbar('Keranjang masih kosong!');
    return;
  }

  // 2. Calculate total
  final total = _cartItems.fold<double>(
    0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  // 3. Show payment dialog
  final paymentResult = await showDialog(
    context: context,
    builder: (context) => PaymentDialog(total: total),
  );

  if (paymentResult == null) return; // User cancelled

  // 4. Create sale model
  final sale = SaleModel(
    id: Uuid().v4(),
    invoiceNumber: _generateInvoiceNumber(),
    items: _cartItems,
    total: total,
    paymentMethod: paymentResult.paymentMethod,
    amountPaid: paymentResult.amountPaid,
    change: paymentResult.change,
    cashierId: authService.currentUser!.id,
    branchId: AppConstants.currentBranchId,
    createdAt: DateTime.now(),
    isSynced: false, // Belum sync
    syncedAt: null,
  );

  // 5. Save to LOCAL database FIRST (INSTANT!)
  await _hiveService.salesBox.put(sale.id, sale.toJson());
  print('✅ Sale saved to local: ${sale.invoiceNumber}');

  // 6. Update UI immediately
  setState(() {
    _cartItems.clear();
    _lastTransaction = sale;
  });

  // 7. Show success notification
  _showSnackbar('✅ Transaksi berhasil: ${sale.invoiceNumber}');

  // 8. Print receipt
  await _printReceipt(sale);

  // 9. Background sync to server (Tidak blocking UI!)
  _backgroundSyncSale(sale);
}

Future<void> _backgroundSyncSale(SaleModel sale) async {
  // Check if online
  final syncStatus = syncService.getSyncStatus();
  final isOnline = syncStatus['is_online'] as bool;

  if (!isOnline) {
    print('⚠️ Offline mode - Sale will sync later');
    return;
  }

  // Sync immediately in background
  Future.microtask(() async {
    try {
      print('📤 Background sync: ${sale.invoiceNumber}');
      
      final success = await syncService.syncSaleImmediately(sale.id);
      
      if (success) {
        print('✅ Real-time sync success: ${sale.invoiceNumber}');
        
        // Optional: Show subtle notification
        _showSyncSuccessNotification(sale.invoiceNumber);
      } else {
        print('⚠️ Sync failed - will retry later');
      }
    } catch (e) {
      print('❌ Background sync error: $e');
      // Sale tetap tersimpan lokal, akan di-sync nanti
    }
  });
}

void _showSyncSuccessNotification(String invoiceNumber) {
  // Optional: Show small notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('📡 $invoiceNumber tersinkron'),
      duration: Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      width: 250,
    ),
  );
}
```

**⏱️ Waktu (User Perspective):**
- Save to local: < 10ms ✅
- Update UI: Instant ✅
- Print receipt: 1-2 seconds ✅
- Sync to server: Background (user tidak tahu) ✅

**🎯 Result:** User langsung bisa lanjut transaksi berikutnya!

---

### Skenario 3: Transaksi Saat Offline

**Situasi:**
- Koneksi internet terputus
- Kasir tetap perlu melakukan transaksi
- Data harus tersimpan aman

**Implementasi:**

```dart
// Sama persis dengan Skenario 2!
// Tidak ada perbedaan dari sisi user

Future<void> _processPayment() async {
  // ... (code sama persis seperti di atas)

  // 5. Save to LOCAL database (TETAP BISA!)
  await _hiveService.salesBox.put(sale.id, sale.toJson());

  // 6. Update UI (TETAP INSTANT!)
  setState(() {
    _cartItems.clear();
    _lastTransaction = sale;
  });

  // 7. Show notification dengan info offline
  final isOnline = syncService.getSyncStatus()['is_online'] as bool;
  
  _showSnackbar(
    isOnline
      ? '✅ Transaksi berhasil: ${sale.invoiceNumber}'
      : '✅ Transaksi tersimpan (offline): ${sale.invoiceNumber}',
  );

  // 8. Print receipt (TETAP BISA!)
  await _printReceipt(sale);

  // 9. Background sync (akan otomatis retry saat online)
  _backgroundSyncSale(sale);
}

// SyncService akan otomatis sync saat koneksi kembali
void _initSocketListener() {
  _socketStatusSubscription = _socketService.serverStatus.listen((isOnline) {
    if (isOnline) {
      print('🟢 Back online - Auto-syncing pending sales...');
      
      // AUTO-SYNC semua pending sales!
      syncAll().then((success) {
        if (success) {
          final pendingCount = _getPendingSalesCount();
          print('✅ Synced all pending sales! Count: $pendingCount');
        }
      });
    }
  });
}
```

**⏱️ Waktu (User Perspective):**
- Save to local: < 10ms ✅ (SAMA dengan online!)
- Update UI: Instant ✅
- Print receipt: 1-2 seconds ✅
- Sync to server: Pending (akan auto-sync saat online) ⏰

**🎯 Result:** 
- User tidak terganggu sama sekali!
- Transaksi tetap aman tersimpan
- Auto-sync saat koneksi kembali

---

### Skenario 4: Multi-Device Real-Time Update

**Situasi:**
- Kasir 1 jual produk X (stock: 100 → 99)
- Kasir 2, 3, 4 harus lihat update stock secara real-time
- Tidak boleh ada delay lebih dari 1 detik

**Implementasi:**

#### Backend (Node.js + Socket.IO)

```javascript
// backend_v2/src/socket/socket-handler.js

const handleStockUpdate = async (io, socket, data) => {
  const { productId, newStock, branchId } = data;

  try {
    // 1. Update database
    await db.query(
      'UPDATE products SET stock = $1, updated_at = NOW() WHERE id = $2',
      [newStock, productId]
    );

    // 2. Broadcast ke semua device di branch yang sama
    io.to(`branch_${branchId}`).emit('stock_updated', {
      product_id: productId,
      new_stock: newStock,
      updated_at: new Date().toISOString(),
    });

    console.log(`📡 Broadcast stock update: Product ${productId} → ${newStock}`);
  } catch (error) {
    console.error('❌ Error updating stock:', error);
  }
};

// Handle sale creation
const handleNewSale = async (io, socket, saleData) => {
  const { branchId } = saleData;

  try {
    // 1. Save sale to database
    const result = await db.query(
      'INSERT INTO sales (...) VALUES (...) RETURNING *',
      [...]
    );

    // 2. Update stock untuk semua items
    for (const item of saleData.items) {
      await db.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [item.quantity, item.productId]
      );

      // 3. Broadcast stock update
      io.to(`branch_${branchId}`).emit('stock_updated', {
        product_id: item.productId,
        new_stock: item.newStock,
        updated_at: new Date().toISOString(),
      });
    }

    // 4. Broadcast new sale
    io.to(`branch_${branchId}`).emit('new_sale', {
      invoice_number: result.rows[0].invoice_number,
      total: result.rows[0].total,
      cashier_id: saleData.cashierId,
      created_at: result.rows[0].created_at,
    });

    console.log(`✅ Sale created and broadcasted: ${result.rows[0].invoice_number}`);
  } catch (error) {
    console.error('❌ Error creating sale:', error);
  }
};

module.exports = { handleStockUpdate, handleNewSale };
```

#### Frontend (Flutter)

```dart
// lib/core/socket/socket_service.dart

class SocketService {
  late IO.Socket _socket;
  final _stockUpdateController = StreamController<StockUpdate>.broadcast();
  final _newSaleController = StreamController<SaleNotification>.broadcast();

  Stream<StockUpdate> get stockUpdates => _stockUpdateController.stream;
  Stream<SaleNotification> get newSales => _newSaleController.stream;

  Future<void> connect() async {
    final socketUrl = await AppSettings.getSocketUrl();

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build(),
    );

    // Listen to stock updates
    _socket.on('stock_updated', (data) {
      print('📥 Received stock update: $data');
      
      final update = StockUpdate.fromJson(data);
      _stockUpdateController.add(update);

      // Update local database
      _updateLocalStock(update);
    });

    // Listen to new sales from other devices
    _socket.on('new_sale', (data) {
      print('📥 Received new sale notification: $data');
      
      final notification = SaleNotification.fromJson(data);
      _newSaleController.add(notification);

      // Show notification to user
      _showNewSaleNotification(notification);
    });

    _socket.connect();
  }

  Future<void> _updateLocalStock(StockUpdate update) async {
    try {
      final product = await productRepository.getProductById(update.productId);
      
      if (product != null) {
        await productRepository.updateProductStock(
          update.productId,
          update.newStock,
        );
        
        print('✅ Local stock updated: ${update.productId} → ${update.newStock}');
      }
    } catch (e) {
      print('❌ Error updating local stock: $e');
    }
  }

  void _showNewSaleNotification(SaleNotification notification) {
    // Optional: Show notification to user
    print('📦 New sale from another cashier: ${notification.invoiceNumber}');
  }
}

// Product list page - listen to stock updates
class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  StreamSubscription? _stockUpdateSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to real-time stock updates
    _stockUpdateSubscription = socketService.stockUpdates.listen((update) {
      setState(() {
        // UI will automatically refresh dengan data baru dari local DB
        _loadProducts();
      });
    });
  }

  @override
  void dispose() {
    _stockUpdateSubscription?.cancel();
    super.dispose();
  }

  void _loadProducts() {
    // Load from local database
    final products = productRepository.getLocalProducts();
    setState(() {
      _products = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('Stock: ${product.stock}'), // Auto-update!
          trailing: Text('Rp ${product.price}'),
        );
      },
    );
  }
}
```

**⏱️ Waktu:**
- Kasir 1 jual → Server terima: 100-300ms
- Server broadcast → Kasir 2,3,4 terima: 200-500ms
- Update UI di semua device: < 1 second total ✅

**🎯 Result:** Semua kasir lihat stock yang sama secara real-time!

---

### Skenario 5: Background Sync (Periodic)

**Situasi:**
- User sedang idle (tidak ada transaksi)
- Perlu update data produk dari server
- Sync berkala setiap 5 menit
- Tidak boleh mengganggu user

**Implementasi:**

```dart
// lib/features/sync/data/datasources/sync_service.dart

class SyncService {
  Timer? _syncTimer;

  void startBackgroundSync() {
    // Cancel existing timer
    _syncTimer?.cancel();

    // Start periodic sync
    _syncTimer = Timer.periodic(
      AppConstants.syncInterval, // 5 minutes
      (_) async {
        if (_isOnline && !_isSyncing) {
          print('⏰ Background sync triggered');
          await _performBackgroundSync();
        }
      },
    );

    print('✅ Background sync started (every ${AppConstants.syncInterval.inMinutes} min)');
  }

  Future<void> _performBackgroundSync() async {
    try {
      print('🔄 Starting background sync...');

      // 1. Incremental product sync (hanya yang berubah)
      final productCount = await _productRepository.syncProductsFromServer(
        force: false, // Incremental only
        onProgress: null, // No UI progress (background)
      );

      if (productCount > 0) {
        print('✅ Background sync: $productCount products updated');
        
        // Optional: Show subtle notification
        _syncEventController.add(
          SyncEvent(
            type: 'success',
            message: '🔄 $productCount produk diperbarui',
            syncedCount: productCount,
          ),
        );
      }

      // 2. Upload pending sales (jika ada)
      await _uploadPendingSales();

      // 3. Sync categories
      await _downloadCategories();

      print('✅ Background sync completed');
    } catch (e) {
      print('⚠️ Background sync error (will retry): $e');
      // Don't show error to user untuk background sync
    }
  }

  void stopBackgroundSync() {
    _syncTimer?.cancel();
    print('⏹️ Background sync stopped');
  }
}

// main.dart - start background sync after login
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... initialize services ...

  // Start background sync
  syncService.startBackgroundSync();

  runApp(MyApp());
}
```

**⏱️ Waktu:**
- Interval: Setiap 5 menit
- Duration: 5-30 detik per sync (tergantung perubahan)
- User impact: **ZERO** (tidak ada loading, tidak blocking UI)

**🎯 Result:** Data selalu fresh tanpa user perlu manual refresh!

---

### Skenario 6: Manual Full Sync

**Situasi:**
- User merasa data tidak match dengan server
- Ingin force download ulang semua data
- Butuh progress indicator yang jelas

**Implementasi:**

```dart
// lib/features/sync/presentation/pages/sync_settings_page.dart

class SyncSettingsPage extends StatefulWidget {
  @override
  _SyncSettingsPageState createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  bool _isSyncing = false;
  int _currentProgress = 0;
  int _totalProgress = 0;

  Future<void> _performFullSync() async {
    // 1. Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sinkronisasi Penuh'),
        content: Text(
          'Ini akan mengunduh ulang SEMUA data dari server.\n'
          'Proses ini memakan waktu 2-3 menit.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Start sync with progress
    setState(() {
      _isSyncing = true;
      _currentProgress = 0;
      _totalProgress = 0;
    });

    try {
      await syncService.forceFullSync(
        onProgress: (current, total) {
          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        },
      );

      // 3. Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('✅ Berhasil'),
          content: Text(
            'Sinkronisasi penuh selesai!\n'
            'Total: $_totalProgress produk',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Show error dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('❌ Gagal'),
          content: Text('Sinkronisasi gagal: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan Sinkronisasi')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Sinkronisasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStatusRow(
                      'Total Produk',
                      '${syncService.getSyncStatus()['total_products']}',
                      Icons.inventory_2,
                    ),
                    _buildStatusRow(
                      'Transaksi Pending',
                      '${syncService.getSyncStatus()['pending_sales']}',
                      Icons.pending_actions,
                    ),
                    _buildStatusRow(
                      'Terakhir Sync',
                      _formatLastSync(),
                      Icons.sync,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Progress bar (saat syncing)
            if (_isSyncing) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Mengunduh produk...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalProgress > 0
                          ? _currentProgress / _totalProgress
                          : 0,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_currentProgress / $_totalProgress produk',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Sync buttons
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : _performQuickSync,
              icon: Icon(Icons.sync),
              label: Text('Sinkronisasi Cepat'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _isSyncing ? null : _performFullSync,
              icon: Icon(Icons.cloud_download),
              label: Text('Sinkronisasi Penuh'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Tips
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Tips:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Sinkronisasi Cepat: Update data harian (5-30 detik)\n'
                      '• Sinkronisasi Penuh: Download ulang semua (2-3 menit)\n'
                      '• Background sync otomatis setiap 5 menit',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _performQuickSync() async {
    setState(() => _isSyncing = true);

    try {
      await syncService.manualSync();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Sinkronisasi selesai')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Sinkronisasi gagal: $e')),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String _formatLastSync() {
    // ... format logic ...
    return 'Baru saja';
  }
}
```

**⏱️ Waktu:**
- Quick Sync: 5-30 detik
- Full Sync: 2-3 menit (dengan progress bar)

**🎯 Result:** User punya kontrol penuh untuk refresh data!

---

## 🔧 Configuration Best Practices

### App Constants

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int productBatchSize = 500;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Real-time Configuration
  static const bool enableWebSocket = true;
  static const bool autoReconnectWebSocket = true;
  static const Duration reconnectDelay = Duration(seconds: 5);
  
  // Offline Configuration
  static const bool enableOfflineMode = true;
  static const Duration offlineDataExpiry = Duration(hours: 24);
  
  // Performance Configuration
  static const int productListPageSize = 50;
  static const bool enableLocalCache = true;
  static const bool enableImageCache = true;
  
  // Current Branch (set after login)
  static String currentBranchId = '1';
}
```

### Environment-Specific Config

```dart
// lib/core/config/environment.dart

enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment current = Environment.production;
  
  static String get apiBaseUrl {
    switch (current) {
      case Environment.development:
        return 'http://localhost:3001';
      case Environment.staging:
        return 'https://staging-api.yourapp.com';
      case Environment.production:
        return 'https://api.yourapp.com';
    }
  }
  
  static String get socketUrl {
    switch (current) {
      case Environment.development:
        return 'http://localhost:3001';
      case Environment.staging:
        return 'https://staging-socket.yourapp.com';
      case Environment.production:
        return 'https://socket.yourapp.com';
    }
  }
  
  static bool get enableDebugLogs {
    return current == Environment.development;
  }
}
```

---

## 📊 Monitoring & Debugging

### Debug Logger

```dart
// lib/core/utils/logger.dart

class AppLogger {
  static void log(String message, {String? tag}) {
    if (!EnvironmentConfig.enableDebugLogs) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    
    print('$timestamp $tagStr $message');
  }
  
  static void syncLog(String message) {
    log(message, tag: 'SYNC');
  }
  
  static void socketLog(String message) {
    log(message, tag: 'SOCKET');
  }
  
  static void errorLog(String message, [dynamic error]) {
    log('ERROR: $message ${error ?? ""}', tag: 'ERROR');
  }
}

// Usage
AppLogger.syncLog('Starting full sync');
AppLogger.socketLog('WebSocket connected');
AppLogger.errorLog('Sync failed', error);
```

### Sync Status Dashboard (Admin)

```dart
// lib/features/admin/presentation/pages/sync_dashboard_page.dart

class SyncDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sync Dashboard')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: Stream.periodic(
          Duration(seconds: 5),
          (_) => syncService.getSyncStatus(),
        ),
        builder: (context, snapshot) {
          final status = snapshot.data ?? {};
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildStatusCard(
                'Online Status',
                status['is_online'] == true ? 'ONLINE' : 'OFFLINE',
                status['is_online'] == true ? Colors.green : Colors.red,
              ),
              _buildStatusCard(
                'Total Products',
                '${status['total_products'] ?? 0}',
                Colors.blue,
              ),
              _buildStatusCard(
                'Pending Sales',
                '${status['pending_sales'] ?? 0}',
                status['pending_sales'] > 0 ? Colors.orange : Colors.green,
              ),
              _buildStatusCard(
                'Last Sync',
                _formatDate(status['last_sync']),
                Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatusCard(String title, String value, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

---

## ✅ Testing Checklist

### 1. Online Mode Tests

```dart
✅ Login dengan koneksi internet
✅ Download semua produk (full sync)
✅ Transaksi langsung sync ke server
✅ WebSocket connected dan terima updates
✅ Background sync berjalan setiap 5 menit
✅ Multi-device real-time update
```

### 2. Offline Mode Tests

```dart
✅ Login offline (dengan credentials tersimpan)
✅ Load produk dari local database
✅ Transaksi tersimpan dengan status pending
✅ Print receipt tetap berjalan
✅ UI tetap responsive
✅ Pending counter bertambah
```

### 3. Online → Offline Transition

```dart
✅ Matikan WiFi saat aplikasi berjalan
✅ Status berubah ke OFFLINE
✅ Transaksi tetap bisa dilakukan
✅ Data tersimpan lokal
✅ Notifikasi "Offline mode" muncul
```

### 4. Offline → Online Transition

```dart
✅ Nyalakan WiFi kembali
✅ Status berubah ke ONLINE
✅ Auto-sync pending sales
✅ Pending counter berkurang/reset
✅ Notifikasi "X transaksi tersinkron"
✅ WebSocket auto-reconnect
```

### 5. Edge Cases

```dart
✅ Koneksi flaky (on-off berulang)
✅ Server timeout
✅ Invalid data dari server
✅ Database corruption
✅ Memory full
✅ 20,000+ produk sync
```

---

## 🎓 Tips & Tricks

### 1. Optimasi Performance

```dart
// Lazy loading untuk product list
ListView.builder(
  itemCount: _products.length,
  itemBuilder: (context, index) {
    // Load product on demand
    return ProductListItem(product: _products[index]);
  },
);

// Image caching
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
);

// Debounce search
Timer? _searchDebounce;
void _onSearchChanged(String query) {
  _searchDebounce?.cancel();
  _searchDebounce = Timer(Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}
```

### 2. Error Handling

```dart
// Graceful error handling
try {
  await apiService.syncData();
} on SocketException {
  // Network error
  _showErrorDialog('Tidak ada koneksi internet');
} on TimeoutException {
  // Timeout
  _showErrorDialog('Server tidak merespons');
} on FormatException {
  // Invalid data
  _showErrorDialog('Data tidak valid');
} catch (e) {
  // Generic error
  _showErrorDialog('Terjadi kesalahan: $e');
}
```

### 3. User Feedback

```dart
// Clear status indicators
Widget _buildSyncStatus() {
  final isOnline = syncService.getSyncStatus()['is_online'];
  final pendingCount = syncService.getSyncStatus()['pending_sales'];
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isOnline ? Colors.green : Colors.orange,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          size: 16,
          color: Colors.white,
        ),
        SizedBox(width: 4),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(color: Colors.white),
        ),
        if (pendingCount > 0) ...[
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pendingCount',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
```

---

## 🎯 Kesimpulan

Dengan implementasi di atas, aplikasi POS kasir Anda akan:

✅ **CEPAT**: Semua operasi instant (< 10ms)
✅ **FLEKSIBEL**: Auto-switch online/offline
✅ **REAL-TIME**: Update ke semua device < 1 detik
✅ **RELIABLE**: Retry mechanism, queue system
✅ **USER-FRIENDLY**: Clear status, progress bar

**🚀 Ready for production dengan 100+ devices!**

---

## 📚 Resources

- **Main Docs**: `STRATEGI_ONLINE_OFFLINE_FLEKSIBEL.md`
- **Diagrams**: `DIAGRAM_ALUR_SYNC.md`
- **Implementation**: `OFFLINE_SYNC_IMPLEMENTATION.md`
- **Quick Guide**: `QUICK_SYNC_GUIDE.md`

**💡 Jika ada pertanyaan atau perlu bantuan implementasi, silakan refer ke dokumentasi di atas atau contact development team!**
