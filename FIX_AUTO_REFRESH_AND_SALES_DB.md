# FIX: Auto-Refresh POS & Database Sales

## Masalah yang Diperbaiki

### 1. **Auto-Refresh Data di Halaman POS**
**Masalah:** Ketika menambah produk di halaman Product atau menambah customer di halaman Customer, halaman POS tidak otomatis refresh dengan data baru.

**Solusi:**
- Menambahkan `WidgetsBindingObserver` untuk mendeteksi lifecycle aplikasi
- Ketika aplikasi/window menjadi aktif kembali (`AppLifecycleState.resumed`), data otomatis di-refresh
- Menambahkan `BlocListener` untuk `ProductBloc` dan `CustomerBloc` yang akan auto-refresh ketika ada operasi sukses (tambah/edit)
- Menambahkan tombol refresh manual di AppBar untuk refresh data produk dan customer

**Perubahan:**
```dart
class _POSPageState extends State<POSPage> with WidgetsBindingObserver {
  // ... existing code ...
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadInitialData(); // Auto refresh when app becomes active
    }
  }

  void _loadInitialData() {
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<CustomerBloc>().add(LoadAllCustomers());
    _generateSaleNumber();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ... dispose controllers ...
  }
}
```

**BlocListener untuk auto-refresh:**
```dart
MultiBlocListener(
  listeners: [
    // ... existing SaleBloc listener ...
    
    BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          context.read<ProductBloc>().add(const LoadProducts());
        }
      },
    ),
    BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerOperationSuccess) {
          context.read<CustomerBloc>().add(LoadAllCustomers());
        }
      },
    ),
  ],
  // ... child ...
)
```

### 2. **Error: Field `cashier_name` Tidak Ada**
**Masalah:** Database tabel `transactions` tidak memiliki kolom `cashier_name`, menyebabkan error saat menyimpan transaksi penjualan.

**Solusi:**
- Menambahkan kolom `cashier_name TEXT NOT NULL` ke tabel `transactions`
- Membuat migration script (version 8) untuk database yang sudah ada
- Update untuk memberikan nilai default "Kasir" pada record yang sudah ada

**Perubahan Database Schema:**
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  transaction_number TEXT UNIQUE NOT NULL,
  customer_id TEXT,
  cashier_id TEXT NOT NULL,
  cashier_name TEXT NOT NULL,  -- FIELD BARU
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

**Migration Code (database_helper.dart):**
```dart
if (oldVersion < 8) {
  // Add cashier_name to transactions table if it doesn't exist
  try {
    await db.execute('ALTER TABLE transactions ADD COLUMN cashier_name TEXT');
  } catch (e) {
    // Column might already exist, ignore error
  }
  
  // Set default value for existing records
  await db.execute('UPDATE transactions SET cashier_name = "Kasir" WHERE cashier_name IS NULL');
}
```

## File yang Diubah

1. **lib/core/database/database_helper.dart**
   - Tambah kolom `cashier_name` di tabel `transactions`
   - Tambah migration untuk version 8

2. **lib/core/constants/app_constants.dart**
   - Update `localDatabaseVersion` dari 7 ke 8

3. **lib/features/sales/presentation/pages/pos_page.dart**
   - Tambah `WidgetsBindingObserver` mixin
   - Implementasi `didChangeAppLifecycleState` untuk auto-refresh
   - Tambah listener untuk ProductBloc dan CustomerBloc
   - Tambah tombol refresh manual di AppBar
   - Extract reload logic ke method `_loadInitialData()`

4. **migrate_sales_database.ps1** (NEW)
   - Script PowerShell untuk informasi migrasi database

## Cara Penggunaan

### Auto-Refresh Otomatis
1. Buka halaman POS
2. Buka tab/window lain dan tambah produk baru di halaman Product
3. Kembali ke halaman POS → Data otomatis ter-refresh ✓

### Manual Refresh
- Klik tombol "Refresh Data" (icon reload) di AppBar untuk memuat ulang produk dan customer
- Klik tombol "Reset Transaksi" (icon refresh) untuk mereset keranjang

### Migrasi Database (Opsional)
```powershell
# Jika ingin melihat info migrasi
.\migrate_sales_database.ps1
```

Atau cukup jalankan aplikasi, database akan otomatis di-upgrade:
```powershell
flutter run -d windows
```

## Testing Scenario

### Test 1: Auto-Refresh dengan App Lifecycle
1. ✅ Buka aplikasi POS
2. ✅ Buka tab/window baru → Edit/Tambah product
3. ✅ Kembali ke window POS
4. ✅ Data produk otomatis ter-update

### Test 2: Auto-Refresh dengan BlocListener
1. ✅ Halaman POS terbuka
2. ✅ Navigate ke halaman Product → Tambah produk baru
3. ✅ Kembali ke halaman POS (via navigation)
4. ✅ Produk baru langsung muncul di grid

### Test 3: Manual Refresh
1. ✅ Klik tombol "Refresh Data" di AppBar
2. ✅ Produk dan customer ter-reload

### Test 4: Transaksi dengan cashier_name
1. ✅ Tambah produk ke keranjang
2. ✅ Proses transaksi
3. ✅ Simpan ke database tanpa error
4. ✅ Field `cashier_name` terisi dengan benar

## Catatan Penting

1. **Database Baru:** Jika database belum ada, akan otomatis dibuat dengan schema terbaru (version 8)
2. **Database Lama:** Jika database sudah ada, akan otomatis di-upgrade ke version 8 saat aplikasi dijalankan
3. **Data Existing:** Record transaksi yang sudah ada akan diberi nilai default `cashier_name = "Kasir"`
4. **Backward Compatible:** Perubahan ini tidak merusak data yang sudah ada

## Fitur Tambahan

1. **Double Refresh Button:**
   - 🔄 (Replay icon) = Refresh data produk & customer
   - ♻️ (Refresh icon) = Reset transaksi/keranjang

2. **Smart Refresh:**
   - Auto-refresh saat aplikasi menjadi aktif
   - Auto-refresh saat ada operasi sukses di Product/Customer
   - Manual refresh tersedia kapan saja

## Versi Database

- **Sebelumnya:** Version 7 (tanpa cashier_name)
- **Sekarang:** Version 8 (dengan cashier_name)

## Kompatibilitas

- ✅ Windows Desktop
- ✅ Data existing tetap aman
- ✅ Tidak perlu manual migration
- ✅ Auto-upgrade saat aplikasi dijalankan
