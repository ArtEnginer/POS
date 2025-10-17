# ADD ITEM TO RECEIVING - Fitur Tambah Barang di Proses Receiving

## Overview
Fitur ini memungkinkan user untuk menambahkan barang yang **TIDAK ADA** di Purchase Order (PO) saat proses receiving. Ini berguna ketika supplier mengirim barang tambahan atau pengganti.

---

## Fitur Utama

### 1. **Tambah Barang Baru**
- User dapat klik tombol "➕ Tambah Barang Baru" di form receiving
- Akan muncul dialog untuk memilih produk
- Dialog dilengkapi dengan:
  - Search bar untuk cari produk
  - List produk dengan kode, nama, dan stok
  - Input quantity dan harga

### 2. **Pencarian Produk**
- Terintegrasi dengan `ProductBloc`
- Real-time search saat user mengetik
- Menampilkan semua produk aktif dari database

### 3. **Item Tambahan (Additional Item)**
- Item yang ditambah akan ditandai dengan badge **"TAMBAHAN"** berwarna orange
- Di bagian Qty PO akan muncul: **"Item Tambahan (Tidak di PO)"** (orange)
- Di bagian Harga PO akan muncul: **"Harga Bebas"** (orange)
- Item tambahan bisa **EDIT** dengan tombol **✏️** (biru)
- Item tambahan bisa **HAPUS** dengan tombol **❌** (merah)

### 4. **Data Item Tambahan**
- `poQuantity = 0` (menandakan tidak ada di PO)
- `poPrice` = harga yang diinput user
- `isAdditionalItem = true` (flag khusus)
- Tetap memiliki `productId` yang valid dari database

---

## Technical Implementation

### File Modified
**`lib/features/purchase/presentation/pages/receiving_form_page.dart`**

### Key Changes

#### 1. **Import Dependencies**
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../product/presentation/bloc/product_bloc.dart';
import '../../product/presentation/bloc/product_event.dart' as product_event;
import '../../product/presentation/bloc/product_state.dart' as product_state;
import '../../product/domain/entities/product.dart';
import '../../../injection_container.dart' as di;
```

#### 2. **Updated _ReceivingItem Class**
```dart
class _ReceivingItem {
  final PurchaseItem purchaseItem;
  int receivedQuantity;
  double receivedPrice;
  double discount;
  String discountType; // 'AMOUNT' atau 'PERCENTAGE'
  double tax;
  String taxType; // 'AMOUNT' atau 'PERCENTAGE'
  bool isAdditionalItem; // ✅ NEW FLAG
  
