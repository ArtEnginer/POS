# Update Purchase Return - Diskon & PPN Per Item

## 📋 Overview

Purchase Return telah di-update untuk **mendukung diskon dan PPN per item** yang berasal dari receiving. Fitur ini memastikan bahwa saat melakukan return, perhitungan diskon dan PPN dilakukan secara proporsional berdasarkan quantity yang di-return.

## ✨ Fitur yang Di-Update

### 1. **Database Schema** ✅
Table `purchase_return_items` sudah memiliki kolom:
- `discount` (REAL) - Nilai diskon untuk item return
- `discount_type` (TEXT) - Tipe diskon: 'AMOUNT' atau 'PERCENTAGE'
- `tax` (REAL) - Nilai PPN untuk item return
- `tax_type` (TEXT) - Tipe PPN: 'AMOUNT' atau 'PERCENTAGE'

### 2. **Entity & Model** ✅
- `PurchaseReturnItem` entity support diskon & PPN per item
- `PurchaseReturn` entity support itemDiscount, itemTax, totalDiscount, totalTax
- `PurchaseReturnItemModel` sudah support toJson/fromJson untuk semua field

### 3. **Purchase Return Form** ✅
Form otomatis mengambil data diskon dan PPN dari receiving item:
- ✅ Diskon per item diambil dari receiving item
- ✅ PPN per item diambil dari receiving item
- ✅ Tipe diskon/PPN (Rp atau %) dipertahankan
- ✅ **Perhitungan proporsional** berdasarkan quantity return

### 4. **Purchase Return Detail Page** ✅
- ✅ Menampilkan diskon & PPN per item
- ✅ Box perhitungan detail per item:
  - Subtotal
  - Diskon (jika ada) dengan keterangan tipe
  - PPN (jika ada) dengan keterangan tipe
  - Total item
- ✅ Summary card dengan semua total
- ✅ Helper methods untuk kalkulasi

### 5. **PDF Print** ✅
- ✅ Tabel menampilkan kolom **Diskon** dan **PPN**
- ✅ Summary lengkap dengan diskon & PPN
- ✅ Format yang rapi dan profesional

## 🧮 Cara Perhitungan

### Perhitungan Proporsional Per Item:

```
LANGKAH 1: Hitung Diskon & PPN per Item
─────────────────────────────────────────
Proporsi Item = Return Qty / Received Qty
Subtotal Return Item = Return Qty × Harga

Jika discount_type = 'PERCENTAGE':
  Diskon Item = Subtotal Return Item × (Diskon% / 100)
Jika discount_type = 'AMOUNT':
  Diskon Item = Diskon Receiving Item × Proporsi Item

After Discount = Subtotal Return Item - Diskon Item

Jika tax_type = 'PERCENTAGE':
  PPN Item = After Discount × (PPN% / 100)
Jika tax_type = 'AMOUNT':
  PPN Item = PPN Receiving Item × Proporsi Item


LANGKAH 2: Hitung Total Discount & Tax yang Harus Di-Return
────────────────────────────────────────────────────────────
Total Subtotal Return = Σ(Subtotal Return Item)
Total Subtotal Receiving = Σ(Subtotal Receiving Item)

Proporsi Return = Total Subtotal Return / Total Subtotal Receiving

Total Discount to Distribute = Total Discount Receiving × Proporsi Return
Total Tax to Distribute = Total Tax Receiving × Proporsi Return


LANGKAH 3: Distribusi Total Discount & Tax ke Setiap Item
──────────────────────────────────────────────────────────
Untuk setiap item return:
  Proporsi Item = Subtotal Item / Total Subtotal Return
  
  Diskon Total Item = Total Discount to Distribute × Proporsi Item
  PPN Total Item = Total Tax to Distribute × Proporsi Item


LANGKAH 4: Hitung Total Akhir Per Item
───────────────────────────────────────
Total Return Item = Subtotal Item - Diskon Item - Diskon Total Item + PPN Item + PPN Total Item
```

### Perhitungan Total Keseluruhan:

```
Subtotal All = Σ(Subtotal Return Item)
Total Diskon Item = Σ(Diskon Return Item)
Total PPN Item = Σ(PPN Return Item)
Total Diskon Total = Σ(Diskon Total per Item)
Total PPN Total = Σ(PPN Total per Item)

GRAND TOTAL = Subtotal All - Total Diskon Item - Total Diskon Total + Total PPN Item + Total PPN Total
```

