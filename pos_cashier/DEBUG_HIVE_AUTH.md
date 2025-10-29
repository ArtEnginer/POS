# 🔍 Debug Guide: Hive Auth Not Saving

## Problem

Auth credentials tidak tersimpan di Hive setelah login online.

## Symptoms

```
flutter: 🔍 Checking offline credentials:
flutter:    Saved Username: "null"
flutter:    Saved Hash exists: false
flutter:    User data exists: false
flutter:    Branch data exists: false
flutter: ❌ No saved credentials found for offline login
```

## Testing Steps

### 1. Clear All Data

```bash
# Di aplikasi POS Cashier
1. Buka Login Page
2. Klik icon wrench (🔧) di kanan atas
3. Klik "Clear ALL Data" (tombol merah)
4. Confirm
5. Kembali ke Login Page
```

### 2. Test Hive Write/Read

```bash
# Di Dev Tools Page
1. Klik "Test Hive Write/Read" (tombol purple)
2. Lihat output console
3. Expected output:
   🧪 Testing Hive Write/Read...
   Writing test data...
   Flushing to disk...
   Reading test data...
   test_string: Hello Hive
   test_number: 12345
   test_map: {key: value, nested: {data: test}}
   ✅ Hive is working correctly!
```

**Jika test gagal**: Ada masalah dengan Hive initialization atau permissions.

### 3. Start Backend

```powershell
# Terminal baru
cd D:\PROYEK\POS\backend_v2
npm run dev

# Expected output:
# ✓ Redis connected
# ✓ Database pool created
# 🚀 POS Enterprise API Server
# Port: 3001
```

### 4. Login Online & Watch Logs

```bash
# Di aplikasi POS Cashier
1. Username: cashier1
2. Password: (password yang benar)
3. Klik LOGIN
4. Perhatikan console log dengan SANGAT detail
```

**Expected log output:**

```
📦 Auth box status:
   Box name: auth
   Box is open: true
   Box path: /path/to/hive/auth
   Current length: 0

💾 Saving auth data...
   ✓ Token saved
   ✓ User saved
   ✓ Branch saved
   ✓ Login time saved

💾 Saving offline credentials...
   ✓ Username saved: cashier1
   ✓ Password hash saved: a665a45920422f9d417e...
   ✓ Last online login saved

💾 Flushing to disk...
   ✓ Flush complete

🔍 Verifying saved data...
🔐 Verification results:
   Username saved: cashier1
   Username verified: cashier1
   Match: true
   Password Hash: a665a45920422f9d417e...
   Hash verified: a665a45920422f9d417e...
   Hash match: true
   User saved: true
   Branch saved: true
   Box length after save: 7
   All keys: [auth_token, user, branch, login_time, saved_username, saved_password_hash, last_online_login]
```

### 5. Debug Auth Box

```bash
# Setelah login online berhasil
1. Buka Dev Tools lagi
2. Klik "Debug Auth Box"
3. Lihat output
```

**Expected output:**

```
📦 Auth Box Debug:
   Total keys: 7
   auth_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   user: _InternalLinkedHashMap
   branch: _InternalLinkedHashMap
   login_time: 2025-10-29T10:30:00.000Z
   saved_username: cashier1
   saved_password_hash: a665a45920422f9d417e4867efdc4fb8a04a1f3...
   last_online_login: 2025-10-29T10:30:00.000Z
```

### 6. Test Offline Login

```bash
1. Logout dari aplikasi
2. STOP backend (Ctrl+C di terminal npm run dev)
3. Kembali ke Login Page
4. Input: cashier1 + password
5. Klik LOGIN
```

**Expected log output:**

```
⚠️ Online login failed, trying offline login: ...
🔍 Checking offline credentials:
   Input Username: "cashier1"
   Saved Username: "cashier1"
   Saved Hash exists: true
   Saved Hash: a665a45920422f9d417e...
   User data exists: true
   Branch data exists: true
🔐 Password validation:
   Input Hash: a665a45920422f9d417e...
   Saved Hash: a665a45920422f9d417e...
   Full Input Hash: a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
   Full Saved Hash: a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
✅ Offline login successful: cashier1
```

## Possible Issues & Solutions

### Issue 1: Box is not open

**Log shows:**

```
Box is open: false
```

**Solution:**

```dart
// Check main.dart - HiveService.instance.init() harus dipanggil
await HiveService.instance.init();
```

### Issue 2: Data saved but verification shows null

**Log shows:**

```
✓ Username saved: cashier1
Username verified: null
Match: false
```

**Possible causes:**

1. Hive tidak punya permission write ke disk
2. Box path tidak valid
3. Data type tidak compatible dengan Hive

**Solution:**

- Check permissions di folder Hive
- Try `flutter clean && flutter pub get`
- Cek apakah ada error di save operation

### Issue 3: Box length stays 0

**Log shows:**

```
Box length after save: 0
```

**This means:** Data tidak tersimpan sama sekali

**Debug:**

1. Check stack trace untuk error
2. Verify box is open
3. Try manual test dengan Dev Tools "Test Hive Write/Read"

### Issue 4: Keys ada tapi value null

**Log shows:**

```
All keys: [saved_username, saved_password_hash]
Saved Username: "null"
```

**This means:** Keys tersimpan tapi value-nya null/corrupt

**Solution:**

- Clear data completely
- Pastikan value yang disave bukan null
- Check data type conversion

## Quick Commands

```bash
# Clean & rebuild
flutter clean
flutter pub get
flutter run -d windows

# Kill all flutter processes
taskkill /F /IM flutter.exe

# Check Hive data location (Windows)
# Default: C:\Users\<username>\AppData\Roaming\<app_name>\
```

## Debug Checklist

- [ ] Hive initialized (log: "📦 Hive initialized successfully")
- [ ] Auth box is open (log: "Box is open: true")
- [ ] No error saat save (log: "✓" untuk setiap save)
- [ ] Flush complete (log: "✓ Flush complete")
- [ ] Verification Match: true untuk username & hash
- [ ] Box length > 0 setelah save
- [ ] All 7 keys present
- [ ] Debug Auth Box menampilkan semua data
- [ ] Offline login berhasil setelah backend dimatikan

## Contact Points

Jika semua langkah di atas sudah dicoba dan masih gagal, kemungkinan:

1. Platform-specific issue (Windows permissions)
2. Hive version incompatibility
3. Flutter cache corrupt

**Nuclear option:**

```bash
flutter clean
flutter pub cache repair
flutter pub get
flutter run -d windows
```
