# 🚀 Quick Guide - Form Penerimaan Barang Baru

## Cara Menggunakan Form Penerimaan yang Baru

### 📌 Akses Form
1. Buka **Daftar Purchase Order**
2. Pilih PO yang ingin diproses
3. Klik tombol **"Terima Barang"** atau **Edit** untuk receiving yang sudah ada

### 🔵 Tab 1: INFORMASI

#### Step 1: Review Detail PO
Cek informasi PO (tidak bisa diedit):
- ✅ Nomor PO
- ✅ Supplier
- ✅ Tanggal PO
- ✅ Status

#### Step 2: Input Detail Penerimaan ⭐
**WAJIB:**
- 📝 **Nomor Faktur** (sesuai nota dari supplier) ⚠️ REQUIRED

**Opsional:**
- 📄 Nomor Surat Jalan
- 🚗 Nomor Kendaraan (plat nomor)
- 👤 Nama Sopir

#### Step 3: Diskon & Pajak Total (Opsional)
Jika ada diskon/pajak untuk **SELURUH RECEIVING**:
- 💰 Diskon Total (Rp)
- 📊 PPN Total (Rp)
- 📝 Catatan Penerimaan

### 🟢 Tab 2: BARANG

#### Daftar Barang dari PO
Setiap item PO sudah ditampilkan otomatis:

**Yang Bisa Diubah:**
1. **Qty Diterima** *(default: sesuai PO)*
   - Ubah jika jumlah barang diterima berbeda
   - Harus > 0

2. **Harga Terima** *(default: harga PO)*
   - Ubah jika harga berubah saat terima
   - Harus > 0

3. **Diskon Item** (per item)
   - Pilih tipe: Rp atau %
   - Masukkan nilai diskon

4. **PPN Item** (per item)
   - Pilih tipe: Rp atau %
   - Masukkan nilai PPN

**Perhitungan Otomatis:**
Box abu-abu di bawah setiap item menampilkan:
- Subtotal
- Diskon (-) warna merah
- PPN (+) warna hijau
- **Total Item** (bold biru)

#### Tambah Barang Baru 🆕
Untuk barang yang **TIDAK ADA di PO** tapi ikut dikirim:

1. Klik tombol **"Tambah Barang Baru (Tidak Ada di PO)"**
2. Dialog akan muncul:
   - **Cari Produk**: Ketik nama/PLU produk
   - **Pilih Produk**: Klik produk dari list
   - **Qty**: Masukkan jumlah barang
   - **Harga**: Masukkan harga beli
3. Klik **"Tambah ke Receiving"**

**Item tambahan** akan ditandai dengan:
- 🟨 Border KUNING
- 🏷️ Badge "TAMBAHAN"
- ✏️ Tombol EDIT (bisa ubah qty & harga)
- 🗑️ Tombol HAPUS (bisa dihapus)

### 💚 Bottom Bar (Selalu Terlihat)

**Ringkasan Total Receiving:**
```
Subtotal Barang:       Rp XXX
Total Diskon Item:    - Rp XXX  (merah)
Total PPN Item:       + Rp XXX  (hijau)
Diskon Total:         - Rp XXX
PPN Total:            + Rp XXX
─────────────────────────────
TOTAL:                 Rp XXX  (biru besar)
```

**Tombol Proses:**
- Klik **"Proses Penerimaan"** (hijau)
- Data akan disimpan
- Stok akan terupdate otomatis

## ⚠️ Validasi Wajib

Form tidak bisa diproses jika:
- ❌ Nomor Faktur kosong
- ❌ Ada Qty Diterima ≤ 0
- ❌ Ada Harga Terima ≤ 0

## 📊 Contoh Kasus Penggunaan

### Kasus 1: Receiving Normal
1. PO: 10 item A @ Rp 1.000
2. Terima: 10 item A @ Rp 1.000
3. Input nomor faktur: "INV-001"
4. Tidak ada perubahan qty/harga
5. Proses ✅

### Kasus 2: Qty Berbeda
1. PO: 10 item A @ Rp 1.000
2. Terima: **8** item A @ Rp 1.000 (kurang 2)
3. Input nomor faktur: "INV-002"
4. Ubah Qty Diterima dari 10 → **8**
5. Proses ✅

### Kasus 3: Harga Berubah
1. PO: 10 item A @ Rp 1.000
2. Terima: 10 item A @ **Rp 1.100** (naik)
3. Input nomor faktur: "INV-003"
4. Ubah Harga Terima dari 1.000 → **1.100**
5. Proses ✅

### Kasus 4: Ada Item Bonus
1. PO: 10 item A @ Rp 1.000
2. Terima: 10 item A + **5 item B (BONUS)**
3. Input nomor faktur: "INV-004"
4. Klik "Tambah Barang Baru"
5. Pilih item B, qty 5, harga 0 (atau harga bonus)
6. Item B akan muncul dengan **border kuning** + badge "TAMBAHAN"
7. Proses ✅

### Kasus 5: Ada Diskon & PPN
1. PO: 100 item A @ Rp 1.000 = Rp 100.000
2. Terima: 100 item A @ Rp 1.000
3. Input nomor faktur: "INV-005"
4. **Tab Informasi**:
   - Diskon Total: Rp 10.000 (diskon faktur)
   - PPN Total: Rp 9.900 (11% dari 90.000)
5. Total = 100.000 - 10.000 + 9.900 = **Rp 99.900**
6. Proses ✅

### Kasus 6: Diskon & PPN Per Item
1. PO: 10 item A @ Rp 1.000
2. Terima: 10 item A @ Rp 1.000
3. Input nomor faktur: "INV-006"
4. Pada item A:
   - Diskon: 10% (maka diskon = 10.000 × 10% = 1.000)
   - PPN: 11% (dari 9.000 = 990)
5. Total Item A = 10.000 - 1.000 + 990 = **9.990**
6. Proses ✅

## 🎯 Tips

### ✅ DO's
- ✅ Selalu input nomor faktur sesuai nota supplier
- ✅ Cek qty diterima sebelum proses
- ✅ Gunakan "Tambah Barang Baru" untuk item bonus/tambahan
- ✅ Input detail pengiriman (surat jalan, plat, sopir) untuk tracking
- ✅ Verifikasi total akhir sebelum proses

### ❌ DON'Ts
- ❌ Jangan lupa input nomor faktur (WAJIB)
- ❌ Jangan langsung proses tanpa cek qty
- ❌ Jangan hapus item PO (kecuali item tambahan)
- ❌ Jangan proses jika total tidak sesuai nota

## 🔍 Troubleshooting

### "Nomor faktur wajib diisi"
➡️ Kembali ke **Tab Informasi**, isi field Nomor Faktur

### "Harus > 0"
➡️ Cek qty atau harga, tidak boleh 0 atau negatif

### Item tambahan tidak bisa dihapus?
➡️ Hanya item dengan **border kuning** yang bisa dihapus
➡️ Item dari PO tidak bisa dihapus (hanya bisa set qty = 0 jika tidak terima)

### Perhitungan tidak sesuai?
1. Cek diskon per item vs diskon total
2. Cek PPN per item vs PPN total
3. Lihat ringkasan di bottom bar
4. Formula:
   ```
   Total = Subtotal Barang 
         - Total Diskon Item 
         + Total PPN Item 
         - Diskon Total 
         + PPN Total
   ```

## 📞 Support

Jika ada masalah atau bug, dokumentasikan:
1. Screenshot form saat error
2. Data yang diinput
3. Error message yang muncul
4. Step-by-step untuk reproduce error

---

**Version**: 2.0
**Last Updated**: 2024
**Status**: ✅ Production Ready
