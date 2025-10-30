# Sync Header Notification - UI Enhancement

## 📢 Perubahan: Notifikasi Sync di Header

### Sebelumnya:
- ❌ Menggunakan SnackBar yang muncul dari bawah
- ❌ Mengganggu interaksi user
- ❌ Bisa tertutup oleh widget lain

### Sekarang:
- ✅ **Header Notification** yang muncul dari atas dengan animasi smooth
- ✅ **Tidak mengganggu** - berada di atas konten, tidak blocking
- ✅ **Animated** - slide down dari top dengan fade-in
- ✅ **Auto-hide** untuk success, persistent untuk progress
- ✅ **Visual feedback** yang lebih jelas

## 🎨 Fitur

### 1. Animasi Smooth
```dart
// Slide down from top
Transform.translate(
  offset: Offset(0, _slideAnimation.value), // -100 to 0
  child: ...
)

// Fade in
Opacity(
  opacity: _fadeAnimation.value, // 0 to 1
  child: ...
)
```

**Durasi:** 300ms dengan `Curves.easeOutCubic`

### 2. Warna Berdasarkan Status

| Status | Warna | Icon |
|--------|-------|------|
| Progress | Blue | CircularProgressIndicator |
| Success | Green | check_circle |
| Error | Red | error_outline |

### 3. Behavior

**Progress:**
- Muncul saat sync dimulai
- Tetap tampil selama proses sync
- Menampilkan count (jika ada)

**Success:**
- Muncul saat sync selesai
- Auto-hide setelah 3 detik
- Animasi slide up + fade out

**Error:**
- Muncul saat ada error
- Tidak auto-hide
- Ada tombol close manual

## 📝 Implementasi

### 1. Widget Baru
**File:** `lib/features/sync/presentation/widgets/sync_header_notification.dart`

```dart
SyncHeaderNotification(
  syncEvents: syncService.syncEvents,
)
```

### 2. Integrasi di CashierPage

**File:** `lib/features/cashier/presentation/pages/cashier_page.dart`

```dart
body: Column(
  children: [
    // Header notification
    SyncHeaderNotification(
      syncEvents: syncService.syncEvents,
    ),
    
    // Main content
    Expanded(
      child: Row(
        children: [...]
      ),
    ),
  ],
)
```

### 3. Integrasi di SyncSettingsPage

**File:** `lib/features/sync/presentation/pages/sync_settings_page.dart`

Sama seperti CashierPage, notification di header.

## 🎯 Cara Kerja

### Event Flow:
```
SyncService
  ↓ (emit event via Stream)
SyncHeaderNotification
  ↓ (listen & update state)
AnimationController
  ↓ (forward/reverse)
UI Update (animated)
```

### State Management:
```dart
// Saat event diterima
if (event.type == 'progress') {
  _showNotification(event);
  // Tidak auto-hide
}

if (event.type == 'success') {
  _showNotification(event);
  // Auto-hide setelah 3 detik
  Future.delayed(Duration(seconds: 3), _hideNotification);
}

if (event.type == 'error') {
  _showNotification(event);
  // User harus close manual
}
```

## 🎬 Contoh Tampilan

### Progress (Blue):
```
┌─────────────────────────────────────────┐
│ ⟳ Mengunduh produk: 5000 / 20000   [5000] │
└─────────────────────────────────────────┘
```

### Success (Green):
```
┌─────────────────────────────────────────┐
│ ✓ Berhasil menyinkronkan 20000 produk    │
└─────────────────────────────────────────┘
```

### Error (Red):
```
┌─────────────────────────────────────────┐
│ ⚠ Gagal mengunduh produk: timeout    [×] │
└─────────────────────────────────────────┘
```

## ⚙️ Customization

### Durasi Animasi
```dart
// Di sync_header_notification.dart, line ~28
_controller = AnimationController(
  duration: const Duration(milliseconds: 300), // Ubah sesuai keinginan
  vsync: this,
);
```

### Auto-hide Duration (Success)
```dart
// Di sync_header_notification.dart, line ~65
Future.delayed(const Duration(seconds: 3), () { // Ubah durasi
  if (mounted) _hideNotification();
});
```

### Warna
```dart
// Di sync_header_notification.dart, line ~105
case 'progress':
  backgroundColor = Colors.blue[700]!; // Ubah warna
  break;
```

## 🔍 Testing

### Manual Test:
1. Jalankan aplikasi
2. Trigger sync (manual atau auto)
3. Perhatikan notifikasi muncul dari atas dengan smooth
4. Verifikasi tidak blocking UI
5. Verifikasi auto-hide untuk success

### Event Types:
```dart
// Trigger dari code
syncService.syncEvents.add(
  SyncEvent(
    type: 'progress',
    message: 'Test progress',
    syncedCount: 100,
  ),
);
```

## ✅ Checklist

- [x] Widget SyncHeaderNotification dibuat
- [x] Integrasi di CashierPage
- [x] Integrasi di SyncSettingsPage
- [x] Remove SnackBar notifications
- [x] Animasi smooth (slide + fade)
- [x] Auto-hide untuk success
- [x] Manual close untuk error
- [x] Warna berdasarkan status
- [x] Tidak blocking UI
- [x] Responsive design

## 📱 UI/UX Benefits

1. **Non-Intrusive:** Tidak menutupi konten penting
2. **Consistent:** Selalu di posisi yang sama (top)
3. **Informative:** Jelas status sync dengan warna & icon
4. **Professional:** Animasi smooth seperti app modern
5. **User-Friendly:** Auto-hide, tidak perlu manual close untuk success

## 🚀 Next Enhancements (Optional)

1. **Progress Bar:** Tambah linear progress bar untuk visual yang lebih jelas
2. **Queue System:** Jika ada multiple events, queue dan tampilkan satu per satu
3. **Swipe to Dismiss:** User bisa swipe untuk close notification
4. **Sound/Haptic:** Tambah feedback sound atau vibration
5. **Customizable Position:** Bisa di top atau bottom based on preference
