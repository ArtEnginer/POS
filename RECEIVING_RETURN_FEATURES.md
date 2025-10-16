# Receiving & Return Purchase - Update Documentation

## Fitur Yang Ditambahkan

### 1. **Receiving History & Actions** ✅

Fitur ini menambahkan kemampuan untuk melihat, mengedit, menghapus, dan mencetak penerimaan barang yang sudah dibuat.

#### File yang Dibuat/Diubah:

- `lib/features/purchase/presentation/pages/receiving_history_page.dart` - Halaman daftar riwayat receiving
- `lib/features/purchase/presentation/pages/receiving_detail_page.dart` - Halaman detail & print receiving
- `lib/features/purchase/presentation/pages/receiving_list_page.dart` - Ditambahkan menu navigasi ke history

#### Cara Menggunakan:

1. Buka menu **"Penerimaan Barang (Receiving)"**
2. Klik icon **History** di toolbar untuk melihat riwayat receiving
3. Pada setiap receiving, tersedia 3 action buttons:
   - **Print**: Mencetak bukti penerimaan barang (PDF)
   - **Edit**: Mengedit receiving (akan load data PO terkait)
   - **Hapus**: Menghapus receiving dengan konfirmasi

### 2. **Return Purchase (Retur Pembelian)** ✅

Fitur return pembelian untuk mengembalikan barang yang sudah diterima ke supplier.

#### File yang Dibuat:

**Domain Layer:**

- `lib/features/purchase/domain/entities/purchase_return.dart` - Entity untuk return & items
- `lib/features/purchase/domain/repositories/purchase_return_repository.dart` - Repository interface
- `lib/features/purchase/domain/usecases/purchase_return_usecases.dart` - Use cases (CRUD + generate number)

**Data Layer:**

- `lib/features/purchase/data/models/purchase_return_model.dart` - Model dengan JSON serialization
- `lib/features/purchase/data/datasources/purchase_return_local_data_source.dart` - SQLite operations
- `lib/features/purchase/data/repositories/purchase_return_repository_impl.dart` - Repository implementation

**Presentation Layer:**

- `lib/features/purchase/presentation/bloc/purchase_return_event.dart` - Events
- `lib/features/purchase/presentation/bloc/purchase_return_state.dart` - States
- `lib/features/purchase/presentation/bloc/purchase_return_bloc.dart` - BLoC logic
- `lib/features/purchase/presentation/pages/purchase_return_list_page.dart` - Daftar receiving untuk di-return
- `lib/features/purchase/presentation/pages/purchase_return_form_page.dart` - Form membuat return

**Database:**

- `lib/core/database/database_helper.dart` - Ditambahkan tabel `purchase_returns` dan `purchase_return_items`
- `lib/core/constants/app_constants.dart` - Database version updated to 6

**Dependency Injection:**

- `lib/injection_container.dart` - Registrasi semua dependencies purchase return

#### Cara Menggunakan:

1. Navigasi ke halaman **"Return Pembelian"**
2. Pilih receiving yang ingin di-return (hanya yang berstatus COMPLETED)
3. Pada form return:
   - Isi alasan return (wajib)
   - Pilih item yang akan di-return dan tentukan quantity
   - Bisa tambahkan alasan spesifik per item (opsional)
   - Isi nama petugas dan catatan tambahan (opsional)
4. Klik **"Simpan Return Pembelian"**

#### Fitur Return:

- ✅ Generate nomor return otomatis (format: RTN-YYYYMM-0001)
- ✅ Return berdasarkan receiving yang sudah completed
- ✅ Pilih item dan quantity yang akan di-return
- ✅ Alasan return (global dan per item)
- ✅ Auto calculate subtotal, discount, tax proportionally
- ✅ Stock adjustment otomatis (mengurangi stock saat return completed)
- ✅ Validasi quantity (tidak boleh melebihi qty yang diterima)

## Struktur Database Baru

### Tabel: `purchase_returns`

