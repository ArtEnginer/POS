# 🔀 STRATEGI PEMISAHAN POS DAN MANAGEMENT

## 📌 KONSEP DASAR

### Prinsip Utama
- **POS App**: Bisa OFFLINE untuk operasional kasir
- **Management App**: HARUS ONLINE untuk manajemen data
- **Pemisahan**: Dua aplikasi terpisah untuk performa optimal

---

## 🎯 ALASAN PEMISAHAN

### 1. **Kebutuhan Offline/Online yang Berbeda**
```
┌─────────────────────────────────────────┐
│           POS APPLICATION                │
│  ✅ OFFLINE Mode: Full Support           │
│  - Transaksi penjualan                   │
│  - Lihat produk (cache)                  │
│  - Lihat customer (cache)                │
│  - Print struk                           │
│                                          │
│  🔄 SYNC when Online:                    │
│  - Upload transaksi ke server            │
│  - Download update produk/harga          │
│  - Download customer baru                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│        MANAGEMENT APPLICATION            │
│  ❌ OFFLINE Mode: NOT ALLOWED            │
│  - Kelola produk (CRUD)                  │
│  - Kelola customer/supplier (CRUD)       │
│  - Lihat laporan real-time               │
│  - Analitik & dashboard                  │
│  - Kelola cabang & user                  │
│                                          │
│  ⚠️ Wajib Online:                        │
│  - Semua operasi langsung ke server      │
│  - Real-time update ke semua cabang      │
│  - Konsistensi data terjamin             │
└─────────────────────────────────────────┘
```

### 2. **Performa & Resource**
```
POS App (Ringan):
- Hanya fitur transaksi
- Cache minimal (produk aktif + customer sering)
- UI sederhana & cepat
- Bundle size: ~50MB
- RAM usage: ~200MB

Management App (Lengkap):
- Full CRUD semua entitas
- Laporan kompleks & grafik
- UI kaya fitur & dashboard
- Bundle size: ~100MB
- RAM usage: ~500MB
```

### 3. **User Experience**
```
Kasir (POS App):
- Login sekali, bisa offline
- Fokus transaksi cepat
- Tidak perlu akses internet terus-menerus
- Tidak bingung dengan menu manajemen

Manager/Admin (Management App):
- Harus online untuk data real-time
- Full kontrol semua data
- Dashboard analitik lengkap
- Multi-cabang monitoring
```

---

## 🏗️ ARSITEKTUR BARU

### High-Level Architecture
```
┌────────────────────────────────────────────────────────────┐
│                    BACKEND SERVER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ PostgreSQL   │  │    Redis     │  │  Socket.IO   │    │
│  │  (Master)    │  │   (Cache)    │  │   (Events)   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │           Node.js REST API + GraphQL              │   │
│  │  /api/v1/pos/*     (POS endpoints)                │   │
│  │  /api/v1/mgmt/*    (Management endpoints)         │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────┬───────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
┌────────▼──────────┐          ┌────────▼──────────┐
│   POS CLIENT      │          │  MANAGEMENT CLIENT │
│  (Flutter App)    │          │   (Flutter App)    │
│                   │          │                    │
│  ✅ Offline OK    │          │  ❌ Online Only    │
│  📦 SQLite Local  │          │  🌐 Direct to DB   │
│  🔄 Sync Queue    │          │  📊 Real-time      │
└───────────────────┘          └────────────────────┘
```

---

## 📁 STRUKTUR PROJECT BARU

