# Database Seeder Guide

## 📦 Overview

File `seed_database.js` berisi data sample untuk testing dan development. Script ini akan mengisi database dengan data dummy yang siap pakai.

## 🎯 Data yang Di-insert

### 1. **Branches (4 cabang)**
- **HQ** - Head Office (Jakarta)
- **JKT-01** - Jakarta Pusat
- **BDG-01** - Bandung
- **SBY-01** - Surabaya

### 2. **Users (5 users)**
| Username | Password | Role | Branch |
|----------|----------|------|--------|
| admin | admin123 | super_admin | HQ (akses semua cabang) |
| manager | admin123 | manager | JKT-01 |
| cashier1 | admin123 | cashier | JKT-01 |
| cashier2 | admin123 | cashier | BDG-01 |
| staff1 | admin123 | staff | HQ |

### 3. **Categories (8 kategori)**
```
Makanan & Minuman
├── Makanan Ringan
└── Minuman

Elektronik
├── Handphone
└── Komputer

Pakaian

Alat Tulis
```

### 4. **Suppliers (3 suppliers)**
- PT Sumber Makmur (Jakarta) - Net 30
- CV Maju Jaya (Bandung) - Net 14
- UD Berkah Abadi (Surabaya) - Cash

### 5. **Customers (5 customers)**
- Budi Santoso (regular)
- Siti Nurhaliza (VIP)
- PT Sentosa Jaya (wholesale)
- Ahmad Wijaya (retail)
- Dewi Lestari (VIP)

### 6. **Products (20 products)**

#### Makanan & Minuman
- Indomie Goreng - Rp 3.000
- Aqua 600ml - Rp 3.000
- Beras Premium - Rp 15.000/kg
- Minyak Goreng - Rp 22.000/liter
- Gula Pasir - Rp 13.000/kg
- Chitato BBQ - Rp 7.000
- Coca Cola 390ml - Rp 6.000
- Kopi Sachet - Rp 2.000
- Teh Celup - Rp 1.500
- Sabun Mandi - Rp 5.000
- Shampoo Sachet - Rp 2.500

#### Alat Tulis
- Pulpen Standard - Rp 2.500
- Buku Tulis 58lbr - Rp 5.000
- Pensil 2B - Rp 2.000

#### Pakaian
- Kaos Polos Putih - Rp 45.000
- Celana Jeans - Rp 125.000

#### Elektronik
- Mouse USB - Rp 45.000
- Keyboard USB - Rp 85.000
- Kabel Data Type-C - Rp 25.000
- Tempered Glass - Rp 20.000

### 7. **Product Stocks**
- Setiap product di-assign ke **semua 4 branches**
- Stock quantity: **random antara min_stock dan max_stock**
- Total: **80 stock records** (20 products × 4 branches)

## 🚀 Cara Penggunaan

### Langkah 1: Setup Database (jika belum)
```bash
npm run db:setup
```

### Langkah 2: Jalankan Seeder
```bash
npm run db:seed
```

Atau langsung dengan node:
```bash
node seed_database.js
```

### Langkah 3: Verifikasi
```bash
# Login dengan salah satu user
POST http://localhost:5000/api/auth/login
{
  "username": "admin",
  "password": "admin123"
}
```

## 🔄 Re-run Seeder

Script ini menggunakan `ON CONFLICT DO UPDATE`, jadi **aman untuk dijalankan berulang kali**:

- Data yang sudah ada akan di-update
- Data baru akan di-insert
- Tidak ada duplicate error

## 📊 Output Example

```
╔══════════════════════════════════════════════════════════════════╗
║          POS ENTERPRISE - DATABASE SEEDER                        ║
║          Insert Sample Data for Testing                          ║
╚══════════════════════════════════════════════════════════════════╝

🏢 Seeding Branches...
   ✅ 4 branches inserted

👤 Seeding Users...
   ✅ 5 users inserted (password: admin123)

🔗 Assigning Users to Branches...
   ✅ 8 user-branch assignments created

📁 Seeding Categories...
   ✅ 8 categories inserted

🚚 Seeding Suppliers...
   ✅ 3 suppliers inserted

🧑‍🤝‍🧑 Seeding Customers...
   ✅ 5 customers inserted

📦 Seeding Products...
   ✅ 20 products inserted

📊 Seeding Product Stocks...
   ✅ 80 product stocks inserted

╔══════════════════════════════════════════════════════════════════╗
║                ✅ SEEDING COMPLETED!                              ║
╚══════════════════════════════════════════════════════════════════╝
```

## 🧪 Testing dengan Data Seeder

### Test Login
```bash
# Super Admin
username: admin
password: admin123

# Manager
username: manager
password: admin123

# Cashier
username: cashier1
password: admin123
```

### Test Products
```bash
# Get all products
GET http://localhost:5000/api/products

# Get product by SKU
GET http://localhost:5000/api/products/PRD-001

# Check stock by branch
GET http://localhost:5000/api/products/PRD-001/stock?branch_code=JKT-01
```

### Test Branches
```bash
# Get all branches
GET http://localhost:5000/api/branches

# Get branch by code
GET http://localhost:5000/api/branches/JKT-01
```

### Test with DECIMAL Quantities
```bash
# Create purchase with decimal quantity
POST http://localhost:5000/api/purchases
{
  "supplier_id": 1,
  "branch_id": 1,
  "items": [
    {
      "product_id": 3,
      "quantity_ordered": 15.5,  // Beras 15.5 kg
      "unit_price": 12000
    },
    {
      "product_id": 4,
      "quantity_ordered": 10.75, // Minyak 10.75 liter
      "unit_price": 18000
    }
  ]
}
```

## 🎯 Use Cases

### 1. Development Testing
```bash
# Reset database + setup + seed (fresh start)
npm run db:setup && npm run db:seed
```

### 2. Demo Presentation
- Data lengkap dengan relasi
- Multiple branches, users, products
- Siap untuk demo fitur

### 3. Integration Testing
- Test multi-branch functionality
- Test user permissions by role
- Test stock management across branches

### 4. Performance Testing
- Baseline data untuk load testing
- Test dengan quantity decimal
- Test transaction dengan stock real

## ⚠️ Notes

1. **Password Default**: Semua user menggunakan password `admin123`
2. **Stock Random**: Stock quantity random setiap run
3. **Safe to Re-run**: Menggunakan `ON CONFLICT DO UPDATE`
4. **Transaction Safe**: Semua insert dalam 1 transaction (rollback jika error)
5. **DECIMAL Support**: Products dan stocks sudah support quantity decimal

## 🔧 Customization

Jika ingin modifikasi data seeder, edit file `seed_database.js`:

```javascript
// Tambah branch baru
const branches = [
  // ... existing branches
  {
    code: "SMG-01",
    name: "Semarang",
    address: "Jl. Pemuda No. 100",
    city: "Semarang",
    // ...
  }
];

// Tambah product baru
const products = [
  // ... existing products
  {
    sku: "PRD-021",
    barcode: "1234567890021",
    name: "Product Baru",
    category: "Makanan & Minuman",
    // ...
  }
];
```

## 📚 Related Documentation

- [DATABASE_SETUP.md](./DATABASE_SETUP.md) - Setup database dari awal
- [QUANTITY_MIGRATION_GUIDE.md](../QUANTITY_MIGRATION_GUIDE.md) - Migrasi quantity ke DECIMAL
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Quick reference commands
