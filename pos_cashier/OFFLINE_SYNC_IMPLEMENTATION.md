# Implementasi Offline-Online Sync untuk POS Kasir

## 📋 Ringkasan

Aplikasi POS Kasir kini mendukung sinkronisasi offline-online yang lebih baik untuk menangani dataset besar (20,000+ produk) dengan fitur:

1. **Batch Download** - Download produk dalam batch 500 per halaman
2. **Incremental Sync** - Hanya sync produk yang berubah
3. **Progress Reporting** - Real-time progress saat download
4. **Smart Sync** - Otomatis pilih full sync atau incremental sync

## 🚀 Fitur Baru

### 1. ProductModel dengan Timestamp Tracking

**File:** `lib/features/cashier/data/models/product_model.dart`

Ditambahkan field baru:
- `updatedAt` - Server update timestamp untuk incremental sync
- `syncVersion` - Versi sync untuk conflict resolution

```dart
class ProductModel {
  final DateTime? lastSynced;     // Local sync timestamp
  final DateTime? updatedAt;      // Server update timestamp
  final int syncVersion;          // Sync version
}
```

### 2. API Service dengan Batch Support

**File:** `lib/core/network/api_service.dart`

Method baru:
- `getProductsCount()` - Dapatkan total jumlah produk
- `getProductsUpdatedSince()` - Dapatkan produk yang berubah setelah waktu tertentu

```dart
// Get total products
final total = await apiService.getProductsCount(branchId: '1');

// Get products updated since last sync
final updated = await apiService.getProductsUpdatedSince(
  since: lastSyncTime,
  branchId: '1',
  page: 1,
  limit: 500,
);
```

### 3. ProductRepository dengan Smart Sync

**File:** `lib/core/utils/product_repository.dart`

Implementasi:
- **Full Sync** - Download semua produk dalam batch 500
- **Incremental Sync** - Hanya download produk yang berubah
- **Progress Callback** - Report progress real-time

```dart
// Full sync dengan progress
await productRepository.syncProductsFromServer(
  force: true,  // Force full sync
  onProgress: (current, total) {
    print('Progress: $current / $total');
  },
);

// Incremental sync (otomatis jika ada lastSyncTime)
await productRepository.syncProductsFromServer();
```

**Alur Full Sync:**
1. Dapatkan total count produk dari server
2. Hitung jumlah batch (total ÷ 500)
3. Download batch demi batch
4. Simpan ke Hive local database
5. Report progress setiap batch
6. Simpan timestamp sync terakhir

**Alur Incremental Sync:**
1. Dapatkan timestamp sync terakhir
2. Request produk yang berubah sejak timestamp
3. Update produk yang berubah di local database
4. Simpan timestamp baru

### 4. SyncService dengan Progress Events

**File:** `lib/features/sync/data/datasources/sync_service.dart`

Method baru:
- `forceFullSync()` - Trigger full sync manual
- Stream `syncEvents` - Broadcast progress ke UI

```dart
// Listen to sync events
syncService.syncEvents.listen((event) {
  if (event.type == 'progress') {
    print('Syncing: ${event.message}');
  } else if (event.type == 'success') {
    print('Success: ${event.message}');
  } else if (event.type == 'error') {
    print('Error: ${event.message}');
  }
});

// Trigger full sync
await syncService.forceFullSync(
  onProgress: (current, total) {
    print('$current / $total');
  },
);
```

### 5. UI Components

#### SyncProgressOverlay
**File:** `lib/features/sync/presentation/widgets/sync_progress_overlay.dart`

Widget overlay untuk menampilkan progress sync di UI.

#### SyncSettingsPage
**File:** `lib/features/sync/presentation/pages/sync_settings_page.dart`

Halaman pengaturan sinkronisasi dengan:
- Status sinkronisasi (total produk, pending sales, last sync)
- Progress bar real-time
- Button Sinkronisasi Cepat (incremental)
- Button Sinkronisasi Penuh (full sync)
- Tips penggunaan

## 📊 Performance

### Dataset Besar (20,000 produk)

**Full Sync:**
- Batch size: 500 produk per request
- Total batches: 40 batch (20,000 ÷ 500)
- Estimasi waktu: ~2-3 menit (tergantung koneksi)
- Progress: Real-time update setiap batch

**Incremental Sync:**
- Hanya download produk yang berubah
- Estimasi waktu: ~5-30 detik (tergantung jumlah perubahan)
- Ideal untuk sync harian

