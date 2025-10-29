# 🎓 User Guide - Aplikasi POS Kasir

Panduan lengkap penggunaan aplikasi POS Kasir untuk kasir toko.

## 📱 Tampilan Utama

Aplikasi menggunakan mode **landscape** (horizontal) dengan 2 bagian:
- **Kiri**: Daftar produk & pencarian
- **Kanan**: Keranjang belanja & pembayaran

## 🔐 1. Login

### Langkah-langkah:
1. Masukkan **Username** kasir Anda
2. Masukkan **Password**
3. Klik tombol **LOGIN**

### Tips:
- Pastikan Caps Lock tidak aktif
- Username tidak case-sensitive
- Password case-sensitive

---

## 🛒 2. Memulai Transaksi

### Menambah Produk ke Keranjang

#### Cara 1: Klik Produk
1. Lihat daftar produk di sebelah kiri
2. Klik **card produk** yang ingin dibeli
3. Produk otomatis masuk ke keranjang

#### Cara 2: Cari Produk
1. Ketik nama produk di **search bar**
2. Hasil pencarian akan muncul otomatis
3. Klik produk yang dicari

#### Cara 3: Scan Barcode (Coming Soon)
1. Klik tombol **SCAN**
2. Arahkan camera ke barcode
3. Produk otomatis masuk keranjang

### Informasi Produk
Setiap card produk menampilkan:
- **Gambar** produk (atau icon placeholder)
- **Nama** produk
- **Harga** satuan
- **Stok** tersedia

---

## 🧮 3. Mengelola Keranjang

### Melihat Keranjang
Di sebelah kanan layar, Anda akan melihat:
- Daftar produk yang dipilih
- Quantity setiap item
- Harga per item
- Subtotal per item

### Mengubah Quantity

#### Menambah Quantity:
- Klik tombol **+** (hijau) di samping item

#### Mengurangi Quantity:
- Klik tombol **-** (merah) di samping item
- Jika quantity = 0, item akan dihapus otomatis

### Menghapus Item
- Kurangi quantity sampai 0, atau
- Klik tombol hapus (jika ada)

---

## 💰 4. Pembayaran

### Melihat Total

Di bagian bawah keranjang, Anda akan melihat:
```
Subtotal:  Rp 50.000
Diskon:    Rp  5.000
─────────────────────
TOTAL:     Rp 45.000
```

### Proses Pembayaran

1. **Pastikan semua item sudah benar**
   - Check nama produk
   - Check quantity
   - Check harga

2. **Klik tombol BAYAR** (hijau besar)

3. **Input Jumlah Bayar**
   - Masukkan nominal uang dari customer
   - Contoh: 50000 (tanpa titik atau koma)

4. **Klik PROSES**

### Hasil Pembayaran

Akan muncul popup:
```
✅ Pembayaran Berhasil!

Invoice: INV-20251029-143052
Total:     Rp 45.000
Bayar:     Rp 50.000
Kembalian: Rp  5.000
```

5. **Berikan kembalian** ke customer

6. **Klik OK** untuk transaksi baru

---

## 🎯 5. Tips & Trik

### ⚡ Transaksi Cepat

#### Keyboard Shortcuts:
- `Enter` - Proses pembayaran
- `Esc` - Batal/Clear cart
- `F1` - Search produk
- `F5` - Refresh data

#### Best Practices:
1. **Scan barcode** untuk produk populer (lebih cepat)
2. **Gunakan search** untuk produk jarang
3. **Double-check** quantity sebelum bayar
4. **Konfirmasi total** dengan customer

### 🔍 Pencarian Efektif

Anda bisa cari produk dengan:
- **Nama**: "indomie", "aqua", "beras"
- **Barcode**: "1000001", "1000002"
- **Kategori**: "makanan", "minuman", "snack"

Tips:
- Ketik minimal 3 huruf
- Pencarian tidak case-sensitive
- Hasil muncul real-time

### 💡 Handling Error

#### Jika produk tidak ditemukan:
1. Check spelling
2. Coba cari dengan barcode
3. Tanya supervisor

#### Jika stok habis:
- Produk dengan stok = 0 tidak bisa ditambahkan
- Icon atau warna akan berbeda
- Tawarkan produk alternatif

