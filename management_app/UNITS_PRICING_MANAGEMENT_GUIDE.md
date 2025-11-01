# Product Units & Pricing Management - User Guide

## Overview
Fitur ini memungkinkan Anda untuk:
- ✅ Mengelola multi-unit conversion (PCS, BOX, DUS, dll)
- ✅ Mengatur harga berbeda untuk setiap cabang dan unit
- ✅ Bulk edit pricing untuk multiple branch & unit sekaligus

## 🎯 Use Case

### Contoh: Produk Minuman Botol
- **Unit Dasar**: PCS (1 botol)
- **Unit Konversi**:
  - 1 PAK = 6 PCS
  - 1 BOX = 24 PCS (4 PAK)
  - 1 DUS = 120 PCS (5 BOX)

### Pricing per Cabang
| Cabang | Unit | Harga Beli | Harga Jual | Margin |
|--------|------|------------|------------|--------|
| Pusat  | PCS  | 3,000      | 5,000      | 66.7%  |
| Pusat  | PAK  | 17,000     | 28,000     | 64.7%  |
| Cabang A | PCS | 3,200      | 5,500      | 71.9%  |
| Cabang A | PAK | 18,000     | 30,000     | 66.7%  |

---

## 📋 Cara Menggunakan

### 1. Product Form - Units Tab

#### Menambah Unit Baru
1. Buka Product Form (Tambah/Edit Product)
2. Klik tab **"Units"**
3. Klik tombol **"Tambah Unit"**
4. Isi form:
   - **Nama Unit**: Contoh `BOX`, `DUS`, `KG`
   - **Nilai Konversi**: Berapa unit dasar = 1 unit ini
     - Contoh: 1 BOX = 10 PCS → isi `10`
   - **Barcode**: Optional, barcode khusus untuk unit ini
   - **Dapat Dijual**: ✅ Unit ini bisa digunakan untuk penjualan
   - **Dapat Dibeli**: ✅ Unit ini bisa digunakan untuk pembelian

#### Set Unit Dasar
- Klik **"Set sebagai dasar"** pada unit yang ingin dijadikan base
- Unit dasar otomatis memiliki conversion value = 1
- Hanya boleh ada 1 unit dasar per produk

#### Menghapus Unit
- Klik icon 🗑️ di pojok kanan card unit
- Unit dasar **tidak bisa dihapus**

---

### 2. Product Form - Pricing Tab

#### Menambah Harga (Single)
1. Buka tab **"Pricing"**
2. Klik **"Tambah Bulk"**
3. Pilih cabang dan unit yang diinginkan
4. Klik **"Tambahkan"**
5. Isi harga beli, harga jual, dan harga optional (grosir/member)

#### Menambah Harga (Bulk)
1. Klik **"Tambah Bulk"**
2. Dialog akan muncul dengan pilihan:
   - ✅ **Cabang**: Pilih multiple cabang
   - ✅ **Unit**: Pilih multiple unit
3. Klik **"Tambahkan"**
4. Sistem akan membuat price entry untuk setiap kombinasi branch × unit

**Contoh Bulk Add:**
- Pilih Cabang: `Pusat`, `Cabang A`, `Cabang B` (3 cabang)
- Pilih Unit: `PCS`, `BOX`, `DUS` (3 unit)
- Result: **9 price entries** dibuat (3 × 3)

#### Edit Harga
Setiap price card memiliki field:
- **Harga Beli** (\*wajib): Cost price
- **Harga Jual** (\*wajib): Selling price
- **Harga Grosir** (optional): Special price untuk pelanggan grosir
- **Harga Member** (optional): Special price untuk member/VIP
- **Margin**: Auto-calculated dari `(jual - beli) / beli × 100%`
- **Status Aktif**: Toggle untuk enable/disable harga

#### Filter Harga
- **Filter Cabang**: Tampilkan harga untuk cabang tertentu saja
- **Filter Unit**: Tampilkan harga untuk unit tertentu saja

#### Menghapus Harga
- Klik icon 🗑️ di pojok kanan card harga

---

## 🔄 Workflow: Create Product dengan Multi-Unit & Pricing

### Step 1: Basic Info
```
1. Buka Product Form
2. Isi informasi dasar:
   - Nama: "Minuman Soda Botol"
   - Barcode: "8991234567890"
   - Kategori: "Minuman"
```

### Step 2: Setup Units
```
1. Klik tab "Units"
2. Tambah unit pertama (base):
   - Nama: PCS
   - Konversi: 1 (auto)
   - Set sebagai dasar: ✅

3. Tambah unit kedua:
   - Nama: PAK
   - Konversi: 6
   - Dapat Dijual: ✅
   - Dapat Dibeli: ✅

4. Tambah unit ketiga:
   - Nama: DUS
   - Konversi: 120
   - Dapat Dijual: ❌ (hanya untuk internal)
   - Dapat Dibeli: ✅
```

