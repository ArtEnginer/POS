# POS System - Data Sync Strategy

## Architecture Overview

Aplikasi POS ini menggunakan **2 strategi berbeda** untuk sinkronisasi data:

### 1. **Management Features** (Online-Only)

Fitur-fitur management **HARUS ONLINE** untuk melakukan operasi CREATE/UPDATE/DELETE.

**Fitur yang termasuk:**

- ✅ Product Management (Manajemen Produk)
- ✅ Customer Management (Manajemen Pelanggan)
- ✅ Supplier Management (Manajemen Supplier)
- ✅ Branch Management (Manajemen Cabang)
- ✅ Category Management (Manajemen Kategori)
- ✅ User Management (Manajemen User)
- ✅ Settings & Configuration

**Alasan:**

- Data harus konsisten antar cabang
- Mencegah konflik data
- Central management dari server pusat

**Behavior:**

- **READ**: Cache-first (baca dari local cache, refresh dari server jika online)
- **CREATE/UPDATE/DELETE**: Online-only (wajib internet, gagal jika offline)
- Error message: _"Koneksi internet diperlukan untuk fitur management data"_

---

### 2. **POS/Sales Features** (Hybrid Online/Offline)

Fitur POS **TETAP BISA BERJALAN OFFLINE** untuk tidak mengganggu operasional kasir.

**Fitur yang termasuk:**

- ✅ Sales Transactions (Transaksi Penjualan)
- ✅ Product Search (dari local cache)
- ✅ Payment Processing
- ✅ Receipt Printing
- ✅ Pending Sales

**Alasan:**

- Kasir harus tetap bisa melayani customer meskipun internet mati
- Transaksi tidak boleh terhenti
- User experience lebih baik

**Behavior:**

- **CREATE Sale**: Bisa offline, data disimpan local dan masuk sync queue
- **READ Products**: Dari local cache (diupdate saat management update product)
- **SYNC**: Otomatis sync ke server saat online kembali
- Info message: _"Mode Offline: Transaksi tetap dapat dilakukan. Data akan disinkronkan saat online"_

---

## Data Flow

### Management Flow (Product Create Example)

```
User Create Product
    ↓
Check Internet Connection
    ↓
[OFFLINE] → Error: "Koneksi internet diperlukan"
    ↓
[ONLINE] → Send to API Server (PostgreSQL)
    ↓
Server Response (Product with ID)
    ↓
Update Local Cache (SQLite)
    ↓
Success!
```

### POS Flow (Sale Transaction Example)

```
Kasir Create Transaction
    ↓
Save to Local (SQLite)
    ↓
Add to Sync Queue
    ↓
Check Internet Connection
    ↓
[OFFLINE] → Show: "Data akan disinkronkan saat online"
    ↓
[ONLINE] → Background Sync to Server
    ↓
Update Sync Status
    ↓
Success!
```

---

## Implementation Details

### Product Repository Strategy

```dart
// READ: Cache-first with remote refresh
Future<Either<Failure, List<Product>>> getAllProducts() async {
  if (isOnline) {
    final remote = await remoteDataSource.getAllProducts();
    await updateLocalCache(remote);
    return Right(remote);
  }
  return Right(await localDataSource.getAllProducts());
}

// CREATE/UPDATE/DELETE: Online-only
Future<Either<Failure, Product>> createProduct(Product product) async {
  if (!isOnline) {
    return Left(NetworkFailure(
      message: 'Koneksi internet diperlukan untuk management data'
    ));
  }
  final created = await remoteDataSource.createProduct(product);
  await localDataSource.insertProduct(created);
  return Right(created);
}
```

### Sales Repository Strategy

```dart
// CREATE: Offline-capable with queue
Future<Either<Failure, Sale>> createSale(Sale sale) async {
  // Always save locally first
  await localDataSource.insertSale(sale);

  if (!isOnline) {
    // Add to sync queue
    await syncQueue.add(sale);
    return Right(sale);
  }

  // Try to sync immediately if online
  try {
    await remoteDataSource.createSale(sale);
  } catch (e) {
    // If fails, will retry via background sync
    await syncQueue.add(sale);
  }

  return Right(sale);
}
```

---

## Database Schema Alignment

### SQLite (Local Cache)

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  cost_price REAL DEFAULT 0,
  selling_price REAL NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  min_stock INTEGER DEFAULT 0,
  max_stock INTEGER DEFAULT 0,
  reorder_point INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  is_trackable INTEGER DEFAULT 1,
  tax_rate REAL DEFAULT 0,
  discount_percentage REAL DEFAULT 0,
  attributes TEXT DEFAULT '{}',
  sync_status TEXT DEFAULT 'SYNCED',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);
```

### PostgreSQL (Server Database)

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  sku VARCHAR(50) UNIQUE NOT NULL,
  cost_price DECIMAL(15, 2) DEFAULT 0,
  selling_price DECIMAL(15, 2) NOT NULL,
  min_stock INTEGER DEFAULT 0,
  max_stock INTEGER DEFAULT 0,
  reorder_point INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_trackable BOOLEAN DEFAULT true,
  tax_rate DECIMAL(5, 2) DEFAULT 0,
  discount_percentage DECIMAL(5, 2) DEFAULT 0,
  attributes JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL
);
```

---

## Migration Notes

### Field Name Changes

- `plu` → `sku` (Stock Keeping Unit)
- `purchase_price` → `cost_price` (lebih standard)

### New Fields Added

- `max_stock` - Maximum stock threshold
- `reorder_point` - Auto reorder trigger point
- `is_trackable` - Track inventory or not
- `tax_rate` - Tax percentage
- `discount_percentage` - Default discount
- `attributes` - JSON for flexible additional data

### Backward Compatibility

Temporary getters added for smooth migration:

```dart
@Deprecated('Use sku instead')
String get plu => sku;

@Deprecated('Use costPrice instead')
double get purchasePrice => costPrice;
```

---

## Testing Checklist

### Product Management (Online-Only)

- [ ] Create product ONLINE → Success
- [ ] Create product OFFLINE → Error message shown
- [ ] Update product ONLINE → Success
- [ ] Update product OFFLINE → Error message shown
- [ ] Delete product ONLINE → Success
- [ ] Delete product OFFLINE → Error message shown
- [ ] List products OFFLINE → Shows cached data

### Sales/POS (Hybrid)

- [ ] Create sale ONLINE → Immediate sync
- [ ] Create sale OFFLINE → Queued for sync
- [ ] List products OFFLINE → Works from cache
- [ ] Process payment OFFLINE → Works
- [ ] Print receipt OFFLINE → Works
- [ ] Auto sync when back online → Success

---

## Future Improvements

1. **Conflict Resolution**: Handle concurrent edits from multiple branches
2. **Partial Sync**: Only sync changed records (delta sync)
3. **Priority Queue**: High-priority items sync first
4. **Retry Logic**: Exponential backoff for failed syncs
5. **Compression**: Compress large sync payloads
6. **WebSocket**: Real-time updates instead of polling

---

Generated: 2025-10-27
Last Updated: Product module completed