## 📊 Contoh Perhitungan

### Contoh Data Receiving (2 Item):
```
Item A:
- Received Qty: 10 pcs
- Harga: Rp 10,000
- Diskon: 3% (PERCENTAGE)
- PPN: 0%
- Subtotal: Rp 100,000
- Diskon Amount: Rp 3,000 (3%)
- After Discount: Rp 97,000
- PPN Amount: Rp 0
- Total Item A: Rp 97,000

Item B:
- Received Qty: 10 pcs
- Harga: Rp 10,000
- Diskon: 0%
- PPN: 0%
- Subtotal: Rp 100,000
- Diskon Amount: Rp 0
- After Discount: Rp 100,000
- PPN Amount: Rp 0
- Total Item B: Rp 100,000

Receiving Total:
- Subtotal: Rp 200,000 (100,000 + 100,000)
- Item Discount: Rp 3,000 (dari Item A)
- Item Tax: Rp 0
- Total Discount: Rp 2,000 (diskon total untuk semua)
- Total Tax: Rp 0
- Grand Total: Rp 195,000 (200,000 - 3,000 - 2,000)
```

### Return 5 unit dari Item A dan 5 unit dari Item B:

#### Langkah 1: Hitung Diskon & PPN Per Item
```
Item A Return:
- Return Qty: 5 pcs
- Proporsi: 5/10 = 0.5
- Subtotal Return: 5 × 10,000 = Rp 50,000

- Diskon Item A (PERCENTAGE 3%):
  = Rp 50,000 × 3% = Rp 1,500

- After Discount: Rp 50,000 - Rp 1,500 = Rp 48,500
- PPN Item A: Rp 0

Item B Return:
- Return Qty: 5 pcs
- Proporsi: 5/10 = 0.5
- Subtotal Return: 5 × 10,000 = Rp 50,000

- Diskon Item B: Rp 0
- After Discount: Rp 50,000
- PPN Item B: Rp 0
```

#### Langkah 2: Hitung Total Discount & Tax yang Harus Di-Return
```
Total Subtotal Return = Rp 50,000 + Rp 50,000 = Rp 100,000
Total Subtotal Receiving = Rp 200,000

Proporsi Return = Rp 100,000 / Rp 200,000 = 0.5

Total Discount to Distribute = Rp 2,000 × 0.5 = Rp 1,000
Total Tax to Distribute = Rp 0 × 0.5 = Rp 0
```

#### Langkah 3: Distribusi Total Discount & Tax ke Setiap Item
```
Item A:
- Proporsi Item A terhadap total return = Rp 50,000 / Rp 100,000 = 0.5
- Diskon Total untuk Item A = Rp 1,000 × 0.5 = Rp 500
- PPN Total untuk Item A = Rp 0 × 0.5 = Rp 0

Item B:
- Proporsi Item B terhadap total return = Rp 50,000 / Rp 100,000 = 0.5
- Diskon Total untuk Item B = Rp 1,000 × 0.5 = Rp 500
- PPN Total untuk Item B = Rp 0 × 0.5 = Rp 0
```

#### Langkah 4: Hitung Total Akhir Per Item
```
Item A Return:
Subtotal:         Rp 50,000
Diskon Item:    - Rp  1,500 (3% dari subtotal)
Diskon Total:   - Rp    500 (bagian dari diskon total Rp 2,000)
PPN Item:       + Rp      0
PPN Total:      + Rp      0
─────────────────────────
Total Item A:     Rp 48,000

Item B Return:
Subtotal:         Rp 50,000
Diskon Item:    - Rp      0
Diskon Total:   - Rp    500 (bagian dari diskon total Rp 2,000)
PPN Item:       + Rp      0
PPN Total:      + Rp      0
─────────────────────────
Total Item B:     Rp 49,500
```

#### Grand Total Return:
```
Subtotal All:      Rp 100,000 (50,000 + 50,000)
Diskon Item All: - Rp   1,500 (1,500 + 0)
Diskon Total:    - Rp   1,000 (500 + 500)
PPN Item All:    + Rp       0
PPN Total:       + Rp       0
────────────────────────────
GRAND TOTAL:       Rp  97,500

Verifikasi:
48,000 + 49,500 = 97,500 ✅ BENAR!
```

