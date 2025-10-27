# 📊 ANALISIS FITUR PRODUCT - MANAGEMENT APP

## 🎯 OVERVIEW
Analisis lengkap dari Database → Backend → Frontend untuk fitur Product Management dengan fokus pada CRUD operations dan Stock Management.

---

## 🗄️ DATABASE LAYER (PostgreSQL)

### 1. **Tabel `products`**
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,                      -- Auto-increment ID
    sku VARCHAR(50) UNIQUE NOT NULL,            -- Stock Keeping Unit
    barcode VARCHAR(100),                       -- Barcode produk
    name VARCHAR(255) NOT NULL,                 -- Nama produk
    description TEXT,                           -- Deskripsi
    category_id INTEGER REFERENCES categories(id),
    unit VARCHAR(50) DEFAULT 'PCS',            -- Satuan (PCS, KG, dll)
    cost_price DECIMAL(15, 2) DEFAULT 0,       -- Harga beli
    selling_price DECIMAL(15, 2) NOT NULL,     -- Harga jual
    min_stock INTEGER DEFAULT 0,               -- Stok minimum
    max_stock INTEGER DEFAULT 0,               -- Stok maksimum
    reorder_point INTEGER DEFAULT 0,           -- Titik reorder
    is_active BOOLEAN DEFAULT true,            -- Status aktif
    is_trackable BOOLEAN DEFAULT true,         -- Tracking stok?
    image_url TEXT,                            -- URL gambar
    attributes JSONB DEFAULT '{}',             -- Custom attributes
    tax_rate DECIMAL(5, 2) DEFAULT 0,         -- Pajak (%)
    discount_percentage DECIMAL(5, 2) DEFAULT 0, -- Diskon (%)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL                  -- Soft delete
);
```

**Indexes:**
- `idx_products_sku` ON products(sku)
- `idx_products_barcode` ON products(barcode)
- `idx_products_name` ON products USING gin (name gin_trgm_ops) -- Full-text search
- `idx_products_category` ON products(category_id)
- `idx_products_active` ON products(is_active)

### 2. **Tabel `product_stocks`** (Multi-Branch)
```sql
CREATE TABLE product_stocks (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,                 -- Stok aktual
    reserved_quantity INTEGER DEFAULT 0,        -- Stok direservasi
    available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED, -- Computed
    last_stock_count_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, branch_id)              -- Satu stok per produk per cabang
);
```

**Key Points:**
- ✅ **Multi-branch support**: Setiap produk punya stok terpisah per cabang
- ✅ **Reserved quantity**: Untuk handle pending transactions
- ✅ **Available quantity**: Auto-calculated (quantity - reserved)
- ✅ **Constraint**: UNIQUE(product_id, branch_id) mencegah duplikasi

### 3. **Auto-Update Stock Trigger**
```sql
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE product_stocks
        SET quantity = quantity - (
            SELECT SUM(quantity)
            FROM sale_items
            WHERE sale_id = NEW.id AND product_id = product_stocks.product_id
        )
        WHERE branch_id = NEW.branch_id;
    END IF;
    RETURN NEW;