```
pos_system/
├── pos_app/                    # POS APPLICATION (Offline-capable)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── database/
│   │   │   │   └── sqlite/      # Local database
│   │   │   ├── sync/            # Sync engine
│   │   │   └── cache/           # Cache manager
│   │   └── features/
│   │       ├── auth/            # Login kasir
│   │       ├── sales/           # Transaksi penjualan
│   │       │   ├── pos_screen/  # Main POS UI
│   │       │   └── transaction_history/
│   │       ├── product/         # Product READ-ONLY
│   │       │   └── product_list/ (cache, no CRUD)
│   │       └── customer/        # Customer READ-ONLY
│   │           └── customer_list/ (cache, no CRUD)
│   ├── pubspec.yaml
│   └── README.md
│
├── management_app/             # MANAGEMENT APPLICATION (Online-only)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── network/         # API client (no offline)
│   │   │   └── realtime/        # Socket.IO
│   │   └── features/
│   │       ├── auth/            # Login admin/manager
│   │       ├── dashboard/       # Analytics & overview
│   │       ├── product/         # Product CRUD
│   │       ├── customer/        # Customer CRUD
│   │       ├── supplier/        # Supplier CRUD
│   │       ├── branch/          # Branch management
│   │       ├── purchase/        # Purchase & receiving
│   │       ├── reports/         # Advanced reports
│   │       └── settings/        # System settings
│   ├── pubspec.yaml
│   └── README.md
│
├── shared/                     # SHARED CODE (optional)
│   ├── lib/
│   │   ├── models/             # Shared models
│   │   ├── constants/          # Shared constants
│   │   └── utils/              # Shared utilities
│   └── pubspec.yaml
│
└── backend_v2/                 # EXISTING BACKEND
    └── src/
        ├── routes/
        │   ├── pos/            # POS-specific routes
        │   └── management/     # Management-specific routes
        └── ...
```

---

## 🔄 FLOW DATA

### 1. **POS App Flow (Offline-First)**
```
User Action (Kasir):
  ↓
┌─────────────────────────────┐
│ 1. Buat transaksi           │
│    - Pilih produk (cache)   │
│    - Input customer (cache) │
│    - Hitung total           │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 2. Simpan ke SQLite LOCAL   │
│    - sales table            │
│    - sale_items table       │
│    - Status: PENDING_SYNC   │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 3. Print struk (opsional)   │
│    - Dari data lokal        │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 4. Background Sync Job      │
│    IF online:               │
│    - POST /api/v1/pos/sales │
│    - Update status: SYNCED  │
│    - Delete if success      │
└─────────────────────────────┘
```

### 2. **Management App Flow (Online-Only)**
```
User Action (Manager):
  ↓
┌─────────────────────────────┐
│ 1. Check connection         │
│    IF offline:              │
│    - Show error dialog      │
│    - Block all actions      │
│    ELSE: Continue           │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 2. Direct API call          │
│    - No local cache         │
│    - Direct to PostgreSQL   │
│    - Real-time data         │
└──────────────┬──────────────┘
               ↓
┌─────────────────────────────┐
│ 3. Socket.IO broadcast      │
│    - Notify all clients     │
│    - Update POS cache       │
│    - Update other managers  │
└─────────────────────────────┘
```

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### Role-Based Access
```
┌─────────────┬──────────────┬───────────────┐
│    Role     │   POS App    │  Mgmt App     │
├─────────────┼──────────────┼───────────────┤
│ SUPER_ADMIN │      ✅      │      ✅       │
│ MANAGER     │      ✅      │      ✅       │
│ CASHIER     │      ✅      │      ❌       │
│ WAREHOUSE   │      ❌      │      ✅       │
└─────────────┴──────────────┴───────────────┘
```

### Permission Matrix
```
Feature             │ Cashier │ Manager │ Admin │ Warehouse
────────────────────┼─────────┼─────────┼───────┼──────────
Sales Transaction   │    ✅   │    ✅   │   ✅  │    ❌
View Products       │    ✅   │    ✅   │   ✅  │    ✅
Manage Products     │    ❌   │    ✅   │   ✅  │    ❌
View Customers      │    ✅   │    ✅   │   ✅  │    ❌
Manage Customers    │    ❌   │    ✅   │   ✅  │    ❌
Purchase Orders     │    ❌   │    ✅   │   ✅  │    ✅
Receiving Goods     │    ❌   │    ✅   │   ✅  │    ✅
Reports (View)      │    ❌   │    ✅   │   ✅  │    ❌
Reports (Export)    │    ❌   │    ✅   │   ✅  │    ❌
User Management     │    ❌   │    ❌   │   ✅  │    ❌
Branch Management   │    ❌   │    ❌   │   ✅  │    ❌
```

---

## 📋 FITUR PER APLIKASI