### Penjelasan:
1. **Diskon per item** dihitung dari subtotal item tersebut (jika PERCENTAGE) atau proporsional dari receiving (jika AMOUNT)
2. **Diskon total** dari receiving (Rp 2,000) dibagi proporsional:
   - Pertama hitung berapa yang harus di-return: 2,000 × (100,000/200,000) = 1,000
   - Lalu bagi ke setiap item berdasarkan proporsi subtotal: 
     - Item A dapat: 1,000 × (50,000/100,000) = 500
     - Item B dapat: 1,000 × (50,000/100,000) = 500
3. Total akhir per item = Subtotal - Diskon Item - Diskon Total + PPN Item + PPN Total
```

## 🎯 Fitur Detail Page

### Item Card:
```
┌─────────────────────────────────────┐
│ Nama Produk                         │
├─────────────────────────────────────┤
│ Qty Diterima: 100 → Qty Return: 30 │
│ Harga: Rp 10,000                    │
├─────────────────────────────────────┤
│ ┌─ Perhitungan ─────────────────┐  │
│ │ Subtotal:    Rp 300,000       │  │
│ │ Diskon (10%): - Rp 30,000     │  │ <- Merah
│ │ PPN (11%):   + Rp 29,700      │  │ <- Hijau
│ │ ──────────────────────────     │  │
│ │ Total:       Rp 299,700       │  │ <- Bold, Orange
│ └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Summary Card:
```
┌─────────────────────────────────────┐
│ Subtotal:         Rp 300,000        │
│ Diskon Item:    - Rp  30,000        │ <- jika ada
│ Diskon Total:   - Rp  15,000        │ <- jika ada
│ PPN Item:       + Rp  29,700        │ <- jika ada
│ PPN Total:      + Rp   6,000        │ <- jika ada
│ ─────────────────────────────────   │
│ TOTAL:            Rp 290,700        │ <- Bold
└─────────────────────────────────────┘
```

## 🖨️ PDF Print Layout

### Tabel Items:
| No | Nama Barang | Qty Diterima | Qty Return | Harga | Diskon | PPN | Total |
|----|-------------|--------------|------------|-------|--------|-----|-------|
| 1  | Item A      | 100          | 30         | 10,000| 30,000 | 29,700 | 299,700 |

### Summary PDF:
```
Subtotal:         Rp   300,000
Diskon Item:      Rp    30,000 (-)
Diskon Total:     Rp    15,000 (-)
Pajak Item:       Rp    29,700 (+)
Pajak Total:      Rp     6,000 (+)
────────────────────────────────
TOTAL:            Rp   290,700
```

## 📝 Kode Implementasi

### Helper Methods di Detail Page:

```dart
double _calculateItemDiscount(PurchaseReturnItem item) {
  if (item.discountType == 'PERCENTAGE') {
    return item.subtotal * (item.discount / 100);
  }
  return item.discount;
}

double _calculateItemTax(PurchaseReturnItem item) {
  final afterDiscount = item.subtotal - _calculateItemDiscount(item);
  if (item.taxType == 'PERCENTAGE') {
    return afterDiscount * (item.tax / 100);
  }
  return item.tax;
}
```

### Perhitungan di Return Form:

