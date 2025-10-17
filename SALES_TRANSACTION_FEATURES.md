# Fitur Transaksi Penjualan (Sales/POS)

## 📋 Overview

Fitur transaksi penjualan yang lengkap, user-friendly, dan responsive untuk sistem Point of Sale (POS). Fitur ini memungkinkan kasir untuk melakukan transaksi penjualan dengan mudah dan cepat.

---

## ✨ Fitur Yang Diimplementasikan

### 1. **POS/Kasir Interface** ✅

Interface kasir yang modern dan mudah digunakan untuk melakukan transaksi penjualan.

#### Fitur Utama:
- **Barcode Scanner Input** - Scan atau ketik barcode produk untuk menambah ke keranjang
- **Product Search** - Pencarian produk real-time
- **Product Grid** - Tampilan produk dalam bentuk grid yang responsive
- **Shopping Cart** - Keranjang belanja dengan kontrol quantity
- **Multiple Payment Methods** - Tunai, Kartu Debit/Kredit, QRIS, E-Wallet
- **Tax & Discount** - Perhitungan pajak dan diskon otomatis
- **Customer Info** - Input nama pelanggan (opsional)
- **Change Calculation** - Perhitungan kembalian otomatis untuk pembayaran tunai
- **Stock Validation** - Validasi ketersediaan stok produk
- **Auto Transaction Number** - Generate nomor transaksi otomatis

#### Cara Menggunakan:
1. Buka menu **"Kasir"** di dashboard
2. Scan barcode atau pilih produk dari grid
3. Atur quantity produk di keranjang
4. Tambahkan pajak/diskon jika perlu
5. Pilih metode pembayaran
6. Untuk tunai, masukkan jumlah bayar (kembalian akan dihitung otomatis)
7. Klik **"PROSES TRANSAKSI"**
8. Transaksi tersimpan dan stok produk terupdate otomatis

#### File:
- `lib/features/sales/presentation/pages/pos_page.dart`

---

### 2. **Riwayat Transaksi** ✅

Halaman untuk melihat daftar semua transaksi penjualan dengan filter dan pencarian.

#### Fitur:
- **List Transaksi** - Daftar semua transaksi dengan informasi lengkap
- **Search** - Cari berdasarkan nomor transaksi, nama pelanggan
- **Filter by Date Range** - Filter transaksi berdasarkan rentang tanggal
- **Filter by Status** - Filter berdasarkan status (Selesai, Batal, Refund)
- **Detail Info** - Nomor transaksi, tanggal, kasir, pelanggan, total, metode pembayaran
- **Status Badge** - Visual indicator untuk status transaksi
- **Click to Detail** - Klik transaksi untuk melihat detail lengkap

#### Cara Menggunakan:
1. Buka menu **"Transaksi"** di dashboard
2. Gunakan search bar untuk mencari transaksi
3. Klik icon tanggal untuk filter by date range
4. Pilih status untuk filter transaksi
5. Klik transaksi untuk melihat detail

#### File:
- `lib/features/sales/presentation/pages/sale_list_page.dart`

---

### 3. **Detail Transaksi & Print Receipt** ✅

Halaman detail transaksi lengkap dengan fitur cetak struk.

#### Fitur:
- **Header Info** - Status, nomor transaksi, tanggal
- **Item List** - Daftar produk dengan qty, harga, subtotal
- **Summary** - Subtotal, pajak, diskon, total
- **Payment Info** - Metode pembayaran, jumlah bayar, kembalian
- **Staff Info** - Nama kasir dan pelanggan
- **Notes** - Catatan transaksi (jika ada)
- **Print Receipt** - Cetak struk thermal 80mm

#### Cara Menggunakan:
1. Dari riwayat transaksi, klik salah satu transaksi
2. Lihat detail lengkap transaksi
3. Klik icon **Print** untuk mencetak struk

#### File:
- `lib/features/sales/presentation/pages/sale_detail_page.dart`

---

## 🗂️ Struktur File

### Domain Layer
```
lib/features/sales/domain/
├── entities/
│   └── sale.dart                    # Entity Sale & SaleItem
├── repositories/
│   └── sale_repository.dart         # Repository interface
└── usecases/
    └── sale_usecases.dart           # Use cases (9 use cases)
```