### **POS App Features**
```
✅ SUPPORTED:
1. Login Kasir
   - Username/password
   - PIN (opsional)
   - Remember device

2. Transaksi Penjualan
   - Scan barcode
   - Pilih produk dari list
   - Input customer
   - Pilih metode pembayaran
   - Print struk
   - Split payment

3. Riwayat Transaksi
   - Hari ini
   - 7 hari terakhir
   - Filter by kasir
   - Reprint struk

4. Produk (READ-ONLY)
   - Lihat daftar produk
   - Search produk
   - Lihat stok
   - Lihat harga
   - ❌ Tidak bisa edit/hapus

5. Customer (READ-ONLY)
   - Lihat daftar customer
   - Search customer
   - Lihat history pembelian
   - ❌ Tidak bisa edit/hapus

6. Sinkronisasi
   - Manual sync button
   - Auto sync (background)
   - Sync status indicator
   - Offline indicator

❌ NOT AVAILABLE:
- CRUD produk/customer/supplier
- Laporan lengkap (hanya summary)
- Pengaturan sistem
- Manajemen cabang
- Purchase order
```

### **Management App Features**
```
✅ FULL FEATURES:
1. Dashboard
   - Sales overview
   - Top products
   - Low stock alerts
   - Multi-branch comparison
   - Real-time charts

2. Product Management
   - Full CRUD
   - Batch import (Excel)
   - Category management
   - Stock adjustment
   - Price history

3. Customer Management
   - Full CRUD
   - Customer groups
   - Loyalty program
   - Purchase history
   - Export to Excel

4. Supplier Management
   - Full CRUD
   - Contact management
   - Purchase history

5. Purchase & Receiving
   - Create PO
   - Receive goods
   - Return to supplier
   - Payment tracking

6. Reports & Analytics
   - Sales report (detailed)
   - Inventory report
   - Profit/loss report
   - Custom date range
   - Export PDF/Excel
   - Schedule auto-email

7. Branch Management
   - Add/edit branches
   - Transfer stock
   - Branch comparison
   - User assignment

8. Settings
   - User management
   - Role & permissions
   - Printer setup
   - Tax settings
   - Receipt template
```

---

## 🔧 TECHNICAL IMPLEMENTATION

### **POS App Stack**
```yaml
Dependencies:
  # Core
  flutter_bloc: ^8.1.6
  get_it: ^8.0.2
  
  # Local Database
  sqflite: ^2.3.3+2
  hive_flutter: ^1.1.0
  
  # Network (minimal)
  dio: ^5.7.0
  connectivity_plus: ^6.1.0
  
  # Sync
  workmanager: ^0.5.2        # Background sync
  rxdart: ^0.28.0
  
  # Barcode
  mobile_scanner: ^5.2.3
  
  # Printing
  pdf: ^3.11.1
  printing: ^5.13.4
  
  # Utils
  intl: ^0.19.0
  uuid: ^4.5.1
```

### **Management App Stack**
```yaml
Dependencies:
  # Core (same as POS)
  flutter_bloc: ^8.1.6
  get_it: ^8.0.2
  
  # Network (full featured)
  dio: ^5.7.0
  socket_io_client: ^2.0.3+1
  
  # NO Local Database (online-only)
  # NO sqflite
  # NO hive (except for settings cache)
  
  # Charts & Visualization
  fl_chart: ^0.69.0
  syncfusion_flutter_charts: ^27.1.58
  
  # Export
  excel: ^4.0.6
  pdf: ^3.11.1
  
  # Image handling
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  
  # Utils
  intl: ^0.19.0
  file_picker: ^8.1.4
```

---

## 🚀 MIGRATION PLAN

### **Phase 1: Preparation (Week 1)**
```
1. Create new folder structure:
   ✓ pos_app/
   ✓ management_app/
   ✓ shared/ (optional)

2. Setup new projects:
   ✓ Run flutter create pos_app
   ✓ Run flutter create management_app
   ✓ Copy dependencies to pubspec.yaml

3. Backend API separation:
   ✓ Create /api/v1/pos/* routes
   ✓ Create /api/v1/mgmt/* routes
   ✓ Add middleware untuk validasi app_type
```

