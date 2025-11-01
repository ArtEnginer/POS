# Multi-Unit & Branch-Specific Pricing

## 📋 Overview

Sistem POS sekarang mendukung:
1. **Multi-Unit Conversion**: Produk dapat dijual/dibeli dalam berbagai satuan (PCS, BOX, DUS, dll)
2. **Branch-Specific Pricing**: Setiap cabang dapat memiliki harga beli dan jual berbeda untuk setiap unit

## 🎯 Fitur Utama

### 1. Multi-Unit Conversion (Satuan Konversi)

Produk dapat memiliki multiple units dengan conversion value ke unit dasar.

**Contoh:**
```
Produk: Coca Cola
- PCS (Base Unit): 1 PCS = 1 PCS
- BOX: 1 BOX = 10 PCS
- DUS: 1 DUS = 100 PCS (atau 10 BOX)
```

**Fitur:**
- ✅ Unit dasar (base unit) sebagai acuan perhitungan stok
- ✅ Conversion value otomatis untuk perhitungan
- ✅ Barcode khusus per unit (optional)
- ✅ Flag purchasable/sellable per unit
- ✅ Sort order untuk mengurutkan tampilan

### 2. Branch-Specific Pricing (Harga Per Cabang)

Setiap cabang dapat memiliki harga berbeda untuk setiap unit.

**Contoh:**
```
Produk: Coca Cola - DUS
Branch A (Jakarta):
  - Harga Beli: Rp 200.000
  - Harga Jual: Rp 250.000
  - Margin: 25%

Branch B (Bandung):
  - Harga Beli: Rp 190.000
  - Harga Jual: Rp 240.000
  - Margin: 26.3%
```

**Fitur:**
- ✅ Harga beli & jual per branch per unit
- ✅ Harga grosir (wholesale price)
- ✅ Harga member (member price)
- ✅ Auto-calculated margin percentage
- ✅ Validity period (valid from/until)

## 🗄️ Database Schema

### Table: `product_units`

```sql
CREATE TABLE product_units (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    unit_name VARCHAR(50) NOT NULL,
    conversion_value DECIMAL(15, 3) NOT NULL DEFAULT 1,
    is_base_unit BOOLEAN DEFAULT FALSE,
    is_purchasable BOOLEAN DEFAULT TRUE,
    is_sellable BOOLEAN DEFAULT TRUE,
    barcode VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
```

### Table: `product_branch_prices`

```sql
CREATE TABLE product_branch_prices (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    product_unit_id INTEGER, -- NULL = harga untuk unit dasar
    cost_price DECIMAL(15, 2) DEFAULT 0,
    selling_price DECIMAL(15, 2) NOT NULL,
    wholesale_price DECIMAL(15, 2),
    member_price DECIMAL(15, 2),
    margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS (...) STORED,
    valid_from TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
```

### View: `v_product_units_prices`

View untuk query lengkap produk dengan units dan prices:

```sql
SELECT * FROM v_product_units_prices 
WHERE product_id = 1;
```

## 🚀 Installation & Setup

### 1. Run Migration

```bash
cd backend_v2
node run_multi_unit_migration.js
```

**Output:**
```
✅ Migration completed successfully!
📊 Migration Summary:
   - Created table: product_units
   - Created table: product_branch_prices
   - Created view: v_product_units_prices
   - Migrated existing products with base units
   - Created default prices for all branches
```

### 2. Restart Backend Server

```bash
cd backend_v2
npm start
```

Server akan otomatis load routes baru untuk unit management.

## 📡 API Endpoints

### Product Units Management

#### Get Product Units
```http
GET /api/v2/products/:productId/units
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "product_id": "123",
      "unit_name": "PCS",
      "conversion_value": 1,
      "is_base_unit": true,
      "is_purchasable": true,
      "is_sellable": true,
      "sort_order": 0
    },
    {
      "id": "2",
      "product_id": "123",
      "unit_name": "BOX",
      "conversion_value": 10,
      "is_base_unit": false,
      "is_purchasable": true,
      "is_sellable": true,
      "sort_order": 1
    }
  ]
}
```

