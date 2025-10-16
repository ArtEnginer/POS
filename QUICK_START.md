# 🚀 Panduan Cepat - SuperPOS

## Selamat Datang! 👋

Anda baru saja mendapatkan proyek **SuperPOS** - sistem Point of Sale profesional dengan arsitektur yang solid dan siap dikembangkan!

---

## ✅ Apa yang Sudah Siap?

### 1. Infrastruktur Lengkap
- ✨ Clean Architecture (Domain, Data, Presentation)
- 🗄️ Database SQLite dengan 9 tabel
- 🔄 Sistem sinkronisasi otomatis lokal ↔ remote
- 🎨 Design system profesional
- 📱 UI responsif untuk mobile & tablet

### 2. Feature Product (Backend Complete)
- Entity, Model, Repository
- 9 Use Cases siap pakai
- BLoC untuk state management
- Data source dengan SQLite

---

## 🎯 Langkah Selanjutnya

### Option 1: Lanjutkan Develop Product Management 📦
Develop UI untuk manajemen produk yang backend-nya sudah ready.

**File yang perlu dibuat:**
```
lib/features/product/presentation/pages/
├── product_list_page.dart        ⏳ NEXT
├── product_detail_page.dart      ⏳ TODO
└── product_form_page.dart        ⏳ TODO
```

**Estimasi**: 2-3 hari

### Option 2: Build POS/Kasir Interface 🛒
Buat interface kasir untuk transaksi penjualan.

**Yang perlu dibuat:**
1. Transaction backend (entity, use cases, repository, BLoC)
2. POS UI (product search, cart, payment)
3. Barcode scanner integration
4. Print receipt

**Estimasi**: 3-4 hari

---

## 📚 Dokumentasi Tersedia

Baca file-file ini untuk memahami proyek:

### 1. **README.md** 📖
- Overview proyek lengkap
- Cara install & run
- Struktur database
- Konfigurasi

### 2. **DEVELOPMENT_GUIDE.md** 👨‍💻
- Panduan pengembangan step-by-step
- Clean Architecture explained
- Cara menambah feature baru
- Best practices
- Troubleshooting

### 3. **TODO.md** ✅
- Task list lengkap
- Progress tracking
- Prioritas development
- Testing plan

### 4. **PROJECT_SUMMARY.md** 📊
- Summary lengkap apa yang sudah dibuat
- Technologies used
- Next steps
- Estimasi waktu

---

## 🏃 Cara Menjalankan

### 1. Buka Terminal
```bash
cd d:\DOKUMEN\EDP\angga\FLUTTER\pos
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Aplikasi
```bash
flutter run
```

### 4. Build APK (Optional)
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

---

## 🎨 Preview Aplikasi

Saat ini aplikasi menampilkan:
- ✅ Splash screen dengan logo
- ✅ Dashboard dengan 5 tab:
  - Kasir (placeholder)
  - Produk (placeholder)
  - Transaksi (placeholder)
  - Laporan (placeholder)
  - Pengaturan (with settings list)

---

## 📝 Contoh: Membuat Product List Page

Berikut contoh cara membuat halaman list produk:

### 1. Buat File Baru
```
lib/features/product/presentation/pages/product_list_page.dart
```

### 2. Template Dasar
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ProductBloc>()
        ..add(const event.LoadProducts()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Produk'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Navigate to form
              },
            ),
          ],
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ProductError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }

            if (state is ProductLoaded) {
              final products = state.products;

              if (products.isEmpty) {
                return const Center(
                  child: Text('Belum ada produk'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(product.name[0]),
                      ),
                      title: Text(product.name),
                      subtitle: Text('Rp ${product.sellingPrice}'),
                      trailing: Text('Stok: ${product.stock}'),
                      onTap: () {
                        // Navigate to detail
                      },
                    ),
                  );
                },
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
```

### 3. Integrasikan ke Dashboard
Edit file `dashboard_page.dart`, ganti placeholder `ProductsPage` dengan `ProductListPage` yang baru dibuat.

---

## 🔧 Konfigurasi Penting

### 1. API Base URL
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com/api/v1';
```

### 2. Company Info
```dart
static const String companyName = 'Toko Anda';
static const String appName = 'POS Toko Anda';
```

### 3. Sync Settings
```dart
// Interval sync (default: 5 menit)
static const Duration syncInterval = Duration(minutes: 5);

// Retry attempts (default: 3x)
static const int maxRetryAttempts = 3;
```

---

## 💡 Tips Development

### 1. Hot Reload
Setelah save file, Flutter otomatis reload:
- **Hot Reload**: `r` atau `Ctrl+S`
- **Hot Restart**: `R`

### 2. Debug Mode
Gunakan `print()` atau `debugPrint()` untuk debugging:
```dart
print('Product: ${product.name}');
debugPrint('Stock: ${product.stock}');
```

### 3. Logger
Atau gunakan logger yang sudah disediakan:
```dart
final logger = sl<Logger>();
logger.i('Info message');
logger.e('Error message');
logger.w('Warning message');
```

### 4. BLoC DevTools
Install ekstensi BLoC Inspector di IDE untuk monitoring state.

### 5. Database Inspector
Gunakan tools seperti **DB Browser for SQLite** untuk inspect database.

---

## 🐛 Troubleshooting

### Error: "No Firebase App"
- Abaikan, Firebase belum di-setup (tidak diperlukan untuk local development)

### Error: "Failed to load image"
- Normal, karena belum ada product images

### Build Error
```bash
# Clean & rebuild
flutter clean
flutter pub get
flutter run
```

### Database Error
```bash
# Reset database: uninstall app & reinstall
flutter clean
flutter run
```

---

## 📱 Testing di Device

### Android
1. Enable **Developer Mode** di HP
2. Enable **USB Debugging**
3. Sambungkan ke PC via USB
4. Run `flutter run`

### iOS (Mac only)
1. Sambungkan iPhone
2. Trust computer
3. Run `flutter run`

### Emulator
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

---

## 📊 Project Stats

```
Files Created:     50+
Lines of Code:     ~5,000
Features:          1 (Product - 40%)
Database Tables:   9
Dependencies:      40+
Documentation:     4 files
```

---

## 🎯 Roadmap Singkat

### Week 1-2: Core Features
- [ ] Product Management UI
- [ ] POS/Kasir Interface
- [ ] Transaction Processing

### Week 3: Additional Features
- [ ] Customer Management
- [ ] Transaction History
- [ ] Basic Reports

### Week 4: Polish & Testing
- [ ] UI improvements
- [ ] Testing
- [ ] Bug fixes
- [ ] Documentation updates

---

## 🤝 Need Help?

### Resources
- 📖 Flutter Docs: https://flutter.dev/docs
- 📖 BLoC Docs: https://bloclibrary.dev
- 📖 Dart Docs: https://dart.dev

### Common Commands
```bash
# Check Flutter installation
flutter doctor

# Analyze code
flutter analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Check outdated packages
flutter pub outdated
```

---

## ✨ Ready to Code!

Sekarang Anda siap untuk mulai develop! 

**Rekomendasi**: Mulai dengan membuat **Product List Page** karena backend-nya sudah 100% ready.

Selamat coding! 🚀

---

*Last Updated: October 16, 2025*
*Version: 1.0.0-dev*
