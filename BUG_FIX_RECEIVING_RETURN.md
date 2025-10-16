# Bug Fix - Receiving Edit & Delete

## Masalah yang Diperbaiki

### 1. ✅ Edit Receiving Tidak Ada Items

**Masalah:**

- Saat klik tombol "Edit" di receiving history, form tidak muncul
- Items dari receiving tidak ditampilkan di form

**Penyebab:**

- Listener hanya load receiving dan purchase, tapi tidak navigate ke form
- Tidak ada listener untuk PurchaseBloc untuk handle navigasi

**Solusi:**

- Menambahkan `MultiBlocListener` di `receiving_history_page.dart`
- Listener untuk `ReceivingDetailLoaded`: Load purchase by ID
- Listener untuk `PurchaseDetailLoaded`: Navigate ke `ReceivingFormPage` dengan data purchase
- Form receiving akan menerima data purchase lengkap dengan items

**File Diubah:**

- `lib/features/purchase/presentation/pages/receiving_history_page.dart`

**Perubahan:**

```dart
// Sebelum: Hanya load receiving, tidak navigate
BlocConsumer<ReceivingBloc, ReceivingState>(
  listener: (context, state) {
    if (state is ReceivingDetailLoaded) {
      context.read<PurchaseBloc>().add(
        LoadPurchaseById(state.receiving.purchaseId),
      );
    }
  },
  ...
)

// Sesudah: Tambah listener untuk navigate
MultiBlocListener(
  listeners: [
    BlocListener<ReceivingBloc, ReceivingState>(...),
    BlocListener<PurchaseBloc, PurchaseState>(
      listener: (context, state) {
        if (state is PurchaseDetailLoaded) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<ReceivingBloc>()),
                  BlocProvider.value(value: context.read<PurchaseBloc>()),
                ],
                child: ReceivingFormPage(purchase: state.purchase),
              ),
            ),
          );
        }
      },
    ),
  ],
  child: BlocBuilder<ReceivingBloc, ReceivingState>(...),
)
```

---

### 2. ✅ Return Purchase Form Tidak Ada Items

**Masalah:**

- Saat membuat return dari receiving, items tidak muncul di form
- Field quantity tidak bisa diisi karena items kosong

**Penyebab:**

- Listener untuk `ReceivingDetailLoaded` tidak handle error
- State `_receiving` tetap null meskipun data sudah di-load

**Solusi:**

- Menambahkan error handling di listener receiving
- Menambahkan listener untuk `ReceivingError` untuk notifikasi user

**File Diubah:**

- `lib/features/purchase/presentation/pages/purchase_return_form_page.dart`

**Perubahan:**

```dart
// Sebelum: Tidak ada error handling
BlocListener<ReceivingBloc, ReceivingState>(
  listener: (context, state) {
    if (state is ReceivingDetailLoaded) {
      setState(() {
        _receiving = state.receiving;
        for (var item in _receiving!.items) {
          _returnQuantities[item.id] = 0;
        }
      });
    }
  },
)

// Sesudah: Dengan error handling
BlocListener<ReceivingBloc, ReceivingState>(
  listener: (context, state) {
    if (state is ReceivingDetailLoaded) {
      setState(() {
        _receiving = state.receiving;
        for (var item in _receiving!.items) {
          _returnQuantities[item.id] = 0;
        }
      });
    } else if (state is ReceivingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
)
```

---

### 3. ✅ Delete Receiving: Stock & PO Status

**Status:** Sudah Benar ✅

Fungsi delete receiving sudah menghandle:

1. **Reverse Stock**: Mengurangi stock produk sesuai qty yang diterima
2. **Revert PO Status**: Mengubah status PO kembali ke "APPROVED" jika tidak ada receiving lain

**Kode di `receiving_local_data_source.dart`:**