#### Create Product Unit
```http
POST /api/v2/products/:productId/units
Authorization: Bearer {token}
Content-Type: application/json

{
  "unitName": "DUS",
  "conversionValue": 100,
  "isBaseUnit": false,
  "isPurchasable": true,
  "isSellable": true,
  "barcode": "1234567890128",
  "sortOrder": 2
}
```

#### Update Product Unit
```http
PUT /api/v2/products/:productId/units/:unitId
Authorization: Bearer {token}
Content-Type: application/json

{
  "unitName": "CARTON",
  "conversionValue": 100,
  "sortOrder": 2
}
```

#### Delete Product Unit
```http
DELETE /api/v2/products/:productId/units/:unitId
Authorization: Bearer {token}
```

### Product Pricing Management

#### Get Product Prices
```http
GET /api/v2/products/:productId/prices?unitId=1&branchId=1
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "product_id": "123",
      "branch_id": "1",
      "product_unit_id": "1",
      "cost_price": 5000,
      "selling_price": 7000,
      "wholesale_price": 6500,
      "member_price": 6800,
      "margin_percentage": 40,
      "branch_name": "Jakarta Pusat",
      "unit_name": "PCS"
    }
  ]
}
```

#### Update Product Price (Single Branch & Unit)
```http
PUT /api/v2/products/:productId/prices
Authorization: Bearer {token}
Content-Type: application/json

{
  "branchId": "1",
  "unitId": "1",
  "costPrice": 5000,
  "sellingPrice": 7000,
  "wholesalePrice": 6500,
  "memberPrice": 6800
}
```

#### Bulk Update Prices (All Branches)
```http
PUT /api/v2/products/:productId/prices/bulk
Authorization: Bearer {token}
Content-Type: application/json

{
  "unitId": "1",
  "costPrice": 5000,
  "sellingPrice": 7000,
  "wholesalePrice": 6500,
  "memberPrice": 6800
}
```

#### Get Product Complete (with Units & Prices)
```http
GET /api/v2/products/:productId/complete?branchId=1
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123",
    "sku": "PRD-001",
    "name": "Coca Cola",
    "units": [
      {
        "id": "1",
        "unit_name": "PCS",
        "conversion_value": 1,
        "is_base_unit": true
      },
      {
        "id": "2",
        "unit_name": "BOX",
        "conversion_value": 10,
        "is_base_unit": false
      }
    ],
    "prices": [
      {
        "id": "1",
        "branch_id": "1",
        "product_unit_id": "1",
        "cost_price": 5000,
        "selling_price": 7000,
        "branch_name": "Jakarta Pusat",
        "unit_name": "PCS"
      },
      {
        "id": "2",
        "branch_id": "1",
        "product_unit_id": "2",
        "cost_price": 50000,
        "selling_price": 70000,
        "branch_name": "Jakarta Pusat",
        "unit_name": "BOX"
      }
    ]
  }
}
```

## 💻 Flutter Integration

### Domain Entities

#### ProductUnit Entity
```dart
class ProductUnit extends Equatable {
  final String id;
  final String productId;
  final String unitName;
  final double conversionValue;
  final bool isBaseUnit;
  final bool isPurchasable;
  final bool isSellable;
  
  // Helper methods
  double toBaseUnit(double quantity);
  double fromBaseUnit(double baseQuantity);
  bool canSell(double quantity);
  bool canPurchase(double quantity);
}
```

#### ProductBranchPrice Entity
```dart
class ProductBranchPrice extends Equatable {
  final String id;
  final String productId;
  final String branchId;
  final String? productUnitId;
  final double costPrice;
  final double sellingPrice;
  final double? wholesalePrice;
  final double? memberPrice;
  final double marginPercentage;
  
  // Helper methods
  double get profit;
  bool get isValidNow;
  double getPriceForCustomerType(String customerType);
}
```

