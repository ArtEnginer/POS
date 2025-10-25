# 🏪 SuperPOS - Enterprise Point of Sale System

Modern POS system built with **Flutter 3.29** & **Clean Architecture**, powered by **Node.js + PostgreSQL + Redis + Socket.IO** backend for real-time sync and scalability.

## 🚀 Tech Stack

### **Backend V2** (Production-Ready)
- **PostgreSQL 16** - Primary database (ACID compliant, scalable)
- **Redis 7** - Caching layer & real-time sync queue
- **Node.js 20 + Express 4** - RESTful API server
- **Socket.IO 4** - Real-time bidirectional communication
- **PM2** - Process manager for production deployment
- **JWT** - Secure authentication (15min access, 7day refresh)

### **Frontend** (Flutter)
- **Flutter 3.29.1 / Dart 3.7.0** - Cross-platform framework
- **BLoC Pattern** - State management
- **Clean Architecture** - Domain/Data/Presentation separation
- **SQLite** - Local cache for offline-first experience
- **Dio** - HTTP client with interceptors
- **Socket.IO Client** - Real-time updates
- **GetIt** - Dependency injection

## ✨ Features

### ✅ **Fully Implemented**
- 🔐 **Authentication** - JWT-based secure login with token refresh
- 📦 **Product Management** - Full CRUD with categories, stock tracking
- 👥 **Customer Management** - Customer profiles with transaction history
- 🏢 **Supplier Management** - Supplier data with purchase tracking
- 🛒 **POS/Sales** - Fast checkout with cart, discounts, payment methods
- 📥 **Purchase & Receiving** - Purchase orders with receiving workflow
- � **Purchase Returns** - Return defective/incorrect items
- 🌐 **Multi-Branch Support** - Tenant isolation for multiple locations
- 🔄 **Real-time Sync** - Socket.IO broadcasts all entity changes
- 📴 **Offline Mode** - Works without internet, syncs when available
- 🎨 **Modern UI/UX** - Material Design 3 with professional theme

### 🎯 **Architecture Highlights**
- ✨ **Clean Architecture** - Testable, maintainable, scalable
- �️ **Offline-First** - SQLite cache, Backend as source of truth
- � **Auto-Sync** - Socket.IO real-time updates across all clients
- 🏢 **Multi-Tenant** - Branch-level data isolation
- � **Secure** - JWT auth, role-based access control
- � **RESTful API** - Standard HTTP endpoints for all operations
- 🖨️ **Print Receipt** - Cetak struk belanja
- 📈 **Stock Management** - Tracking stok dan notifikasi low stock

## 🏗️ Arsitektur Proyek

```
lib/
├── core/                          # Core functionality
│   ├── constants/                 # App constants, colors, text styles
│   ├── database/                  # Local database setup (SQLite)
│   ├── error/                     # Error handling (Failures & Exceptions)
│   ├── network/                   # API client & network info
│   ├── sync/                      # Sync manager for data synchronization
│   └── theme/                     # App theme configuration
│
├── features/                      # Feature modules
│   ├── product/                   # Product management feature
│   │   ├── data/
│   │   │   ├── datasources/      # Local & remote data sources
│   │   │   ├── models/           # Data models
│   │   │   └── repositories/     # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/         # Business entities
│   │   │   ├── repositories/     # Repository interfaces
│   │   │   └── usecases/         # Business logic use cases
│   │   └── presentation/
│   │       ├── bloc/             # State management (BLoC)
│   │       ├── pages/            # UI pages
│   │       └── widgets/          # Reusable widgets
│   │
│   └── dashboard/                 # Dashboard feature
│       └── presentation/
│           └── pages/
│
├── injection_container.dart       # Dependency injection setup
└── main.dart                      # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.0 atau lebih tinggi
- Dart SDK 3.7.0 atau lebih tinggi
- Android Studio / VS Code

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run aplikasi**
   ```bash
   flutter run
   ```

## 📦 Dependencies Utama

### State Management
- `flutter_bloc` - State management dengan BLoC pattern
- `equatable` - Value equality

### Database
- `sqflite` - SQLite database untuk local storage
- `hive` - NoSQL database untuk caching

### Network
- `dio` - HTTP client untuk API calls
- `connectivity_plus` - Check koneksi internet

### Dependency Injection
- `get_it` - Service locator untuk DI

### UI/UX
- `google_fonts` - Custom fonts
- `animations` - Advanced animations

### Hardware Integration
- `mobile_scanner` - Barcode/QR scanner
- `qr_flutter` - QR code generator
- `printing` - Print receipts

## 🔧 Konfigurasi

### Database Configuration
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String localDatabaseName = 'pos_local.db';
static const Duration syncInterval = Duration(minutes: 5);
```

### API Configuration
Update base URL di `app_constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com/api/v1';
```

## 🗄️ Database Schema

### Tables
1. **products** - Data produk
2. **categories** - Kategori produk
3. **transactions** - Transaksi penjualan
4. **transaction_items** - Item dalam transaksi
5. **customers** - Data pelanggan
6. **users** - Data pengguna/kasir
7. **stock_movements** - Pergerakan stok
8. **sync_queue** - Antrian sinkronisasi
9. **settings** - Pengaturan aplikasi

## 🔄 Sistem Sinkronisasi

### Cara Kerja
1. **Write Operations** → Simpan ke database lokal + tambahkan ke sync queue
2. **Periodic Sync** → Setiap 5 menit (configurable)
3. **Manual Sync** → Tombol sync di UI
4. **Retry Mechanism** → Max 3x retry

### Sync Status
- `PENDING` - Menunggu sync
- `SYNCED` - Sudah tersinkronisasi
- `FAILED` - Gagal sync
- `CONFLICT` - Terjadi konflik data

## 🎨 Design System

### Colors
- **Primary**: Blue (#1E88E5)
- **Secondary**: Orange (#FF6F00)
- **Success**: Green (#4CAF50)
- **Error**: Red (#E53935)

### Typography
- **Font Family**: Inter (via Google Fonts)

## 📱 Build & Release

### Android
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## 🗺️ Roadmap

### Phase 1 - Foundation (Current)
- ✅ Project setup & architecture
- ✅ Database & sync infrastructure
- ✅ Basic UI framework

### Phase 2 - Core Features
- ⏳ POS/Cashier interface
- ⏳ Product management
- ⏳ Transaction processing

### Phase 3 - Advanced Features
- ⏳ Reports & analytics
- ⏳ Multi-payment methods
- ⏳ Receipt printing

---

**Made with ❤️ using Flutter**