END;
```

**Masalah Potensial:**
- ⚠️ Trigger hanya update saat penjualan `completed`
- ⚠️ Belum ada trigger untuk purchase receiving
- ⚠️ Belum ada trigger untuk stock adjustment

---

## 🔧 BACKEND LAYER (Node.js + Express)

### API Endpoints (`/api/v2/products`)

| Method | Endpoint | Auth | Role | Deskripsi |
|--------|----------|------|------|-----------|
| GET | `/` | ✅ | All | Get all products (pagination, filters) |
| GET | `/search` | ✅ | All | Search products by name/SKU/barcode |
| GET | `/low-stock` | ✅ | All | Get products dengan stok rendah |
| GET | `/barcode/:barcode` | ✅ | All | Get product by barcode |
| GET | `/:id` | ✅ | All | Get product by ID |
| GET | `/:id/stock` | ✅ | All | Get stock per branch |
| POST | `/` | ✅ | Admin, Manager | Create new product |
| PUT | `/:id` | ✅ | Admin, Manager | Update product |
| PUT | `/:id/stock` | ✅ | Admin, Manager | Update stock |
| DELETE | `/:id` | ✅ | Admin | Delete product (soft delete) |

### Controller Analysis

#### ✅ **GET All Products** (`getAllProducts`)
```javascript
// Query dengan JOIN categories dan product_stocks
SELECT p.*, c.name as category_name,
       ps.quantity as stock_quantity,
       ps.available_quantity
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN product_stocks ps ON p.id = ps.product_id
WHERE p.deleted_at IS NULL
```

**Features:**
- ✅ Pagination (page, limit)
- ✅ Search (ILIKE pada name, sku, barcode)
- ✅ Filter by categoryId
- ✅ Filter by isActive
- ✅ Filter by branchId (untuk stock)

**Masalah:**
- ⚠️ **LEFT JOIN product_stocks tanpa branchId bisa return multiple rows**
  - Jika product ada di 3 cabang → 3 rows
  - Frontend akan menerima duplikasi data
  
**Solusi:**
```javascript
// Harus specify branchId atau aggregate:
LEFT JOIN product_stocks ps ON p.id = ps.product_id 
  AND (ps.branch_id = $X OR ps.branch_id IS NULL)

