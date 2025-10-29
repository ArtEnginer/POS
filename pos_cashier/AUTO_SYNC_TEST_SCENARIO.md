# 🧪 Auto-Sync Test Scenario

## Test: Offline Transactions → Auto-Sync When Online

### Objective

Memastikan transaksi yang tersimpan secara offline **langsung tersinkronkan otomatis** saat koneksi ke server kembali online.

---

## 📋 Prerequisites

1. ✅ Backend server dapat di-start/stop (untuk simulasi offline/online)
2. ✅ POS Cashier app running dengan login berhasil
3. ✅ Minimal 1 produk tersedia di database

---

## 🎯 Test Steps

### **FASE 1: Buat Transaksi Offline** 🟠

**Step 1:** Pastikan app dalam status **ONLINE**

```
✅ Lihat header: "🟢 Online"
✅ Console: "🔌 WebSocket connected"
```

**Step 2:** **MATIKAN** backend server

```bash
# Di terminal backend:
Ctrl + C (stop server)
```

**Step 3:** Tunggu status berubah jadi **OFFLINE**

```
⏱️ Tunggu 2-5 detik
✅ Lihat header berubah: "🟠 Offline"
✅ Console: "🔌 WebSocket disconnected"
```

**Step 4:** Buat **3 transaksi penjualan** saat offline

```
Transaksi #1:
  - Pilih produk → Tambah ke cart
  - Klik "Bayar" → Input pembayaran
  - ✅ Console: "💾 Sale saved locally: INV-xxx-0001"
  - ⚠️ Console: "⚠️ Sale will be synced later when online"

Transaksi #2:
  - Ulangi proses yang sama
  - ✅ Console: "💾 Sale saved locally: INV-xxx-0002"

Transaksi #3:
  - Ulangi proses yang sama
  - ✅ Console: "💾 Sale saved locally: INV-xxx-0003"
```

**Step 5:** Verifikasi pending count

```
✅ Lihat header: "🟠 Offline (3)"
    ↑ Badge menunjukkan 3 transaksi pending
```

---

### **FASE 2: Auto-Sync Saat Online** 🟢

**Step 6:** **NYALAKAN** kembali backend server

```bash
# Di terminal backend:
cd backend_v2
npm run dev

# Tunggu sampai server ready
✅ Output: "Server running on port 3001"
```

**Step 7:** Observe auto-sync magic! ✨

```
⏱️ Dalam 1-3 detik, lihat perubahan:

Console Log:
┌─────────────────────────────────────────────┐
│ 🔌 WebSocket status changed: ONLINE         │
│ 🟢 Server is ONLINE - Checking for pending...│
│ 📦 Found 3 pending sales - AUTO-SYNCING...  │
│ 🔄 Starting full sync...                    │
│ 📤 Uploading 3 pending sales...             │
│ 📤 Sending sale to server: INV-xxx-0001     │
│ 📤 Sending sale to server: INV-xxx-0002     │
│ 📤 Sending sale to server: INV-xxx-0003     │
│ ✅ Uploaded 3 sales (Failed: 0)             │
│ ✅ AUTO-SYNC COMPLETED: 3/3 sales synced    │
└─────────────────────────────────────────────┘

UI Changes:
┌─────────────────────────────────────────────┐
│ 📢 SnackBar muncul (floating, green):       │
│    ✅ Berhasil menyinkronkan 3 transaksi!   │
│                                             │
│ 📊 Header badge berubah:                    │
│    "🟠 Offline (3)" → "🟢 Online"           │
└─────────────────────────────────────────────┘
```

**Step 8:** Verifikasi di backend database

```sql
-- Login ke PostgreSQL
psql -U your_user -d your_database

-- Cek sales yang baru masuk
SELECT sale_number, total_amount, created_at
FROM sales
ORDER BY created_at DESC
LIMIT 5;

Expected Result:
┌──────────────────┬──────────────┬──────────────────────┐
│  sale_number     │ total_amount │     created_at       │
├──────────────────┼──────────────┼──────────────────────┤
│ INV-xxx-0003     │    150000.00 │ 2025-10-30 10:15:03  │
│ INV-xxx-0002     │     75000.00 │ 2025-10-30 10:14:45  │
│ INV-xxx-0001     │    120000.00 │ 2025-10-30 10:14:20  │
└──────────────────┴──────────────┴──────────────────────┘

✅ Semua 3 transaksi tersimpan di server!
```

---

## 🔍 Verification Checklist

### ✅ Console Logs

- [x] `🔌 WebSocket status changed: ONLINE`
- [x] `📦 Found X pending sales - AUTO-SYNCING...`
- [x] `📤 Uploading X pending sales...`
- [x] `✅ Uploaded X sales (Failed: 0)`
- [x] `✅ AUTO-SYNC COMPLETED: X/X sales synced`

### ✅ UI Indicators

- [x] Header badge: `🟠 Offline (3)` → `🟢 Online`
- [x] SnackBar notification muncul dengan pesan sukses
- [x] SnackBar background: **Green** (success)
- [x] Icon: ✅ Check circle

### ✅ Data Integrity

- [x] Semua transaksi tersimpan di Hive (local)
- [x] Semua transaksi ter-upload ke server
- [x] Field `is_synced` berubah dari `false` → `true`
- [x] `synced_at` timestamp ter-update

---

## 🧪 Advanced Test Scenarios