### Data Layer
```
lib/features/sales/data/
├── models/
│   └── sale_model.dart              # Model dengan JSON serialization
├── datasources/
│   └── sale_local_data_source.dart  # SQLite operations
└── repositories/
    └── sale_repository_impl.dart    # Repository implementation
```

### Presentation Layer
```
lib/features/sales/presentation/
├── bloc/
│   ├── sale_event.dart              # Events
│   ├── sale_state.dart              # States
│   └── sale_bloc.dart               # BLoC logic
└── pages/
    ├── pos_page.dart                # POS/Kasir interface
    ├── sale_list_page.dart          # Daftar transaksi
    └── sale_detail_page.dart        # Detail & print transaksi
```

---

## 🗄️ Database Schema

### Table: `transactions`
Menyimpan data transaksi penjualan.

```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  transaction_number TEXT UNIQUE NOT NULL,
  customer_id TEXT,
  customer_name TEXT,
  cashier_id TEXT NOT NULL,
  cashier_name TEXT NOT NULL,
  subtotal REAL NOT NULL,
  tax REAL NOT NULL DEFAULT 0,
  discount REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL,
  payment_method TEXT NOT NULL,
  payment_amount REAL NOT NULL,
  change_amount REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  notes TEXT,
  sync_status TEXT DEFAULT 'PENDING',
  transaction_date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### Table: `transaction_items`
Menyimpan item dalam transaksi.

```sql
CREATE TABLE transaction_items (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  discount REAL NOT NULL DEFAULT 0,
  subtotal REAL NOT NULL,
  sync_status TEXT DEFAULT 'PENDING',
  created_at TEXT NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions (id)
)
```

---

## 🔄 Business Logic

### Alur Transaksi Penjualan

1. **Pilih Produk**
   - Scan barcode atau pilih dari grid
   - Validasi stok tersedia
   - Tambahkan ke keranjang

2. **Atur Keranjang**
   - Adjust quantity
   - Remove item jika perlu
   - Tambahkan pajak/diskon

3. **Payment**
   - Pilih metode pembayaran
   - Input jumlah bayar (untuk tunai)
   - Validasi pembayaran cukup

4. **Proses Transaksi**
   - Generate transaction number
   - Simpan ke database
   - Update stok produk (dikurangi)
   - Tampilkan konfirmasi sukses

5. **Reset & Ready**
   - Clear cart
   - Generate new transaction number
   - Siap untuk transaksi berikutnya

---

## 💡 Fitur User-Friendly

### Responsive Design
- ✅ **Dual Panel Layout** - Product selection di kiri, cart di kanan
- ✅ **Grid View** - Produk ditampilkan dalam grid responsive
- ✅ **Real-time Update** - Cart update langsung saat ada perubahan
- ✅ **Visual Feedback** - Loading states, success/error messages
- ✅ **Out of Stock Indicator** - Produk habis ditandai dengan jelas

### Ease of Use
- ✅ **Quick Product Search** - Search real-time dengan debouncing
- ✅ **Barcode Scanner** - Quick add dengan scan barcode
- ✅ **One-Click Add** - Klik produk langsung masuk cart
- ✅ **Quantity Control** - Increment/decrement dengan tombol
- ✅ **Smart Validation** - Validasi stok, payment, dll
- ✅ **Auto Calculation** - Subtotal, tax, total, change otomatis
- ✅ **Quick Reset** - Reset transaksi dengan 1 klik

### Performance
- ✅ **Local Database** - SQLite untuk performa cepat
- ✅ **Efficient Queries** - Query dioptimalkan
- ✅ **Lazy Loading** - Load data sesuai kebutuhan
- ✅ **State Management** - BLoC pattern untuk state yang efisien

---

## 📝 Payment Methods

### Metode Pembayaran yang Didukung:

1. **Tunai (CASH)**
   - Input jumlah bayar
   - Kembalian dihitung otomatis
   - Validasi jumlah bayar >= total

2. **Kartu Debit/Kredit (CARD)**
   - Payment amount = total (exact)
   - No change needed

3. **QRIS**
   - Payment amount = total (exact)
   - No change needed

4. **E-Wallet**
   - Payment amount = total (exact)
   - No change needed

---

## 🖨️ Print Receipt

### Format Struk:
- **Header** - Nama toko, alamat, telepon
- **Transaction Info** - Nomor, tanggal, kasir, pelanggan
- **Items** - Produk, qty, harga, subtotal
- **Summary** - Subtotal, pajak, diskon, total
- **Payment** - Jumlah bayar, kembalian
- **Footer** - Ucapan terima kasih

### Spesifikasi:
- Format: Thermal 80mm
- Library: `pdf` & `printing`
- Output: Print preview atau direct print

---

## 🔐 Data Security

- ✅ **Transaction Integrity** - Database transactions untuk consistency
- ✅ **Stock Validation** - Mencegah overselling
- ✅ **Payment Validation** - Memastikan pembayaran cukup
- ✅ **Audit Trail** - Semua transaksi tercatat dengan timestamp
- ✅ **Sync Status** - Tracking untuk sinkronisasi ke server

---

## 🎯 Use Cases

### 9 Use Cases Diimplementasikan:

1. **GetAllSales** - Load semua transaksi
2. **GetSaleById** - Load detail transaksi by ID
3. **GetSalesByDateRange** - Filter by date range
4. **SearchSales** - Search transaksi
5. **CreateSale** - Buat transaksi baru
6. **UpdateSale** - Update transaksi
7. **DeleteSale** - Hapus transaksi
8. **GenerateSaleNumber** - Generate nomor transaksi
9. **GetDailySummary** - Summary penjualan harian

---

## 📊 Daily Summary

Summary penjualan harian mencakup:
- Total transaksi
- Total penjualan (amount)
- Total pajak
- Total diskon
- Breakdown per payment method:
  - Cash sales
  - Card sales
  - QRIS sales
  - E-Wallet sales

---

## 🚀 Cara Testing

### Test POS/Kasir:
1. Pastikan ada produk dengan stok
2. Buka menu Kasir
3. Tambahkan produk ke cart
4. Coba berbagai payment methods
5. Proses transaksi
6. Verifikasi stok produk berkurang
7. Cek di riwayat transaksi

### Test Print Receipt:
1. Buka detail transaksi
2. Klik icon print
3. Verifikasi format struk
4. Test print atau save PDF

### Test Filter & Search:
1. Buat beberapa transaksi
2. Test search by transaction number
3. Test filter by date range
4. Test filter by status

---

## ⚙️ Configuration

### Transaction Number Format:
```
TRX-YYYYMMDD-XXXX
```
- TRX: Prefix
- YYYYMMDD: Date
- XXXX: Sequence number (0001-9999)

Example: `TRX-20251017-0001`

---

## 🔄 Integration

### With Other Modules:

1. **Product Module**
   - Get product info
   - Update stock after sale
   - Check stock availability

2. **Database**
   - Save transactions
   - Save transaction items
   - Update product stock

3. **Sync Manager** (Future)
   - Sync sales to server
   - Update sync status

---

## 📱 UI/UX Highlights

### Colors & Theme:
- Primary color untuk elements penting
- Success green untuk positive actions
- Error red untuk warnings
- Clean white background
- Professional card-based layout

### Typography:
- Bold untuk headers
- Medium untuk body text
- Small untuk secondary info
- Currency format dengan Rp prefix

### Icons:
- Material Icons
- Intuitive meanings
- Consistent sizing

---

## 🎉 Summary

✅ **POS Interface** - Modern, responsive, dan mudah digunakan  
✅ **Transaction Management** - CRUD operations lengkap  
✅ **Filter & Search** - Powerful filtering dan pencarian  
✅ **Print Receipt** - Thermal 80mm format  
✅ **Payment Methods** - 4 metode pembayaran  
✅ **Stock Management** - Auto update stok produk  
✅ **Daily Summary** - Analytics penjualan harian  
✅ **Clean Architecture** - Domain, Data, Presentation layers  
✅ **BLoC Pattern** - State management yang robust  
✅ **Local Database** - SQLite untuk offline capability  

---

## 🔜 Future Enhancements

- [ ] Customer management integration
- [ ] Loyalty points system
- [ ] Return/refund transactions
- [ ] Invoice generation
- [ ] Sales analytics dashboard
- [ ] Multi-cashier management
- [ ] Hardware barcode scanner integration
- [ ] Cash drawer integration
- [ ] Email receipt option
- [ ] Shift management & closing

---

**Created:** October 17, 2025  
**Status:** ✅ Production Ready  
**Version:** 1.0.0
