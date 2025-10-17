# EDIT ITEM TAMBAHAN - Update Feature

## Problem
User tidak bisa **EDIT** quantity dan harga item tambahan yang sudah ditambahkan ke receiving form. Hanya bisa delete, tapi tidak ada cara untuk mengubah nilai tanpa hapus dan tambah ulang.

## Solution
Menambahkan **Dialog Edit** khusus untuk item tambahan dengan fitur:
- Edit quantity
- Edit harga
- Validasi input
- Tombol edit (✏️) di setiap item tambahan

---

## Changes Made

### 1. **New Method: `_showEditItemDialog()`**
**File**: `lib/features/purchase/presentation/pages/receiving_form_page.dart`

```dart
Future<void> _showEditItemDialog(_ReceivingItem item, int index) async {
  final quantityController = TextEditingController(
    text: item.receivedQuantity.toString(),
  );
  final priceController = TextEditingController(
    text: item.receivedPrice.toStringAsFixed(0),
  );
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Edit ${item.purchaseItem.productName}'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info dengan badge "ITEM TAMBAHAN"
            Container(...),
            
            // Quantity input dengan validasi
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity*'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Wajib diisi';
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) return 'Harus > 0';
                return null;
              },
            ),
            
            // Price input dengan validasi
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Harga*', prefixText: 'Rp '),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Wajib diisi';
                final price = double.tryParse(value);
                if (price == null || price <= 0) return 'Harus > 0';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              setState(() {
                item.receivedQuantity = int.parse(quantityController.text);
                item.receivedPrice = double.parse(priceController.text);
              });
              Navigator.pop(dialogContext);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  quantityController.dispose();
  priceController.dispose();
}
```

**Features**:
- ✅ Form validation untuk quantity dan harga
- ✅ Pre-filled dengan nilai existing
- ✅ Product info display dengan badge "ITEM TAMBAHAN"
- ✅ Tombol Batal & Simpan
- ✅ setState untuk update UI setelah edit
- ✅ Proper controller disposal

---

### 2. **Updated UI: Add Edit Button**

**Before**:
```dart
if (item.isAdditionalItem)
  IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () { /* delete */ },
    tooltip: 'Hapus Item',
  ),
```

**After**:
```dart
if (item.isAdditionalItem) ...[
  // Tombol EDIT (biru)
  IconButton(
    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
    onPressed: () {
      _showEditItemDialog(item, index);
    },
    tooltip: 'Edit Item',
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
  ),
  const SizedBox(width: 4),
  // Tombol DELETE (merah)
  IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () {
      setState(() {
        _receivingItems.removeAt(index);
      });
    },
    tooltip: 'Hapus Item',
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
  ),
],
```

**Changes**:
- ✅ Added edit button (blue) before delete button
- ✅ Used spread operator `...[]` for multiple widgets
- ✅ Added 4px spacing between buttons
- ✅ Edit button calls `_showEditItemDialog()`

---

## User Experience

### Before:
1. User tambah item baru
2. Salah input quantity/harga
3. **HARUS hapus dan tambah ulang** ❌
4. Product search lagi dari awal
5. Input ulang semua data

### After:
1. User tambah item baru
2. Salah input quantity/harga
3. **Klik tombol ✏️** ✅
4. Edit langsung quantity/harga
5. Klik "Simpan"
6. Done! 🎉

---

## Dialog UI Structure

```
┌─────────────────────────────────────┐
│ Edit [Product Name]            [X]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Product Name]                  │ │
│ │ 🟧 ITEM TAMBAHAN                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Quantity*                       │ │
│ │ [  10  ]                        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Harga*                          │ │
│ │ Rp [  50000  ]                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│              [Batal] [Simpan]       │
└─────────────────────────────────────┘
```

---

## Validations

### Quantity Field:
- ✅ Required (tidak boleh kosong)
- ✅ Must be integer
- ✅ Must be > 0

### Price Field:
- ✅ Required (tidak boleh kosong)
- ✅ Must be numeric
- ✅ Must be > 0

### Form Level:
- ✅ All validations must pass before save
- ✅ Cancel button bypasses validation
- ✅ Controllers properly disposed after dialog closes

---

## Benefits

### 1. **Better UX**
- Tidak perlu hapus dan tambah ulang
- Quick edit dengan 2 klik (edit button → save)
- Less steps, less errors

### 2. **Data Integrity**
- Validasi tetap ketat
- Tidak bisa input nilai invalid
- Product reference tetap sama (tidak berubah)

### 3. **Consistency**
- Edit behavior sama seperti form field lain
- Dialog pattern consistent dengan add item
- Error messages clear & helpful

---

## Testing

### Test Scenarios:

#### 1. Open Edit Dialog
- [ ] Click edit button (✏️)
- [ ] Dialog opens
- [ ] Product name displayed correctly
- [ ] Badge "ITEM TAMBAHAN" shown
- [ ] Quantity pre-filled
- [ ] Price pre-filled

#### 2. Edit Quantity
- [ ] Clear quantity field → Error: "Wajib diisi"
- [ ] Input 0 → Error: "Harus > 0"
- [ ] Input -5 → Error: "Harus > 0"
- [ ] Input 10 → Valid ✅

#### 3. Edit Price
- [ ] Clear price field → Error: "Wajib diisi"
- [ ] Input 0 → Error: "Harus > 0"
- [ ] Input -1000 → Error: "Harus > 0"
- [ ] Input 50000 → Valid ✅

#### 4. Save Changes
- [ ] Click "Simpan" with valid data
- [ ] Dialog closes
- [ ] Values updated in form
- [ ] Subtotal recalculated
- [ ] UI reflects changes

#### 5. Cancel Changes
- [ ] Edit values
- [ ] Click "Batal"
- [ ] Dialog closes
- [ ] Values NOT changed
- [ ] Original values preserved

#### 6. Multiple Edits
- [ ] Edit item A
- [ ] Edit item B
- [ ] Edit item A again
- [ ] All changes saved correctly

---

## Related Files

- `lib/features/purchase/presentation/pages/receiving_form_page.dart` - Main implementation
- `ADD_ITEM_TO_RECEIVING.md` - Updated documentation

---

## Notes

- Edit dialog **ONLY** for additional items (`isAdditionalItem = true`)
- PO items still use inline form fields (existing behavior)
- Product cannot be changed via edit (by design)
- Discount & PPN still edited via form fields (not in dialog)

---

**Status**: ✅ IMPLEMENTED  
**Date**: October 17, 2025  
**Version**: 1.1