### Test Case 2: **Mixed Online/Offline Transactions**

```
Scenario:
1. Online → 2 transaksi (instant sync)
2. Server mati → 3 transaksi offline (queued)
3. Server hidup → 3 transaksi auto-sync
4. Online → 1 transaksi (instant sync)

Expected:
- Total di server: 6 transaksi
- Pending count: 0
- Console: "✅ AUTO-SYNC COMPLETED: 3/3 sales synced"
```

### Test Case 3: **Partial Sync Failure**

```
Scenario:
1. Buat 5 transaksi offline
2. Ubah 1 transaksi di Hive (corrupt data)
3. Server online → auto-sync

Expected:
- Console: "✅ Uploaded 4 sales (Failed: 1)"
- Pending count: 1 (yang gagal tetap di queue)
- SnackBar: "⚠️ 4 dari 5 transaksi berhasil disinkron"
```

### Test Case 4: **Reconnect During Transaction**

```
Scenario:
1. Server offline
2. Mulai transaksi (pilih produk)
3. Server online saat tengah transaksi
4. Selesaikan pembayaran

Expected:
- Header berubah: 🟠 → 🟢 (saat server hidup)
- Transaksi baru langsung instant sync
- Console: "✅ INSTANT SYNC SUCCESS"
```

---

## 📊 Performance Benchmarks

| Metric                  | Target            | Actual     |
| ----------------------- | ----------------- | ---------- |
| WebSocket detect online | < 3s              | ~1-2s      |
| Auto-sync trigger       | < 1s after detect | ~100-500ms |
| Sync 10 transactions    | < 5s              | ~2-4s      |
| UI notification delay   | < 500ms           | ~100-300ms |
| Badge update            | Real-time         | ✅ Instant |

---

## 🐛 Troubleshooting

### Problem: Auto-sync tidak terjadi

**Diagnosis:**

```bash
# Cek console:
1. Apakah WebSocket berhasil reconnect?
   ✅ "🔌 WebSocket status changed: ONLINE"

2. Apakah ada pending sales?
   ✅ "📦 Found X pending sales"

3. Apakah sync dipanggil?
   ✅ "📤 Uploading X pending sales..."
```

**Solution:**

- Pastikan backend server benar-benar running (port 3001)
- Cek network: `curl http://localhost:3001/api/health`
- Restart app jika perlu

### Problem: SnackBar tidak muncul

**Diagnosis:**

```dart
// Cek apakah listener terpasang:
print('_syncEventListener: $_syncEventListener'); // Should not be null

// Cek apakah context masih mounted:
if (!mounted) return; // Ini bisa jadi masalah
```

**Solution:**

- Pastikan `_syncEventListener` tidak null
- Pastikan widget masih mounted saat event diterima

### Problem: Pending count tidak berkurang

**Diagnosis:**

```dart
// Cek field is_synced di Hive:
final salesBox = HiveService.instance.salesBox;
salesBox.values.forEach((data) {
  final sale = SaleModel.fromJson(data);
  print('${sale.invoiceNumber}: isSynced=${sale.isSynced}');
});
```

**Solution:**

- Cek apakah API response success (200/201)
- Cek apakah field `is_synced` ter-update di Hive
- Manual trigger: Klik tombol Refresh

---

## 🎓 Expected Flow Diagram

```
┌─────────────────┐
│  APP OFFLINE    │
│   🟠 Offline    │
└────────┬────────┘
         │
         │ User creates 3 transactions
         ▼
┌─────────────────┐
│ Hive: 3 Sales   │
│ is_synced=false │
│                 │
│ Badge: 🟠 (3)   │
└────────┬────────┘
         │
         │ Backend server starts
         ▼
┌─────────────────┐
│ WebSocket       │
│ Reconnects      │
│ Status: ONLINE  │
└────────┬────────┘
         │
         │ < 1 second
         ▼
┌─────────────────┐
│ _initSocket     │
│ Listener        │
│ Triggers        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ syncAll()       │
│ Auto-called     │
└────────┬────────┘
         │
         │ 2-4 seconds
         ▼
┌─────────────────┐
│ API: POST       │
│ /api/sales (x3) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Hive:    │
│ is_synced=true  │
│ synced_at=now   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Broadcast Event:│
│ SyncEvent       │
│ type='success'  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ UI Updates:     │
│ ✅ SnackBar     │
│ 🟢 Online       │
│ No pending (0)  │
└─────────────────┘
```

---

## ✅ Success Criteria

Test dianggap **BERHASIL** jika:

1. ✅ **Offline transactions saved locally**

   - Semua transaksi tersimpan di Hive
   - Badge menunjukkan pending count yang benar

2. ✅ **Auto-sync triggered on reconnect**

   - WebSocket detect online dalam < 3 detik
   - Sync otomatis dipanggil tanpa user action

3. ✅ **All transactions synced to server**

   - Semua pending sales ter-upload
   - Database server berisi semua transaksi

4. ✅ **UI feedback accurate**

   - SnackBar notification muncul
   - Badge update dari "Offline (X)" → "Online"
   - Status change real-time (< 500ms)

5. ✅ **Data integrity maintained**
   - No data loss
   - No duplicate transactions
   - Timestamps akurat

---

**Test Status**: ✅ READY TO TEST  
**Last Updated**: October 30, 2025  
**Estimated Test Duration**: 5-10 minutes
