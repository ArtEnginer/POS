# Fitur Diskon & PPN pada Receiving

## 📋 Overview

Receiving form telah disesuaikan untuk mendukung **diskon per barang** dan **PPN per barang**, mirip dengan sistem nota penjualan. Fitur ini memberikan fleksibilitas dalam mencatat penerimaan barang dengan perhitungan yang akurat.

## ✨ Fitur yang Tersedia

### 1. **Diskon Per Barang**
- ✅ Input diskon untuk setiap item yang diterima
- ✅ Pilihan tipe diskon: **Rupiah (AMOUNT)** atau **Persentase (PERCENTAGE)**
- ✅ Radio button untuk memilih tipe diskon
- ✅ Perhitungan otomatis berdasarkan tipe yang dipilih

### 2. **PPN Per Barang**
- ✅ Input PPN untuk setiap item yang diterima
- ✅ Pilihan tipe PPN: **Rupiah (AMOUNT)** atau **Persentase (PERCENTAGE)**
- ✅ Radio button untuk memilih tipe PPN
- ✅ Perhitungan otomatis berdasarkan tipe yang dipilih

### 3. **Diskon Total & PPN Total**
- ✅ Diskon untuk keseluruhan receiving (selain diskon per item)
- ✅ PPN untuk keseluruhan receiving (selain PPN per item)
- ✅ Input dalam bentuk Rupiah

### 4. **Summary Per Item**
- ✅ Subtotal (quantity × harga)
- ✅ Diskon item (ditampilkan jika ada)
- ✅ PPN item (ditampilkan jika ada)
- ✅ Total per item (subtotal - diskon + PPN)

### 5. **Ringkasan Total**
- ✅ Subtotal semua item
- ✅ Total diskon item
- ✅ Total PPN item
- ✅ Diskon total
- ✅ PPN total
- ✅ **Grand Total** (final amount)

## 🧮 Cara Perhitungan

### Perhitungan Per Item:

```
Subtotal Item = Qty × Harga

Jika diskon tipe PERCENTAGE:
  Diskon Item = Subtotal × (Diskon% / 100)
Jika diskon tipe AMOUNT:
  Diskon Item = Diskon Rp

Setelah Diskon = Subtotal - Diskon Item

Jika PPN tipe PERCENTAGE:
  PPN Item = Setelah Diskon × (PPN% / 100)
Jika PPN tipe AMOUNT:
  PPN Item = PPN Rp

Total Item = Subtotal - Diskon Item + PPN Item
```

### Perhitungan Total Keseluruhan:

```
Subtotal = Σ(Subtotal Item)
Total Diskon Item = Σ(Diskon Item)
Total PPN Item = Σ(PPN Item)

Grand Total = Subtotal - Total Diskon Item - Diskon Total + Total PPN Item + PPN Total
```

## 📊 Struktur Database

### Table: `receiving_items`

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `discount` | REAL | Nilai diskon (dalam Rp atau %) |
| `discount_type` | TEXT | Tipe diskon: 'AMOUNT' atau 'PERCENTAGE' |
| `tax` | REAL | Nilai PPN (dalam Rp atau %) |
| `tax_type` | TEXT | Tipe PPN: 'AMOUNT' atau 'PERCENTAGE' |
| `subtotal` | REAL | Quantity × Harga |
| `total` | REAL | Subtotal - Diskon + PPN |

### Table: `receivings`

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `subtotal` | REAL | Total dari semua subtotal item |
| `item_discount` | REAL | Total diskon dari semua item |
| `item_tax` | REAL | Total PPN dari semua item |
| `total_discount` | REAL | Diskon untuk keseluruhan receiving |
| `total_tax` | REAL | PPN untuk keseluruhan receiving |
| `total` | REAL | Grand total setelah semua perhitungan |

## 🎯 Penggunaan di Form Receiving

### Input Per Item:

1. **Quantity & Harga**: Input jumlah barang yang diterima dan harga
2. **Diskon**: 
   - Masukkan nilai diskon
   - Pilih tipe: Rp atau %
   - Perhitungan otomatis
3. **PPN**: 
   - Masukkan nilai PPN
   - Pilih tipe: Rp atau %
   - Perhitungan otomatis
4. **Lihat Summary**: Box menampilkan perhitungan detail per item

### Input Total:

1. **Diskon Total**: Diskon tambahan untuk keseluruhan (opsional)
2. **PPN Total**: PPN tambahan untuk keseluruhan (opsional)
3. **Catatan**: Catatan penerimaan barang

### Summary Akhir:

Box biru menampilkan:
- Subtotal
- Diskon item (jika ada)
- PPN item (jika ada)
- Diskon total (jika ada)
- PPN total (jika ada)
- **GRAND TOTAL**

## 📄 Detail Receiving Page

Halaman detail menampilkan:

### Per Item:
- Nama produk
- Qty PO vs Qty Terima
- Harga
- **Box perhitungan**:
  - Subtotal
  - Diskon (jika ada) - dengan keterangan tipe
  - PPN (jika ada) - dengan keterangan tipe
  - Total item

### Summary Card:
- Subtotal
- Diskon item (jika ada)
- Diskon total (jika ada)
- PPN item (jika ada)
- PPN total (jika ada)
- **TOTAL AKHIR** (bold, besar)

## 🖨️ Print PDF

PDF cetak menampilkan:

### Tabel Items dengan kolom:
1. No
2. Produk
3. Qty PO
4. Qty Terima
5. Harga
6. **Diskon** (menampilkan nilai Rp atau -)
7. **PPN** (menampilkan nilai Rp atau -)
8. **Total**

### Summary:
- Subtotal
- Diskon Item (jika ada)
- Diskon Total (jika ada)
- Pajak Item (jika ada)
- Pajak Total (jika ada)
- **TOTAL** (bold)

## 🔄 Integrasi dengan Return

Purchase Return Form sudah otomatis mengambil data diskon dan PPN dari receiving item:

### Perhitungan Proporsional:

```
Proporsi = Return Qty / Received Qty

Diskon Return = Diskon Item × Proporsi
PPN Return = PPN Item × Proporsi

Total Return Item = (Return Qty × Harga) - Diskon Return + PPN Return
```

### Total Return:

```
Subtotal Return = Σ(Subtotal Return Item)
Total Diskon Item Return = Σ(Diskon Return Item)
Total PPN Item Return = Σ(PPN Return Item)

Proporsi Total = Subtotal Return / Total Receiving
Diskon Total Return = Diskon Total Receiving × Proporsi Total
PPN Total Return = PPN Total Receiving × Proporsi Total

Grand Total Return = Subtotal Return - Total Diskon Item - Diskon Total + Total PPN Item + PPN Total
```

## ✅ Checklist Fitur

- ✅ Entity `Receiving` & `ReceivingItem` support diskon & PPN
- ✅ Database schema `receiving_items` memiliki kolom discount, tax, dll
- ✅ Model `ReceivingModel` & `ReceivingItemModel` support semua field
- ✅ Form receiving support input diskon & PPN per item
- ✅ Form receiving support input diskon & PPN total
- ✅ Detail page menampilkan semua informasi diskon & PPN
- ✅ PDF print menampilkan kolom diskon & PPN
- ✅ Purchase return support diskon & PPN dengan perhitungan proporsional
- ✅ Data source menyimpan & membaca semua field dengan benar

## 📝 Catatan Penting

1. **Default Values**: 
   - Diskon default: 0
   - PPN default: 0
   - Tipe default: 'AMOUNT'

2. **Validasi**:
   - Quantity harus > 0
   - Harga harus > 0
   - Diskon dan PPN boleh 0 (opsional)

3. **Perhitungan**:
   - Diskon dihitung dari subtotal
   - PPN dihitung dari (subtotal - diskon)
   - Total = subtotal - diskon + PPN

4. **Integrasi**:
   - Stock diupdate berdasarkan received_quantity
   - Purchase status berubah menjadi 'RECEIVED'
   - Semua data disimpan dalam database lokal

## 🎨 UI/UX Features

1. **Radio Buttons**: Untuk memilih tipe Rp atau %
2. **Auto-calculation**: Perhitungan otomatis saat input berubah
3. **Summary Box**: Box khusus menampilkan detail perhitungan
4. **Color Coding**: 
   - Merah untuk diskon (pengurangan)
   - Hijau untuk PPN (penambahan)
   - Biru untuk total

5. **Responsive**: Form responsif dengan layout yang rapi

---

**Dibuat**: Oktober 17, 2025  
**Versi**: 1.0  
**Status**: ✅ Completed