### Memory Usage

- Batch processing mencegah memory overflow
- Hive database sangat efisien untuk local storage
- Setiap batch di-clear dari memory setelah disimpan

## 🎯 Cara Penggunaan

### 1. Akses Halaman Sync Settings

```dart
Navigator.pushNamed(context, '/sync-settings');
```

### 2. Sinkronisasi Cepat (Incremental)

Digunakan untuk update harian:
- Klik tombol "Sinkronisasi Cepat"
- Hanya download produk yang berubah sejak sync terakhir
- Cepat dan hemat bandwidth

### 3. Sinkronisasi Penuh (Full Sync)

Digunakan untuk:
- First time setup
- Data hilang atau corrupt
- Reset database

Cara:
- Klik tombol "Sinkronisasi Penuh"
- Konfirmasi dialog
- Tunggu progress bar selesai (2-3 menit)

### 4. Sinkronisasi Otomatis

Background sync berjalan otomatis:
- Interval: Setiap 5 menit
- Mode: Incremental sync
- Hanya saat online

## ⚙️ Konfigurasi Backend

### Endpoint yang Diperlukan

Backend perlu mendukung query parameter berikut:

```
GET /api/products?page=1&limit=500&isActive=true&branchId=1
```

Response:
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 500,
    "total": 20000,
    "totalPages": 40
  }
}
```

### Optional: Incremental Sync Endpoint

Untuk performa optimal, backend bisa support:

```
GET /api/products?updatedSince=2025-10-30T10:00:00Z
```

Response hanya produk yang berubah setelah timestamp tersebut.

## 🔧 Troubleshooting

### 1. Sync Gagal

**Penyebab:**
- Koneksi internet terputus
- Server timeout
- Memory penuh

**Solusi:**
- Cek koneksi internet
- Coba lagi dengan batch size lebih kecil
- Clear cache aplikasi

### 2. Produk Tidak Muncul

**Penyebab:**
- Filter `isActive=true` menghilangkan produk inactive
- Branch filter salah

**Solusi:**
- Cek status produk di server
- Cek branch ID yang digunakan
- Lakukan full sync ulang

### 3. Sync Terlalu Lama

**Penyebab:**
- Dataset terlalu besar
- Koneksi lambat
- Batch size terlalu kecil

**Solusi:**
- Gunakan incremental sync untuk update harian
- Full sync hanya saat diperlukan
- Tingkatkan batch size jika memory cukup

## 📈 Monitoring

### Cek Status Sync

```dart
final status = syncService.getSyncStatus();
print('Total products: ${status['total_products']}');
print('Pending sales: ${status['pending_sales']}');
print('Is online: ${status['is_online']}');
```

### Log Sync Activity

Semua aktivitas sync ter-log dengan prefix:
- `🔄` - Sync dimulai
- `📥` - Downloading
- `✅` - Success
- `❌` - Error
- `⚠️` - Warning

## 🎨 UI/UX Improvements

1. **Progress Bar** - Visual feedback saat download
2. **Percentage Display** - Tampilkan progres dalam %
3. **Time Estimate** - Estimasi waktu tersisa (optional)
4. **Cancelable Sync** - Kemampuan cancel sync (future)
5. **Sync History** - Log riwayat sync (future)

## 🔐 Best Practices

1. **Gunakan Incremental Sync** untuk operasi harian
2. **Full Sync** hanya saat setup atau ada masalah
3. **Monitor Memory** saat sync dataset besar
4. **Background Sync** untuk seamless experience
5. **Error Handling** yang robust dengan retry mechanism

## 📝 Catatan Penting

1. **Batch Size** - Default 500, bisa disesuaikan dengan memory device
2. **Timeout** - Sesuaikan timeout API untuk dataset besar
3. **Retry Logic** - Implementasi retry jika batch gagal (future)
4. **Conflict Resolution** - Gunakan `syncVersion` untuk handle konflik (future)

## 🔮 Future Enhancements

1. **Selective Sync** - Pilih kategori produk tertentu
2. **Delta Sync** - Hanya sync field yang berubah
3. **Compression** - Compress data transfer
4. **Background Worker** - Isolate untuk heavy processing
5. **Smart Scheduling** - Sync di waktu sepi (malam hari)
6. **Offline First** - Prioritas offline dengan eventual consistency
