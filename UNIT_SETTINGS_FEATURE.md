# Unit Settings Feature

Fitur pengaturan satuan produk untuk aplikasi POS Management.

## Deskripsi

Fitur ini memungkinkan admin untuk mengelola satuan produk (unit) seperti PCS, KG, LITER, dll. Satuan disimpan dalam database dan dapat dikelola secara dinamis melalui UI. Produk tidak lagi menggunakan ID unit, melainkan langsung menyimpan nama unit di tabel products.

## Struktur Backend

### Database Migration
- File: `backend_v2/src/database/migrations/create_units_table.sql`
- Tabel: `units`
- Kolom:
  - `id` (serial, primary key)
  - `name` (varchar, unique) - Nama satuan (uppercase)
  - `description` (text) - Deskripsi satuan
  - `is_active` (boolean) - Status aktif
  - `created_at`, `updated_at`, `deleted_at` (timestamp)

### API Endpoints
- `GET /api/v2/units` - Get all units
- `GET /api/v2/units/:id` - Get unit by ID
- `POST /api/v2/units` - Create new unit
- `PUT /api/v2/units/:id` - Update unit
- `DELETE /api/v2/units/:id` - Delete unit (soft delete)

### Files
1. **Controller**: `backend_v2/src/controllers/unitController.js`
2. **Routes**: `backend_v2/src/routes/unitRoutes.js`
3. **Migration Script**: `backend_v2/run_units_migration.js`

## Struktur Frontend (Flutter)

### Feature Structure
```
lib/features/unit/
├── data/
│   ├── models/
│   │   └── unit_model.dart
│   ├── datasources/
│   │   └── unit_remote_data_source.dart
│   └── repositories/
│       └── unit_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── unit.dart
│   └── repositories/
│       └── unit_repository.dart
└── presentation/
    └── pages/
        └── unit_list_page.dart
```

### Key Features
1. **Unit List Page** (`unit_list_page.dart`)
   - Menampilkan daftar satuan
   - Tambah satuan baru
   - Edit satuan existing
   - Hapus satuan (dengan validasi)

2. **Product Form Integration**
   - Unit dropdown di form produk sekarang load dari API
   - Fallback ke default units jika API gagal
   - Validasi unit saat edit produk

### Navigation
- Akses melalui: Dashboard > Pengaturan > Pengaturan Satuan

## Cara Menggunakan

### Setup Database
1. Jalankan migration:
   ```bash
   cd backend_v2
   node run_units_migration.js
   ```

2. Migration akan:
   - Membuat tabel `units`
   - Insert 10 unit default (PCS, KG, GRAM, LITER, ML, BOX, PACK, DUS, LUSIN, METER)

### Mengelola Satuan

1. **Melihat Daftar Satuan**
   - Buka aplikasi Management
   - Pilih menu Pengaturan (Settings)
   - Pilih "Pengaturan Satuan"

2. **Menambah Satuan Baru**
   - Klik tombol "+" di AppBar
   - Isi nama satuan (wajib, akan otomatis uppercase)
   - Isi deskripsi (opsional)
   - Klik "Simpan"

3. **Mengubah Satuan**
   - Klik icon edit (pensil) pada satuan yang ingin diubah
   - Ubah nama atau deskripsi
   - Klik "Simpan"

4. **Menghapus Satuan**
   - Klik icon delete (sampah) pada satuan yang ingin dihapus
   - Konfirmasi penghapusan
   - Note: Satuan yang sedang digunakan oleh produk tidak dapat dihapus

### Menggunakan Satuan di Form Produk

1. Saat membuat/edit produk, dropdown satuan akan otomatis load dari database
2. Pilih satuan yang sesuai dari dropdown
3. Hanya nama satuan yang disimpan di tabel products (bukan ID)

## Validasi

### Backend
- Nama satuan harus unik
- Nama satuan tidak boleh kosong
- Tidak bisa hapus satuan yang sedang digunakan oleh produk

### Frontend
- Validasi input nama satuan
- Loading state saat fetch/save data
- Error handling dengan snackbar

## Default Units

Saat pertama kali migration dijalankan, 10 unit default akan dibuat:

1. **PCS** - Pieces (per potong/buah)
2. **KG** - Kilogram
3. **GRAM** - Gram
4. **LITER** - Liter
5. **ML** - Mililiter
6. **BOX** - Box (per kotak)
7. **PACK** - Pack (per bungkus)
8. **DUS** - Dus
9. **LUSIN** - Lusin (12 buah)
10. **METER** - Meter

## Catatan Penting

1. **Tidak Ada ID Unit di Products**: Produk menyimpan nama unit langsung (bukan foreign key ke tabel units)
2. **Validasi Konsistensi**: Jika unit dihapus dari master tapi masih ada di produk, produk tetap bisa menggunakan unit tersebut
3. **Soft Delete**: Unit yang dihapus akan di-soft delete (tidak benar-benar dihapus dari database)
4. **Case Insensitive**: Nama unit otomatis diubah ke uppercase untuk konsistensi

## Testing

### Test Backend API
```bash
# Get all units
curl http://localhost:3000/api/v2/units

# Create unit
curl -X POST http://localhost:3000/api/v2/units \
  -H "Content-Type: application/json" \
  -d '{"name": "KARTON", "description": "Karton besar"}'

# Update unit
curl -X PUT http://localhost:3000/api/v2/units/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "PCS", "description": "Pieces - Updated"}'

# Delete unit
curl -X DELETE http://localhost:3000/api/v2/units/1
```

### Test Frontend
1. Buka aplikasi management
2. Login dengan user admin
3. Navigate ke Settings > Pengaturan Satuan
4. Test CRUD operations
5. Test integrasi dengan product form

## Troubleshooting

### Migration Gagal
- Pastikan PostgreSQL sudah running
- Cek konfigurasi database di `.env`
- Pastikan user memiliki permission CREATE TABLE

### API Error
- Cek apakah route sudah di-register di `routes/index.js`
- Verify controller import path
- Cek log di console backend

### UI Error
- Pastikan ApiClient sudah di-inject di service locator
- Verify import path untuk UnitListPage
- Cek error di Flutter DevTools

## Future Improvements

1. ~~Konversi antar satuan (misal: 1 KG = 1000 GRAM)~~
2. ~~Unit kategori (berat, volume, panjang, dll)~~
3. ~~Satuan majemuk (misal: 1 DUS = 12 PCS)~~
4. Sorting dan search di unit list
5. Export/import unit data
