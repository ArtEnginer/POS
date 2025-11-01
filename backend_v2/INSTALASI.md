# 📦 Panduan Instalasi Backend POS - SIMPLE & CEPAT

Panduan instalasi backend POS system di komputer baru dalam **5 menit**.

---

## ✅ Yang Harus Diinstall Dulu

### 1. Node.js (versi 20 LTS)
- Download: https://nodejs.org/
- Install dengan klik Next-Next sampai selesai
- Test di CMD: `node --version`

### 2. PostgreSQL (versi 16)
- Download: https://www.postgresql.org/download/
- Install dengan klik Next-Next
- **PENTING**: Catat password yang dimasukkan saat instalasi!
- Default port: 5432

### 3. Redis (untuk Windows)
- Download: https://github.com/microsoftarchive/redis/releases
- Download file: Redis-x64-3.0.504.msi
- Install dengan klik Next-Next

---

## 🚀 Cara Install Backend

### Step 1: Extract Project
```
Ekstrak folder backend_v2 ke lokasi yang diinginkan
Contoh: D:\Project\pos\backend_v2
```

### Step 2: Install Dependencies
Buka Command Prompt/PowerShell di folder backend_v2, lalu jalankan:
```bash
npm install
```

### Step 3: Setup Environment
```bash
# Copy file .env.example jadi .env
copy .env.example .env
```

Edit file `.env` dengan Notepad, sesuaikan:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pos_enterprise
DB_USER=postgres
DB_PASSWORD=password_postgresql_anda

# Redis Configuration  
REDIS_HOST=localhost
REDIS_PORT=6379

# Server Configuration
NODE_ENV=production
PORT=3001

# JWT Secret (bisa pakai random string apa saja)
JWT_SECRET=rahasia_super_kuat_12345
JWT_REFRESH_SECRET=rahasia_refresh_67890
```

### Step 4: Setup Database (PALING PENTING!)
Jalankan script setup otomatis:
```bash
node setup_database_complete.js
```

**Script ini akan:**
- ✅ Drop database lama (kalau ada)
- ✅ Buat database baru
- ✅ Buat semua table (20+ tables)
- ✅ Setup triggers dan views
- ✅ Insert data default:
  - User admin (username: `admin`, password: `admin123`)
  - Kantor Pusat (Head Office)
  - 10 satuan umum (PCS, KG, BOX, DUS, dll)

**Output yang benar:**
```
✅ Database setup completed successfully!
```

### Step 4.1: (OPSIONAL) Insert Sample Data untuk Testing
Jika ingin insert data contoh untuk testing:
```bash
node seed_database.js
```

**Script ini akan insert:**
- ✅ 4 cabang (HQ, Jakarta Pusat, Bandung, Surabaya)
- ✅ 5 user test (admin, manager, cashier1, cashier2, staff1)
- ✅ 8 kategori produk (Makanan, Elektronik, Pakaian, dll)
- ✅ 3 supplier
- ✅ 5 customer
- ✅ 20 produk contoh dengan stok di semua cabang
- ✅ 80 stock records (20 produk × 4 cabang)

**Output yang benar:**
```
✅ SEEDING COMPLETED!
```

**Test Users setelah seeding:**
- admin / admin123 (super_admin)
- manager / admin123 (manager)
- cashier1 / admin123 (cashier - Jakarta Pusat)
- cashier2 / admin123 (cashier - Bandung)
- staff1 / admin123 (staff - HQ)

### Step 5: Jalankan Server

**Mode Development (auto-reload):**
```bash
npm run dev
```

**Mode Production (recommended):**
```bash
npm run cluster
```

### Step 6: Test
Buka browser, akses:
```
http://localhost:3001/api/v2/health
```

Harusnya muncul:
```json
{
  "status": "ok",
  "timestamp": "..."
}
```

---

## 🔑 Login Pertama Kali

```
Username: admin
Password: admin123
```

**⚠️ SEGERA GANTI PASSWORD SETELAH LOGIN PERTAMA!**

---

## ❌ Troubleshooting

### Error: "Cannot connect to PostgreSQL"
**Solusi:**
1. Pastikan PostgreSQL service running (cek di Services Windows)
2. Cek username & password di file `.env`
3. Test koneksi: `psql -U postgres -d pos_enterprise`

### Error: "Cannot connect to Redis"
**Solusi:**
1. Pastikan Redis service running
2. Restart Redis service
3. Test koneksi: `redis-cli ping` (harusnya return "PONG")

### Error: "Port 3001 already in use"
**Solusi:**
1. Ganti PORT di file `.env` jadi 3002 atau lainnya
2. Atau matikan aplikasi yang pakai port 3001:
   ```bash
   netstat -ano | findstr :3001
   taskkill /F /PID [PID_NUMBER]
   ```

### Server tidak jalan
**Solusi:**
```bash
# Stop semua process
npm run stop

# Start ulang
npm run cluster
```

### Database error saat setup
**Solusi:**
```bash
# Drop manual via psql
psql -U postgres
DROP DATABASE IF EXISTS pos_enterprise;
\q

# Jalankan ulang setup
node setup_database_complete.js
```

---

## 📊 Struktur Database

Setelah setup, database punya:

### Tables (20+)
- `branches` - Data cabang
- `users` - User & authentication
- `products` - Master produk
- `product_units` - Multi satuan (PCS, BOX, DUS)
- `product_branch_prices` - Harga per cabang per satuan
- `product_stocks` - Stok per cabang
- `customers` - Data pelanggan
- `suppliers` - Data supplier
- `sales` - Transaksi penjualan
- `purchases` - Transaksi pembelian
- `stock_adjustments` - Adjustment stok
- Dan 10+ table lainnya...

### Contoh Multi-Unit
```
Produk: Coca Cola

Unit:
- PCS (base unit)
- BOX = 24 PCS
- DUS = 12 BOX = 288 PCS

Harga di Kantor Pusat:
- PCS: Rp 5.000
- BOX: Rp 110.000
- DUS: Rp 1.250.000

Harga di Cabang A:
- PCS: Rp 5.500
- BOX: Rp 120.000
- DUS: Rp 1.350.000
```

---

## 🎯 Next Steps

### 1. Ganti Password Admin
Login ke aplikasi, masuk ke Settings → Users → Edit admin → Ganti password

### 2. Tambah Cabang
Dashboard → Branches → Add New Branch

### 3. Tambah User
Dashboard → Users → Add New User → Pilih cabang yang diakses

### 4. Tambah Kategori Produk
Dashboard → Categories → Add Category

### 5. Tambah Produk dengan Multi-Unit
Dashboard → Products → Add Product
- Tab 1: Info dasar (nama, kategori, barcode)
- Tab 2: Units (tambah satuan: PCS, BOX, DUS, dll)
- Tab 3: Pricing (set harga per cabang per satuan)

---

## 📞 Kontak Support

Jika ada masalah:
1. Cek file log di folder `logs/`
2. Screenshot error message
3. Hubungi developer

---

## 🔄 Update Database

Jika ada update schema di masa depan, cukup:
```bash
# Backup dulu database lama
pg_dump -U postgres -F c pos_enterprise > backup.dump

# Jalankan ulang setup (data lama hilang!)
node setup_database_complete.js

# Atau restore backup kalau perlu
pg_restore -U postgres -d pos_enterprise backup.dump
```

---

**Good Luck! 🚀**

File ini dibuat untuk memudahkan instalasi di komputer lain tanpa ribet.
Satu command setup database, langsung jadi semua table dan data default!