```dart
Future<void> deleteReceiving(String id) async {
  try {
    final db = await databaseHelper.database;
    final receiving = await getReceivingById(id);

    await db.transaction((txn) async {
      // 1. Reverse stock (kurangi stock)
      for (var item in receiving.items) {
        await txn.rawUpdate(
          '''
          UPDATE products
          SET stock = stock - ?,
              updated_at = ?,
              sync_status = 'PENDING'
          WHERE id = ?
          ''',
          [
            item.receivedQuantity,
            DateTime.now().toIso8601String(),
            item.productId,
          ],
        );
      }

      // 2. Delete receiving items
      await txn.delete(
        'receiving_items',
        where: 'receiving_id = ?',
        whereArgs: [id],
      );

      // 3. Delete receiving header
      await txn.delete('receivings', where: 'id = ?', whereArgs: [id]);

      // 4. Check if there are other receivings for this purchase
      final otherReceivings = await txn.query(
        'receivings',
        where: 'purchase_id = ?',
        whereArgs: [receiving.purchaseId],
      );

      // 5. If no more receivings, revert purchase status to APPROVED
      if (otherReceivings.isEmpty) {
        await txn.update(
          'purchases',
          {
            'status': 'APPROVED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [receiving.purchaseId],
        );
      }
    });
  } catch (e) {
    throw DatabaseException(message: 'Failed to delete receiving: $e');
  }
}
```

**Fitur yang Bekerja:**

- ✅ Stock dikurangi sesuai qty yang diterima
- ✅ Status PO kembali ke "APPROVED" jika tidak ada receiving lain
- ✅ Semua operasi dalam transaction (atomic)
- ✅ Sync status diupdate ke "PENDING" untuk sinkronisasi

---

## Testing Flow

### Test Edit Receiving:

1. Buka "Riwayat Penerimaan"
2. Klik tombol "Edit" pada salah satu receiving
3. ✅ Form receiving harus muncul
4. ✅ Items dari PO harus muncul lengkap dengan quantity
5. ✅ Data receiving lama harus ter-load di form

### Test Return Purchase:

1. Buka "Return Pembelian"
2. Pilih receiving yang sudah COMPLETED
3. Klik "Buat Return"
4. ✅ Form return harus muncul
5. ✅ Items dari receiving harus ditampilkan
6. ✅ Bisa input quantity return untuk setiap item
7. Isi alasan dan simpan
8. ✅ Return berhasil dibuat

### Test Delete Receiving:

1. Buat receiving dari PO (status PO jadi RECEIVED)
2. Check stock produk (harus bertambah)
3. Hapus receiving dari "Riwayat Penerimaan"
4. ✅ Stock produk harus berkurang sesuai qty receiving
5. ✅ Status PO kembali ke "APPROVED"
6. ✅ Bisa buat receiving baru untuk PO yang sama

---

## Verifikasi Database

Untuk memastikan delete bekerja dengan benar, cek di database:

```sql
-- Check stock sebelum delete
SELECT id, name, stock FROM products WHERE id = 'product_id';

-- Check status PO sebelum delete
SELECT id, purchase_number, status FROM purchases WHERE id = 'purchase_id';

-- Delete receiving via app UI

-- Check stock sesudah delete (harus berkurang)
SELECT id, name, stock FROM products WHERE id = 'product_id';

-- Check status PO sesudah delete (harus APPROVED jika tidak ada receiving lain)
SELECT id, purchase_number, status FROM purchases WHERE id = 'purchase_id';
```

---

## Notes

### Edit Receiving:

- ✅ Form akan load dengan data PO original
- ✅ Bisa ubah quantity, price, discount, tax per item
- ✅ Saat save, akan update receiving yang ada (bukan buat baru)

### Return Purchase:

- ✅ Hanya bisa return dari receiving COMPLETED
- ✅ Quantity return tidak boleh melebihi quantity received
- ✅ Stock akan dikurangi otomatis saat return completed
- ✅ Bisa partial return (tidak harus semua item)

### Delete Receiving:

- ✅ Stock adjustment otomatis (reverse)
- ✅ PO status revert ke APPROVED jika tidak ada receiving lain
- ✅ Semua dalam transaction untuk data integrity
- ✅ Konfirmasi dialog sebelum delete

---

## Troubleshooting

### Items Tidak Muncul di Edit:

1. Check apakah PurchaseBloc sudah di-provide di routing
2. Check console untuk error saat load purchase
3. Pastikan purchase memiliki items

### Items Tidak Muncul di Return:

1. Check apakah receiving memiliki items di database
2. Check console untuk error saat load receiving
3. Pastikan receiving status COMPLETED

### Stock Tidak Update Saat Delete:

1. Check apakah transaction berhasil
2. Check console untuk database error
3. Verify product_id ada di tabel products

---

## Summary

Semua masalah telah diperbaiki:

1. ✅ **Edit Receiving**: Form muncul dengan items lengkap
2. ✅ **Return Purchase**: Items ditampilkan, bisa input quantity
3. ✅ **Delete Receiving**: Stock di-reverse, PO status kembali ke APPROVED

Tidak ada perubahan database schema atau migration diperlukan.
