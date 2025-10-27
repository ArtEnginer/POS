# 🎨 VISUAL ARCHITECTURE - Pemisahan POS & Management

## 📐 Arsitektur Sistem Lengkap

```
┌────────────────────────────────────────────────────────────────────────┐
│                         BACKEND SERVER                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL (Master DB)                        │  │
│  │  ┌────────────┬────────────┬────────────┬────────────┐          │  │
│  │  │  products  │ customers  │  suppliers │   sales    │          │  │
│  │  │  branches  │   users    │  purchases │ inventory  │          │  │
│  │  └────────────┴────────────┴────────────┴────────────┘          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      Redis (Cache & Queue)                       │  │
│  │  ┌─────────────┬─────────────┬──────────────┐                   │  │
│  │  │  Session    │   Cache     │  Pub/Sub     │                   │  │
│  │  └─────────────┴─────────────┴──────────────┘                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                Node.js Express Server (Port 3001)                │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │  API Routes:                                              │  │  │
│  │  │  ┌─────────────────────┐  ┌────────────────────────────┐ │  │  │
│  │  │  │ /api/v1/pos/*       │  │ /api/v1/mgmt/*             │ │  │  │
│  │  │  │ - GET  /products    │  │ - GET    /products         │ │  │  │
│  │  │  │ - GET  /customers   │  │ - POST   /products         │ │  │  │
│  │  │  │ - POST /sales       │  │ - PUT    /products/:id     │ │  │  │
│  │  │  │ (Read-only master)  │  │ - DELETE /products/:id     │ │  │  │
│  │  │  │ (Write sales)       │  │ - ... (Full CRUD all)      │ │  │  │
│  │  │  └─────────────────────┘  └────────────────────────────┘ │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  │  ┌───────────────────────────────────────────────────────────┐  │  │
│  │  │  Socket.IO (Real-time Events)                             │  │  │
│  │  │  - product:created, product:updated, product:deleted      │  │  │
│  │  │  - customer:created, customer:updated                     │  │  │
│  │  │  - stock:low, sale:created                                │  │  │
│  │  └───────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Middleware:                                                     │  │
│  │  - validateAppType(['CASHIER'] or ['MANAGEMENT'])               │  │
│  │  - authMiddleware (JWT token)                                   │  │
│  │  - roleMiddleware (RBAC)                                        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬───────────────────────────────────────────┘
                             │
                             │ HTTP/WebSocket
         ┌───────────────────┴───────────────────┐
         │                                       │
┌────────▼─────────────────┐       ┌────────────▼──────────────────┐
│   POS APP (CASHIER)      │       │  MANAGEMENT APP (ADMIN)       │
├──────────────────────────┤       ├───────────────────────────────┤
│ 📱 Target: Kasir         │       │ 💼 Target: Admin/Manager      │
│ 📦 Bundle: ~50MB         │       │ 📦 Bundle: ~100MB             │
│ 💾 RAM: ~200MB           │       │ 💾 RAM: ~500MB                │
├──────────────────────────┤       ├───────────────────────────────┤
│ ✅ OFFLINE SUPPORT       │       │ ❌ NO OFFLINE MODE            │
│                          │       │                               │
│ ┌──────────────────────┐ │       │ ┌───────────────────────────┐ │
│ │  SQLite Local DB     │ │       │ │  NO Local Database        │ │
│ │  ┌────────────────┐  │ │       │ │  (Only settings cache)    │ │
│ │  │ products_cache │  │ │       │ └───────────────────────────┘ │
│ │  │ customers_cache│  │ │       │                               │
│ │  │ sales_offline  │  │ │       │ ┌───────────────────────────┐ │
│ │  │ sync_queue     │  │ │       │ │  Socket.IO Client         │ │
│ │  └────────────────┘  │ │       │ │  - Listen to real-time    │ │
│ └──────────────────────┘ │       │ │    events                 │ │
│                          │       │ │  - Auto refresh UI        │ │
│ ┌──────────────────────┐ │       │ └───────────────────────────┘ │
│ │  Background Sync     │ │       │                               │
│ │  ┌────────────────┐  │ │       │ ┌───────────────────────────┐ │
│ │  │ Every 5 min    │  │ │       │ │  Connection Guard         │ │
│ │  │ Upload sales   │  │ │       │ │  - Check before action    │ │
│ │  │ Download update│  │ │       │ │  - Block if offline       │ │
│ │  └────────────────┘  │ │       │ └───────────────────────────┘ │
│ └──────────────────────┘ │       │                               │
├──────────────────────────┤       ├───────────────────────────────┤
│ FEATURES:                │       │ FEATURES:                     │
│ ✅ Sales Transaction     │       │ ✅ Dashboard (Real-time)      │
│ ✅ View Products (cache) │       │ ✅ Product CRUD               │
│ ✅ View Customers (cache)│       │ ✅ Customer CRUD              │
│ ✅ Transaction History   │       │ ✅ Supplier CRUD              │
│ ✅ Print Receipt         │       │ ✅ Purchase CRUD              │
│ ✅ Manual Sync           │       │ ✅ Branch Management          │
│ ❌ No CRUD Data Master   │       │ ✅ Reports & Analytics        │
│ ❌ No Management         │       │ ✅ Settings & Config          │
│                          │       │ ✅ User Management            │
│                          │       │ ✅ Export Excel/PDF           │
└──────────────────────────┘       └───────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### 1️⃣ POS App - Offline Transaction Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Kasir: Buat Transaksi                                           │
│ - Scan barcode / pilih produk dari cache                        │
│ - Input customer (opsional)                                     │
│ - Hitung total                                                  │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ SQLite: Save Transaction (INSTANT - No waiting)                 │
│   INSERT INTO sales (id, invoice_number, total, ...)            │
│   INSERT INTO sale_items (product_id, quantity, price, ...)     │
│   Status: PENDING_SYNC                                          │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Print Struk (dari data lokal)                                   │
│ ✅ Transaksi selesai - Kasir bisa lanjut transaksi berikutnya   │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Background Worker (Workmanager)                                 │
│ IF online:                                                      │
│   1. Read from sync_queue                                       │
│   2. POST /api/v1/pos/sales                                     │
│   3. IF success: Update status = SYNCED                         │
│   4. IF failed: Retry (max 3x)                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2️⃣ Management App - Product CRUD Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Admin: Create/Update Product                                    │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Connection Guard: Check Internet                                │
│ IF offline: BLOCK + Show error "Tidak ada internet"             │
│ IF online: Continue                                             │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ API Call: POST/PUT /api/v1/mgmt/products                        │
│ Headers: { "X-App-Type": "MANAGEMENT", "Authorization": "..." } │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Backend: Validate & Save to PostgreSQL                          │
│   INSERT/UPDATE products SET ...                                │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Socket.IO: Broadcast Event                                      │
│   socket.emit('product:created', productData)                   │
└────────────────┬───────────────────────┬────────────────────────┘
                 │                       │
        ┌────────▼────────┐     ┌───────▼─────────┐
        │ Other Management│     │   POS Apps      │
        │ Apps (Real-time)│     │ (Update cache)  │
        │ - Auto refresh  │     │ - Download new  │
        │   product list  │     │   product data  │
        └─────────────────┘     └─────────────────┘
```

