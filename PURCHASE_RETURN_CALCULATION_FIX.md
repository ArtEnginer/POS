# Fix Perhitungan Return - Diskon Total Dibagi Per Item

## 🔧 Masalah yang Diperbaiki

### Masalah Sebelumnya:
Diskon total dan PPN total dari receiving **TIDAK** dibagi per item, hanya dikalikan dengan proporsi keseluruhan. Ini menyebabkan perhitungan tidak akurat.

**Contoh Masalah:**
```
Receiving:
- 10 barang, total Rp 200,000
- Diskon total: Rp 2,000

Return 5 barang (50%):
- Perhitungan LAMA (SALAH):
  Total Discount = Rp 2,000 × 0.5 = Rp 1,000
  (Tidak dibagi per item!)

- Masalah: Jika ada 2 item dengan harga berbeda, 
  pembagian diskon tidak proporsional per item
```

## ✅ Solusi yang Diterapkan

### Perhitungan BARU (BENAR):

**4 Langkah Perhitungan:**

#### Langkah 1: Hitung Diskon & PPN Per Item
```
Untuk setiap item yang di-return:
- Subtotal Item = Return Qty × Harga
- Diskon Item (dari receiving item)
- PPN Item (dari receiving item)
```

#### Langkah 2: Hitung Total Discount & Tax yang Harus Di-Return
```
Total Subtotal Return = Σ(Subtotal Item Return)
Total Subtotal Receiving = Σ(Subtotal Item Receiving)

Proporsi = Total Subtotal Return / Total Subtotal Receiving

Total Discount to Distribute = Diskon Total Receiving × Proporsi
Total Tax to Distribute = PPN Total Receiving × Proporsi
```

#### Langkah 3: Distribusi ke Setiap Item Berdasarkan Proporsi Subtotal
```
Untuk setiap item:
  Proporsi Item = Subtotal Item / Total Subtotal Return
  
  Diskon Total Item = Total Discount to Distribute × Proporsi Item
  PPN Total Item = Total Tax to Distribute × Proporsi Item
```

#### Langkah 4: Hitung Total Akhir
```
Total Item = Subtotal - Diskon Item - Diskon Total Item + PPN Item + PPN Total Item
```

## 📊 Contoh Perhitungan yang Benar

### Data Receiving:
```
Item A: 10 pcs × Rp 10,000 = Rp 100,000 (diskon item 3%)
Item B: 10 pcs × Rp 10,000 = Rp 100,000 (diskon item 0%)
─────────────────────────────────────────────────────
Subtotal:                      Rp 200,000
Diskon Item A (3%):          - Rp   3,000
Diskon Total:                - Rp   2,000  ← INI YANG HARUS DIBAGI!
─────────────────────────────────────────────────────
Grand Total:                   Rp 195,000
```

### Return: 5 pcs Item A dan 5 pcs Item B

#### Langkah 1: Diskon per Item
```
Item A:
- Subtotal: 5 × 10,000 = Rp 50,000
- Diskon Item: 50,000 × 3% = Rp 1,500

Item B:
- Subtotal: 5 × 10,000 = Rp 50,000
- Diskon Item: Rp 0
```

#### Langkah 2: Total Discount yang Harus Di-Return
```
Total Subtotal Return = Rp 100,000 (50,000 + 50,000)
Total Subtotal Receiving = Rp 200,000

Proporsi = 100,000 / 200,000 = 0.5

Total Discount to Distribute = Rp 2,000 × 0.5 = Rp 1,000
```

#### Langkah 3: Distribusi ke Setiap Item
```
Item A:
- Proporsi: 50,000 / 100,000 = 0.5
- Diskon Total Item A: 1,000 × 0.5 = Rp 500

Item B:
- Proporsi: 50,000 / 100,000 = 0.5
- Diskon Total Item B: 1,000 × 0.5 = Rp 500
```

