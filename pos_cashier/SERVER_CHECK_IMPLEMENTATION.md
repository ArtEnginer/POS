# Server Connection Check & Offline Login - POS Cashier

## Overview

Implementasi pengecekan koneksi server dan **offline login capability** untuk aplikasi POS Cashier, mengikuti pattern dari aplikasi Management dengan tambahan fitur offline-first.

## Fitur yang Ditambahkan

### 1. **Offline Login Capability** ⭐ NEW

- Login bisa dilakukan tanpa koneksi internet
- Credentials disimpan secara aman (password di-hash dengan SHA-256)
- Validasi offline menggunakan data yang tersimpan di Hive
- Auto-fallback ke offline login jika server tidak tersedia
- Mode offline indicator saat login berhasil offline

### 2. **App Settings Utility** (`core/utils/app_settings.dart`)

- Mengelola konfigurasi server menggunakan `SharedPreferences`
- Menyimpan:
  - API Base URL
  - Socket URL
  - API Version
  - Status konfigurasi server
- Method untuk update dan reset pengaturan

### 2. **Server Check Page** (`features/server_check_page.dart`)

- Halaman splash yang melakukan pengecekan koneksi server
- Menampilkan status koneksi dengan animasi
- Fitur:
  - Auto-check saat aplikasi dibuka
  - Retry connection
  - Akses ke Server Settings
  - Auto-navigate ke Login jika koneksi berhasil
  - Error handling dengan pesan yang jelas

### 3. **Server Settings Page** (`features/server_settings_page.dart`)

- Halaman untuk mengkonfigurasi koneksi server
- Fitur:
  - Form input untuk API Base URL, Socket URL, dan API Version
  - Test connection sebelum menyimpan
  - Reset to defaults
  - Validasi URL
  - Status indicator koneksi

### 4. **Updated API Service** (`core/network/api_service.dart`)

- Menambahkan method `updateBaseUrlFromSettings()`
- Mendukung konfigurasi dinamis base URL
- Tidak lagi hard-coded ke localhost

### 5. **Enhanced Auth Service** (`core/utils/auth_service.dart`) ⭐ NEW

- **Offline login support** dengan credential caching
- Password hashing menggunakan SHA-256 untuk keamanan
- Auto-fallback dari online ke offline login
- Menyimpan username dan password hash untuk validasi offline
- Tracking last online login timestamp
- Method `_offlineLogin()` untuk validasi credentials lokal

### 6. **Updated Main App** (`main.dart`)

- Flow aplikasi yang lebih baik:
  1. Jika server belum dikonfigurasi → Server Check Page
  2. Jika sudah ada session → Cashier Page
  3. Jika sudah konfigurasi tapi belum login → Login Page
- Update API base URL dari settings saat startup
- Routes baru untuk server check dan settings

### 7. **Updated Login Page** (`features/auth/presentation/pages/login_page.dart`)

- Menampilkan status offline mode
- Different feedback untuk online vs offline login
- Info "Offline Mode Available" di UI
- Skip sync saat login offline
- Error message yang lebih informatif

### 8. **Cashier Page Enhancement**

- Menambahkan menu options dengan akses ke Server Settings
- Memudahkan user untuk mengubah konfigurasi server kapan saja

## User Flow

### First Time Setup (Online Required)

1. **App Start** → Server Check Page
2. Jika koneksi gagal → Tampilkan error dengan opsi:
   - Retry Connection
   - Server Settings
3. User bisa mengatur custom server URL di Settings
4. Test connection
5. Simpan settings
6. Auto-redirect ke Login Page
7. **First login MUST be online** untuk save credentials

### Subsequent Launches

#### Online Mode

1. **App Start** → Load settings
2. Jika ada session → Langsung ke Cashier
3. Jika tidak ada session → Login Page
4. Login online → Sync data → Navigate to Cashier
5. Server check sudah di-bypass karena sudah dikonfigurasi

#### Offline Mode ⭐ NEW

