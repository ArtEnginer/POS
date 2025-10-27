# Purchase Order (PO) - Approved Status Implementation

## 📋 Overview

Implementasi status **APPROVED** pada Purchase Order untuk mendukung workflow approval sebelum proses receiving barang.

## 🎯 Tujuan

1. Menambahkan status `approved` pada PO workflow
2. Validasi receiving hanya untuk PO yang sudah **APPROVED**
3. Memperjelas alur approval PO sebelum barang diterima

## 🔄 Status Workflow Baru

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌─────────┐     ┌──────────┐
│  DRAFT  │────▶│ ORDERED │────▶│ APPROVED │────▶│ PARTIAL │────▶│ RECEIVED │
└─────────┘     └─────────┘     └──────────┘     └─────────┘     └──────────┘
     │               │                │
     │               │                │
     ▼               ▼                ▼
┌───────────────────────────────────────┐
│            CANCELLED                   │
└───────────────────────────────────────┘
```

### Status Explanation:

| Status | Deskripsi | Dapat Di-Receive? |
|--------|-----------|-------------------|
| **draft** | PO masih dalam tahap draft, belum disubmit | ❌ Tidak |
| **ordered** | PO sudah dikirim ke supplier | ❌ Tidak |
| **approved** | PO sudah disetujui, siap untuk receiving | ✅ **YA** |
| **partial** | Sebagian barang sudah diterima | ✅ Ya (sisa barang) |
| **received** | Semua barang sudah diterima lengkap | ❌ Tidak |
| **cancelled** | PO dibatalkan | ❌ Tidak |

## 🛠️ Perubahan yang Dilakukan

### 1. **Database Schema (Backend)**

#### File: `backend_v2/src/database/schema.sql`

```sql
-- BEFORE:
CREATE TYPE purchase_status AS ENUM ('draft', 'ordered', 'received', 'partial', 'cancelled');

-- AFTER:
CREATE TYPE purchase_status AS ENUM ('draft', 'ordered', 'approved', 'partial', 'received', 'cancelled');
```

#### Migration File: `backend_v2/src/database/migrations/004_add_approved_status_to_purchase.sql`

Migration script untuk menambahkan status `approved` ke enum `purchase_status`:

```sql
-- Create new enum type with 'approved' status
CREATE TYPE purchase_status_new AS ENUM (
    'draft', 
    'ordered', 
    'approved',     -- NEW: Status for approved PO ready for receiving
    'partial', 
    'received', 
    'cancelled'
);

-- Convert existing column to new type
ALTER TABLE purchases 
    ALTER COLUMN status TYPE purchase_status_new 
    USING status::text::purchase_status_new;

-- Drop old type and rename new type
DROP TYPE purchase_status;
ALTER TYPE purchase_status_new RENAME TO purchase_status;
```

**Cara Menjalankan Migration:**

```bash
cd backend_v2
node run_migration_approved_status.js
```

### 2. **Domain Entity (Frontend)**

#### File: `management_app/lib/features/purchase/domain/entities/purchase.dart`

```dart
// BEFORE:
final String status; // draft, ordered, received, partial, cancelled

// AFTER:
final String status; // draft, ordered, approved, partial, received, cancelled
```

### 3. **UI - Purchase Form**

#### File: `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart`

**Menambahkan dropdown option untuk status APPROVED:**

```dart
DropdownButtonFormField<String>(
  value: _status,
  decoration: const InputDecoration(
    labelText: 'Status PO',
    isDense: true,
  ),
  items: const [
    DropdownMenuItem(value: 'draft', child: Text('Draft')),
    DropdownMenuItem(
      value: 'ordered',
      child: Text('Ordered - Dikirim ke Supplier'),
    ),
    DropdownMenuItem(
      value: 'approved',  // ✅ NEW
      child: Text('Approved - Disetujui untuk Receiving'),
    ),
    DropdownMenuItem(
      value: 'partial',
      child: Text('Partial - Sebagian Diterima'),
    ),
  ],
  // ...
),
```

**Menambahkan info badge untuk status APPROVED:**

```dart
if (_status == 'approved')
  Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'PO sudah disetujui dan siap untuk proses receiving barang.',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
      ],
    ),
  ),
```

### 4. **UI - Receiving List (Validasi)**

#### File: `management_app/lib/features/purchase/presentation/pages/receiving_list_page.dart`

**Update validasi `canReceive` untuk mengecek status APPROVED:**

```dart
// BEFORE:
final canReceive = purchase.status.toUpperCase() == 'APPROVED';
final isReceived = purchase.status.toUpperCase() == 'RECEIVED';

// AFTER:
final canReceive = purchase.status.toLowerCase() == 'approved';  // ✅ Sekarang benar
final isReceived = purchase.status.toLowerCase() == 'received';
```

**Update status color function:**

```dart
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return Colors.grey;
    case 'ordered':
      return Colors.blue;
    case 'approved':  // ✅ NEW
      return Colors.teal;
    case 'partial':
      return Colors.orange;
    case 'received':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
