# 🧪 Quick Testing Checklist

## ⚙️ Setup (Lakukan Sekali)

```bash
# 1. Start Backend
cd d:\PROYEK\POS\backend_v2
npm start

# 2. Start POS Cashier
cd d:\PROYEK\POS\pos_cashier
flutter run -d windows
```

---

## ✅ Test Scenario

### 1️⃣ Login & Initial Sync

- [ ] App terbuka di halaman login
- [ ] Masukkan username: `admin`, password: (sesuai database)
- [ ] Klik "Login"
- [ ] ✅ **Berhasil**: Masuk ke halaman kasir, produk loading

**Log yang diharapkan:**

```
✅ Login success: admin
🔄 Starting initial sync...
✅ Products synced: 15 items
```

---

### 2️⃣ Tampilan Produk

- [ ] Produk muncul di grid (kiri)
- [ ] AppBar menampilkan jumlah produk (misal: "15 Produk")
- [ ] Badge "Online" berwarna hijau
- [ ] Foto produk tampil (jika ada URL)

**Cek:** Jumlah produk di app = jumlah di database

---

### 3️⃣ Pencarian Produk

- [ ] Ketik nama produk di search box
- [ ] Produk terfilter secara real-time
- [ ] Hapus teks → semua produk muncul lagi

---

### 4️⃣ Tambah ke Keranjang

- [ ] Klik produk "Aqua 600ml"
- [ ] ✅ Muncul di keranjang kanan dengan qty 1
- [ ] Klik lagi → qty bertambah menjadi 2
- [ ] Klik produk lain → keranjang punya 2 item

**Cart total:** Harga produk × qty

---

### 5️⃣ Transaksi Online

- [ ] Tambahkan 2-3 produk ke keranjang
- [ ] Total: Rp 50.000
- [ ] Masukkan bayar: Rp 100.000
- [ ] Klik "Bayar"
- [ ] ✅ Dialog receipt muncul
- [ ] Klik "OK" → keranjang kosong

**Cek Database:**

```sql
SELECT * FROM sales ORDER BY created_at DESC LIMIT 1;
-- Should show the new sale
```

**Log yang diharapkan:**

```
💾 Sale saved locally: sale_xxxxx
✅ Sale synced to server: ID 123
```

---

### 6️⃣ Mode Offline

- [ ] **Putuskan koneksi internet** (WiFi off / unplug LAN)
- [ ] Badge berubah jadi "Offline" (orange)
- [ ] Tambahkan produk ke keranjang
- [ ] Bayar transaksi
- [ ] ✅ Transaksi tersimpan lokal
- [ ] Badge "Offline" muncul angka (misal: "1")

**Log yang diharapkan:**

```
🔌 Connection lost - switching to offline mode
💾 Sale saved locally: sale_xxxxx (pending sync)
```

---

### 7️⃣ Auto Sync Setelah Online

- [ ] **Sambungkan internet kembali**
- [ ] Tunggu 10-20 detik
- [ ] Badge berubah jadi "Online" (hijau)
- [ ] Angka badge hilang

**Log yang diharapkan:**

```
🌐 Connection restored - back online
🔄 Syncing pending sales...
✅ Sale synced to server: ID 124
```

**Cek Database:** Sale offline sekarang ada di database

---

### 8️⃣ Manual Refresh

- [ ] Klik tombol refresh (ikon ⟳) di AppBar
- [ ] Loading spinner muncul sebentar
- [ ] Produk reload

**Log:**

```
🔄 Manual refresh triggered
✅ Products synced: 15 items
```

---

### 9️⃣ Background Sync

- [ ] Biarkan app terbuka 5+ menit (online)
- [ ] **Tidak ada interaksi**
- [ ] Cek log setiap 5 menit

**Log yang diharapkan:**

```
🔄 Background sync triggered (interval)
✅ Products synced: 15 items
```

---

### 🔟 Logout

- [ ] Klik tombol logout
- [ ] Kembali ke halaman login
- [ ] Produk tidak terlihat

---

### 1️⃣1️⃣ Session Persistence

- [ ] Login berhasil
- [ ] **Tutup app** (Close window)
- [ ] **Buka app lagi**
- [ ] ✅ Langsung masuk ke halaman kasir (auto-login)

**Log:**

```
🔐 Session restored for user: admin
```

---

## 🐛 Troubleshooting

### ❌ "Produk tidak muncul"

**Solusi:**

1. Cek backend running: `http://localhost:3000/api/products`
2. Cek log error di console
3. Klik refresh manual

### ❌ "Login gagal"

**Solusi:**

1. Cek username/password di database
2. Test dengan Postman:
   ```json
   POST http://localhost:3000/api/auth/login
   {
     "username": "admin",
     "password": "your_password"
   }
   ```

### ❌ "Transaksi tidak sync"

**Solusi:**

1. Cek koneksi internet
2. Cek badge: jika "Offline" tunggu sampai "Online"
3. Klik refresh manual
4. Cek log `syncService._uploadPendingSales()`

---

## 📊 Expected Results Summary

| Test         | Expected Behavior      | Log Message                            |
| ------------ | ---------------------- | -------------------------------------- |
| Login        | Navigate to cashier    | `✅ Login success`                     |
| Product Load | Grid displays products | `✅ Products synced: X items`          |
| Add to Cart  | Qty increases          | (Silent)                               |
| Online Sale  | Saved + synced         | `✅ Sale synced to server`             |
| Offline Sale | Saved locally          | `💾 Sale saved locally (pending sync)` |
| Auto Sync    | Badge clears           | `✅ Sale synced to server`             |
| Logout       | Return to login        | `🔐 Logged out`                        |

---

## ✅ All Tests Passed?

Jika semua ✅, aplikasi siap untuk:

- 🎯 Deployment ke production
- 📱 Testing di device lain
- 🔧 Feature development lanjutan

**Tested by:** ******\_\_\_******  
**Date:** ******\_\_\_******  
**Backend Version:** V2  
**App Version:** 1.0.0
