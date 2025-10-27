# 📘 IMPLEMENTATION GUIDE - Pemisahan POS & Management

## 🎯 Overview

Guide ini menjelaskan langkah-langkah untuk memigrasikan code dari project monolith (folder `lib/`) ke dua project terpisah:
- **POS App** (`pos_app/`) - Offline-capable cashier app
- **Management App** (`management_app/`) - Online-only management system

---

## 📋 Prerequisites

✅ Sudah dibuat:
1. Folder structure: `pos_app/` dan `management_app/`
2. Flutter projects initialized
3. `pubspec.yaml` configured untuk masing-masing app
4. README.md untuk dokumentasi
5. SEPARATION_STRATEGY.md untuk konsep

⏳ Yang perlu dilakukan:
1. Copy & modify core files
2. Setup features untuk masing-masing app
3. Update backend API routes
4. Testing
5. Deployment

---

## 🗂️ PHASE 1: POS App Implementation

### Step 1.1: Setup Core Structure

```bash
cd pos_app/lib
mkdir -p core/{constants,theme,database/{sqlite,models},sync,network,auth,utils,widgets}
mkdir -p features/{auth,sales,product,customer}/{domain,data,presentation}
```

### Step 1.2: Copy Core Files dari Project Lama

**Files yang perlu di-copy ke POS App:**

```
Source (lib/) → Target (pos_app/lib/)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart ✅ COPY (modify)
│   │   ├── app_colors.dart ✅ COPY
│   │   ├── app_text_styles.dart ✅ COPY
│   │   └── hive_constants.dart ✅ COPY
│   ├── theme/
│   │   └── app_theme.dart ✅ COPY
│   ├── database/
│   │   └── (akan dibuat baru - SQLite only)
│   ├── auth/
│   │   └── auth_service.dart ✅ COPY (modify)
│   ├── network/
│   │   └── network_info.dart ✅ COPY
│   └── utils/
│       └── (copy utils yang diperlukan)
```

### Step 1.3: Modify AppConstants untuk POS

**File: `pos_app/lib/core/constants/app_constants.dart`**

```dart
class AppConstants {
  // App Identity
  static const String appName = 'POS Kasir';
  static const String appVersion = '1.0.0';
  static const String appType = 'CASHIER'; // IMPORTANT!
  
  // API Configuration (POS-specific endpoints)
  static const String apiBaseUrl = 'http://localhost:3001/api/v1/pos';
  
  // Database
  static const String databaseName = 'pos_cashier.db';
  static const String hiveBoxName = 'pos_cashier_cache';
  
  // Sync Configuration
  static const int syncIntervalMinutes = 5;
  static const int maxOfflineDays = 7;
  static const int maxRetryAttempts = 3;
  
  // Cache Configuration
  static const int maxCachedProducts = 1000;
  static const int maxCachedCustomers = 500;
  static const int cacheExpiryHours = 24;
  
  // UI Configuration
  static const int itemsPerPage = 50;
  static const int searchDebounceMs = 500;
}
```

### Step 1.4: Setup SQLite Database

