# 📴 Offline Login Feature - POS Cashier

## Overview

POS Cashier sekarang mendukung **login offline** setelah minimal satu kali login online berhasil. Fitur ini memastikan kasir tetap bisa bekerja meskipun koneksi internet terputus.

## Cara Kerja

### 1️⃣ First Time (Online Required)

```
User belum pernah login → Harus online
   ↓
Login dengan username & password
   ↓
Server validasi credentials
   ↓
✓ Berhasil → Simpan di Hive:
  - JWT Token
  - User data
  - Branch data
  - Username (plain text)
  - Password hash (SHA-256) ← untuk offline login
   ↓
Redirect ke Cashier
```

### 2️⃣ Subsequent Login (Offline Capable)

```
User sudah pernah login online
   ↓
Input username & password
   ↓
Try online login terlebih dahulu
   ↓
┌─────────────┬──────────────┐
│   Online?   │   Offline?   │
├─────────────┼──────────────┤
│ ✓ Berhasil  │ × Koneksi    │
│ Update data │   gagal      │
│ Sync latest │      ↓       │
│             │ Fallback to  │
│             │ Offline Login│
│             │      ↓       │
│             │ Validasi     │
│             │ lokal dengan │
│             │ saved hash   │
│             │      ↓       │
│             │ ✓ Berhasil   │
│             │ (Mode Offline)│
└─────────────┴──────────────┘
        ↓              ↓
    Navigate ke Cashier
```

## Implementasi Teknis

### Password Hashing

```dart
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### Offline Login Validation

```dart
// Check credentials
if (savedUsername != username) return null;
if (savedPasswordHash != _hashPassword(password)) return null;

// Valid! Load saved user data
return {
  'token': saved_token,
  'user': saved_user_data,
  'branch': saved_branch_data,
  'offline_mode': true, // Flag untuk UI
};
```

### Data yang Disimpan

**Location**: Hive Box `auth`

```dart
{
  // Auth
  'auth_token': 'eyJhbG...',
  'login_time': '2025-10-29T10:30:00Z',

  // User & Branch
  'user': {
    'id': 1,
    'username': 'cashier01',
    'fullName': 'Kasir Satu',
    'role': 'cashier',
    ...
  },
  'branch': {
    'id': 1,
    'name': 'Toko Pusat',
    ...
  },

  // Offline Login Data
  'saved_username': 'cashier01',
  'saved_password_hash': 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
  'last_online_login': '2025-10-29T10:30:00Z',
}
```

## Security Considerations

### ✅ Aman

- Password di-hash dengan SHA-256 (tidak reversible)
- Password asli **tidak pernah** disimpan
- Hash hanya untuk validasi lokal
- Token tetap digunakan untuk API calls

### ⚠️ Batasan

- Offline login hanya validasi credentials
- Data produk/customer dari cache lokal (bisa outdated)
- Transaksi tersimpan lokal, sync otomatis saat online
- Tidak ada password reset offline (butuh online)

## UI/UX

### Indicator Mode Offline

```dart
// Login berhasil offline
SnackBar(
  content: Text('✓ Login berhasil (Mode Offline)'),
  backgroundColor: Colors.orange, // Orange untuk offline
);

// Login berhasil online
SnackBar(
  content: Text('✓ Login berhasil! Memuat data produk...'),
  backgroundColor: Colors.green, // Green untuk online
);
```

### Login Page Info

```
┌─────────────────────────────┐
│      🔒 Login Form          │
│                             │
│  Username: [________]       │
│  Password: [________]       │
│                             │
│      [  LOGIN  ]            │
│                             │
│  ⚡ Offline Mode Available  │
│  Login online pertama kali  │
│  untuk mengaktifkan mode    │
│  offline                    │
└─────────────────────────────┘
```

## Error Handling

### Belum Pernah Login Online

```
Error: "Login gagal. Pastikan Anda pernah login online
sebelumnya atau periksa koneksi ke server"
```

### Username/Password Salah (Offline)

```
Error: "Username atau password salah"
```

### Server Error (Online)

```
Error: "Tidak bisa terhubung ke server"
→ Auto-fallback ke offline login
```

## Testing

### Test Case 1: First Time Login

```bash
# Backend: ONLINE
1. Buka app
2. Input username: cashier01
3. Input password: password123
4. Klik LOGIN
✓ Expected: Login berhasil (online), data tersimpan
```

### Test Case 2: Offline Login Success

```bash
# Backend: OFFLINE (matikan server)
1. Buka app
2. Input username: cashier01 (yang sama)
3. Input password: password123 (yang benar)
4. Klik LOGIN
✓ Expected: Login berhasil dengan indicator "Mode Offline"
✓ Navigate ke Cashier
✓ Data produk tersedia dari Hive
```

### Test Case 3: Offline Login Failed (Wrong Password)

```bash
# Backend: OFFLINE
1. Input username: cashier01
2. Input password: wrongpassword
3. Klik LOGIN
✓ Expected: Error "Username atau password salah"
```

### Test Case 4: No Saved Credentials

```bash
# Backend: OFFLINE
# Hapus Hive data (flutter clean atau clear app data)
1. Buka app
2. Input any credentials
3. Klik LOGIN
✓ Expected: Error tentang harus login online dulu
```

## Benefits

### Untuk Kasir

- ✅ Tetap bisa bekerja saat internet down
- ✅ Tidak ada downtime
- ✅ Login cepat (validasi lokal)
- ✅ Familiar flow (sama seperti online)

### Untuk Bisnis

- ✅ Business continuity terjaga
- ✅ Transaksi tidak terganggu koneksi
- ✅ Auto-sync saat online kembali
- ✅ Reduce dependency on internet

### Untuk Developer

- ✅ Clean offline-first architecture
- ✅ Auto-fallback mechanism
- ✅ Secure credential storage
- ✅ Easy to maintain

## Troubleshooting

### Problem: Login offline tidak bisa

**Check**:

1. Apakah pernah login online sebelumnya?
2. Username & password sudah benar?
3. Check Hive data: `saved_username` dan `saved_password_hash` ada?

### Problem: Data produk kosong saat offline

**Solution**:

- Ini normal jika belum pernah sync online
- Login online sekali untuk download data
- Data akan tersimpan di Hive untuk offline access

### Problem: "Password salah" padahal benar

**Check**:

1. Pastikan password tidak berubah di server
2. Coba login online sekali untuk update hash
3. Clear app data dan login online ulang

## Integration dengan Sync Service

```dart
// Login Page
if (result != null) {
  final isOfflineMode = result['offline_mode'] == true;

  if (!isOfflineMode) {
    // Online: Sync data
    syncService.syncAll();
    syncService.startBackgroundSync();
  } else {
    // Offline: Skip sync, use cached data
    print('📴 Offline mode - using cached data');
  }
}
```

## Future Improvements

- [ ] Biometric authentication untuk offline login
- [ ] Multiple user offline login support
- [ ] Offline session expiration
- [ ] PIN code sebagai alternatif password
- [ ] Sync status indicator di Cashier page
- [ ] Force online login setelah X hari offline

---

**Note**: Fitur ini adalah bagian dari arsitektur offline-first POS Cashier, memastikan sistem tetap operasional dalam kondisi apapun.
