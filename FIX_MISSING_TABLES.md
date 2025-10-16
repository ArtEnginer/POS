# Fix: Missing Tables in SQLite Database

## Problem
Tabel `receivings` dan `receiving_items` tidak dibuat saat fresh install aplikasi.

## Root Cause
**Bug di `database_helper.dart`:**

Tabel receivings hanya didefinisikan di method `_onUpgrade()` untuk migrasi dari versi lama:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 5) {
    // CREATE TABLE receivings ...  ✅ Ada di sini
    // CREATE TABLE receiving_items ... ✅ Ada di sini
  }
}
```

**TAPI TIDAK ada di method `_onCreate()`!**

```dart
Future<void> _onCreate(Database db, int version) async {
  // CREATE TABLE products ... ✅
  // CREATE TABLE purchases ... ✅
  // CREATE TABLE settings ... ✅
  // ❌ MISSING: receivings & receiving_items!
}
```

### Why is this a problem?

**Scenario 1: Fresh Install (New User)**
- SQLite memanggil `_onCreate()` untuk membuat database baru
- `_onUpgrade()` TIDAK dipanggil karena tidak ada versi lama
- ❌ Result: Tabel receivings TIDAK dibuat

**Scenario 2: Upgrade (Existing User)**
- SQLite memanggil `_onUpgrade()` karena ada database lama
- ✅ Result: Tabel receivings DIBUAT via migration

**Kesimpulan:** Fresh install akan missing tabel receivings!

---

## Solution ✅

**Fixed in `database_helper.dart`:**

Tambahkan pembuatan tabel receivings di method `_onCreate()`:

```dart
Future<void> _onCreate(Database db, int version) async {
  // ... existing tables ...

  // ✅ ADDED: Receivings Table
  await db.execute('''
    CREATE TABLE receivings (
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

  // ✅ ADDED: Receiving Items Table
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

  // ✅ ADDED: Receivings indexes
  // (in _createIndexes method)
}
```

---

## How to Apply Fix

### Step 1: Code is Already Fixed ✅
File sudah diperbaiki. Sekarang tinggal reset database.

### Step 2: Reset Database

**Option A: Delete Database File**
```powershell
# Find database path
$dbPath = "$env:LOCALAPPDATA\com.example\pos\pos_local.db"

# Stop app first!
# Then delete
Remove-Item $dbPath -Force

# Run app
flutter run -d windows
```

**Option B: Use DatabaseResetPage**
1. Run app
2. Navigate ke Database Management page
3. Click "Reset Database"

**Option C: Manual Uninstall**
1. Uninstall app via Settings > Apps
2. Reinstall: `flutter run -d windows`

### Step 3: Verify Tables Created

Add this debug code in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize
  await init();
  
  // ✅ Verify tables
  final db = await DatabaseHelper.instance.database;
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
  );
  
  print('=== DATABASE TABLES ===');
  for (var table in tables) {
    print('✅ ${table['name']}');
  }
  
  // Should print:
  // ✅ receivings
  // ✅ receiving_items
  // ✅ purchases
  // ✅ products
  // ... etc
  
  runApp(const MyApp());
}
```

---

## Verification Checklist

After applying fix and resetting database, verify:

- [ ] App runs without "no such table" error
- [ ] Can navigate to Receiving Form page
- [ ] Can create receiving from PO
- [ ] Database contains `receivings` table
- [ ] Database contains `receiving_items` table
- [ ] All indexes created properly

Run this SQL to verify:

```sql
-- List all tables
SELECT name FROM sqlite_master WHERE type='table';

-- Should include:
-- receivings
-- receiving_items

-- Check receivings structure
PRAGMA table_info(receivings);

-- Check receiving_items structure  
PRAGMA table_info(receiving_items);

-- Check indexes
SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_receiving%';
```

---

## Prevention for Future

**Best Practice:** Saat menambahkan tabel baru di migration (`_onUpgrade`), **SELALU** tambahkan juga di `_onCreate`.

**Template:**
```dart
// 1. Define table creation as method
Future<void> _createReceivingsTables(Database db) async {
  await db.execute('CREATE TABLE receivings ...');
  await db.execute('CREATE TABLE receiving_items ...');
}

// 2. Call from both onCreate and onUpgrade
Future<void> _onCreate(Database db, int version) async {
  // ... other tables ...
  await _createReceivingsTables(db); // ✅
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 5) {
    await _createReceivingsTables(db); // ✅ Same method
  }
}
```

This ensures consistency between fresh install and migration.

---

## Summary

**What was wrong:**
- Tabel receivings hanya ada di `_onUpgrade` (migration)
- Tidak ada di `_onCreate` (fresh install)
- Fresh install = missing tables

**What was fixed:**
- ✅ Added receivings table to `_onCreate`
- ✅ Added receiving_items table to `_onCreate`
- ✅ Added receivings indexes to `_createIndexes`

**What you need to do:**
1. Delete old database file
2. Run `flutter run -d windows`
3. Verify tables created

**Status:** 🟢 FIXED - Ready to test receiving feature!