### 3️⃣ Sync Flow - Product Update dari Server ke POS

```
┌─────────────────────────────────────────────────────────────────┐
│ Management App: Update harga produk                             │
│   POST /api/v1/mgmt/products/:id                                │
│   { "price": 15000 } (harga lama: 10000)                        │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ PostgreSQL: UPDATE products SET price = 15000                   │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ Socket.IO: Emit event                                           │
│   socket.emit('product:updated', { id, price: 15000 })          │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ POS App: Listen to Socket.IO                                    │
│ IF connected:                                                   │
│   - Receive event immediately                                   │
│   - Update SQLite cache                                         │
│ IF offline:                                                     │
│   - Next sync will download latest data                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎭 User Interface Comparison

### POS App UI (Simple & Fast)

```
┌─────────────────────────────────────────────────────────────┐
│ 🛒 POS Kasir              [Offline] [Sync] [Logout]         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────┐    │
│  │  PRODUCT LIST        │  │  CART                    │    │
│  │  [Search: ______ ]   │  │                          │    │
│  │                      │  │  - Indomie Goreng x3     │    │
│  │  📦 Indomie Goreng   │  │    Rp 9.000              │    │
│  │     Rp 3.000         │  │  - Aqua 600ml x2         │    │
│  │                      │  │    Rp 6.000              │    │
│  │  📦 Aqua 600ml       │  │                          │    │
│  │     Rp 3.000         │  │  ────────────────────    │    │
│  │                      │  │  TOTAL: Rp 15.000        │    │
│  │  📦 Teh Botol        │  │                          │    │
│  │     Rp 4.000         │  │  [BAYAR] [CLEAR]         │    │
│  │                      │  │                          │    │
│  └──────────────────────┘  └──────────────────────────┘    │
│                                                             │
│  [💰 Kasir] [📊 Riwayat] [🔄 Sync]                         │
└─────────────────────────────────────────────────────────────┘
```

### Management App UI (Rich & Detailed)

```
┌─────────────────────────────────────────────────────────────┐
│ 🏢 POS Management         Online ✓  [Admin] [Logout]       │
├─────────────────────────────────────────────────────────────┤
│ 📊 Dashboard | 📦 Product | 👥 Customer | 🏭 Supplier | ... │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📦 PRODUCT MANAGEMENT                                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ [+ Add Product] [Import Excel] [Export]              │  │
│  │ Search: [____________]  Category: [All ▼]            │  │
│  ├──────────┬─────────┬────────┬────────┬──────────────┤  │
│  │ Code     │ Name    │ Price  │ Stock  │ Actions      │  │
│  ├──────────┼─────────┼────────┼────────┼──────────────┤  │
│  │ PRD-001  │ Indomie │ 3.000  │ 150    │ ✏️ 🗑️ 📊     │  │
│  │ PRD-002  │ Aqua    │ 3.000  │ 200    │ ✏️ 🗑️ 📊     │  │
│  │ PRD-003  │ Teh Bot │ 4.000  │ 80     │ ✏️ 🗑️ 📊     │  │
│  │ ...      │ ...     │ ...    │ ...    │ ...          │  │
│  └──────────┴─────────┴────────┴────────┴──────────────┘  │
│  Showing 1-100 of 456 products      [1][2][3][4][5] >>    │
│                                                             │
│  📈 DASHBOARD WIDGETS                                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Sales    │ │ Products │ │ Low Stock│ │ Revenue  │     │
│  │ Today    │ │ Total    │ │ Alerts   │ │ Month    │     │
│  │ 45 trx   │ │ 456      │ │ 12       │ │ 45M      │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security & Validation Flow