#### Jika sistem error:
1. Catat transaksi manual
2. Lapor ke supervisor
3. Restart aplikasi jika perlu

---

## 📊 6. Fitur Lanjutan

### Diskon Per Item (Coming Soon)
1. Long-press item di keranjang
2. Masukkan % diskon
3. Klik Apply

### Diskon Global (Coming Soon)
1. Klik tombol "Diskon"
2. Masukkan % diskon
3. Diskon berlaku untuk semua item

### Multiple Payment (Coming Soon)
- Cash + Card
- Cash + QRIS
- Split payment

---

## 🔴 7. Mode Offline

### Indikator Offline
Di pojok kanan atas ada badge:
- 🟢 **Online** - Terhubung ke server
- 🟠 **Offline** - Tidak ada koneksi

### Apa yang Bisa Dilakukan Offline?
✅ Semua transaksi normal
✅ Lihat produk (cache)
✅ Proses pembayaran
✅ Simpan transaksi

### Apa yang Tidak Bisa?
❌ Update produk baru
❌ Update harga real-time
❌ Sync transaksi ke server

### Saat Koneksi Kembali
Sistem akan otomatis:
1. Upload transaksi yang pending
2. Download produk & harga terbaru
3. Sync stok

**Anda tidak perlu melakukan apa-apa!**

---

## 🚨 8. Error Messages & Solutions

### "Stok tidak cukup"
**Penyebab:** Quantity melebihi stok tersedia
**Solusi:** Kurangi quantity atau batalkan item

### "Jumlah bayar kurang"
**Penyebab:** Uang customer kurang dari total
**Solusi:** Minta tambahan uang atau kurangi items

### "Gagal memproses pembayaran"
**Penyebab:** Error sistem
**Solusi:** 
1. Coba lagi
2. Restart aplikasi
3. Lapor supervisor

### "Produk tidak ditemukan"
**Penyebab:** Produk belum ada di database
**Solusi:** Update data atau tambah manual

---

## 📞 9. Bantuan & Support

### Butuh Bantuan?
1. **Supervisor** - Untuk masalah operasional
2. **IT Support** - Untuk masalah teknis
3. **Manager** - Untuk approval khusus

### Laporan Masalah
Catat informasi:
- Waktu kejadian
- Screenshot error (jika ada)
- Langkah yang dilakukan
- Produk/transaksi terkait

---

## ✅ 10. Checklist Harian

### Saat Buka Toko (Pagi)
- [ ] Login aplikasi
- [ ] Check status online/offline
- [ ] Pastikan data produk ter-update
- [ ] Test scan barcode
- [ ] Check printer (jika ada)

### Selama Operasional
- [ ] Monitor stok produk
- [ ] Check status sync (jika offline)
- [ ] Lapor transaksi bermasalah

### Saat Tutup Toko (Malam)
- [ ] Pastikan semua transaksi ter-sync
- [ ] Check pending transactions
- [ ] Logout aplikasi
- [ ] Shutdown sistem

---

## 🎓 Training Checklist

Kasir baru harus bisa:
- [ ] Login/Logout
- [ ] Cari produk (search)
- [ ] Tambah produk ke cart
- [ ] Update quantity
- [ ] Proses pembayaran
- [ ] Hitung kembalian
- [ ] Handle mode offline
- [ ] Lapor error

**Estimasi waktu training: 30-60 menit**

---

## 📝 FAQ (Frequently Asked Questions)

**Q: Bagaimana jika lupa password?**
A: Hubungi supervisor untuk reset password

**Q: Apakah transaksi aman saat offline?**
A: Ya, semua transaksi tersimpan lokal dan akan di-sync otomatis

**Q: Berapa lama data offline tersimpan?**
A: Permanent, sampai ter-sync atau di-clear manual

**Q: Bisa cancel transaksi yang sudah selesai?**
A: Tidak bisa di aplikasi kasir, harus melalui management app

**Q: Maksimal berapa item dalam 1 transaksi?**
A: Tidak ada limit, tapi disarankan < 100 item untuk performance

**Q: Apakah bisa print struk?**
A: Ya, fitur print akan tersedia di versi berikutnya

---

**Selamat bekerja! 🎉**

Jika ada pertanyaan, jangan ragu untuk bertanya kepada supervisor atau tim IT.