```

### 5. **UI - Purchase Detail**

#### File: `management_app/lib/features/purchase/presentation/pages/purchase_detail_page.dart`

**Menambahkan case untuk status badge APPROVED:**

```dart
switch (status.toLowerCase()) {
  case 'received':
    color = Colors.green;
    label = 'Received';
    break;
  case 'ordered':
    color = Colors.blue;
    label = 'Ordered';
    break;
  case 'approved':  // ✅ NEW
    color = Colors.teal;
    label = 'Approved';
    break;
  case 'partial':
    color = Colors.orange;
    label = 'Partial';
    break;
  // ...
}
```

## 📊 Status Colors

| Status | Color | Hex Code |
|--------|-------|----------|
| Draft | Grey | `Colors.grey` |
| Ordered | Blue | `Colors.blue` |
| **Approved** | **Teal** | `Colors.teal` |
| Partial | Orange | `Colors.orange` |
| Received | Green | `Colors.green` |
| Cancelled | Red | `Colors.red` |

## 🔧 Testing Steps

### 1. **Jalankan Migration Database**

```bash
cd backend_v2
node run_migration_approved_status.js
```

Expected output:
```
🚀 Starting migration: Add approved status to purchase_status enum...
✅ Migration completed successfully!
📊 Current purchase_status enum values:
  - draft
  - ordered
  - approved
  - partial
  - received
  - cancelled
✨ Migration verification passed!
```

### 2. **Test di Management App**

1. **Buat PO Baru:**
   - Buka Management App
   - Pilih menu Purchase Order
   - Klik "Tambah PO"
   - Isi data supplier dan items
   - Pilih status **"Approved - Disetujui untuk Receiving"**
   - Simpan

2. **Verifikasi di Receiving List:**
   - Buka menu "Penerimaan Barang (Receiving)"
   - PO dengan status **APPROVED** akan menampilkan tombol **"Proses Receiving"**
   - PO dengan status lain akan menampilkan **"Menunggu approval"**

3. **Test Edit PO:**
   - Edit PO yang sudah dibuat
   - Ubah status dari **Draft** → **Ordered** → **Approved**
   - Pastikan dropdown menampilkan semua opsi dengan benar

4. **Test Receiving Process:**
   - Dari Receiving List, klik tombol **"Proses Receiving"** pada PO dengan status APPROVED
   - Form receiving akan terbuka
   - Proses receiving barang
   - Setelah selesai, status PO otomatis berubah ke **PARTIAL** atau **RECEIVED**

### 3. **Verifikasi Database**

```sql
-- Check enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'purchase_status'::regtype 
ORDER BY enumsortorder;

-- Check purchases with approved status
SELECT id, purchase_number, status 
FROM purchases 
WHERE status = 'approved';
```

## ✅ Validation Rules

### Receiving Process
- ✅ **ALLOWED**: PO dengan status `approved`, `partial`
- ❌ **NOT ALLOWED**: PO dengan status `draft`, `ordered`, `received`, `cancelled`

### Status Transitions
```
draft → ordered → approved → partial → received
  ↓       ↓          ↓
  └───────┴──────────┴─→ cancelled
```

## 📝 Catatan Penting

1. **Case Sensitivity**: 
   - Database enum menggunakan **lowercase** (`approved`)
   - Frontend harus konsisten menggunakan **lowercase** untuk perbandingan

2. **Backward Compatibility**:
   - PO yang sudah ada dengan status `ordered` akan tetap valid
   - Tidak ada data yang terpengaruh karena hanya menambah enum value baru

3. **Migration**:
   - Migration menggunakan pendekatan **non-destructive**
   - Existing data tidak akan hilang atau rusak
   - Safe untuk production

4. **Frontend**:
   - Semua file UI sudah di-update untuk mendukung status `approved`
   - Status badge menggunakan warna **Teal** untuk approved
   - Info message ditampilkan saat memilih status approved

## 🚀 Files Changed

### Backend:
1. ✅ `backend_v2/src/database/schema.sql` - Update enum definition
2. ✅ `backend_v2/src/database/migrations/004_add_approved_status_to_purchase.sql` - Migration script
3. ✅ `backend_v2/run_migration_approved_status.js` - Migration runner

### Frontend:
1. ✅ `management_app/lib/features/purchase/domain/entities/purchase.dart` - Update comment
2. ✅ `management_app/lib/features/purchase/presentation/pages/purchase_form_page.dart` - Add approved option
3. ✅ `management_app/lib/features/purchase/presentation/pages/receiving_list_page.dart` - Fix validation
4. ✅ `management_app/lib/features/purchase/presentation/pages/purchase_detail_page.dart` - Add approved badge

## ✨ Benefits

1. **Clearer Workflow**: Memisahkan antara PO yang sudah dikirim (ordered) dengan yang sudah disetujui (approved)
2. **Better Control**: Manager dapat approve PO sebelum tim warehouse melakukan receiving
3. **Audit Trail**: Lebih mudah tracking PO mana yang sudah di-approve vs yang masih pending
4. **Flexible**: Tetap backward compatible dengan data yang sudah ada

---

**Status:** ✅ COMPLETED  
**Date:** 27 Oktober 2025  
**Version:** 1.0  
**Author:** System Migration
