import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // Current database version
  static const int _currentVersion = 1;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (kIsWeb) {
      path = inMemoryDatabasePath;
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, AppConstants.localDatabaseName);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _currentVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    await _createMasterDataTables(db);
    await _createPurchaseTables(db);
    await _createSalesTables(db);
    await _createSystemTables(db);

    // Create all indexes
    await _createIndexes(db);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  // ==================== MASTER DATA TABLES ====================
  Future<void> _createMasterDataTables(Database db) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        plu TEXT UNIQUE,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        category_id TEXT,
        unit TEXT,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER DEFAULT 0,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        parent_id TEXT,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // Suppliers Table
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        postal_code TEXT,
        tax_number TEXT,
        payment_terms INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        postal_code TEXT,
        points INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        last_login TEXT,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== PURCHASE TABLES ====================
  Future<void> _createPurchaseTables(Database db) async {
    // Purchases Table
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        purchase_number TEXT UNIQUE NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        purchase_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Purchase Items Table
    await db.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Receivings Table
    await db.execute('''
      CREATE TABLE receivings (
        id TEXT PRIMARY KEY,
        receiving_number TEXT UNIQUE NOT NULL,
        purchase_id TEXT NOT NULL,
        purchase_number TEXT NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        receiving_date TEXT NOT NULL,
        invoice_number TEXT,
        delivery_order_number TEXT,
        vehicle_number TEXT,
        driver_name TEXT,
        subtotal REAL NOT NULL,
        item_discount REAL NOT NULL DEFAULT 0,
        item_tax REAL NOT NULL DEFAULT 0,
        total_discount REAL NOT NULL DEFAULT 0,
        total_tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        notes TEXT,
        received_by TEXT,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id)
      )
    ''');

    // Receiving Items Table
    await db.execute('''
      CREATE TABLE receiving_items (
        id TEXT PRIMARY KEY,
        receiving_id TEXT NOT NULL,
        purchase_item_id TEXT,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        po_quantity INTEGER NOT NULL,
        po_price REAL NOT NULL,
        received_quantity INTEGER NOT NULL,
        received_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        discount_type TEXT DEFAULT 'AMOUNT',
        tax REAL NOT NULL DEFAULT 0,
        tax_type TEXT DEFAULT 'AMOUNT',
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (receiving_id) REFERENCES receivings (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Purchase Returns Table
    await db.execute('''
      CREATE TABLE purchase_returns (
        id TEXT PRIMARY KEY,
        return_number TEXT UNIQUE NOT NULL,
        receiving_id TEXT NOT NULL,
        receiving_number TEXT NOT NULL,
        purchase_id TEXT NOT NULL,
        purchase_number TEXT NOT NULL,
        supplier_id TEXT,
        supplier_name TEXT,
        return_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        item_discount REAL NOT NULL DEFAULT 0,
        item_tax REAL NOT NULL DEFAULT 0,
        total_discount REAL NOT NULL DEFAULT 0,
        total_tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        reason TEXT,
        notes TEXT,
        processed_by TEXT,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (receiving_id) REFERENCES receivings (id),
        FOREIGN KEY (purchase_id) REFERENCES purchases (id)
      )
    ''');

    // Purchase Return Items Table
    await db.execute('''
      CREATE TABLE purchase_return_items (
        id TEXT PRIMARY KEY,
        return_id TEXT NOT NULL,
        receiving_item_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        received_quantity INTEGER NOT NULL,
        return_quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        discount_type TEXT DEFAULT 'AMOUNT',
        tax REAL NOT NULL DEFAULT 0,
        tax_type TEXT DEFAULT 'AMOUNT',
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        reason TEXT,
        notes TEXT,
        sync_status TEXT DEFAULT 'SYNCED',
        created_at TEXT NOT NULL,
        FOREIGN KEY (return_id) REFERENCES purchase_returns (id),
        FOREIGN KEY (receiving_item_id) REFERENCES receiving_items (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // ==================== SALES TABLES ====================
  Future<void> _createSalesTables(Database db) async {
    // Transactions Table (Sales)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        transaction_number TEXT UNIQUE NOT NULL,
        customer_id TEXT,
        cashier_id TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_amount REAL NOT NULL,
        change_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        notes TEXT,
        sync_status TEXT DEFAULT 'PENDING',
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Transaction Items Table
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
    ''');

    // Pending Transactions Table
    await db.execute('''
      CREATE TABLE pending_transactions (
        id TEXT PRIMARY KEY,
        pending_number TEXT UNIQUE NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        saved_at TEXT NOT NULL,
        saved_by TEXT NOT NULL,
        notes TEXT,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL
      )
    ''');

    // Pending Transaction Items Table
    await db.execute('''
      CREATE TABLE pending_transaction_items (
        id TEXT PRIMARY KEY,
        pending_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        subtotal REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pending_id) REFERENCES pending_transactions (id)
      )
    ''');
  }

  // ==================== SYSTEM TABLES ====================
  Future<void> _createSystemTables(Database db) async {
    // Stock Movements Table
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reference_id TEXT,
        reference_type TEXT,
        notes TEXT,
        user_id TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== INDEXES ====================
  Future<void> _createIndexes(Database db) async {
    // Products indexes
    await db.execute('CREATE INDEX idx_products_plu ON products(plu)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute(
      'CREATE INDEX idx_products_category ON products(category_id)',
    );
    await db.execute('CREATE INDEX idx_products_sync ON products(sync_status)');

    // Suppliers indexes
    await db.execute('CREATE INDEX idx_suppliers_code ON suppliers(code)');
    await db.execute('CREATE INDEX idx_suppliers_name ON suppliers(name)');

    // Purchases indexes
    await db.execute(
      'CREATE INDEX idx_purchases_number ON purchases(purchase_number)',
    );
    await db.execute(
      'CREATE INDEX idx_purchases_date ON purchases(purchase_date)',
    );
    await db.execute('CREATE INDEX idx_purchases_status ON purchases(status)');
    await db.execute(
      'CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_items_product ON purchase_items(product_id)',
    );

    // Receivings indexes
    await db.execute(
      'CREATE INDEX idx_receivings_number ON receivings(receiving_number)',
    );
    await db.execute(
      'CREATE INDEX idx_receivings_purchase ON receivings(purchase_id)',
    );
    await db.execute(
      'CREATE INDEX idx_receivings_date ON receivings(receiving_date)',
    );
    await db.execute(
      'CREATE INDEX idx_receivings_status ON receivings(status)',
    );
    await db.execute(
      'CREATE INDEX idx_receivings_invoice ON receivings(invoice_number)',
    );
    await db.execute(
      'CREATE INDEX idx_receiving_items_receiving ON receiving_items(receiving_id)',
    );
    await db.execute(
      'CREATE INDEX idx_receiving_items_product ON receiving_items(product_id)',
    );

    // Purchase Returns indexes
    await db.execute(
      'CREATE INDEX idx_purchase_returns_number ON purchase_returns(return_number)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_returns_receiving ON purchase_returns(receiving_id)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_returns_purchase ON purchase_returns(purchase_id)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_returns_date ON purchase_returns(return_date)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_returns_status ON purchase_returns(status)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_return_items_return ON purchase_return_items(return_id)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_return_items_product ON purchase_return_items(product_id)',
    );

    // Transactions indexes
    await db.execute(
      'CREATE INDEX idx_transactions_number ON transactions(transaction_number)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_status ON transactions(status)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_sync ON transactions(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_items_product ON transaction_items(product_id)',
    );

    // Pending Transactions indexes
    await db.execute(
      'CREATE INDEX idx_pending_transactions_number ON pending_transactions(pending_number)',
    );
    await db.execute(
      'CREATE INDEX idx_pending_transaction_items_pending ON pending_transaction_items(pending_id)',
    );
    await db.execute(
      'CREATE INDEX idx_pending_transaction_items_product ON pending_transaction_items(product_id)',
    );

    // Stock Movements indexes
    await db.execute(
      'CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_movements_date ON stock_movements(created_at)',
    );

    // Sync Queue indexes
    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON sync_queue(status)',
    );
  }

  // ==================== DEFAULT DATA ====================
  Future<void> _insertDefaultSettings(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('settings', {
      'key': 'last_sync',
      'value': now,
      'updated_at': now,
    });

    await db.insert('settings', {
      'key': 'tax_rate',
      'value': AppConstants.defaultTaxRate.toString(),
      'updated_at': now,
    });

    await db.insert('settings', {
      'key': 'company_name',
      'value': AppConstants.companyName,
      'updated_at': now,
    });
  }

  // ==================== UPGRADE HANDLER ====================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For future upgrades, implement migration logic here
    // Currently starting fresh with version 1
  }

  // ==================== HELPER METHODS ====================
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
    await db.delete('suppliers');
    await db.delete('customers');
    await db.delete('purchases');
    await db.delete('purchase_items');
    await db.delete('receivings');
    await db.delete('receiving_items');
    await db.delete('purchase_returns');
    await db.delete('purchase_return_items');
    await db.delete('transactions');
    await db.delete('transaction_items');
    await db.delete('pending_transactions');
    await db.delete('pending_transaction_items');
    await db.delete('stock_movements');
    await db.delete('sync_queue');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    await closeDatabase();

    if (!kIsWeb) {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.localDatabaseName);
      await databaseFactory.deleteDatabase(path);
    }

    _database = await _initDatabase();
  }
}
