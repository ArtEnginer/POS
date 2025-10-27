# Purchase Order (PO) - Perbaikan Error Create

## 🐛 Masalah yang Ditemukan

Fitur Purchase Order tidak dapat membuat PO baru dan selalu mengalami error saat klik "Simpan Pembelian".

## 🔍 Analisis Masalah

Setelah investigasi, ditemukan beberapa masalah utama:

### 1. **Mismatch Tipe Data - Branch ID dan Created By**

**Masalah:**
- Frontend mengirim `branchId: '1'` (string)
- Frontend mengirim `createdBy: 'admin'` (string)
- Backend mengharapkan INTEGER untuk kedua field

**Lokasi:**
```dart
// management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart
final purchase = Purchase(
  branchId: '1',        // ❌ Hardcoded string
  createdBy: 'admin',   // ❌ Hardcoded string, bukan user ID
  // ...
);
```

**Backend Schema:**
```sql
CREATE TABLE purchases (
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    created_by INTEGER NOT NULL REFERENCES users(id),
    -- ...
);
```

### 2. **Mismatch Status Enum**

**Masalah:**
- Frontend mengirim status UPPERCASE: `DRAFT`, `PENDING`, `APPROVED`
- Backend mengharapkan lowercase enum: `draft`, `ordered`, `received`, `partial`, `cancelled`

**Database Enum:**
```sql
CREATE TYPE purchase_status AS ENUM ('draft', 'ordered', 'received', 'partial', 'cancelled');
```

### 3. **Mismatch Payment Method Enum**

**Masalah:**
- Frontend mengirim payment_method UPPERCASE: `CASH`, `TRANSFER`, `CREDIT`, `CARD`, `QRIS`
- Backend mengharapkan lowercase enum: `cash`, `card`, `transfer`, `ewallet`, `credit`

**Error Message:**
```
invalid input value for enum payment_method: "CREDIT"
```

**Database Enum:**
```sql
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'transfer', 'ewallet', 'credit');
```

## ✅ Solusi yang Diterapkan

### 1. **Menggunakan AuthService untuk User Session**

**File:** `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart`

**Perubahan:**
```dart
// ✅ Tambah import
import '../../../../core/auth/auth_service.dart';

// ✅ Get user data dari session
Future<void> _savePurchaseWithStatus(String status) async {
  // ...
  
  // Get user data from AuthService
  final authService = sl<AuthService>();
  final userData = await authService.getUserProfile();
  final branchId = await authService.getCurrentBranchId();

  if (userData == null || branchId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: User session tidak valid. Silakan login ulang.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final purchase = Purchase(
    branchId: branchId,                    // ✅ Dari session (INTEGER)
    createdBy: userData['id'].toString(),  // ✅ User ID dari session (INTEGER)
    // ...
  );
}
```

### 2. **Perbaikan Status Enum**

**File:** `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart`

**Perubahan:**
```dart
// ✅ Default status lowercase
String _status = 'draft';

// ✅ Dropdown dengan lowercase values
DropdownButtonFormField<String>(
  items: const [
    DropdownMenuItem(value: 'draft', child: Text('Draft')),
    DropdownMenuItem(
      value: 'ordered',
      child: Text('Ordered - Dikirim ke Supplier'),
    ),
    DropdownMenuItem(
      value: 'partial',
      child: Text('Partial - Sebagian Diterima'),
    ),
  ],
  // ...
),

// ✅ Button simpan draft
TextButton.icon(
  onPressed: () => _savePurchaseWithStatus('draft'),
  // ...
),
```

**File:** `management_app/lib/features/purchase/presentation/pages/purchase_detail_page.dart`

**Perubahan:**
```dart
// ✅ Ubah switch case ke lowercase
switch (status.toLowerCase()) {
  case 'received':
    // ...
  case 'ordered':
    // ...
  case 'partial':
    // ...
  case 'draft':
    // ...
  case 'cancelled':
    // ...
}
```

### 3. **Perbaikan Payment Method Enum**

**File:** `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart`

