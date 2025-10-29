# 📱 Aplikasi POS Kasir - Dokumentasi Lengkap

## 🎯 Ringkasan

**Aplikasi POS Kasir** adalah aplikasi Point of Sale yang didesain khusus untuk **kecepatan** dan **mode offline**. Berbeda dengan Management App yang fokus pada analytics dan manajemen online, aplikasi ini fokus pada transaksi kasir yang cepat dan reliable.

## 🌟 Keunggulan Utama

### ⚡ **Kecepatan Maksimal**

- **Response Time < 100ms** untuk semua operasi
- Database lokal (Hive) - tidak perlu tunggu server
- UI optimized untuk transaksi cepat
- Minimal navigation - semua dalam 1 layar

### 📴 **Offline-First**

- Bisa jalan 100% tanpa internet
- Semua data tersimpan di local database
- Auto-sync saat koneksi tersedia
- Queue system untuk transaksi pending

### 🎨 **UI untuk Kasir**

- Landscape mode (tablet-friendly)
- Full-screen mode
- Touch-optimized (button besar)
- Minimal distraction

### 🔄 **Smart Sync**

- Background sync otomatis
- Conflict resolution
- Retry mechanism
- Status indicator

## 📊 Perbandingan dengan Management App

| Aspek             | POS Kasir          | Management App            |
| ----------------- | ------------------ | ------------------------- |
| **Target User**   | Kasir toko         | Manager/Admin/Super Admin |
| **Fokus Utama**   | Transaksi cepat    | Analytics & Management    |
| **Mode Operasi**  | Offline-first      | Online-only               |
| **Database**      | Hive (Local NoSQL) | PostgreSQL (via API)      |
| **Orientasi**     | Landscape (tablet) | Portrait/Landscape        |
| **Navigation**    | Single page        | Multi-page with drawer    |
| **Sinkronisasi**  | Background, auto   | Real-time, always         |
| **UI Complexity** | Simple, minimal    | Rich, comprehensive       |
| **Performance**   | Instant response   | Network dependent         |

## 🏗️ Arsitektur

### Clean Architecture + BLoC Pattern

```
Presentation Layer (UI)
    ├── Pages (Views)
    ├── Widgets (Components)
    └── BLoC (State Management)
          ↓
Domain Layer
    ├── Models (Entities)
    └── Use Cases (Business Logic)
          ↓
Data Layer
    ├── Local Data Source (Hive)
    └── Remote Data Source (API)
```

### Data Flow

```
User Action → Event → BLoC → Local DB (Hive)
                        ↓
                     State → UI Update
                        ↓
                  Background Sync → Server
```

## 📁 Struktur File Detail

```
lib/
├── main.dart                           # Entry point
│
├── core/                              # Core utilities
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   ├── database/
│   │   └── hive_service.dart          # Hive database service
│   ├── network/
│   │   └── api_service.dart           # HTTP client (Dio)
│   ├── theme/
│   │   └── app_theme.dart             # Material theme
│   └── utils/
│       ├── currency_formatter.dart    # Format currency (Rupiah)
│       └── sample_data_service.dart   # Sample data loader
│
└── features/                          # Feature modules
    ├── auth/                          # Authentication
    │   └── presentation/
    │       └── pages/
    │           └── login_page.dart    # Login screen
    │
    ├── cashier/                       # Main cashier feature
    │   ├── data/
    │   │   └── models/
    │   │       ├── product_model.dart     # Product entity
    │   │       ├── cart_item_model.dart   # Cart item entity
    │   │       └── sale_model.dart        # Sale/transaction entity
    │   │
    │   └── presentation/
    │       ├── bloc/
    │       │   └── cashier_bloc.dart      # Cashier business logic
    │       └── pages/
    │           └── cashier_page.dart      # Main cashier UI
    │
    └── sync/                          # Synchronization
        └── data/
            └── datasources/
                └── sync_service.dart      # Background sync service
```

## 🔑 Fitur Utama

### 1. **Authentication**

- Simple login untuk kasir
- Session management
- Auto-logout after idle

### 2. **Product Management**

- Grid view produk
- Real-time search
- Barcode scanning (ready for integration)
- Category filtering

### 3. **Shopping Cart**

- Add/remove items
- Update quantity
- Real-time total calculation
- Item-level discount
- Global discount

### 4. **Payment Processing**

- Cash payment
- Card payment (ready)
- QRIS payment (ready)
- Change calculation
- Receipt generation

### 5. **Offline Storage**

- All products cached locally
- Transactions saved locally
- Customer data cached
- Settings persisted

### 6. **Background Sync**

- Auto-sync every 5 minutes
- Manual sync option
- Sync on connection restore
- Queue failed transactions

## 🗄️ Database Schema (Hive)

### Products Box

