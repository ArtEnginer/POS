# CHANGELOG V5 - Products Table Restructure

## 📋 Perubahan Besar

### 1. **Table `products` - Hapus Harga**
❌ **DIHAPUS:**
- `cost_price` (Harga Beli)
- `selling_price` (Harga Jual)  
- `unit` (Unit lama)
- `base_unit_id` (Foreign key ke product_units)

✅ **DITAMBAH/DIUBAH:**
- `base_unit` VARCHAR(50) - Langsung isi string unit (PCS, BOX, KG, dll)

**Alasan:**
- Harga sekarang **HANYA** di `product_branch_prices` (per cabang & unit)
- Base unit tidak perlu foreign key, cukup string untuk kemudahan
- Lebih fleksibel untuk multi-unit dan multi-branch pricing

---

### 2. **Struktur Baru Table `products`**

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES categories(id),
    base_unit VARCHAR(50) DEFAULT 'PCS',        -- ✅ STRING, bukan ID
    min_stock DECIMAL(15, 3) DEFAULT 0,
    max_stock DECIMAL(15, 3) DEFAULT 0,
    reorder_point DECIMAL(15, 3) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_trackable BOOLEAN DEFAULT true,
    image_url TEXT,
    attributes JSONB DEFAULT '{}',
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
```

---

### 3. **Harga Produk** 
Semua harga sekarang di `product_branch_prices`:

```sql
SELECT * FROM product_branch_prices WHERE product_id = 1;

-- Hasil:
-- id | product_id | branch_id | product_unit_id | cost_price | selling_price | wholesale_price | member_price
-- 1  |     1      |     1     |       1         |   2500     |    3000       |     2800        |    2900
-- 2  |     1      |     1     |       2         |  60000     |   72000       |    68000        |    70000
-- 3  |     1      |     2     |       1         |   2600     |    3100       |     2900        |    3000
```

**Keuntungan:**
- Bisa atur harga berbeda per cabang
- Bisa atur harga berbeda per unit (PCS, BOX, KARTON)
- Support harga grosir & harga member
- Support nilai desimal (Rp 2500.50)

---

### 4. **Backend Changes**

**File yang diubah:**
1. `productController.js`:
   - `createProduct`: Remove costPrice, sellingPrice params → Add baseUnit
   - `updateProduct`: Remove costPrice, sellingPrice from field mapping
   - `getAllProducts`: Remove sort by cost_price/selling_price
   - `searchProducts`: Remove cost_price, selling_price from SELECT
   - `importFromExcel`: Remove price validation, add baseUnit

2. `seed_database.js`:
   - Remove cost & price from products array
   - Change `unit` → `base_unit`
   - Update INSERT query

3. `COMPLETE_SCHEME_V4.sql`:
   - Remove cost_price, selling_price, unit, base_unit_id columns
   - Add base_unit VARCHAR(50)
   - Remove foreign key constraint

---

### 5. **Flutter Changes Needed** ⚠️

File yang **PERLU DIUBAH**:
1. `product_form_page.dart`:
   - Remove `_costPriceController` dan `_sellingPriceController` 
   - Tab 1 (Basic Info) hanya untuk: SKU, Name, Category, Description, Base Unit
   - Tab 3 (Pricing) untuk semua harga (per branch & unit)

2. `product.dart` (Entity):
   ```dart
   class Product {
     final String id;
     final String sku;
     final String name;
     final String baseUnit;  // ✅ String, bukan baseUnitId
     // ❌ Remove: costPrice, sellingPrice
     ...
   }
   ```

3. `product_model.dart`:
   ```dart
   factory ProductModel.fromJson(Map<String, dynamic> json) {
     return ProductModel(
       ...
       baseUnit: json['base_unit'] ?? 'PCS',
       // ❌ Remove: costPrice, sellingPrice parsing
     );
   }
   ```

---

### 6. **Migration Steps** 🚀

#### A. Fresh Install (Recommended)
```bash
# 1. Drop & recreate database
node setup_database_complete.js

# 2. Seed sample data
node seed_database.js

# 3. Start backend
npm run dev
```

#### B. Migrate Existing Data
```bash
# 1. Backup database first!
pg_dump pos_enterprise > backup_$(date +%Y%m%d).sql

# 2. Run migration script
psql -U postgres -d pos_enterprise -f MIGRATE_PRODUCTS_V5.sql

# 3. Verify
psql -U postgres -d pos_enterprise -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'products';"

# 4. Re-seed if needed
node seed_database.js
```

---

### 7. **Testing Checklist** ✅

- [ ] Create product baru (tanpa cost/selling price di form basic info)
- [ ] Add product units di tab Units
- [ ] Set harga (cost, selling, wholesale, member) di tab Pricing
- [ ] Edit product existing
- [ ] Search product (tanpa sort by price)
- [ ] Import Excel (kolom: SKU, Nama, Base Unit, Min Stock, etc)
- [ ] View product list
- [ ] Check database: `SELECT * FROM products LIMIT 5;`
- [ ] Check prices: `SELECT * FROM product_branch_prices LIMIT 10;`

---

### 8. **Breaking Changes** ⚠️

**API Changes:**
```javascript
// ❌ OLD - Create Product
POST /api/v2/products
{
  "sku": "PRD-001",
  "name": "Indomie",
  "unit": "PCS",
  "costPrice": 2500,
  "sellingPrice": 3000
}

// ✅ NEW - Create Product
POST /api/v2/products
{
  "sku": "PRD-001",
  "name": "Indomie",
  "baseUnit": "PCS"
  // Harga diatur lewat endpoint terpisah
}

// Set harga per branch & unit
PUT /api/v2/products/:id/prices
{
  "branchId": "1",
  "unitId": "1",
  "costPrice": 2500,
  "sellingPrice": 3000,
  "wholesalePrice": 2800,
  "memberPrice": 2900
}
```

**Response Changes:**
```javascript
// ❌ OLD Response
{
  "id": "1",
  "sku": "PRD-001",
  "name": "Indomie",
  "unit": "PCS",
  "costPrice": 2500,
  "sellingPrice": 3000
}

// ✅ NEW Response
{
  "id": "1",
  "sku": "PRD-001",
  "name": "Indomie",
  "baseUnit": "PCS"
  // Get harga dari endpoint GET /products/:id/prices
}
```

---

### 9. **Rollback Plan** ⏮️

Jika ada masalah:
```bash
# Restore dari backup
psql -U postgres -d pos_enterprise < backup_YYYYMMDD.sql

# Atau drop & setup ulang dengan schema lama
# (Simpan COMPLETE_SCHEME_V4.sql lama sebagai backup)
```

---

## 📞 Support

Jika ada error:
1. Check backend logs: `npm run dev`
2. Check database: `psql -U postgres -d pos_enterprise`
3. Verify schema: `\d products`
4. Check prices: `SELECT * FROM product_branch_prices LIMIT 5;`

---

**Updated:** November 1, 2025  
**Version:** 5.0.0  
**Breaking Changes:** YES  
**Migration Required:** YES
