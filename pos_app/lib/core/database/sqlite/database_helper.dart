import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products table (cache from server)
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

    // Customers table (cache from server)
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

    // Indexes for performance
    await db.execute('CREATE INDEX idx_products_code ON $tableProducts (code)');
    await db.execute(
      'CREATE INDEX idx_products_barcode ON $tableProducts (barcode)',
    );
    await db.execute('CREATE INDEX idx_products_name ON $tableProducts (name)');
    await db.execute(
      'CREATE INDEX idx_customers_phone ON $tableCustomers (phone)',
    );
    await db.execute(
      'CREATE INDEX idx_customers_name ON $tableCustomers (name)',
    );
    await db.execute(
      'CREATE INDEX idx_sales_sync_status ON $tableSales (sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_sales_created_at ON $tableSales (created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON $tableSyncQueue (status)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future versions
  }

  // Clear all cached data (useful for logout or full re-sync)
  Future<void> clearCache() async {
    final db = await database;
    await db.delete(tableProducts);
    await db.delete(tableCustomers);
  }

  // Clear all data including offline transactions
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableProducts);
    await db.delete(tableCustomers);
    await db.delete(tableSales);
    await db.delete(tableSaleItems);
    await db.delete(tableSyncQueue);
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.query(
      tableSales,
      where: 'sync_status = ?',
      whereArgs: ['PENDING'],
    );
    return result.length;
  }

  // Check if cache is expired (older than 24 hours)
  Future<bool> isCacheExpired() async {
    final db = await database;
    final result = await db.query(
      tableProducts,
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return true;

    final cachedAt = DateTime.parse(result.first['cached_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(cachedAt);

    return difference.inHours > 24;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