**File: `pos_app/lib/core/database/sqlite/database_helper.dart`**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'pos_cashier.db';
  static const int _databaseVersion = 1;
  
  // Tables
  static const String tableProducts = 'products';
  static const String tableCustomers = 'customers';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableSyncQueue = 'sync_queue';
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Products table (cache)
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category_id TEXT,
        category_name TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        unit TEXT,
        barcode TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
    
    // Customers table (cache)
    await db.execute('''
      CREATE TABLE $tableCustomers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        total_purchases REAL DEFAULT 0,
        last_purchase_at TEXT,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
    
    // Sales table (offline transactions)
    await db.execute('''
      CREATE TABLE $tableSales (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        notes TEXT,
        cashier_id TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    
    // Sale items table
    await db.execute('''
      CREATE TABLE $tableSaleItems (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES $tableSales (id)
      )
    ''');
    
    // Sync queue table
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        processed_at TEXT
      )
    ''');
    
    // Indexes
    await db.execute('CREATE INDEX idx_products_code ON $tableProducts (code)');
    await db.execute('CREATE INDEX idx_products_barcode ON $tableProducts (barcode)');
    await db.execute('CREATE INDEX idx_customers_phone ON $tableCustomers (phone)');
    await db.execute('CREATE INDEX idx_sales_sync_status ON $tableSales (sync_status)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON $tableSyncQueue (status)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic jika ada update schema
  }
  
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableProducts);
    await db.delete(tableCustomers);
    await db.delete(tableSales);
    await db.delete(tableSaleItems);
    await db.delete(tableSyncQueue);
  }
}
```

### Step 1.5: Setup Sync Manager

**File: `pos_app/lib/core/sync/sync_manager.dart`**

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class SyncManager {
  final DatabaseHelper databaseHelper;
  final ApiClient apiClient;
  final Logger logger;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  SyncManager({
    required this.databaseHelper,
    required this.apiClient,
    required this.logger,
  });
  
  // Start periodic sync
  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: AppConstants.syncIntervalMinutes),
      (_) => syncAll(),
    );
  }
  
  void stopPeriodicSync() {
    _syncTimer?.cancel();
  }
  
  Future<bool> syncAll() async {
    if (_isSyncing) {
      logger.w('Sync already in progress, skipping...');
      return false;
    }
    
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      logger.w('No internet connection, skipping sync');
      return false;
    }
    
    _isSyncing = true;
    
    try {
      logger.i('🔄 Starting sync...');
      
      // 1. Upload pending sales (POS → Server)
      await _uploadPendingSales();
      
      // 2. Download product updates (Server → POS)
      await _downloadProducts();
      
      // 3. Download customer updates (Server → POS)
      await _downloadCustomers();
      
      logger.i('✅ Sync completed successfully');
      return true;
    } catch (e) {
      logger.e('❌ Sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _uploadPendingSales() async {
    final db = await databaseHelper.database;
    final pendingSales = await db.query(
      DatabaseHelper.tableSales,
      where: 'sync_status = ?',
      whereArgs: ['PENDING'],
    );
    
    for (var sale in pendingSales) {
      try {
        // Get sale items
        final items = await db.query(
          DatabaseHelper.tableSaleItems,
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        
        // POST to server
        await apiClient.post('/sales', {
          'sale': sale,
          'items': items,
        });
        
        // Mark as synced
        await db.update(
          DatabaseHelper.tableSales,
          {
            'sync_status': 'SYNCED',
            'synced_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [sale['id']],
        );
        
        logger.i('✅ Uploaded sale: ${sale['invoice_number']}');
      } catch (e) {
        logger.e('❌ Failed to upload sale ${sale['id']}: $e');
      }
    }
  }
  
  Future<void> _downloadProducts() async {
    try {
      final response = await apiClient.get('/products');
      final products = response.data['data'] as List;
      
      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        // Clear old cache
        await txn.delete(DatabaseHelper.tableProducts);
        
        // Insert fresh data
        for (var product in products) {
          await txn.insert(DatabaseHelper.tableProducts, {
            ...product,
            'cached_at': DateTime.now().toIso8601String(),
          });
        }
      });
      
      logger.i('✅ Downloaded ${products.length} products');
    } catch (e) {
      logger.e('❌ Failed to download products: $e');
    }
  }
  
  Future<void> _downloadCustomers() async {
    try {
      final response = await apiClient.get('/customers');
      final customers = response.data['data'] as List;
      
      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        await txn.delete(DatabaseHelper.tableCustomers);
        
        for (var customer in customers) {
          await txn.insert(DatabaseHelper.tableCustomers, {
            ...customer,
            'cached_at': DateTime.now().toIso8601String(),
          });
        }
      });
      
      logger.i('✅ Downloaded ${customers.length} customers');
    } catch (e) {
      logger.e('❌ Failed to download customers: $e');
    }
  }
}
```

### Step 1.6: Copy Features dari Project Lama

**Features yang DI-COPY ke POS App:**

1. **Auth Feature** (modify untuk kasir only)
   ```
   lib/features/auth/ → pos_app/lib/features/auth/
   - Modify: Remove role selection, kasir only
   - Modify: Add PIN login support
   ```

2. **Sales/POS Feature** (full copy)
   ```
   lib/features/sales/ → pos_app/lib/features/sales/
   - Keep: POS screen
   - Keep: Transaction history
   - Modify: Make it work offline
   ```

3. **Product Feature** (READ-ONLY)
   ```
   lib/features/product/ → pos_app/lib/features/product/
   - Keep: product_list (read from cache)
   - Remove: product_form (no CRUD)
   - Remove: create/update/delete functionality
   ```

4. **Customer Feature** (READ-ONLY)
   ```
   lib/features/customer/ → pos_app/lib/features/customer/
   - Keep: customer_list (read from cache)
   - Remove: customer_form (no CRUD)
   ```

---

## 🗂️ PHASE 2: Management App Implementation

### Step 2.1: Setup Core Structure

```bash
cd management_app/lib
mkdir -p core/{constants,theme,network,auth,realtime,utils,widgets}
mkdir -p features/{auth,dashboard,product,customer,supplier,purchase,branch,reports,settings}/{domain,data,presentation}
```

### Step 2.2: Modify AppConstants untuk Management

**File: `management_app/lib/core/constants/app_constants.dart`**

```dart
class AppConstants {
  // App Identity
  static const String appName = 'POS Management';
  static const String appVersion = '1.0.0';
  static const String appType = 'MANAGEMENT'; // IMPORTANT!
  
  // API Configuration (Management-specific endpoints)
  static const String apiBaseUrl = 'http://localhost:3001/api/v1/mgmt';
  static const String socketUrl = 'http://localhost:3001';
  
  // CRITICAL: No offline mode
  static const bool requiresOnline = true; // ALWAYS TRUE
  
  // Cache (settings only)
  static const String hiveBoxName = 'pos_management_settings';
  
  // UI Configuration
  static const int itemsPerPage = 100;
  static const int dashboardRefreshSeconds = 30;
  static const int reportMaxDays = 365;
}
```

### Step 2.3: Setup Online-Only Guard

**File: `management_app/lib/core/network/connection_guard.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectionGuard {
  static Future<bool> checkAndWarn(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();
    
    if (result == ConnectivityResult.none) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 10),
              Text('Tidak Ada Internet'),
            ],
          ),
          content: Text(
            'Aplikasi Management membutuhkan koneksi internet untuk beroperasi.\n\n'
            'Silakan periksa koneksi Anda dan coba lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    
    return true;
  }
  
  static Future<T?> executeOnline<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    if (!await checkAndWarn(context)) return null;
    return await action();
  }
}
```

### Step 2.4: Setup Socket.IO Service

**File: `management_app/lib/core/realtime/socket_service.dart`**

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  final Logger _logger = Logger();
  
  final _productUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _customerUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _stockUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get productUpdates => _productUpdateController.stream;
  Stream<Map<String, dynamic>> get customerUpdates => _customerUpdateController.stream;
  Stream<Map<String, dynamic>> get stockUpdates => _stockUpdateController.stream;
  
  void connect(String token) {
    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );
    
    _socket!.onConnect((_) {
      _logger.i('✅ Socket.IO connected');
    });
    
    _socket!.onDisconnect((_) {
      _logger.w('⚠️ Socket.IO disconnected');
    });
    
    // Listen to events
    _socket!.on('product:created', (data) {
      _logger.i('🔔 Product created: ${data['name']}');
      _productUpdateController.add({'action': 'created', 'data': data});
    });
    
    _socket!.on('product:updated', (data) {
      _logger.i('🔔 Product updated: ${data['name']}');
      _productUpdateController.add({'action': 'updated', 'data': data});
    });
    
    _socket!.on('product:deleted', (data) {
      _logger.i('🔔 Product deleted: ${data['id']}');
      _productUpdateController.add({'action': 'deleted', 'data': data});
    });
    
    _socket!.on('stock:low', (data) {
      _logger.w('⚠️ Low stock alert: ${data['product_name']}');
      _stockUpdateController.add(data);
    });
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }
  
  void dispose() {
    disconnect();
    _productUpdateController.close();
    _customerUpdateController.close();
    _stockUpdateController.close();
  }
}
```

### Step 2.5: Copy ALL Features ke Management App

**Copy semua features dengan FULL CRUD:**

```
lib/features/ → management_app/lib/features/
├── auth/ ✅ (modify: admin/manager login)
├── dashboard/ ✅ (enhance dengan real-time charts)
├── product/ ✅ (FULL CRUD)
├── customer/ ✅ (FULL CRUD)
├── supplier/ ✅ (FULL CRUD)
├── purchase/ ✅ (FULL CRUD)
├── branch/ ✅ (FULL CRUD)
└── (add new):
    ├── reports/ ⭐ NEW
    └── settings/ ⭐ NEW
```

---

## 🔧 PHASE 3: Backend API Separation

### Step 3.1: Update Backend Routes

**File: `backend_v2/src/routes/index.js`**

```javascript
const express = require('express');
const router = express.Router();

// Middleware untuk validasi app_type
const validateAppType = (allowedTypes) => {
  return (req, res, next) => {
    const appType = req.headers['x-app-type'];
    
    if (!appType) {
      return res.status(400).json({ 
        error: 'Missing X-App-Type header' 
      });
    }
    
    if (!allowedTypes.includes(appType)) {
      return res.status(403).json({ 
        error: `Access denied for app type: ${appType}` 
      });
    }
    
    next();
  };
};

// POS Routes (cashier app only)
router.use(
  '/api/v1/pos',
  validateAppType(['CASHIER']),
  require('./pos')
);

// Management Routes (management app only)
router.use(
  '/api/v1/mgmt',
  validateAppType(['MANAGEMENT']),
  require('./management')
);

module.exports = router;
```

**File: `backend_v2/src/routes/pos/index.js`**

```javascript
const router = require('express').Router();
const authMiddleware = require('../../middleware/auth');

// POS-specific endpoints (read-only for products/customers)
router.get('/products', authMiddleware, require('./products').getAll);
router.get('/customers', authMiddleware, require('./customers').getAll);

// Sales (write-only for POS)
router.post('/sales', authMiddleware, require('./sales').create);
router.get('/sales/history', authMiddleware, require('./sales').getHistory);

module.exports = router;
```

**File: `backend_v2/src/routes/management/index.js`**

```javascript
const router = require('express').Router();
const authMiddleware = require('../../middleware/auth');
const roleMiddleware = require('../../middleware/role');

// Products (FULL CRUD)
router.get('/products', authMiddleware, require('./products').getAll);
router.post('/products', authMiddleware, roleMiddleware(['ADMIN', 'MANAGER']), require('./products').create);
router.put('/products/:id', authMiddleware, roleMiddleware(['ADMIN', 'MANAGER']), require('./products').update);
router.delete('/products/:id', authMiddleware, roleMiddleware(['ADMIN']), require('./products').delete);

// Customers (FULL CRUD)
router.get('/customers', authMiddleware, require('./customers').getAll);
router.post('/customers', authMiddleware, require('./customers').create);
router.put('/customers/:id', authMiddleware, require('./customers').update);
router.delete('/customers/:id', authMiddleware, roleMiddleware(['ADMIN']), require('./customers').delete);

// ... similar untuk supplier, purchase, branch, etc

module.exports = router;
```

---

## ✅ PHASE 4: Testing & Deployment

### Step 4.1: Testing Checklist

**POS App:**
- [ ] Login kasir berhasil
- [ ] Transaksi offline berhasil
- [ ] Data tersimpan ke SQLite
- [ ] Sync otomatis ketika online
- [ ] Product list dari cache
- [ ] Customer list dari cache
- [ ] Print struk berhasil
- [ ] No CRUD features available

**Management App:**
- [ ] Login admin/manager berhasil
- [ ] Block semua aksi jika offline
- [ ] Product CRUD lengkap
- [ ] Customer CRUD lengkap
- [ ] Supplier CRUD lengkap
- [ ] Real-time update via Socket.IO
- [ ] Dashboard real-time
- [ ] Report generation
- [ ] Export Excel/PDF

### Step 4.2: Build & Deploy

```bash
# POS App
cd pos_app
flutter build windows --release
# Output: build/windows/runner/Release/

# Management App
cd management_app
flutter build windows --release
# atau
flutter build web --release
```

---

## 📝 Summary

### Perbedaan Utama

| Aspek | POS App | Management App |
|-------|---------|----------------|
| **Offline** | ✅ Full support | ❌ Not allowed |
| **Database** | SQLite | No local DB |
| **Sync** | Background sync | Real-time Socket.IO |
| **CRUD** | Read-only | Full CRUD |
| **Size** | ~50MB | ~100MB |
| **RAM** | ~200MB | ~500MB |
| **Target** | Kasir | Admin/Manager |

---

**Next Steps:**
1. Ikuti step-by-step sesuai phase
2. Test setiap feature
3. Deploy bertahap (POS dulu, lalu Management)
4. Training user

---

**Version**: 1.0.0  
**Date**: October 2025