  _ReceivingItem({
    required this.purchaseItem,
    required this.receivedQuantity,
    required this.receivedPrice,
    this.discount = 0,
    this.discountType = 'AMOUNT',
    this.tax = 0,
    this.taxType = 'AMOUNT',
    this.isAdditionalItem = false, // ✅ DEFAULT FALSE
  });
}
```

#### 3. **Method _showAddItemDialog()**
Membuka dialog untuk memilih produk:
```dart
Future<void> _showAddItemDialog() async {
  final selectedProduct = await showDialog<Product>(
    context: context,
    builder: (context) => BlocProvider(
      create: (context) => di.sl<ProductBloc>()..add(product_event.LoadProductsEvent()),
      child: const _AddItemDialog(),
    ),
  );
  
  if (selectedProduct != null) {
    // Tambahkan ke list dengan dummy PurchaseItem
    setState(() {
      _receivingItems.add(_ReceivingItem(
        purchaseItem: PurchaseItem(
          id: const Uuid().v4(),
          purchaseId: widget.purchase.id,
          productId: selectedProduct.id,
          productName: selectedProduct.name,
          quantity: 0, // ✅ Qty PO = 0 (tidak ada di PO)
          price: 0,
          subtotal: 0,
          createdAt: DateTime.now(),
        ),
        receivedQuantity: 1,
        receivedPrice: selectedProduct.sellingPrice,
        isAdditionalItem: true, // ✅ MARK AS ADDITIONAL
      ));
    });
  }
}
```

#### 4. **Method _showEditItemDialog()**
Dialog untuk edit item tambahan yang sudah ada:
```dart
Future<void> _showEditItemDialog(_ReceivingItem item, int index) async {
  final quantityController = TextEditingController(
    text: item.receivedQuantity.toString(),
  );
  final priceController = TextEditingController(
    text: item.receivedPrice.toStringAsFixed(0),
  );
  
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Edit ${item.purchaseItem.productName}'),
      content: Form(
        // Form dengan input quantity dan price
        // Dengan validation
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            setState(() {
              item.receivedQuantity = int.parse(quantityController.text);
              item.receivedPrice = double.parse(priceController.text);
            });
            Navigator.pop(dialogContext);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
```

#### 5. **Widget _AddItemDialog**
Dialog lengkap dengan:
- Search TextFormField
- BlocBuilder untuk menampilkan produk
- Loading state
- Empty state
- Product list dengan selection

```dart
class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  Product? _selectedProduct;
  
  // ... implementation
}
```

#### 6. **UI Updates**

**Tombol Tambah Barang:**
```dart
Padding(
  padding: const EdgeInsets.all(16.0),
  child: OutlinedButton.icon(
    onPressed: _showAddItemDialog,
    icon: const Icon(Icons.add_circle_outline),
    label: const Text('Tambah Barang Baru'),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue,
      side: const BorderSide(color: Colors.blue),
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
),
```

**Badge "TAMBAHAN":**
```dart
if (item.isAdditionalItem)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.shade100,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.orange),
    ),
    child: Text(
      'TAMBAHAN',
      style: TextStyle(
        color: Colors.orange.shade900,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
```

**Tombol Edit & Delete untuk Item Tambahan:**
```dart
if (item.isAdditionalItem) ...[
  // Tombol Edit (biru)
  IconButton(
    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
    onPressed: () {
      _showEditItemDialog(item, index);
    },
    tooltip: 'Edit Item',
  ),
  const SizedBox(width: 4),
  // Tombol Delete (merah)
  IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      setState(() {
        _receivingItems.removeAt(index);
      });
    },
    tooltip: 'Hapus Item',
  ),
],
```

**Conditional Display Qty PO:**
```dart
if (!item.isAdditionalItem)
  Text(
    'Qty PO: ${item.purchaseItem.quantity}',
    style: TextStyle(
      color: Colors.grey.shade600,
      fontSize: 13,
    ),
  ),