1. **App Start** → Load settings
2. Jika ada session → Langsung ke Cashier
3. Jika tidak ada session tapi ada saved credentials → Login Page
4. User input username & password
5. Sistem try online login → **gagal** (no internet)
6. Auto-fallback ke offline login
7. Validasi credentials dengan hash yang tersimpan
8. Login berhasil → Show "Mode Offline" indicator
9. Skip sync → Navigate to Cashier
10. Data produk dari local Hive database

### Offline Login Flow Detail

```
User enters credentials
      ↓
Try online login (API call)
      ↓
  [Connection Failed]
      ↓
Fallback to offline login
      ↓
Check saved credentials in Hive:
  - saved_username
  - saved_password_hash (SHA-256)
  - user data
  - branch data
      ↓
Validate:
  - Username matches?
  - Password hash matches?
      ↓
  [Valid] → Login Success (Offline Mode)
  [Invalid] → Show error
```

### Changing Server Settings

1. Di Cashier Page → Menu (⋮) → Server Settings
2. Update URL
3. Test connection
4. Save
5. Aplikasi akan menggunakan URL baru

## Default Configuration

```dart
API Base URL: http://localhost:3001
Socket URL: http://localhost:3001
API Version: v2
```

## Error Handling

Server Check Page menangani berbagai error:

- **Connection Timeout**: Server tidak merespons dalam waktu yang ditentukan
- **Connection Error**: Tidak bisa connect (server mati, URL salah, firewall)
- **Bad Response**: Server merespons dengan error code
- Error messages yang user-friendly dalam bahasa Indonesia

## Security

### Password Security

- Passwords **never** stored in plain text
- SHA-256 hashing for stored credentials
- Hash comparison untuk validasi offline
- Credentials hanya disimpan setelah online login berhasil

### Data Stored in Hive (authBox)

```dart
{
  'auth_token': 'jwt_token_here',
  'user': { id, username, fullName, role, ... },
  'branch': { id, name, address, ... },
  'saved_username': 'cashier01',
  'saved_password_hash': 'sha256_hash_here',
  'last_online_login': '2025-10-29T10:30:00.000Z',
  'login_time': '2025-10-29T10:30:00.000Z',
}
```

## Benefits

### For Cashier

- ✅ Tetap bisa login saat internet mati
- ✅ Tidak perlu menunggu koneksi server
- ✅ Business continuity terjaga
- ✅ Fast login (local validation)

### For Business

- ✅ Tidak ada downtime karena internet
- ✅ Transaksi tetap berjalan offline
- ✅ Data tersinkronisasi otomatis saat online
- ✅ Offline-first architecture

## Testing Checklist

### Online Mode

- [ ] First time app open - harus show Server Check Page
- [ ] Connection success - auto redirect ke Login
- [ ] Online login - save credentials dan navigate ke cashier
- [ ] Logout dan login ulang online - masih pakai settings yang disimpan

### Offline Mode ⭐

- [ ] Matikan backend server
- [ ] Buka app (sudah pernah login sebelumnya)
- [ ] Input username & password yang benar
- [ ] Harus berhasil login dengan indicator "Mode Offline"
- [ ] Navigate ke Cashier berhasil
- [ ] Data produk tersedia dari Hive
- [ ] Input username/password salah - harus gagal
- [ ] Belum pernah login online - harus gagal dengan pesan yang jelas

### Server Settings

- [ ] Connection failed - show error dengan retry option
- [ ] Server Settings - form validation works
- [ ] Test connection - berhasil untuk valid URL
- [ ] Save settings - tersimpan dan digunakan
- [ ] Reset to defaults - kembali ke localhost
- [ ] Access from Cashier menu - bisa buka Server Settings

## Technical Notes

- Menggunakan `shared_preferences` untuk persistent storage (server config)
- Menggunakan `hive` untuk offline data (credentials, products, sales)
- Package `crypto` untuk SHA-256 password hashing
- Dio untuk HTTP client dengan timeout 10 detik
- Health check endpoint: `/api/v2/health`
- Support untuk custom port dan remote servers
- Validasi URL: harus dimulai dengan http:// atau https://
- Offline login hanya tersedia setelah minimal 1x login online berhasil