### Step 3: Setup Pricing
```
1. Klik tab "Pricing"
2. Klik "Tambah Bulk"
3. Pilih:
   - Cabang: ✅ Pusat, ✅ Cabang A
   - Unit: ✅ PCS, ✅ PAK

4. Hasil: 4 price entries:
   - Pusat - PCS
   - Pusat - PAK
   - Cabang A - PCS
   - Cabang A - PAK

5. Isi harga untuk masing-masing:
   
   Pusat - PCS:
   - Harga Beli: 3,000
   - Harga Jual: 5,000
   - Margin: 66.7% (auto)

   Pusat - PAK:
   - Harga Beli: 17,000
   - Harga Jual: 28,000
   - Margin: 64.7% (auto)

   Cabang A - PCS:
   - Harga Beli: 3,200
   - Harga Jual: 5,500
   - Margin: 71.9% (auto)

   Cabang A - PAK:
   - Harga Beli: 18,500
   - Harga Jual: 31,000
   - Margin: 67.6% (auto)
```

### Step 4: Save
```
1. Klik tombol "Simpan" di bawah form
2. Data akan tersimpan ke backend
3. Sistem akan save:
   - Product basic info
   - Product units (3 entries)
   - Product prices (4 entries)
```

---

## 📊 Features

### Auto-Calculations
- ✅ **Margin Percentage**: Otomatis dihitung dari cost & selling price
  ```
  Margin = ((Selling - Cost) / Cost) × 100%
  ```

### Validations
- ✅ Nama unit harus diisi
- ✅ Conversion value harus > 0
- ✅ Hanya boleh 1 unit dasar
- ✅ Unit dasar tidak bisa dihapus
- ✅ Duplicate branch-unit combination dicegah

### UI Indicators
Di **Product List Page**, setiap product card menampilkan:
- `[3]` = Jumlah units
- `🏪` = Memiliki branch-specific pricing

Di **Product Detail Page**, terdapat:
- **Units Card**: Table dengan kolom Unit, Konversi, Jual, Beli
- **Pricing Matrix**: Table dengan group by Branch, showing prices per unit

---

## 🎨 Screenshots Guide

### Units Tab
```
┌─────────────────────────────────────────────┐
│ 🔲 Unit Konversi          [Tambah Unit]    │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ [UNIT DASAR]                   #1  🗑️  │ │
│ ├─────────────────────────────────────────┤ │
│ │ Nama Unit: PCS                          │ │
│ │ Nilai Konversi: 1    Barcode: ______   │ │
│ │ ✅ Dapat Dijual  ✅ Dapat Dibeli       │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ Set sebagai dasar              #2  🗑️  │ │
│ ├─────────────────────────────────────────┤ │
│ │ Nama Unit: BOX                          │ │
│ │ Nilai Konversi: 10   Barcode: ______   │ │
│ │ ✅ Dapat Dijual  ✅ Dapat Dibeli       │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Pricing Tab
```
┌─────────────────────────────────────────────┐
│ 🏪 Harga per Cabang & Unit [Tambah Bulk]   │
├─────────────────────────────────────────────┤
│ Filter: [Semua Cabang ▼] [Semua Unit ▼]   │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ 🏪 Cabang Pusat   [PCS]          🗑️   │ │
│ ├─────────────────────────────────────────┤ │
│ │ Harga Beli: Rp 3000  Harga Jual: 5000  │ │
│ │ Grosir: 4500         Member: 4800      │ │
│ │ Margin: 66.7%        ✅ Aktif          │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## 🔧 Technical Notes

### Data Structure

#### Product Units
```dart
{
  'id': '1',
  'productId': '123',
  'unitName': 'BOX',
  'conversionValue': 10.0,
  'isBaseUnit': false,
  'canSell': true,
  'canPurchase': true,
  'barcode': 'BOX123456',
  'sortOrder': 1
}
```

#### Product Prices
```dart
{
  'id': '1',
  'productId': '123',
  'branchId': '1',
  'branchName': 'Pusat',
  'productUnitId': '1',
  'unitName': 'PCS',
  'costPrice': 3000.0,
  'sellingPrice': 5000.0,
  'wholesalePrice': 4500.0,
  'memberPrice': 4800.0,
  'marginPercentage': 66.7,
  'validFrom': null,
  'validUntil': null,
  'isActive': true
}
```

### Backend Integration
Widget akan memanggil callback:
- `onUnitsChanged(List<Map>)` - Setiap ada perubahan units
- `onPricesChanged(List<Map>)` - Setiap ada perubahan prices

Parent form (ProductFormPage) akan handle save ke backend menggunakan endpoint yang sudah ada.

---

## ⚠️ Important Notes

1. **Unit Dasar Wajib**: Setiap produk harus memiliki minimal 1 unit dasar
2. **Conversion Value**: Selalu dihitung relatif terhadap unit dasar
3. **Stock Calculation**: Backend akan convert semua stock ke base unit
4. **Pricing Priority**: Jika ada harga branch-specific, gunakan itu. Jika tidak, fallback ke harga default produk
5. **Validation**: Frontend melakukan validation, tapi backend juga harus validate untuk keamanan

---

## 🚀 Next Steps (Future Enhancement)

- [ ] Import/Export Units & Pricing via Excel
- [ ] Copy pricing dari satu branch ke branch lain
- [ ] Bulk edit prices dengan % adjustment
- [ ] Price history & validity period management
- [ ] Multi-currency support per branch

---

## 📞 Support

Jika ada pertanyaan atau issue, silakan hubungi tim development.

**Last Updated**: November 2024
**Version**: 1.0