if (item.isAdditionalItem)
  Text(
    'Item Tambahan (Tidak di PO)',
    style: TextStyle(
      color: Colors.orange.shade700,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
```

**Conditional Display Harga PO:**
```dart
if (!item.isAdditionalItem)
  Text(
    'Harga PO: ${NumberFormat.currency(...).format(item.purchaseItem.price)}',
    style: TextStyle(
      color: Colors.grey.shade600,
      fontSize: 13,
    ),
  ),
if (item.isAdditionalItem)
  Text(
    'Harga Bebas',
    style: TextStyle(
      color: Colors.orange.shade700,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
```

---

## Database Impact

### receiving_items Table
Item tambahan akan disimpan dengan:
- `poQuantity = 0` → Menandakan tidak ada di PO
- `poPrice` → Harga yang diinput user
- `productId` → Valid product ID dari database
- `receivedQuantity` → Quantity yang diterima
- `receivedPrice` → Harga aktual yang diterima

Data ini **TIDAK AKAN MENGGANGGU** logika existing karena:
1. Semua field required tetap terisi
2. `poQuantity = 0` sudah valid value
3. Product reference tetap valid
4. Calculation tetap benar

---

## User Flow

### Scenario: Tambah Item Baru

1. **User di Receiving Form**
   - Melihat list item dari PO
   - Ingin menambah barang yang tidak di PO

2. **Klik "Tambah Barang Baru"**
   - Dialog muncul
   - List produk ditampilkan

3. **Search Product**
   - Ketik nama/kode produk di search bar
   - List produk ter-filter real-time

4. **Pilih Product**
   - Tap pada produk yang diinginkan
   - Card product highlight dengan checkmark

5. **Input Quantity & Price**
   - Masukkan jumlah yang diterima
   - Masukkan harga (pre-filled dengan selling price)

6. **Tambahkan ke List**
   - Klik "Tambahkan"
   - Dialog close
   - Item muncul di list dengan badge "TAMBAHAN"

7. **Edit/Delete Item Tambahan**
   - Klik tombol **✏️** (biru) untuk edit quantity & harga
   - Klik tombol **❌** (merah) untuk hapus item
   - Bisa juga edit discount & PPN di form field biasa

8. **Process Receiving**
   - Item tambahan ikut tersimpan
   - Stok product terupdate
   - History tercatat

### Scenario: Edit Item Tambahan

1. **User melihat item dengan badge "TAMBAHAN"**
   - Item ditandai dengan badge orange
   - Ada tombol ✏️ (edit) dan ❌ (delete)

2. **Klik tombol Edit (✏️)**
   - Dialog edit muncul
   - Menampilkan nama produk & badge "ITEM TAMBAHAN"
   - Field quantity dan harga sudah terisi

3. **Ubah Quantity/Harga**
   - Edit nilai yang diperlukan
   - Validasi otomatis (harus > 0)

4. **Simpan Perubahan**
   - Klik "Simpan"
   - Dialog close
   - Nilai ter-update di form

5. **Atau Batal**
   - Klik "Batal"
   - Nilai tetap tidak berubah

---

## Validations

### Dialog Validations:
1. ✅ Product harus dipilih
2. ✅ Quantity > 0
3. ✅ Harga > 0

### Form Validations (per item):
1. ✅ Received Quantity > 0
2. ✅ Received Price > 0
3. ✅ Discount ≥ 0
4. ✅ Tax ≥ 0

---

## Benefits

### 1. **Fleksibilitas**
- Tidak terpaku pada PO
- Bisa terima barang pengganti
- Bisa terima bonus dari supplier

### 2. **Akurasi Data**
- Semua barang tercatat
- Stok tetap akurat
- History lengkap

### 3. **User Friendly**
- Search product mudah
- Interface jelas (badge "TAMBAHAN")
- Bisa delete jika salah input

### 4. **Data Integrity**
- Flag `isAdditionalItem` untuk identifikasi
- `poQuantity = 0` untuk differensiasi
- Product reference valid
- Calculation tetap akurat

---

## Testing Checklist

### Add Item Feature:
- [ ] Dialog tambah barang bisa dibuka
- [ ] Search product berfungsi
- [ ] Product bisa dipilih
- [ ] Quantity & price validation bekerja
- [ ] Item muncul di list dengan badge "TAMBAHAN"
- [ ] Label "Item Tambahan (Tidak di PO)" muncul
- [ ] Label "Harga Bebas" muncul

### Edit Item Feature:
- [ ] Tombol edit (✏️) muncul untuk item tambahan
- [ ] Dialog edit bisa dibuka
- [ ] Dialog menampilkan data item yang benar
- [ ] Quantity bisa diubah dengan validasi
- [ ] Harga bisa diubah dengan validasi
- [ ] Tombol "Simpan" meng-update nilai
- [ ] Tombol "Batal" tidak mengubah nilai

### Delete & Processing:
- [ ] Tombol delete (❌) berfungsi
- [ ] Item terhapus dari list
- [ ] Discount & PPN bisa di-edit di form field
- [ ] Process receiving berhasil dengan item tambahan
- [ ] Data tersimpan di database dengan `poQuantity = 0`
- [ ] Stok product terupdate
- [ ] Detail receiving menampilkan item tambahan dengan benar

---

## Future Enhancements

### Possible Improvements:
1. **Barcode Scanner** - Scan barcode untuk tambah item
2. **Recent Products** - Tampilkan produk yang sering ditambah
3. **Category Filter** - Filter produk by category di dialog
4. **Bulk Add** - Tambah multiple items sekaligus
5. **Reason Field** - Input alasan kenapa item ditambah (tidak di PO)
6. **Approval Flow** - Item tambahan perlu approval manager
7. **Reporting** - Laporan item tambahan per supplier/periode

---

## Notes

- Item tambahan **TIDAK MENGUBAH** PO yang ada
- Item tambahan hanya ada di **RECEIVING**
- Jika create return dari receiving ini, item tambahan **BISA DI-RETURN**
- Flag `isAdditionalItem` hanya untuk UI, **TIDAK DISIMPAN** ke database
- Database hanya pakai `poQuantity = 0` sebagai marker

---

## Related Files

- `lib/features/purchase/presentation/pages/receiving_form_page.dart` - Main implementation
- `lib/features/product/presentation/bloc/product_bloc.dart` - Product search
- `lib/features/purchase/domain/entities/purchase.dart` - PurchaseItem entity
- `lib/features/purchase/domain/entities/receiving.dart` - ReceivingItem entity

---

**Status**: ✅ IMPLEMENTED
**Version**: 1.0
**Last Updated**: 2024