### **Phase 2: POS App Development (Week 2-3)**
```
1. Core setup:
   ✓ Setup dependency injection
   ✓ Setup SQLite database
   ✓ Setup sync engine

2. Features (copy from existing):
   ✓ Auth (login kasir)
   ✓ Sales/POS screen
   ✓ Product list (read-only)
   ✓ Customer list (read-only)
   ✓ Transaction history

3. Offline support:
   ✓ Cache management
   ✓ Sync queue
   ✓ Background worker
   ✓ Conflict resolution

4. Testing:
   ✓ Offline mode
   ✓ Sync reliability
   ✓ Performance
```

### **Phase 3: Management App Development (Week 4-5)**
```
1. Core setup:
   ✓ Setup dependency injection
   ✓ Setup API client (online-only)
   ✓ Setup Socket.IO

2. Features (copy & enhance):
   ✓ Auth (login admin/manager)
   ✓ Dashboard
   ✓ Product CRUD
   ✓ Customer CRUD
   ✓ Supplier CRUD
   ✓ Purchase & Receiving
   ✓ Reports

3. Real-time features:
   ✓ Live dashboard updates
   ✓ Multi-user notifications
   ✓ Stock alerts

4. Testing:
   ✓ Multi-user scenarios
   ✓ Real-time sync
   ✓ Performance
```

### **Phase 4: Deployment (Week 6)**
```
1. Backend deployment:
   ✓ Update API with new routes
   ✓ Test endpoints
   ✓ Setup monitoring

2. POS App deployment:
   ✓ Build Windows installer
   ✓ Distribute to branches
   ✓ Training kasir

3. Management App deployment:
   ✓ Build Windows/Web version
   ✓ Deploy to managers
   ✓ Training admin

4. Migration:
   ✓ Data migration (if needed)
   ✓ Gradual rollout
   ✓ Monitor & fix issues
```

---

## 📊 COMPARISON: Before vs After

### Before (Single App)
```
❌ Problems:
- Kasir bingung dengan banyak menu
- Manajemen data bisa offline (inkonsistensi)
- App berat (100MB+ bundle, 500MB+ RAM)
- Sync conflict sering terjadi
- Performa lambat karena banyak fitur
- Satu crash, semua fitur down

Bundle Size: ~120MB
RAM Usage: ~600MB
Features: 40+ features in one app
Offline: All features (inconsistent)
```

### After (Separated Apps)
```
✅ Benefits:
- Kasir fokus transaksi (UI simple)
- Manajemen data real-time (konsisten)
- POS app ringan (50MB, 200MB RAM)
- Mgmt app full featured (100MB, 500MB RAM)
- No sync conflict (POS offline, Mgmt online)
- Performa optimal per use case
- Isolated failures

POS App:
  Bundle: ~50MB
  RAM: ~200MB
  Features: 6 core features
  Offline: Full support

Management App:
  Bundle: ~100MB
  RAM: ~500MB
  Features: 30+ features
  Offline: Not allowed (online-only)
```

---

## 🎯 SUCCESS CRITERIA

### **POS App**
- ✅ Bisa transaksi offline 100%
- ✅ Sync otomatis dalam 5 detik setelah online
- ✅ Startup time < 3 detik
- ✅ RAM usage < 250MB
- ✅ Transaksi time < 1 detik
- ✅ No data loss

### **Management App**
- ✅ Real-time update < 2 detik
- ✅ Dashboard load < 5 detik
- ✅ Multi-user support 10+ concurrent
- ✅ Report generation < 10 detik
- ✅ No stale data
- ✅ Must be online (enforced)

---

## 📝 NOTES

### Important Decisions
1. **Shared code**: Minimal, hanya models & constants
2. **Database**: POS uses SQLite, Management uses API only
3. **Sync**: One-way (POS → Server) for sales
4. **Sync**: One-way (Server → POS) for products/customers
5. **Authentication**: Separate tokens per app

### Future Enhancements
- [ ] POS mobile app (Android/iOS)
- [ ] Management web dashboard
- [ ] API gateway untuk security
- [ ] Microservices untuk scalability

---

**Version**: 1.0.0  
**Date**: October 2025  
**Author**: System Architect  