```dart
// Step 1: Calculate item-level discount and tax
final returnItemsTemp = <Map<String, dynamic>>[];
double subtotalAll = 0;

for (var item in receiving.items) {
  final returnQty = _returnQuantities[item.id] ?? 0;
  if (returnQty > 0) {
    final proportion = returnQty / item.receivedQuantity;
    final itemSubtotal = returnQty * item.receivedPrice;
    
    // Calculate item discount
    double itemDiscountAmount = 0;
    if (item.discountType == 'PERCENTAGE') {
      itemDiscountAmount = itemSubtotal * (item.discount / 100);
    } else {
      itemDiscountAmount = item.discount * proportion;
    }
    
    // Calculate item tax
    final afterItemDiscount = itemSubtotal - itemDiscountAmount;
    double itemTaxAmount = 0;
    if (item.taxType == 'PERCENTAGE') {
      itemTaxAmount = afterItemDiscount * (item.tax / 100);
    } else {
      itemTaxAmount = item.tax * proportion;
    }

    returnItemsTemp.add({
      'receivingItem': item,
      'returnQty': returnQty,
      'itemSubtotal': itemSubtotal,
      'itemDiscountAmount': itemDiscountAmount,
      'itemTaxAmount': itemTaxAmount,
    });

    subtotalAll += itemSubtotal;
  }
}

// Step 2: Calculate total discount and tax to distribute
final receivingSubtotalAll = receiving.items.fold<double>(
  0, (sum, item) => sum + (item.receivedQuantity * item.receivedPrice),
);

final totalDiscountToDistribute = receiving.totalDiscount * (subtotalAll / receivingSubtotalAll);
final totalTaxToDistribute = receiving.totalTax * (subtotalAll / receivingSubtotalAll);

// Step 3: Distribute total discount and tax proportionally
for (var tempItem in returnItemsTemp) {
  final itemSubtotal = tempItem['itemSubtotal'] as double;
  final itemDiscountAmount = tempItem['itemDiscountAmount'] as double;
  final itemTaxAmount = tempItem['itemTaxAmount'] as double;
  
  // Calculate item proportion
  final itemProportion = subtotalAll > 0 ? (itemSubtotal / subtotalAll) : 0;
  final itemTotalDiscount = totalDiscountToDistribute * itemProportion;
  final itemTotalTax = totalTaxToDistribute * itemProportion;
  
  // Calculate final total (subtotal - item discount - total discount + item tax + total tax)
  final itemTotal = itemSubtotal - itemDiscountAmount - itemTotalDiscount + itemTaxAmount + itemTotalTax;
  
  // Create return item with calculated values
  returnItems.add(PurchaseReturnItem(
    // ... other fields
    discount: itemDiscountAmount,
    discountType: item.discountType,
    tax: itemTaxAmount,
    taxType: item.taxType,
    subtotal: itemSubtotal,
    total: itemTotal,
  ));
}
```

## ✅ Checklist Update

- ✅ Database schema `purchase_return_items` support diskon & PPN
- ✅ Entity `PurchaseReturnItem` support semua field diskon & PPN
- ✅ Model `PurchaseReturnItemModel` support toJson/fromJson
- ✅ Form return mengambil data dari receiving dengan perhitungan proporsional
- ✅ Detail page menampilkan diskon & PPN per item dengan box detail
- ✅ Helper methods untuk kalkulasi diskon & PPN
- ✅ PDF print menampilkan kolom diskon & PPN
- ✅ Summary lengkap dengan semua perhitungan

## 🔄 Integrasi dengan Receiving

### Flow Data:
```
Receiving Item (Source)
  ↓
  - discount (value)
  - discount_type (AMOUNT/PERCENTAGE)
  - tax (value)
  - tax_type (AMOUNT/PERCENTAGE)
  ↓
Return Form (Calculation)
  ↓
  - Proporsi berdasarkan quantity
  - Perhitungan discount & tax
  ↓
Return Item (Result)
  ↓
  - Nilai discount & tax proporsional
  - Tipe discount & tax dipertahankan
  ↓
Detail & Print (Display)
```

## 📁 File yang Dimodifikasi

1. ✅ `purchase_return_detail_page.dart`
   - Tambah helper methods `_calculateItemDiscount()` & `_calculateItemTax()`
   - Update item card dengan box detail perhitungan
   - Update PDF table dengan kolom Diskon & PPN
   - Tambah method `_buildItemDetailRow()`

2. ✅ Entity, Model, Database Schema
   - Sudah ada sebelumnya (tidak perlu diubah)
   - Semua field sudah support diskon & PPN

3. ✅ `purchase_return_form_page.dart`
   - Sudah implementasi perhitungan proporsional
   - Mengambil data dari receiving item

## 🎨 UI/UX Features

1. **Box Detail Per Item**: Container dengan border menampilkan perhitungan lengkap
2. **Color Coding**:
   - Merah untuk diskon (pengurangan)
   - Hijau untuk PPN (penambahan)
   - Orange untuk total
3. **Keterangan Tipe**: Menampilkan "(10%)" atau "(Rp)" di label
4. **Conditional Display**: Hanya tampilkan diskon/PPN jika > 0

## 🚀 Keuntungan Fitur

1. **Akurat**: Perhitungan proporsional memastikan nilai yang tepat
2. **Transparan**: User bisa melihat detail perhitungan per item
3. **Konsisten**: Data diskon & PPN dari receiving dipertahankan
4. **Professional**: Print PDF dengan format yang rapi
5. **Traceability**: Semua perhitungan bisa di-trace dari receiving

---

**Dibuat**: Oktober 17, 2025  
**Versi**: 1.0  
**Status**: ✅ Completed  
**Related**: `RECEIVING_DISCOUNT_TAX_FEATURES.md`
