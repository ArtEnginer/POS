# 🚀 DATABASE SETUP - QUICK START GUIDE

## ✨ Fitur Terbaru: DECIMAL QUANTITY SUPPORT

Database POS Enterprise sekarang mendukung **quantity dalam bentuk pecahan/desimal**!

Contoh: 
- 1.5 kg beras
- 2.75 liter minyak  
- 0.333 meter kain
- 12.50 botol

---

## 📋 PERSIAPAN

### 1. Pastikan PostgreSQL Running

```bash
# Check status PostgreSQL
pg_ctl status

# Jika belum running, start PostgreSQL
pg_ctl start
```

### 2. Buat Database (Jika Belum Ada)

```bash
# Login ke PostgreSQL
psql -U postgres

# Buat database
CREATE DATABASE pos_enterprise;

# Keluar
\q
```

### 3. Setup Environment Variables

Buat/edit file `.env` di folder `backend_v2`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pos_enterprise
DB_USER=postgres
DB_PASSWORD=admin123

PORT=3000
JWT_SECRET=your-secret-key-here
NODE_ENV=development
```

---

## 🔧 SETUP DATABASE

### Opsi 1: Setup Complete (RECOMMENDED) ⭐

**Script ini akan:**
- ✅ DROP semua table lama
- ✅ CREATE ulang semua table dengan schema terbaru
- ✅ Setup DECIMAL untuk quantity (mendukung pecahan)
- ✅ Insert data default (admin user, branch, dll)

```bash
cd backend_v2
node setup_database_complete.js
```

**Output:**
```
✅ Database setup completed!
📊 Total Tables: 20+ tables created
📐 DECIMAL QUANTITY COLUMNS: 15+ columns
👤 Username: admin | Password: admin123
```

### Opsi 2: Manual dengan SQL File

Jika ingin setup manual:

```bash
cd backend_v2
psql -U postgres -d pos_enterprise -f src/database/COMPLETE_SCHEMA.sql
```

---

## 🎯 SETELAH SETUP

### 1. Verifikasi Database

```bash
# Login ke database
psql -U postgres -d pos_enterprise

# Check tables
\dt

# Check quantity columns (harus DECIMAL)
SELECT table_name, column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE column_name LIKE '%quantity%' 
  AND table_schema = 'public'
ORDER BY table_name;

# Keluar
\q
```

### 2. Test Login

**Default Credentials:**
- Username: `admin`
- Password: `admin123`
- Role: `super_admin`

**Default Branch:**
- Code: `HQ`
- Name: `Head Office`

### 3. Start Backend Server

```bash
cd backend_v2
npm run dev
```

Server akan running di: `http://localhost:3000`

---

## 📊 STRUKTUR DATABASE

### Core Tables (20+ Tables)

| No | Table | Deskripsi | Quantity Support |
|----|-------|-----------|------------------|
| 1 | `branches` | Cabang/Branch | - |
| 2 | `users` | User & authentication | - |
| 3 | `user_branches` | User-Branch mapping | - |
| 4 | `categories` | Kategori produk | - |
| 5 | `products` | Master produk | min/max/reorder: **DECIMAL(15,3)** |
| 6 | `product_stocks` | Stok per branch | quantity: **DECIMAL(15,3)** |
| 7 | `customers` | Master customer | - |
| 8 | `suppliers` | Master supplier | - |
| 9 | `sales` | Transaksi penjualan | - |
| 10 | `sale_items` | Detail item penjualan | quantity: **DECIMAL(15,3)** ✅ |
| 11 | `purchases` | Purchase Order | - |
| 12 | `purchase_items` | Detail PO | quantity_ordered/received: **DECIMAL(15,3)** ✅ |
| 13 | `receivings` | Penerimaan barang | - |
| 14 | `receiving_items` | Detail penerimaan | po_quantity/received_quantity: **DECIMAL(15,3)** ✅ |
| 15 | `purchase_returns` | Retur pembelian | - |
| 16 | `purchase_return_items` | Detail retur | received/return_quantity: **DECIMAL(15,3)** ✅ |
| 17 | `stock_adjustments` | Penyesuaian stok | all quantities: **DECIMAL(15,3)** ✅ |
| 18 | `sync_logs` | Log sync data | - |
| 19 | `audit_logs` | Audit trail | - |

