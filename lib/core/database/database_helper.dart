import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (kIsWeb) {
      // For web, use in-memory database with a unique name
      path = inMemoryDatabasePath;
    } else {
      // For mobile/desktop
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, AppConstants.localDatabaseName);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.localDatabaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        created_at TEXT NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

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

    // Receivings Table (separate from purchases)
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

    // Receiving Items Table with discount & tax per item
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
        created_at TEXT NOT NULL,
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
        created_at TEXT NOT NULL,
        FOREIGN KEY (return_id) REFERENCES purchase_returns (id),
        FOREIGN KEY (receiving_item_id) REFERENCES receiving_items (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Create indexes
    await _createIndexes(db);

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_products_plu ON products(plu)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute(
      'CREATE INDEX idx_products_category ON products(category_id)',
    );
    await db.execute('CREATE INDEX idx_products_sync ON products(sync_status)');

    await db.execute('CREATE INDEX idx_suppliers_code ON suppliers(code)');
    await db.execute('CREATE INDEX idx_suppliers_name ON suppliers(name)');

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

    await db.execute(
      'CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_movements_date ON stock_movements(created_at)',
    );

    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON sync_queue(status)',
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
  }

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add PLU column to products table
      await db.execute('ALTER TABLE products ADD COLUMN plu TEXT');
      // Create unique index for PLU
      await db.execute(
        'CREATE UNIQUE INDEX idx_products_plu_unique ON products(plu) WHERE plu IS NOT NULL',
      );
    }

    if (oldVersion < 3) {
      // Create purchases tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases (
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

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_items (
          id TEXT PRIMARY KEY,
          purchase_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          subtotal REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (purchase_id) REFERENCES purchases (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // Create indexes
      await db.execute(
        'CREATE INDEX idx_purchases_number ON purchases(purchase_number)',
      );
      await db.execute(
        'CREATE INDEX idx_purchases_date ON purchases(purchase_date)',
      );
      await db.execute(
        'CREATE INDEX idx_purchases_status ON purchases(status)',
      );
      await db.execute(
        'CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id)',
      );
      await db.execute(
        'CREATE INDEX idx_purchase_items_product ON purchase_items(product_id)',
      );
    }

    if (oldVersion < 4) {
      // Create suppliers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
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

      // Create indexes for suppliers
      await db.execute('CREATE INDEX idx_suppliers_code ON suppliers(code)');
      await db.execute('CREATE INDEX idx_suppliers_name ON suppliers(name)');
    }

    if (oldVersion < 5) {
      // Create receivings table (separate from purchases)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receivings (
          id TEXT PRIMARY KEY,
          receiving_number TEXT UNIQUE NOT NULL,
          purchase_id TEXT NOT NULL,
          purchase_number TEXT NOT NULL,
          supplier_id TEXT,
          supplier_name TEXT,
          receiving_date TEXT NOT NULL,
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

      // Create receiving_items table with discount & tax per item
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receiving_items (
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
          created_at TEXT NOT NULL,
          FOREIGN KEY (receiving_id) REFERENCES receivings (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // Create indexes for receivings
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
        'CREATE INDEX idx_receiving_items_receiving ON receiving_items(receiving_id)',
      );
      await db.execute(
        'CREATE INDEX idx_receiving_items_product ON receiving_items(product_id)',
      );
    }

    if (oldVersion < 6) {
      // Create purchase_returns table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_returns (
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

      // Create purchase_return_items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_return_items (
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
          created_at TEXT NOT NULL,
          FOREIGN KEY (return_id) REFERENCES purchase_returns (id),
          FOREIGN KEY (receiving_item_id) REFERENCES receiving_items (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // Create indexes for purchase_returns
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
    }

    if (oldVersion < 7) {
      // Add receiving detail fields
      await db.execute('ALTER TABLE receivings ADD COLUMN invoice_number TEXT');
      await db.execute(
        'ALTER TABLE receivings ADD COLUMN delivery_order_number TEXT',
      );
      await db.execute('ALTER TABLE receivings ADD COLUMN vehicle_number TEXT');
      await db.execute('ALTER TABLE receivings ADD COLUMN driver_name TEXT');

      // Create index for invoice_number for faster search
      await db.execute(
        'CREATE INDEX idx_receivings_invoice ON receivings(invoice_number)',
      );
    }

    if (oldVersion < 8) {
      // Add cashier_name to transactions table if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN cashier_name TEXT',
        );
      } catch (e) {
        // Column might already exist, ignore error
      }

      // Set default value for existing records
      await db.execute(
        'UPDATE transactions SET cashier_name = "Kasir" WHERE cashier_name IS NULL',
      );
    }
  }

  // Helper methods
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
    await db.delete('transactions');
    await db.delete('transaction_items');
    await db.delete('customers');
    await db.delete('stock_movements');
    await db.delete('sync_queue');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Force recreate database (for development/testing)
  Future<void> resetDatabase() async {
    await closeDatabase();

    if (!kIsWeb) {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.localDatabaseName);
      await databaseFactory.deleteDatabase(path);
    }

    // Reinitialize
    _database = await _initDatabase();
  }
}
