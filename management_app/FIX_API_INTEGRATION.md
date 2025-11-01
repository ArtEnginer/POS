# Fix API Integration untuk Multi-Unit dan Branch-Specific Pricing

## Masalah
User melaporkan tidak melihat adanya perubahan pada UI product meskipun semua kode UI sudah diimplementasikan.

## Root Cause Analysis
1. **API Endpoint Issue**: `getProductById()` di `product_remote_data_source.dart` menggunakan endpoint `/products/$id` yang tidak mengembalikan data `units` dan `prices`
2. **Model Parsing Issue**: `ProductModel.fromJson()` tidak melakukan parsing untuk field `units` dan `prices` dari response API

## Solusi yang Diimplementasikan

### 1. Update API Endpoint
**File**: `lib/features/product/data/datasources/product_remote_data_source.dart`

**Perubahan**:
```dart
// SEBELUM
final response = await http.get(
  Uri.parse('$baseUrl/products/$id'),
  headers: {'Content-Type': 'application/json'},
);

// SESUDAH
final response = await http.get(
  Uri.parse('$baseUrl/products/$id/complete'), // Menggunakan endpoint /complete
  headers: {'Content-Type': 'application/json'},
);
```

**Alasan**: Endpoint `/products/:id/complete` mengembalikan data lengkap termasuk `units` dan `prices`.

### 2. Update Model Parsing
**File**: `lib/features/product/data/models/product_model.dart`

#### 2.1 Tambah Import
```dart
import '../../../product/domain/entities/product_unit.dart';
import '../../../product/domain/entities/product_branch_price.dart';
import 'product_unit_model.dart';
import 'product_branch_price_model.dart';
```

#### 2.2 Parse Units dan Prices di fromJson
```dart
// Parse product units
List<ProductUnit>? units;
if (json['units'] != null && json['units'] is List) {
  units = (json['units'] as List)
      .map((unitJson) => ProductUnitModel.fromJson(unitJson).toEntity())
      .toList();
}

// Parse product prices
List<ProductBranchPrice>? prices;
if (json['prices'] != null && json['prices'] is List) {
  prices = (json['prices'] as List)
      .map((priceJson) =>
          ProductBranchPriceModel.fromJson(priceJson).toEntity())
      .toList();
}
```

#### 2.3 Tambahkan ke Constructor
```dart
return ProductModel(
  // ... parameter lainnya ...
  branchStocks: branchStocks,
  units: units,        // ← Ditambahkan
  prices: prices,      // ← Ditambahkan
);
```

#### 2.4 Update fromEntity Method
```dart
factory ProductModel.fromEntity(Product product) {
  return ProductModel(
    // ... parameter lainnya ...
    branchStocks: product.branchStocks,
    units: product.units,        // ← Ditambahkan
    prices: product.prices,      // ← Ditambahkan
  );
}
```

## Data Flow Setelah Fix

```
API Request
    ↓
GET /products/{id}/complete
    ↓
JSON Response (includes units, prices)
    ↓
ProductModel.fromJson()
    ├─> Parse units → List<ProductUnit>
    └─> Parse prices → List<ProductBranchPrice>
    ↓
Product Entity (with units & prices)
    ↓
UI Display
    ├─> Product Detail Page
    │   ├─> _buildUnitsCard() → Table satuan
    │   └─> _buildPricingCard() → Matrix harga per cabang
    └─> Product List Page
        ├─> Multi-unit badge: [3]
        └─> Branch pricing badge: 🏪
```

## Cara Test

### 1. Restart Flutter App
Hot reload mungkin tidak cukup untuk perubahan data source:
```bash
# Di terminal Flutter
r  # untuk hot reload
# atau
R  # untuk hot restart
```

### 2. Cek Product Detail Page
1. Buka Management App
2. Navigasi ke Product List
3. Tap pada product yang sudah memiliki multi-unit dan branch pricing
4. Verifikasi muncul:
   - **Units Card**: Tabel showing unit conversions (PCS, BOX, DUS)
   - **Pricing Card**: Matrix showing prices per branch and unit

### 3. Cek Product List Page
1. Lihat product card di list
2. Verifikasi badge indicator:
   - `[3]` = Product memiliki 3 units
   - `🏪` = Product memiliki branch-specific pricing

## Expected Backend Response

Endpoint `/products/:id/complete` seharusnya return:
```json
{
  "id": 1,
  "sku": "PROD-001",
  "name": "Sample Product",
  // ... fields lainnya ...
  "units": [
    {
      "id": 1,
      "product_id": 1,
      "unit_name": "PCS",
      "conversion_to_base": 1.0,
      "is_base_unit": true,
      "can_sell": true,
      "can_purchase": true,
      "barcode": "123456789"
    },
    {
      "id": 2,
      "product_id": 1,
      "unit_name": "BOX",
      "conversion_to_base": 10.0,
      "is_base_unit": false,
      "can_sell": true,
      "can_purchase": true,
      "barcode": "BOX123456789"
    }
  ],
  "prices": [
    {
      "id": 1,
      "product_id": 1,
      "branch_id": 1,
      "branch_name": "Cabang Pusat",
      "unit_id": 1,
      "unit_name": "PCS",
      "cost_price": 5000,
      "selling_price": 7000,
      "margin_percentage": 40.0,
      "valid_from": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Troubleshooting

### UI Masih Belum Muncul
1. **Cek Backend Response**: 
   - Buka Network Inspector di Flutter DevTools
   - Verifikasi response dari `/products/:id/complete` contains `units` dan `prices`
   
2. **Cek Console Log**:
   ```dart
   // Temporary debug di product_detail_page.dart
   print('Product units: ${product.units?.length ?? 0}');
   print('Product prices: ${product.prices?.length ?? 0}');
   ```

3. **Cek Backend Endpoint**:
   - Pastikan backend sudah dijalankan migration: `run_multi_unit_migration.js`
   - Test endpoint manual: `GET http://localhost:3000/api/products/1/complete`

### Badge Tidak Muncul di List Page
- Pastikan product sudah memiliki data di table `product_units` dan `product_branch_prices`
- Badge hanya muncul jika `product.units != null && product.units!.isNotEmpty`

## Files yang Dimodifikasi

1. ✅ `lib/features/product/data/datasources/product_remote_data_source.dart`
2. ✅ `lib/features/product/data/models/product_model.dart`

## Status
- [x] Fix API endpoint
- [x] Fix model parsing
- [x] Fix import paths (product_unit_model.dart, product_branch_price_model.dart)
- [x] Remove duplicate copyWith method
- [x] No compilation errors
- [ ] Testing dengan real data (pending user verification)

## Next Steps
Jika UI masih belum muncul setelah fix ini, langkah selanjutnya:
1. Verifikasi backend response contains units dan prices
2. Add debug logging untuk trace data flow
3. Check if migration was run successfully on backend database