### Precision & Scale

```
DECIMAL(15, 3)
  ↓      ↓    ↓
  Type   Total Decimal
         Digits Places
         
Contoh: 999,999,999,999.999 (max value)
        1.5
        2.75
        0.333
```

---

## 🔄 RESET DATABASE

Jika perlu reset ulang database (HATI-HATI: DATA AKAN HILANG!):

```bash
cd backend_v2
node setup_database_complete.js
```

Script akan otomatis:
1. DROP semua table
2. DROP semua type
3. CREATE ulang semuanya
4. Insert default data

---

## 📱 UPDATE APLIKASI FLUTTER

Setelah database setup, **penting** untuk update aplikasi Flutter:

### 1. Update Entity & Models

```dart
// BEFORE (SALAH)
class PurchaseItem {
  final int quantityOrdered;
  final int quantityReceived;
}

// AFTER (BENAR)
class PurchaseItem {
  final double quantityOrdered;
  final double quantityReceived;
}
```

### 2. Update Parsing JSON

```dart
// BEFORE (SALAH)
quantityOrdered: json['quantity_ordered'] as int

// AFTER (BENAR)
quantityOrdered: (json['quantity_ordered'] as num).toDouble()
```

### 3. Update Form Validation

```dart
// BEFORE (SALAH)
final qty = int.tryParse(value);

// AFTER (BENAR)  
final qty = double.tryParse(value) ?? 0.0;
```

### 4. Update TextInputType

```dart
// BEFORE (SALAH)
TextFormField(
  keyboardType: TextInputType.number,
)

// AFTER (BENAR)
TextFormField(
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
  ],
)
```

Lihat dokumentasi lengkap di: **`QUANTITY_MIGRATION_GUIDE.md`**

---

## 🐛 TROUBLESHOOTING

### Error: Database does not exist

```bash
# Buat database dulu
psql -U postgres
CREATE DATABASE pos_enterprise;
\q
```

### Error: Permission denied

```bash
# Login sebagai superuser
psql -U postgres

# Grant permission
GRANT ALL PRIVILEGES ON DATABASE pos_enterprise TO postgres;
```

### Error: Extension not found

```bash
# Install extensions
psql -U postgres -d pos_enterprise
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

### Error: Port already in use

Edit `.env`, ganti `DB_PORT` atau `PORT`

---

## 📚 DOKUMENTASI LENGKAP

1. **COMPLETE_SCHEMA.sql** - Schema database lengkap
2. **QUANTITY_MIGRATION_GUIDE.md** - Panduan migration quantity
3. **setup_database_complete.js** - Setup script otomatis

---

## ✅ CHECKLIST SETUP

- [ ] PostgreSQL running
- [ ] Database `pos_enterprise` created
- [ ] File `.env` configured
- [ ] Run `node setup_database_complete.js`
- [ ] Verify tables created
- [ ] Test login dengan admin/admin123
- [ ] Start backend server
- [ ] Update Flutter models (int → double)
- [ ] Update form validators
- [ ] Test dengan quantity pecahan

---

## 🎉 SELAMAT!

Database POS Enterprise Anda sudah siap dengan fitur **DECIMAL QUANTITY**!

Sekarang sistem mendukung:
- ✅ Penjualan per kg, liter, meter
- ✅ Quantity pecahan (1.5, 2.75, 0.333)
- ✅ Perhitungan akurat dengan DECIMAL
- ✅ Multi-branch support
- ✅ Complete audit trail

**Happy coding! 🚀**