```
┌───────────────────────────────────────────────────────────────┐
│ CLIENT REQUEST                                                │
│                                                               │
│ POS App → Headers: { "X-App-Type": "CASHIER" }               │
│ Management App → Headers: { "X-App-Type": "MANAGEMENT" }     │
└────────────────────────────┬──────────────────────────────────┘
                             ↓
┌───────────────────────────────────────────────────────────────┐
│ BACKEND: Middleware Layer                                     │
│                                                               │
│ 1. validateAppType(['CASHIER'] or ['MANAGEMENT'])            │
│    - Check X-App-Type header                                 │
│    - BLOCK jika tidak sesuai                                 │
│                                                               │
│ 2. authMiddleware                                            │
│    - Verify JWT token                                        │
│    - Extract user info                                       │
│                                                               │
│ 3. roleMiddleware (optional)                                 │
│    - Check user role (ADMIN, MANAGER, CASHIER)               │
│    - BLOCK jika role tidak authorized                        │
└────────────────────────────┬──────────────────────────────────┘
                             ↓
┌───────────────────────────────────────────────────────────────┐
│ ROUTE HANDLER                                                 │
│                                                               │
│ IF /api/v1/pos/*:                                            │
│   - Allow: GET products, GET customers, POST sales           │
│   - Deny: All CRUD operations on master data                 │
│                                                               │
│ IF /api/v1/mgmt/*:                                           │
│   - Allow: Full CRUD on all entities                         │
│   - Role-based: Some actions require ADMIN role              │
└───────────────────────────────────────────────────────────────┘
```

---

## 📊 Performance Metrics

### POS App Performance Targets

```
Metric                   Target        Measurement
─────────────────────────────────────────────────────
App Startup             < 3 sec       Time to show POS screen
Transaction Time        < 1 sec       Scan → Add to cart
Product Search          < 500 ms      Query SQLite cache
Print Receipt           < 2 sec       Generate → Print
Sync Duration           < 30 sec      Upload + Download
Offline Days            7 days        Max without sync
Bundle Size             < 60 MB       Windows installer
RAM Usage               < 250 MB      Peak memory
Battery (if mobile)     < 5% / hour   Background sync
```

### Management App Performance Targets

```
Metric                   Target        Measurement
─────────────────────────────────────────────────────
App Startup             < 5 sec       Time to dashboard
Dashboard Load          < 3 sec       Charts + widgets
Product List Load       < 2 sec       100 items
Product Search          < 1 sec       Server query
Report Generation       < 10 sec      PDF/Excel export
Real-time Update        < 2 sec       Socket.IO event → UI
API Response            < 100 ms      95th percentile
Bundle Size             < 120 MB      Windows installer
RAM Usage               < 600 MB      Peak memory
```

---

## 🎯 Decision Matrix

### Kapan Pakai POS App?

| Scenario | POS App | Management App |
|----------|---------|----------------|
| Transaksi penjualan | ✅ Ya | ❌ Tidak |
| Lihat stok produk | ✅ Ya (cache) | ✅ Ya (real-time) |
| Edit harga produk | ❌ Tidak | ✅ Ya |
| Tambah customer baru | ❌ Tidak | ✅ Ya |
| Offline mode | ✅ Bisa | ❌ Tidak bisa |
| Laporan detail | ❌ Terbatas | ✅ Lengkap |
| Multi-branch view | ❌ Tidak | ✅ Ya |
| User management | ❌ Tidak | ✅ Ya |

---

**Dibuat**: October 27, 2025  
**Purpose**: Visual reference untuk arsitektur pemisahan POS & Management  
**Audience**: Developers, System Architects, Stakeholders