// ATAU pakai aggregate untuk total stock:
LEFT JOIN (
  SELECT product_id, SUM(quantity) as total_quantity
  FROM product_stocks
  GROUP BY product_id
) ps ON p.id = ps.product_id
```

#### ✅ **GET Product by ID** (`getProductById`)
```javascript
// With Redis cache (1 hour TTL)
const cacheKey = `product:${id}`;
```

**Features:**
- ✅ Redis caching (3600s)
- ✅ JOIN with categories

**Masalah:**
- ⚠️ Tidak include stock information
- ⚠️ Cache invalidation hanya pada update, tidak pada stock change

#### ⚠️ **CREATE Product** (`createProduct`)
```javascript
INSERT INTO products (...) VALUES (...) RETURNING *
```

**Masalah Kritis:**
- ❌ **Tidak auto-create initial stock record di `product_stocks`**
  - Product baru tidak punya row di product_stocks
  - Query JOIN akan return NULL untuk stock
  - Harus manual insert stock untuk setiap branch

**Solusi:**
```javascript
// Setelah INSERT product:
const branches = await db.query('SELECT id FROM branches WHERE is_active = true');
for (const branch of branches.rows) {
  await db.query(
    'INSERT INTO product_stocks (product_id, branch_id, quantity) VALUES ($1, $2, 0)',
    [product.id, branch.id]
  );
}
```

#### ⚠️ **UPDATE Product Stock** (`updateProductStock`)
```javascript
// Support 3 operations: 'set', 'add', 'subtract'
if (operation === 'add') {
  newQuantity = existing.rows[0].quantity + quantity;
}
```

**Masalah:**
- ⚠️ Tidak ada validasi stok tidak boleh negatif
- ⚠️ Tidak ada logging/audit trail
- ⚠️ Tidak emit socket event untuk real-time update

---

## 📱 FRONTEND LAYER (Flutter - Management App)

### Entity vs Database Mismatch

#### 🔴 **MASALAH UTAMA: Stock Field**

**Database:**
```sql
-- Stock ada di tabel terpisah product_stocks (per branch)
SELECT ps.quantity FROM product_stocks ps 
WHERE ps.product_id = 1 AND ps.branch_id = 1
```

**Backend Response:**
```json
{
  "id": 1,
  "sku": "PRD001",
  "name": "Product A",
  "stock_quantity": 100,        // ❌ Hanya 1 cabang
  "available_quantity": 95       // ❌ Computed dari 1 cabang
}
```

**Frontend Entity:**
```dart
class Product {
  final int stock;  // ❌ TIDAK SESUAI! 
  // Seharusnya Map<String, StockInfo> per branch
  // ATAU fetch stock separately
}
```

**Dampak:**
- ❌ Product entity menyimpan stock sebagai single integer
- ❌ Tidak support multi-branch stock management
- ❌ Frontend tidak bisa lihat stock per cabang
- ❌ Stock update tidak real-time sync antar cabang

### Remote Data Source Issues

#### ⚠️ **getAllProducts()**
```dart
final response = await apiClient.get(
  '/products',
  queryParameters: {
    'limit': 1000, // ⚠️ Hardcoded limit
    // ❌ Tidak kirim branchId
  },
);
```

**Masalah:**
- ⚠️ Limit 1000 bisa insufficient untuk produk banyak
- ❌ Tidak filter by branch → bisa dapat duplicate rows
- ⚠️ Tidak support pagination untuk large dataset

#### ❌ **updateStock()**
```dart
Future<void> updateStock(String id, int quantity) async {
  final response = await apiClient.patch(
    '/products/$id/stock',  // ❌ Endpoint salah!
    data: {'quantity': quantity},
  );
}
```

**Masalah Kritis:**
- ❌ **Endpoint seharusnya PUT bukan PATCH** (backend pakai PUT)
- ❌ **Tidak kirim branchId** (required di backend)
- ❌ **Tidak kirim operation** (set/add/subtract)

**Seharusnya:**
```dart
final response = await apiClient.put(
  '/products/$id/stock',
  data: {
    'branchId': currentBranchId,
    'quantity': quantity,
    'operation': 'set',  // atau 'add'/'subtract'
  },
);
```

### Repository Issues

#### ⚠️ **Socket.IO Integration**
```dart
void _listenToProductUpdates() {
  socketService.productUpdates.listen((data) async {
    // ❌ Hanya listen, tapi tidak trigger UI refresh
    // ❌ Tidak update local state di BLoC
  });
}
```

**Masalah:**
- Product update dari user lain tidak auto-refresh UI
- Perlu trigger BLoC event untuk rebuild widget

---

## 🐛 BUGS & ISSUES SUMMARY

### 🔴 **CRITICAL ISSUES**

1. **Stock Multi-Branch Mismatch**
   - ❌ Backend return stock untuk 1 branch saja
   - ❌ Frontend tidak support multi-branch stock
   - ❌ getAllProducts bisa return duplicate rows (multiple stocks)
   
2. **Product Creation Incomplete**
   - ❌ Create product tidak auto-create stock record
   - ❌ New product tidak punya initial stock di any branch
   
3. **Stock Update Broken**
   - ❌ Frontend pakai endpoint wrong (PATCH vs PUT)
   - ❌ Tidak kirim branchId (required parameter)
   - ❌ Tidak ada validasi stok tidak boleh negatif

### ⚠️ **HIGH Priority**

4. **Entity Structure Tidak Sesuai**
   - Entity Product.stock harus dirubah
   - Perlu entity terpisah untuk ProductStock per branch
   
5. **No Real-time Stock Updates**
   - Socket.IO hanya emit tapi tidak consume
   - Multi-user bisa conflict stock changes
   
6. **Missing Stock History**
   - Tidak ada log stock mutations
   - Tidak bisa trace stock changes

### 🟡 **MEDIUM Priority**

7. **Performance Issues**
   - No pagination on getAllProducts (hardcoded 1000)
   - LEFT JOIN stock bisa return duplicate rows
   - Redis cache tidak include stock info
   
8. **Missing Features**
   - Tidak ada bulk import products
   - Tidak ada export to Excel
   - Tidak ada product image upload

---

## ✅ RECOMMENDED FIXES

### Fix 1: Update Backend - getAllProducts
```javascript
// Option A: Always filter by branchId
if (!branchId) {
  branchId = req.user.defaultBranchId; // Get from auth
}
query += ` AND ps.branch_id = $${paramIndex}`;