#### Updated Product Entity
```dart
class Product extends Equatable {
  // ... existing fields ...
  
  // New fields
  final List<ProductUnit>? units;
  final List<ProductBranchPrice>? prices;
  
  // Helper methods
  bool get hasMultipleUnits;
  int get totalUnits;
  ProductUnit? get baseUnit;
  bool get hasBranchSpecificPricing;
  ProductBranchPrice? getPriceFor({
    required String branchId, 
    String? unitId
  });
}
```

### Usage Example

```dart
// Get product with units and prices
final product = await productRepository.getProductById(
  productId: '123',
  includeUnits: true,
  includePrices: true,
);

// Check if has multiple units
if (product.hasMultipleUnits) {
  print('Units: ${product.totalUnits}');
  product.units?.forEach((unit) {
    print('${unit.unitName}: ${unit.conversionValue}x');
  });
}

// Get price for specific branch
final price = product.getPriceFor(
  branchId: currentBranchId,
  unitId: selectedUnitId,
);

if (price != null) {
  print('Cost: ${price.costPrice}');
  print('Selling: ${price.sellingPrice}');
  print('Margin: ${price.marginPercentage}%');
}

// Convert quantity
final baseUnit = product.baseUnit;
final boxUnit = product.units?.firstWhere(
  (u) => u.unitName == 'BOX'
);

// 5 BOX = 50 PCS
final pcsQuantity = boxUnit?.toBaseUnit(5); // 50

// 100 PCS = 10 BOX
final boxQuantity = boxUnit?.fromBaseUnit(100); // 10
```

## 🔄 Migration Process

Ketika migration dijalankan, sistem akan:

1. **Create Tables**: Membuat `product_units` dan `product_branch_prices`
2. **Migrate Existing Data**:
   - Setiap produk existing akan otomatis dibuatkan 1 base unit (dari field `unit` yang lama)
   - Setiap produk akan dibuatkan harga default untuk semua branch aktif
3. **Create View**: Membuat view `v_product_units_prices` untuk query yang mudah
4. **Add Foreign Keys**: Update `products` table dengan `base_unit_id`

**Data Existing Tetap Aman!** Migration tidak menghapus data lama, hanya menambahkan struktur baru.

## 📊 Use Cases

### Use Case 1: Toko Grosir

```
Produk: Minyak Goreng Bimoli

Units:
- BOTOL (base): 1 botol
- KARTON: 12 botol
- PACK: 6 botol

Pricing (Branch Jakarta):
- BOTOL: Beli Rp 25.000, Jual Rp 28.000
- PACK: Beli Rp 150.000, Jual Rp 165.000 (hemat Rp 3.000)
- KARTON: Beli Rp 300.000, Jual Rp 330.000 (hemat Rp 6.000)

Pricing (Branch Bandung):
- BOTOL: Beli Rp 24.000, Jual Rp 27.000
- PACK: Beli Rp 144.000, Jual Rp 160.000
- KARTON: Beli Rp 288.000, Jual Rp 320.000
```

### Use Case 2: Apotek

```
Produk: Paracetamol 500mg

Units:
- TABLET (base): 1 tablet
- STRIP: 10 tablet
- BOX: 100 tablet (10 strip)

Pricing:
- TABLET: Jual Rp 500
- STRIP: Jual Rp 4.500 (hemat Rp 500)
- BOX: Jual Rp 40.000 (hemat Rp 10.000)

Customer Types:
- Retail: harga jual normal
- Member: dapat member_price (diskon 5%)
- Grosir: dapat wholesale_price (diskon 10%)
```

### Use Case 3: Toko Bangunan