```dart
{
  'id': String,
  'barcode': String,
  'name': String,
  'description': String?,
  'price': double,
  'stock': int,
  'category_id': String?,
  'category_name': String?,
  'image_url': String?,
  'is_active': bool,
  'last_synced': DateTime?
}
```

### Sales Box

```dart
{
  'id': String,
  'invoice_number': String,
  'transaction_date': DateTime,
  'items': List<CartItem>,
  'subtotal': double,
  'discount': double,
  'tax': double,
  'total': double,
  'paid': double,
  'change': double,
  'payment_method': String,
  'customer_id': String?,
  'cashier_id': String,
  'is_synced': bool,
  'synced_at': DateTime?
}
```

### Categories Box

```dart
{
  'id': String,
  'name': String,
  'icon': String
}
```

## 🎯 State Management (BLoC)

### Events

- `AddToCart` - Tambah produk ke cart
- `RemoveFromCart` - Hapus produk dari cart
- `UpdateCartItemQuantity` - Update jumlah item
- `ApplyDiscountToItem` - Diskon per item
- `ApplyGlobalDiscount` - Diskon keseluruhan
- `ClearCart` - Kosongkan cart
- `ProcessPayment` - Proses pembayaran

### States

- `CashierInitial` - State awal (cart kosong)
- `CashierLoaded` - Cart ada isi
- `PaymentProcessing` - Sedang proses payment
- `PaymentSuccess` - Payment berhasil
- `CashierError` - Error state

## 🔄 Synchronization Strategy

### Download from Server (Priority: High)

1. Master products
2. Product prices
3. Stock updates
4. Categories
5. Customers

### Upload to Server (Priority: Normal)

1. Completed transactions
2. New customers
3. Stock adjustments

### Conflict Resolution

- Server data always wins for master data
- Local transactions always preserved
- Timestamp-based for stock updates

## 🚀 Performance Optimization

### 1. **Local Database**

- Hive is 10x faster than SQLite
- In-memory caching
- Lazy loading
- Indexed searches

### 2. **UI Optimization**

- Widget reuse
- Const constructors
- Efficient rebuilds with BLoC
- Image caching

### 3. **Network Optimization**

- Background sync only
- Batch operations
- Compression
- Connection pooling

## 🔒 Security

- JWT token authentication
- Local data encryption (optional)
- Session timeout
- Role-based access

## 📱 Device Support

### Recommended

- **Tablet** 10-13 inch
- **Landscape orientation**
- **Touch screen**
- Windows/Android

### Minimum Requirements

- Screen: 7 inch
- RAM: 2GB
- Storage: 100MB
- OS: Windows 10+, Android 6+

## 🎨 Customization Guide

### Colors

Edit `lib/core/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF2196F3);
static const Color secondaryColor = Color(0xFF4CAF50);
```

### Currency

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String currency = 'Rp';
```

### Tax Rate

Edit `cashier_bloc.dart` → `_calculateTotals()`:

```dart
final taxRate = 0.1; // 10%
```

### Sync Interval

Edit `app_constants.dart`:

```dart
static const Duration syncInterval = Duration(minutes: 5);
```

## 🧪 Testing

### Run Tests

```bash
flutter test
```

### Test Coverage

```bash
flutter test --coverage
```

## 📦 Build & Deployment

### Windows

```bash
flutter build windows --release
```

### Android

```bash
flutter build apk --release
```

### Web (Not recommended for offline-first)

```bash
flutter build web --release
```

## 🐛 Troubleshooting

### Problem: Hive Error

**Solution:**

```bash
flutter clean
flutter pub get
rm -rf build
```

### Problem: Sync Not Working

**Check:**

1. Internet connection
2. Server status
3. API endpoint configuration
4. Auth token valid

### Problem: Performance Slow

**Check:**

1. Clear Hive cache
2. Reduce product count
3. Optimize images
4. Check memory usage

## 📚 Dependencies

### Production

- `flutter_bloc` - State management
- `hive` & `hive_flutter` - Local database
- `dio` - HTTP client
- `connectivity_plus` - Network status
- `intl` - Internationalization
- `equatable` - Value equality
- `uuid` - Unique IDs

### Development

- `flutter_lints` - Code quality
- `hive_generator` - Code generation
- `build_runner` - Build tools

## 🔮 Future Enhancements

1. **Barcode Integration** ✅ Ready for integration
2. **Thermal Printer** ✅ API ready
3. **Customer Display** (secondary screen)
4. **Cash Drawer Integration**
5. **Multi-currency Support**
6. **Advanced Analytics**
7. **Loyalty Program**
8. **Employee Time Tracking**
9. **Inventory Management**
10. **Multiple Payment Split**

## 📞 Support & Contact

Untuk bantuan teknis atau pertanyaan:

- Developer: POS Team
- Email: support@pos-system.com
- Documentation: [Link to docs]

---

**Built with ❤️ using Flutter**

Last Updated: October 29, 2025
Version: 1.0.0