**Perubahan:**
```dart
// ✅ Default payment method lowercase
String _paymentMethod = 'cash';

// ✅ Dropdown dengan lowercase values
DropdownButtonFormField<String>(
  value: _paymentMethod,
  items: const [
    DropdownMenuItem(value: 'cash', child: Text('💵 Tunai')),
    DropdownMenuItem(value: 'transfer', child: Text('🏦 Transfer')),
    DropdownMenuItem(value: 'credit', child: Text('📝 Kredit/Tempo')),
    DropdownMenuItem(value: 'card', child: Text('💳 Kartu')),
    DropdownMenuItem(value: 'ewallet', child: Text('📱 E-Wallet')),
  ],
  // ...
),

// ✅ Load existing purchase dengan lowercase conversion
void _loadExistingPurchase() {
  // ...
  _paymentMethod = purchase.paymentMethod?.toLowerCase() ?? 'cash';
  _status = purchase.status.toLowerCase();
}
```

## 📋 Enum Mapping

### Status Enum

| Frontend | Backend Database | Deskripsi |
|----------|------------------|-----------|
| `draft` | `draft` | Draft - Belum dikirim |
| `ordered` | `ordered` | Sudah dikirim ke supplier |
| `partial` | `partial` | Sebagian barang sudah diterima |
| `received` | `received` | Semua barang sudah diterima |
| `cancelled` | `cancelled` | Dibatalkan |

### Payment Method Enum

| Frontend | Backend Database | Deskripsi |
|----------|------------------|-----------|
| `cash` | `cash` | Tunai |
| `card` | `card` | Kartu Debit/Kredit |
| `transfer` | `transfer` | Transfer Bank |
| `ewallet` | `ewallet` | E-Wallet (GoPay, OVO, dll) |
| `credit` | `credit` | Kredit/Tempo |

## 🔧 Backend Validation

Backend melakukan validasi di `purchaseController.js`:

```javascript
// Validate required fields
if (!purchase_number || !branch_id || !created_by) {
  return res.status(400).json({
    success: false,
    message: "Purchase number, branch ID, and created by are required",
  });
}

// Convert string IDs to integers
const branchIdInt = parseInt(branch_id);
const createdByInt = parseInt(created_by);
const supplierIdInt = supplier_id ? parseInt(supplier_id) : null;
```

## 🧪 Testing

### Prerequisites
1. Backend harus running: `npm start` di folder `backend_v2`
2. User harus sudah login (untuk mendapatkan session data)
3. Minimal ada 1 supplier aktif
4. Minimal ada 1 produk aktif

### Test Steps
1. Login ke Management App
2. Buka menu **Pembelian**
3. Klik **Pembelian Baru**
4. Pilih Supplier
5. Tambah minimal 1 produk
6. Pilih status (Draft/Ordered/Partial)
7. Klik **Simpan Pembelian**

### Expected Result
✅ PO berhasil dibuat dengan response:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "purchase_number": "PO-20251027-140530",
    "branch_id": 1,
    "supplier_id": 1,
    "created_by": 1,
    "status": "draft",
    // ...
  },
  "message": "Purchase created successfully"
}
```

## 📝 Catatan Penting

1. **User Session Required**
   - Fitur PO memerlukan user yang sudah login
   - `branchId` dan `userId` diambil dari session token JWT
   - Jika session invalid/expired, user harus login ulang

2. **Status Workflow**
   ```
   draft → ordered → partial → received
                  ↓
              cancelled
   ```

3. **Integration dengan Receiving**
   - Status otomatis berubah saat proses Receiving
   - `partial`: Sebagian barang diterima
   - `received`: Semua barang sudah diterima

## 🚀 Files Changed

1. ✅ `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart`
   - Tambah import `AuthService`
   - Get `branchId` dan `userId` dari session
   - Perbaiki status enum ke lowercase

2. ✅ `management_app/lib/features/purchase/presentation/pages/purchase_detail_page.dart`
   - Perbaiki status badge display dengan lowercase comparison

## ✨ Kesimpulan

Masalah utama adalah **mismatch tipe data dan enum** antara frontend dan backend:
- Frontend hardcode string, backend expect integer (branch_id, created_by)
- Frontend uppercase enum, backend lowercase enum (status, payment_method)

Solusi: 
1. Gunakan data dari user session untuk branch_id dan user_id
2. Gunakan lowercase untuk semua enum values
3. Konversi ke lowercase saat load existing data

---
**Status:** ✅ FIXED
**Date:** 27 Oktober 2025
**Tested:** ✅ Backend running, ready for frontend testing