// Option B: Aggregate total stock across branches
LEFT JOIN (
  SELECT product_id, 
         SUM(quantity) as total_stock,
         SUM(available_quantity) as total_available
  FROM product_stocks
  GROUP BY product_id
) ps ON p.id = ps.product_id
```

### Fix 2: Auto-create Stock on Product Creation
```javascript
// In createProduct controller:
const client = await db.getClient();
try {
  await client.query('BEGIN');
  
  // Insert product
  const productResult = await client.query(
    'INSERT INTO products (...) VALUES (...) RETURNING *',
    [...]
  );
  const product = productResult.rows[0];
  
  // Insert initial stock for all active branches
  const branches = await client.query(
    'SELECT id FROM branches WHERE is_active = true'
  );
  
  for (const branch of branches.rows) {
    await client.query(
      `INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity)
       VALUES ($1, $2, 0, 0)`,
      [product.id, branch.id]
    );
  }
  
  await client.query('COMMIT');
  return product;
} catch (e) {
  await client.query('ROLLBACK');
  throw e;
}
```

### Fix 3: Fix Frontend updateStock
```dart
@override
Future<void> updateStock(String id, int quantity, String branchId) async {
  try {
    final response = await apiClient.put(  // ✅ PUT bukan PATCH
      '/products/$id/stock',
      data: {
        'branchId': branchId,              // ✅ Required
        'quantity': quantity,
        'operation': 'set',                 // ✅ Explicit operation
      },
    );
    // ... rest of code
  }
}
```

### Fix 4: Redesign Entity untuk Multi-Branch
```dart
// Option A: Separate stock entity
class Product {
  final String id;
  final String sku;
  // ... other fields
  // ❌ Remove: final int stock;
}

class ProductStock {
  final String productId;
  final String branchId;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
}

// Option B: Stock map in entity
class Product {
  // ...
  final Map<String, ProductStock>? stockByBranch; // branchId → stock
}
```

### Fix 5: Real-time Updates
```dart
// In BLoC
void _listenToProductUpdates() {
  socketService.productUpdates.listen((data) {
    if (data['action'] == 'updated') {
      // Trigger event to refresh product list
      add(RefreshProductsEvent());
    }
  });
}
```

### Fix 6: Add Stock Validation
```javascript
// In backend updateProductStock
if (newQuantity < 0) {
  throw new ValidationError('Stock cannot be negative');
}

// Log to audit
await db.query(
  `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, old_data, new_data)
   VALUES ($1, 'stock_update', 'product', $2, $3, $4)`,
  [userId, productId, { old: oldQty }, { new: newQty }]
);
```

---

## 🎯 ACTION PLAN

### Phase 1: Fix Critical Bugs (IMMEDIATE)
1. ✅ Fix backend getAllProducts - add branchId filter
2. ✅ Fix backend createProduct - auto-create stock records
3. ✅ Fix frontend updateStock - correct endpoint & parameters
4. ✅ Add stock validation (no negative)

### Phase 2: Multi-Branch Support (HIGH)
5. 🔄 Redesign Product entity (remove single stock field)
6. 🔄 Create ProductStock entity
7. 🔄 Update UI to show stock per branch
8. 🔄 Add branch selector for stock operations

### Phase 3: Real-time & Performance (MEDIUM)
9. 🔄 Implement real-time stock updates via Socket.IO
10. 🔄 Add pagination to getAllProducts
11. 🔄 Optimize queries with proper indexes
12. 🔄 Add Redis cache for stock data

### Phase 4: Features & UX (LOW)
13. 🔄 Bulk import products (Excel/CSV)
14. 🔄 Export products report
15. 🔄 Product image upload & management
16. 🔄 Stock history & audit trail
17. 🔄 Low stock alerts & notifications

---

## 📝 NOTES

**Management App Role:**
- ✅ Manage product master data (CRUD)
- ✅ View stock across all branches
- ✅ Adjust stock per branch
- ✅ Generate reports
- ❌ NOT for POS transactions (di POS App)

**Backend Design:**
- Multi-branch support via product_stocks table
- Soft delete untuk data integrity
- Redis caching untuk performance
- Socket.IO untuk real-time updates

**Current State:**
- ✅ Basic CRUD works
- ⚠️ Stock management partially broken
- ❌ Multi-branch not fully implemented
- ❌ Real-time updates not working

---

*Analisis dibuat: 27 Oktober 2025*
*Backend Version: v2.0.0*
*Management App: Flutter 3.7.0+*