```
Produk: Semen Portland

Units:
- ZAK (base): 1 sak (50kg)
- TON: 20 zak

Branch A (Dekat Pabrik):
- ZAK: Beli Rp 65.000, Jual Rp 70.000
- TON: Beli Rp 1.300.000, Jual Rp 1.380.000

Branch B (Jauh dari Pabrik):
- ZAK: Beli Rp 68.000, Jual Rp 73.000
- TON: Beli Rp 1.360.000, Jual Rp 1.440.000
```

## ⚠️ Important Notes

### Constraints & Validations

1. **One Base Unit Per Product**: Setiap produk hanya boleh punya 1 base unit
2. **Cannot Delete Base Unit**: Base unit tidak dapat dihapus
3. **Conversion Must Be > 0**: Conversion value harus lebih besar dari 0
4. **Base Unit Conversion = 1**: Base unit selalu conversion value = 1
5. **Prices Per Branch Per Unit**: Setiap kombinasi (product, branch, unit) hanya punya 1 active price

### Stock Calculation

- **Semua stok disimpan dalam base unit**
- Contoh: Stok 100 PCS
  - Dalam PCS: 100 PCS
  - Dalam BOX (10x): 10 BOX
  - Dalam DUS (100x): 1 DUS

### Price Calculation

- **Harga bisa manual atau auto-calculated**
- Contoh: Base unit PCS = Rp 5.000
  - BOX (10x) bisa:
    - Auto: Rp 50.000 (5.000 × 10)
    - Manual: Rp 48.000 (bundle discount)

## 🎨 UI Recommendations (Management App)

### Product Form Page

Tambahkan tab/section baru untuk:
1. **Units Management**
   - List units dengan conversion value
   - Add/Edit/Delete unit
   - Set base unit

2. **Pricing Management**
   - Matrix view: Branch vs Units
   - Bulk edit untuk semua branch
   - Individual edit per branch per unit

### Product Detail Page

Tampilkan:
1. **Units Section**
   - Table: Unit | Conversion | Purchasable | Sellable
   
2. **Pricing Section**
   - Table: Branch | Unit | Cost | Selling | Margin
   - Filter by branch/unit

## 🧪 Testing

### Manual Testing

```bash
# 1. Run migration
node run_multi_unit_migration.js

# 2. Create product dengan multiple units
curl -X POST http://localhost:3000/api/v2/products/1/units \
  -H "Authorization: Bearer {token}" \
  -d '{
    "unitName": "BOX",
    "conversionValue": 10,
    "sortOrder": 1
  }'

# 3. Set prices
curl -X PUT http://localhost:3000/api/v2/products/1/prices \
  -H "Authorization: Bearer {token}" \
  -d '{
    "branchId": "1",
    "unitId": "2",
    "costPrice": 50000,
    "sellingPrice": 70000
  }'

# 4. Get complete product data
curl http://localhost:3000/api/v2/products/1/complete?branchId=1 \
  -H "Authorization: Bearer {token}"
```

## 📝 TODO / Future Enhancements

- [ ] UI Form untuk manage units di Management App
- [ ] UI Matrix pricing editor
- [ ] Validation: prevent price below cost
- [ ] Price history tracking
- [ ] Bulk unit creation from template
- [ ] Import units & prices from Excel
- [ ] Multi-currency support per branch
- [ ] Promotion pricing (time-based)
- [ ] Automatic price sync across branches
- [ ] Price change approval workflow

## 🤝 Contributing

Untuk menambahkan fitur atau fix bug:

1. Buat feature branch
2. Update migration jika perlu
3. Update API endpoints
4. Update Flutter models
5. Update dokumentasi
6. Test thoroughly
7. Create Pull Request

## 📞 Support

Jika ada pertanyaan atau issue:
- Check dokumentasi ini dulu
- Check API response untuk error details
- Check backend logs untuk debugging
- Consult dengan tim development

---

**Version**: 1.0.0
**Last Updated**: 2025-11-01
**Author**: Development Team