#### Langkah 4: Total Akhir
```
Item A:
Subtotal:       Rp 50,000
Diskon Item:  - Rp  1,500
Diskon Total: - Rp    500  ← DIBAGI!
─────────────────────────
Total:          Rp 48,000

Item B:
Subtotal:       Rp 50,000
Diskon Item:  - Rp      0
Diskon Total: - Rp    500  ← DIBAGI!
─────────────────────────
Total:          Rp 49,500

Grand Total Return: Rp 97,500 ✅
(48,000 + 49,500 = 97,500)
```

## 🎯 Kenapa Cara Ini Benar?

### Prinsip:
**Diskon total harus didistribusikan proporsional ke setiap item berdasarkan kontribusi subtotal item tersebut.**

### Alasan:
1. **Adil**: Item dengan subtotal lebih besar mendapat bagian diskon total lebih besar
2. **Proporsional**: Pembagian sesuai dengan proporsi nilai item
3. **Akurat**: Total perhitungan selalu konsisten

### Contoh Ilustrasi:
```
Bayangkan diskon total Rp 1,000 untuk 2 item:

Item A: Rp 80,000 (80% dari total)
Item B: Rp 20,000 (20% dari total)

Diskon dibagi:
- Item A dapat: 1,000 × 80% = Rp 800 ✅
- Item B dapat: 1,000 × 20% = Rp 200 ✅

Bukan dibagi rata:
- Item A dapat: 1,000 / 2 = Rp 500 ❌ SALAH!
- Item B dapat: 1,000 / 2 = Rp 500 ❌ SALAH!
```

## 💻 Implementasi Kode

### File yang Diubah:
`lib/features/purchase/presentation/pages/purchase_return_form_page.dart`

### Perubahan Utama:

**SEBELUM (SALAH):**
```dart
// Hanya kalikan proporsi keseluruhan
final proportion = returnedItemsValue / totalItemsValue;
final totalDiscount = receiving.totalDiscount * proportion;
// Tidak dibagi per item!
```

**SESUDAH (BENAR):**
```dart
// 1. Hitung diskon & ppn per item
// 2. Hitung total discount & tax yang harus di-return
final totalDiscountToDistribute = receiving.totalDiscount * (subtotalAll / receivingSubtotalAll);

// 3. Distribusi ke setiap item
for (var tempItem in returnItemsTemp) {
  final itemProportion = itemSubtotal / subtotalAll;
  final itemTotalDiscount = totalDiscountToDistribute * itemProportion;
  final itemTotalTax = totalTaxToDistribute * itemProportion;
  
  // 4. Hitung total item
  final itemTotal = itemSubtotal - itemDiscountAmount - itemTotalDiscount + itemTaxAmount + itemTotalTax;
}
```

## ✅ Validasi

### Test Case:
```
Receiving:
- Item A: 10 × 10,000 = 100,000 (diskon 3%)
- Item B: 10 × 10,000 = 100,000 (diskon 0%)
- Subtotal: 200,000
- Diskon item: 3,000
- Diskon total: 2,000
- Grand Total: 195,000

Return 5 A + 5 B:
Expected: 97,500
Result: 97,500 ✅ BENAR!

Breakdown:
- Item A: 50,000 - 1,500 - 500 = 48,000 ✅
- Item B: 50,000 - 0 - 500 = 49,500 ✅
- Total: 48,000 + 49,500 = 97,500 ✅
```

## 📝 Kesimpulan

### Yang Diperbaiki:
✅ Diskon total dibagi proporsional per item  
✅ PPN total dibagi proporsional per item  
✅ Perhitungan akurat dan konsisten  
✅ Total return item selalu balance dengan grand total  

### Formula Kunci:
```
Diskon Total per Item = (Diskon Total Receiving × Proporsi Return) × (Subtotal Item / Total Subtotal Return)
```

---

**Tanggal Update**: Oktober 17, 2025  
**Status**: ✅ Fixed and Verified  
**File Modified**: `purchase_return_form_page.dart`
