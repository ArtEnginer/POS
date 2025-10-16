# Database Migration Guide - Version 5

## Problem
Error: **"no such table: receivings"**

Database aplikasi masih menggunakan versi lama (v3 atau v4) yang belum memiliki tabel `receivings` dan `receiving_items`.

## Root Cause
Saat aplikasi pertama kali dibuat, database dibuat dengan struktur versi lama. Meskipun kode sudah diupdate ke v5, database yang sudah ada di device tidak otomatis ter-upgrade karena:
- SQLite tidak auto-migrate jika app tidak di-reinstall
- Hot reload/restart tidak trigger database migration
- Migration `_onUpgrade` hanya jalan saat app pertama kali install atau version berubah

## Solution (Pilih Salah Satu)

### ✅ **Option 1: Uninstall & Reinstall App (RECOMMENDED)**

**Untuk Windows:**
1. Stop aplikasi yang sedang berjalan (Ctrl+C)
2. Uninstall manual:
   - Buka **Settings** > **Apps** > Cari aplikasi POS
   - Klik **Uninstall**
3. Atau via PowerShell:
   ```powershell
   # List installed apps
   Get-AppxPackage | Select Name, PackageFullName
   
   # Uninstall (ganti dengan nama package yang benar)
   Remove-AppxPackage -Package "YourAppPackageName"
   ```
4. Install ulang:
   ```bash
   flutter run -d windows
   ```

**Untuk Android:**
```bash
# Stop app
# Uninstall
adb uninstall com.yourcompany.pos

# Reinstall
flutter run
```

**Untuk Android Emulator:**
- Long press app icon > App info > Uninstall
- Atau via Settings > Apps

---

### ✅ **Option 2: Manual Delete Database File**

**Windows:**
```
C:\Users\[USERNAME]\AppData\Local\[AppName]\pos_local.db
```

**Steps:**
1. Close aplikasi
2. Buka folder di atas
3. Hapus file `pos_local.db`
4. Run ulang aplikasi: `flutter run`

**Android:**
```bash
adb shell
cd /data/data/com.yourcompany.pos/databases/
rm pos_local.db
```

---

### ✅ **Option 3: Via Code - Database Reset Page**

Sudah disediakan utility page untuk reset database.

**Cara 1: Akses via Dashboard**
Tambahkan menu di `dashboard` atau `settings`:

```dart
// Di file navigation/settings page
import 'package:pos/core/database/database_reset_page.dart';

// Tambahkan menu
ListTile(
  leading: Icon(Icons.storage, color: Colors.orange),
  title: Text('Database Management'),
  subtitle: Text('Reset database (Development)'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DatabaseResetPage()),
    );
  },
),
```

**Cara 2: Direct Route**
Di `main.dart`, tambahkan route:
```dart
MaterialApp(
  routes: {
    '/database-reset': (context) => DatabaseResetPage(),
  },
)
```

Akses via URL atau button temporary.

---

### ✅ **Option 4: Force Migration on First Run**

Tambahkan check di `main.dart` untuk auto-reset jika ada error:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize dependencies
    await init();
    
    // Test database
    final db = await DatabaseHelper.instance.database;
    await db.query('receivings', limit: 1); // Test query
    
  } catch (e) {
    if (e.toString().contains('no such table')) {
      print('Database outdated, resetting...');
      await DatabaseHelper.instance.resetDatabase();
      await init(); // Reinitialize
    }
  }

  runApp(const MyApp());
}
```

---

## Database Schema v5

### New Tables

**1. receivings**
```sql
CREATE TABLE receivings (
  id TEXT PRIMARY KEY,
  receiving_number TEXT UNIQUE NOT NULL,
  purchase_id TEXT NOT NULL,           -- Reference to PO (READ ONLY)
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
```

**2. receiving_items**
```sql
CREATE TABLE receiving_items (
  id TEXT PRIMARY KEY,
  receiving_id TEXT NOT NULL,
  purchase_item_id TEXT,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  po_quantity INTEGER NOT NULL,        -- PO qty (reference, READ ONLY)
  po_price REAL NOT NULL,              -- PO price (reference, READ ONLY)
  received_quantity INTEGER NOT NULL,  -- Actual received (EDITABLE)
  received_price REAL NOT NULL,        -- Actual price (EDITABLE)
  discount REAL NOT NULL DEFAULT 0,
  discount_type TEXT DEFAULT 'AMOUNT', -- 'AMOUNT' or 'PERCENTAGE'
  tax REAL NOT NULL DEFAULT 0,
  tax_type TEXT DEFAULT 'AMOUNT',      -- 'AMOUNT' or 'PERCENTAGE'
  subtotal REAL NOT NULL,
  total REAL NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (receiving_id) REFERENCES receivings (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
```

### Key Changes
- ✅ **PO (purchases) table**: TIDAK BERUBAH (protected)
- ✅ **Receiving tables**: TERPISAH dari PO
- ✅ **Stock management**: Dari receiving, bukan dari PO
- ✅ **Discount & Tax**: Per-item + total level support

---

## Verification

Setelah reset database, verify:

```dart
// Check database version
final db = await DatabaseHelper.instance.database;
final version = await db.getVersion();
print('Database version: $version'); // Should be 5

// Check tables exist
final tables = await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type='table'"
);
print('Tables: $tables');
// Should include: receivings, receiving_items
```

---

## Troubleshooting

**Q: Migration tidak jalan meskipun sudah uninstall?**
A: 
- Pastikan uninstall benar-benar bersih
- Delete build folder: `flutter clean`
- Delete database path manual (lihat Option 2)

**Q: Error "database is locked"?**
A: 
- Close semua instance aplikasi
- Restart device/emulator
- Delete database file manual

**Q: Kehilangan data setelah reset?**
A: 
- Database reset AKAN menghapus semua data
- Untuk production, buat backup dulu atau gunakan migration script
- Untuk development, ini normal dan expected

---

## Production Migration Strategy

Untuk production (jika app sudah ada user):

1. **Backup data** dari database lama
2. **Export** ke JSON/CSV
3. **Uninstall & Reinstall** (atau gunakan migration script)
4. **Import** data kembali ke struktur baru

Code untuk backup/restore bisa ditambahkan di `DatabaseResetPage`.

---

## Scripts Available

**PowerShell Helper:**
```bash
.\database_migration_fix.ps1
```

**Database Reset Page:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => DatabaseResetPage()),
);
```

---

## Support

Jika masih ada masalah setelah mengikuti langkah di atas:
1. Run `flutter clean`
2. Delete `pos_local.db` manual
3. Run `flutter run --verbose` untuk melihat log detail
4. Check database version: `SELECT * FROM pragma_database_list;`
