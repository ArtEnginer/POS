# Migration: Add Receiving Detail Fields

## Deskripsi
Menambahkan kolom detail penerimaan barang pada tabel `receivings`:
- `invoice_number`: Nomor faktur dari supplier (WAJIB)
- `delivery_order_number`: Nomor surat jalan
- `vehicle_number`: Nomor kendaraan pengiriman
- `driver_name`: Nama sopir/pengemudi

## SQL Migration

```sql
-- Add new columns to receivings table
ALTER TABLE receivings ADD COLUMN invoice_number TEXT;
ALTER TABLE receivings ADD COLUMN delivery_order_number TEXT;
ALTER TABLE receivings ADD COLUMN vehicle_number TEXT;
ALTER TABLE receivings ADD COLUMN driver_name TEXT;
```

## Cara Menjalankan

### Opsi 1: Otomatis via Database Helper
Database helper akan otomatis mendeteksi versi dan menjalankan migration saat app dibuka.

### Opsi 2: Manual via SQL (jika diperlukan)
1. Buka database dengan SQLite browser
2. Jalankan query SQL di atas
3. Restart aplikasi

## Checklist Perubahan

- [x] Update `Receiving` entity (domain/entities/receiving.dart)
- [x] Update `ReceivingModel` (data/models/receiving_model.dart)
- [x] Update `ReceivingFormPage` untuk input fields
- [x] Update database schema di `DatabaseHelper`
- [ ] Update receiving detail page untuk menampilkan info baru
- [ ] Update receiving list untuk menampilkan nomor faktur

## Field Details

### invoice_number (WAJIB)
- **Tipe**: TEXT
- **Nullable**: Yes (untuk backward compatibility)
- **Validasi**: Required saat create/edit receiving baru
- **Deskripsi**: Nomor faktur yang tertera di nota pengiriman dari supplier

### delivery_order_number
- **Tipe**: TEXT
- **Nullable**: Yes
- **Deskripsi**: Nomor surat jalan pengiriman

### vehicle_number
- **Tipe**: TEXT
- **Nullable**: Yes
- **Deskripsi**: Plat nomor kendaraan yang mengirim barang

### driver_name
- **Tipe**: TEXT
- **Nullable**: Yes
- **Deskripsi**: Nama sopir/pengemudi yang mengirim barang

## Notes
- Field `invoice_number` dibuat WAJIB diisi di form (validasi di UI)
- Field lain bersifat opsional
- Data lama (sebelum migration) akan memiliki nilai NULL untuk field baru
- Perlu update UI untuk menampilkan info detail ini
