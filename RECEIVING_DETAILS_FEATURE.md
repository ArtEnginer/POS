# Fitur Detail Penerimaan Barang

## Deskripsi
Fitur ini menambahkan detail lengkap pada proses penerimaan barang (receiving), termasuk informasi dari nota pengiriman supplier.

## Field Detail Penerimaan

### 1. Nomor Faktur (WAJIB)
- **Field**: `invoice_number`
- **Tipe**: TEXT
- **Required**: Ya
- **Deskripsi**: Nomor faktur/invoice yang tertera di nota pengiriman dari supplier
- **Contoh**: "INV-2025-001", "FKT/2025/10/0001"
- **Validasi**: Wajib diisi saat proses receiving

### 2. Nomor Surat Jalan (Opsional)
- **Field**: `delivery_order_number`
- **Tipe**: TEXT
- **Required**: Tidak
- **Deskripsi**: Nomor surat jalan pengiriman barang
- **Contoh**: "DO-2025-0001", "SJ/2025/001"

### 3. Nomor Kendaraan (Opsional)
- **Field**: `vehicle_number`
- **Tipe**: TEXT
- **Required**: Tidak
- **Deskripsi**: Plat nomor kendaraan yang mengirim barang
- **Contoh**: "B 1234 ABC", "D 5678 XYZ"
- **Format**: Otomatis uppercase

### 4. Nama Sopir (Opsional)
- **Field**: `driver_name`
- **Tipe**: TEXT
- **Required**: Tidak
- **Deskripsi**: Nama sopir/pengemudi yang mengirim barang
- **Contoh**: "Budi Santoso", "Ahmad Rizki"
- **Format**: Title case

## Cara Penggunaan

### 1. Proses Penerimaan Baru
1. Buka menu **Purchase** → **Purchase Orders**
2. Pilih PO yang akan diproses
3. Klik tombol **Proses Receiving**
4. Di form receiving, **WAJIB** isi **Nomor Faktur**
5. Opsional: Isi Nomor Surat Jalan, Nomor Kendaraan, dan Nama Sopir
6. Lakukan validasi barang dan qty yang diterima
7. Klik **Proses Penerimaan**

### 2. Edit Penerimaan Existing
1. Buka menu **Purchase** → **Receiving History**
2. Pilih receiving yang akan diedit
3. Klik tombol **Edit**
4. Update detail receiving jika diperlukan
5. Simpan perubahan

## UI Form Detail Penerimaan

```
┌─────────────────────────────────────────────────┐
│ 📋 Detail Penerimaan                           │
├─────────────────────────────────────────────────┤
│                                                 │
│ 🔢 Nomor Faktur*          📦 Nomor Surat Jalan │
│ [________________]         [________________]   │
│ Sesuai nota pengiriman                         │
│                                                 │
│ 🚗 Nomor Kendaraan         👤 Nama Sopir       │
│ [________________]         [________________]   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Validasi Form

### Nomor Faktur
- **Wajib diisi**: Ya
- **Error message**: "Nomor faktur wajib diisi"
- **Trimmed**: Ya (whitespace dihilangkan)

### Field Lainnya
- **Wajib diisi**: Tidak
- **Trimmed**: Ya (whitespace dihilangkan)

## Perubahan Database

### Schema Update
```sql
ALTER TABLE receivings ADD COLUMN invoice_number TEXT;
ALTER TABLE receivings ADD COLUMN delivery_order_number TEXT;
ALTER TABLE receivings ADD COLUMN vehicle_number TEXT;
ALTER TABLE receivings ADD COLUMN driver_name TEXT;