```sql
- id (TEXT PRIMARY KEY)
- return_number (TEXT UNIQUE NOT NULL)
- receiving_id (TEXT NOT NULL, FK to receivings)
- receiving_number (TEXT NOT NULL)
- purchase_id (TEXT NOT NULL, FK to purchases)
- purchase_number (TEXT NOT NULL)
- supplier_id (TEXT)
- supplier_name (TEXT)
- return_date (TEXT NOT NULL)
- subtotal (REAL NOT NULL)
- item_discount (REAL DEFAULT 0)
- item_tax (REAL DEFAULT 0)
- total_discount (REAL DEFAULT 0)
- total_tax (REAL DEFAULT 0)
- total (REAL NOT NULL)
- status (TEXT DEFAULT 'DRAFT') -- DRAFT, COMPLETED, CANCELLED
- reason (TEXT) -- Alasan return
- notes (TEXT)
- processed_by (TEXT)
- sync_status (TEXT DEFAULT 'PENDING')
- created_at (TEXT NOT NULL)
- updated_at (TEXT NOT NULL)
```

### Tabel: `purchase_return_items`

```sql
- id (TEXT PRIMARY KEY)
- return_id (TEXT NOT NULL, FK to purchase_returns)
- receiving_item_id (TEXT NOT NULL, FK to receiving_items)
- product_id (TEXT NOT NULL, FK to products)
- product_name (TEXT NOT NULL)
- received_quantity (INTEGER NOT NULL) -- Qty yang diterima
- return_quantity (INTEGER NOT NULL) -- Qty yang di-return
- price (REAL NOT NULL)
- discount (REAL DEFAULT 0)
- discount_type (TEXT DEFAULT 'AMOUNT')
- tax (REAL DEFAULT 0)
- tax_type (TEXT DEFAULT 'AMOUNT')
- subtotal (REAL NOT NULL)
- total (REAL NOT NULL)
- reason (TEXT) -- Alasan return item ini
- notes (TEXT)
- created_at (TEXT NOT NULL)
```

## Fitur Stock Management

### Auto Stock Adjustment:

- **Saat Create Return (COMPLETED)**: Stock produk dikurangi sesuai qty return
- **Saat Update Return**:
  - Reverse adjustment lama
  - Apply adjustment baru
- **Saat Delete Return**: Stock di-restore sesuai qty return yang dihapus

## Testing

Untuk testing fitur ini:

1. **Reset Database** (jika diperlukan):

   ```powershell
   .\reset_database.ps1
   ```

2. **Test Flow**:
   - Buat Purchase Order (PO)
   - Approve PO
   - Proses Receiving
   - Lihat di Receiving History
   - Print bukti receiving
   - Buat Return dari receiving
   - Check stock adjustment

## Navigasi Menu

Untuk mengakses fitur-fitur baru, tambahkan menu navigasi di dashboard/main menu:

```dart
// Menu untuk Receiving History
ListTile(
  leading: Icon(Icons.history),
  title: Text('Riwayat Penerimaan'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ReceivingBloc>(),
          child: ReceivingHistoryPage(),
        ),
      ),
    );
  },
),

// Menu untuk Return Purchase
ListTile(
  leading: Icon(Icons.assignment_return),
  title: Text('Return Pembelian'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<ReceivingBloc>()),
            BlocProvider(create: (_) => sl<PurchaseReturnBloc>()),
          ],
          child: PurchaseReturnListPage(),
        ),
      ),
    );
  },
),
```

## Dependencies Baru

Pastikan package berikut sudah ada di `pubspec.yaml`:

- `printing: ^5.11.0` - Untuk PDF printing
- `pdf: ^3.10.4` - Untuk generate PDF
- `uuid: ^4.0.0` - Untuk generate ID

## Notes

- Return hanya bisa dibuat dari receiving dengan status COMPLETED
- Qty return tidak boleh melebihi qty yang diterima
- Stock akan otomatis disesuaikan saat return completed
- Nomor return generate otomatis dengan format RTN-YYYYMM-XXXX
- Semua perhitungan discount dan tax menggunakan proporsi

## Troubleshooting

### Error: Table doesn't exist

Jalankan reset database atau pastikan app version di-upgrade untuk trigger migration:

```powershell
.\reset_database.ps1
```

### Stock tidak update

Pastikan status return adalah "COMPLETED". Hanya return dengan status completed yang mengupdate stock.

### Print tidak bekerja

Pastikan package `printing` dan `pdf` sudah terinstall dengan benar.
