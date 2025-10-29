## POS Kasir - Quick Start Guide

### ✅ Struktur Project Sudah Dibuat

```
pos_cashier/
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart       ✅ Config & constants
│   │   ├── database/hive_service.dart          ✅ Offline database
│   │   ├── network/api_service.dart            ✅ API service
│   │   ├── theme/app_theme.dart                ✅ UI theme
│   │   └── utils/
│   │       ├── currency_formatter.dart         ✅ Format mata uang
│   │       └── sample_data_service.dart        ✅ Sample data
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/pages/
│   │   │       └── login_page.dart             ✅ Halaman login
│   │   │
│   │   ├── cashier/
│   │   │   ├── data/models/
│   │   │   │   ├── product_model.dart          ✅ Model produk
│   │   │   │   ├── cart_item_model.dart        ✅ Model item cart
│   │   │   │   └── sale_model.dart             ✅ Model transaksi
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── bloc/cashier_bloc.dart      ✅ Business logic
│   │   │       └── pages/cashier_page.dart     ✅ UI kasir
│   │   │
│   │   └── sync/
│   │       └── data/datasources/
│   │           └── sync_service.dart           ✅ Background sync
│   │
│   └── main.dart                               ✅ Entry point
│
├── assets/
│   ├── images/                                 ✅ Created
│   └── sounds/                                 ✅ Created
│
├── pubspec.yaml                                ✅ Dependencies installed
└── README.md                                   🔨 Needs creation
```

### 🚀 Cara Menjalankan

1. **Pastikan di folder pos_cashier**

```bash
cd d:\PROYEK\POS\pos_cashier
```

2. **Run aplikasi**

```bash
flutter run
```

3. **Atau run di Windows**

```bash
flutter run -d windows
```

### 🎯 Fitur yang Sudah Dibuat

#### ✅ Offline-First Architecture

- Hive database untuk penyimpanan lokal
- 20 sample produk otomatis dimuat saat pertama kali
- 6 kategori produk

#### ✅ Login Page

- Simple login (untuk demo bisa pakai username & password apa saja)
- Akan redirect ke halaman kasir

#### ✅ Cashier Page (Landscape Mode)

- **Kiri:** Grid produk dengan pencarian
- **Kanan:** Keranjang belanja & checkout
- Real-time update cart
- Quantity controls (+/-)
- Calculate total otomatis
- Payment dialog
- Payment success notification dengan kembalian

#### ✅ BLoC State Management

- Add to cart
- Remove from cart
- Update quantity
- Apply discount (per item & global)
- Process payment
- Clear cart

#### ✅ Sample Data

- 20 produk siap pakai
- Kategori: Makanan, Minuman, Snack, Sembako, Toiletries, Fresh Food
- Harga realistic
- Stok management

### 📱 Cara Pakai Aplikasi

1. **Login**

   - Username: apa saja
   - Password: apa saja
   - Klik LOGIN

2. **Pilih Produk**

   - Klik produk untuk tambah ke cart
   - Atau gunakan search bar

3. **Atur Quantity**

   - Gunakan tombol +/- di cart

4. **Bayar**

   - Klik tombol BAYAR (hijau)
   - Input jumlah bayar
   - Klik PROSES
   - Lihat kembalian

5. **Transaksi Baru**
   - Otomatis cart clear setelah pembayaran
   - Mulai transaksi baru

### 🔧 Konfigurasi

Edit `lib/core/constants/app_constants.dart` untuk:

- Server URL
- Sync interval
- Tax rate
- Currency format

### 📊 Data Flow

```
[UI] → [BLoC Events] → [BLoC Logic] → [Hive DB] → [BLoC States] → [UI Update]
                                    ↓
                              [Sync Service] ← → [Backend API]
```

### 🎨 Customization

**Ubah Warna:**

```dart
// lib/core/theme/app_theme.dart
static const Color primaryColor = Color(0xFF2196F3); // Ubah ini
```

**Tambah Produk:**

```dart
// lib/core/utils/sample_data_service.dart
// Tambahkan ProductModel baru di array sampleProducts
```

**Ubah Layout:**

```dart
// lib/features/cashier/presentation/pages/cashier_page.dart
crossAxisCount: 4, // Ubah jumlah kolom grid
```

### 🐛 Troubleshooting

**Error "Box not found":**

```bash
flutter clean
flutter pub get
```

**Landscape tidak muncul:**

- Pastikan run di device/emulator yang support landscape
- Atau ubah di `main.dart` ke portrait mode

**Sample data tidak muncul:**

- Check console log
- Restart aplikasi

### 📝 Next Steps (Fitur Tambahan yang Bisa Ditambahkan)

1. ⬜ Barcode scanner integration
2. ⬜ Print receipt (thermal printer)
3. ⬜ Sync dengan backend server
4. ⬜ History transaksi
5. ⬜ Report harian/bulanan
6. ⬜ Customer management
7. ⬜ Multiple payment methods (Cash/Card/QRIS)
8. ⬜ Discount validation
9. ⬜ Stock alert
10. ⬜ Multi-language support

### 🚀 Test Aplikasi Sekarang!

```bash
cd d:\PROYEK\POS\pos_cashier
flutter run -d windows
```

Login → Pilih Produk → Bayar → Done! 🎉