CREATE INDEX idx_receivings_invoice ON receivings(invoice_number);
```

### Migration
- **Database Version**: 6 → 7
- **Migration**: Otomatis saat app pertama kali dibuka setelah update
- **Backward Compatible**: Ya (data lama akan memiliki NULL value)

## File yang Dimodifikasi

### 1. Entity Layer
```
lib/features/purchase/domain/entities/receiving.dart
```
- Tambah field: `invoiceNumber`, `deliveryOrderNumber`, `vehicleNumber`, `driverName`
- Update constructor & copyWith
- Update props untuk equality

### 2. Data Layer
```
lib/features/purchase/data/models/receiving_model.dart
```
- Tambah field di constructor
- Update `fromJson()` untuk deserialize
- Update `toJson()` untuk serialize
- Update `fromEntity()` untuk konversi

### 3. Presentation Layer
```
lib/features/purchase/presentation/pages/receiving_form_page.dart
```
- Tambah state variables untuk input
- Tambah form section untuk detail penerimaan
- Tambah validasi nomor faktur
- Update create/update receiving logic

### 4. Database Layer
```
lib/core/database/database_helper.dart
```
- Update CREATE TABLE receivings
- Tambah migration untuk version 7
- Tambah index untuk invoice_number

```
lib/core/constants/app_constants.dart
```
- Update `localDatabaseVersion` dari 6 ke 7

## Testing Checklist

- [ ] Proses receiving baru dengan semua field terisi
- [ ] Proses receiving baru dengan hanya nomor faktur (minimal required)
- [ ] Edit receiving existing dan update detail
- [ ] Validasi error saat nomor faktur kosong
- [ ] Cek data tersimpan di database
- [ ] Cek tampilan detail di receiving detail page
- [ ] Cek tampilan di receiving list
- [ ] Test dengan data lama (sebelum migration)
- [ ] Test backward compatibility

## Next Steps

### 1. Update Receiving Detail Page
Tampilkan informasi detail receiving:
```dart
// lib/features/purchase/presentation/pages/receiving_detail_page.dart

Container(
  child: Column(
    children: [
      DetailRow(label: 'Nomor Faktur', value: receiving.invoiceNumber),
      DetailRow(label: 'No. Surat Jalan', value: receiving.deliveryOrderNumber),
      DetailRow(label: 'Nomor Kendaraan', value: receiving.vehicleNumber),
      DetailRow(label: 'Nama Sopir', value: receiving.driverName),
    ],
  ),
)
```

### 2. Update Receiving List
Tambahkan kolom nomor faktur di tabel:
```dart
DataColumn(label: Text('Nomor Faktur')),
```

### 3. Export/Print
Include detail receiving di:
- Laporan receiving
- Export Excel
- Print receipt

### 4. Search & Filter
Tambah fitur search berdasarkan:
- Nomor faktur
- Nomor surat jalan
- Nomor kendaraan

## Manfaat Fitur

1. **Audit Trail**: Tracking lengkap dari dokumen supplier
2. **Compliance**: Memenuhi requirement akuntansi dan pajak
3. **Traceability**: Mudah lacak barang dari nomor faktur
4. **Verification**: Validasi penerimaan dengan dokumen fisik
5. **Reporting**: Laporan lebih detail dengan info pengiriman

## Screenshot

### Before (Tanpa Detail)
```
┌─────────────────────────────┐
│ PO: PO-2025-001            │
│ Supplier: PT ABC           │
│ Tanggal: 17/10/2025        │
└─────────────────────────────┘
```

### After (Dengan Detail)
```
┌─────────────────────────────────────┐
│ PO: PO-2025-001                    │
│ Supplier: PT ABC                   │
│ Tanggal: 17/10/2025                │
├─────────────────────────────────────┤
│ 📋 Detail Penerimaan               │
│ Nomor Faktur: INV-2025-001         │
│ No. Surat Jalan: SJ-2025-001       │
│ Nomor Kendaraan: B 1234 ABC        │
│ Nama Sopir: Budi Santoso           │
└─────────────────────────────────────┘
```

## Troubleshooting

### Migration Error
**Problem**: Database migration failed
**Solution**: 
1. Backup data terlebih dahulu
2. Jalankan `reset_database.ps1`
3. Re-import data jika perlu

### Validation Error
**Problem**: Nomor faktur tidak tervalidasi
**Solution**: 
1. Cek form key sudah di-validate
2. Pastikan validator return message yang benar
3. Check `onSaved` dipanggil

### Data Tidak Tersimpan
**Problem**: Detail receiving tidak tersimpan
**Solution**:
1. Cek `toJson()` include semua field baru
2. Cek database schema sudah diupdate
3. Check migration sudah jalan

## Support

Untuk pertanyaan atau issue:
1. Check documentation ini
2. Check error logs
3. Contact development team
