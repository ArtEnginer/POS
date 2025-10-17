# EDIT RECEIVING WITH ADDITIONAL ITEMS - Feature Implementation

## Problem
Saat **EDIT RECEIVING** yang sudah ada, item tambahan (yang tidak ada di PO) **TIDAK MUNCUL** di form edit. Ini karena sistem hanya load data dari Purchase Order (PO), bukan dari Receiving yang sudah tersimpan.

### Impact:
- ❌ Item tambahan hilang saat edit
- ❌ User tidak bisa update receiving yang memiliki item tambahan
- ❌ Data tidak konsisten

---

## Solution
Modifikasi `ReceivingFormPage` untuk support **EDIT MODE** dengan:
1. Parameter `existingReceiving` opsional
2. Load data dari Receiving (bukan hanya dari PO)
3. Restore item tambahan dengan flag `isAdditionalItem = true`
4. Update receiving (bukan create baru)

---

## Changes Made

### 1. **ReceivingFormPage - Add Edit Mode Support**

**File**: `lib/features/purchase/presentation/pages/receiving_form_page.dart`

#### A. Updated Constructor
```dart
class ReceivingFormPage extends StatefulWidget {
  final Purchase purchase;
  final Receiving? existingReceiving; // ✅ NEW: For edit mode

  const ReceivingFormPage({
    Key? key,
    required this.purchase,
    this.existingReceiving, // ✅ Optional parameter
  }) : super(key: key);
}
```

#### B. Updated initState
```dart
@override
void initState() {
  super.initState();
  
  if (widget.existingReceiving != null) {
    // ✅ Edit mode: Load from existing receiving
    _initializeFromReceiving();
  } else {
    // Create mode: Load from PO
    _initializeItems();
  }

  // Generate or use existing receiving number
  if (widget.existingReceiving != null) {
    _receivingNumber = widget.existingReceiving!.receivingNumber;
    _totalDiscount = widget.existingReceiving!.totalDiscount;
    _totalTax = widget.existingReceiving!.totalTax;
    _notes = widget.existingReceiving!.notes ?? '';
  } else {
    context.read<ReceivingBloc>().add(
      const receiving_event.GenerateReceivingNumberEvent(),
    );
  }
}
```

#### C. New Method: `_initializeFromReceiving()`
```dart
void _initializeFromReceiving() {
  _receivingItems.clear();
  final receiving = widget.existingReceiving!;
  
  for (var receivingItem in receiving.items) {
    // ✅ Check if item is additional (not in PO)
    final isAdditional = receivingItem.poQuantity == 0;
    
    // Find corresponding PurchaseItem or create dummy
    PurchaseItem purchaseItem;
    if (isAdditional) {
      // ✅ Create dummy PurchaseItem for additional items
      purchaseItem = PurchaseItem(
        id: receivingItem.purchaseItemId ?? const Uuid().v4(),
        purchaseId: widget.purchase.id,
        productId: receivingItem.productId,
        productName: receivingItem.productName,
        quantity: 0, // ✅ Mark as additional
        price: receivingItem.receivedPrice,
        subtotal: 0,
        createdAt: DateTime.now(),
      );
    } else {
      // Find from PO items
      purchaseItem = widget.purchase.items.firstWhere(
        (pi) => pi.id == receivingItem.purchaseItemId,
        orElse: () => PurchaseItem(...),
      );
    }
    
    _receivingItems.add(
      _ReceivingItem(
        purchaseItem: purchaseItem,
        receivedQuantity: receivingItem.receivedQuantity,
        receivedPrice: receivingItem.receivedPrice,
        discount: receivingItem.discount,
        discountType: receivingItem.discountType,
        tax: receivingItem.tax,
        taxType: receivingItem.taxType,
        isAdditionalItem: isAdditional, // ✅ Restore flag
      ),
    );
  }
}
```

**Key Logic**:
- ✅ Check `poQuantity == 0` to identify additional items
- ✅ Create dummy `PurchaseItem` with `quantity = 0` for additional items
- ✅ Find real `PurchaseItem` from PO for regular items
- ✅ Restore all fields including discount, tax, etc.
- ✅ Set `isAdditionalItem` flag correctly

#### D. Updated `_processReceiving()` for Update Mode
```dart
Future<void> _processReceiving() async {
  // ... validation ...

  // ✅ Use existing ID for edit mode, generate new for create mode
  final receivingId = widget.existingReceiving?.id ?? const Uuid().v4();

  // ... create receiving items ...

  // Create receiving object
  final receiving = Receiving(
    id: receivingId, // ✅ Same ID for update
    receivingNumber: _receivingNumber!,
    purchaseId: widget.purchase.id,
    purchaseNumber: widget.purchase.purchaseNumber,
    supplierId: widget.purchase.supplierId,
    supplierName: widget.purchase.supplierName,
    receivingDate: widget.existingReceiving?.receivingDate ?? DateTime.now(), // ✅ Keep original date
    subtotal: _calculateSubtotal(),
    itemDiscount: _calculateItemDiscountTotal(),
    itemTax: _calculateItemTaxTotal(),
    totalDiscount: _totalDiscount,
    totalTax: _totalTax,
    total: _calculateTotal(),
    status: 'COMPLETED',
    notes: _notes.isNotEmpty ? _notes : null,
    receivedBy: widget.existingReceiving?.receivedBy, // ✅ Keep original receiver
    syncStatus: 'PENDING',
    createdAt: widget.existingReceiving?.createdAt ?? DateTime.now(), // ✅ Keep original created date
    updatedAt: DateTime.now(), // ✅ Update timestamp
    items: receivingItems,
  );

  // ✅ Dispatch correct event based on mode
  if (widget.existingReceiving != null) {
    // Edit mode: Update existing
    context.read<ReceivingBloc>().add(
      receiving_event.UpdateReceivingEvent(receiving),
    );
  } else {
    // Create mode: Create new
    context.read<ReceivingBloc>().add(
      receiving_event.CreateReceivingEvent(receiving),
    );
  }
}
```

#### E. Updated AppBar Title
```dart
appBar: AppBar(
  title: Text(
    widget.existingReceiving != null
        ? 'Edit Penerimaan Barang' // ✅ Edit mode
        : 'Proses Penerimaan Barang', // Create mode
  ),
),
```

---

### 2. **ReceivingHistoryPage - Pass Receiving Data**

**File**: `lib/features/purchase/presentation/pages/receiving_history_page.dart`

#### A. Add Import
```dart
import '../../domain/entities/receiving.dart';
```

#### B. Add State Variable
```dart
class _ReceivingHistoryPageState extends State<ReceivingHistoryPage> {
  final _searchController = TextEditingController();
  bool _isNavigatingToEdit = false;
  Receiving? _receivingToEdit; // ✅ Store receiving data for edit
  // ...
}
```

#### C. Store Receiving in Listener
```dart
BlocListener<ReceivingBloc, ReceivingState>(
  listener: (context, state) {
    // ...
    } else if (state is ReceivingDetailLoaded && _isNavigatingToEdit) {
      final receiving = state.receiving;
      _receivingToEdit = receiving; // ✅ Store for later use
      context.read<PurchaseBloc>().add(
        LoadPurchaseById(receiving.purchaseId),
      );
    }
  },
),
```

#### D. Pass to Form
```dart
BlocListener<PurchaseBloc, PurchaseState>(
  listener: (context, state) {
    if (state is PurchaseDetailLoaded && _isNavigatingToEdit) {
      setState(() {
        _isNavigatingToEdit = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [...],
            child: ReceivingFormPage(
              purchase: state.purchase,
              existingReceiving: _receivingToEdit, // ✅ Pass receiving data
            ),
          ),
        ),
      ).then((result) {
        if (result == true) {
          _loadReceivings();
        }
        _receivingToEdit = null; // ✅ Clear after use
      });
    }
  },
),
```

---

## How It Works

### Create Mode (New Receiving):
1. User clicks "Receive" from PO
2. `ReceivingFormPage(purchase: po)`
3. `existingReceiving = null`
4. Load items from PO → `_initializeItems()`
5. User can add additional items
6. Save → `CreateReceivingEvent`

### Edit Mode (Existing Receiving):
1. User clicks "Edit" from receiving history
2. Load receiving detail → `LoadReceivingById`
3. Load purchase detail → `LoadPurchaseById`
4. Navigate → `ReceivingFormPage(purchase: po, existingReceiving: receiving)`
5. `existingReceiving != null`
6. Load items from receiving → `_initializeFromReceiving()`
7. Items with `poQuantity = 0` restored as additional items
8. User can edit/add/delete items
9. Save → `UpdateReceivingEvent`

---

## Data Flow

```
┌──────────────────────────────────────────────────────┐
│ Receiving History Page                               │
│                                                      │
│  [Edit Button Clicked]                              │
│         ↓                                           │
│  LoadReceivingById                                  │
│         ↓                                           │
│  ReceivingDetailLoaded                              │
│         ↓                                           │
│  Store: _receivingToEdit = receiving                │
│         ↓                                           │
│  LoadPurchaseById                                   │
│         ↓                                           │
│  PurchaseDetailLoaded                               │
└──────────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────┐
│ Navigate to:                                         │
│ ReceivingFormPage(                                   │
│   purchase: purchase,                                │
│   existingReceiving: _receivingToEdit ✅            │
│ )                                                    │
└──────────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────┐
│ Receiving Form Page                                  │
│                                                      │
│  initState()                                         │
│         ↓                                           │
│  existingReceiving != null? ✅                      │
│         ↓                                           │
│  _initializeFromReceiving()                         │
│         ↓                                           │
│  Loop receiving.items:                              │
│    - poQuantity == 0? → isAdditional = true ✅      │
│    - Create dummy PurchaseItem with qty=0           │
│    - Restore all fields                             │
│         ↓                                           │
│  UI renders with:                                   │
│    - PO items (editable)                            │
│    - Additional items (with badge) ✅               │
│    - Edit/Delete buttons for additional items       │
│         ↓                                           │
│  User edits/saves                                   │
│         ↓                                           │
│  UpdateReceivingEvent ✅                            │
└──────────────────────────────────────────────────────┘
```

---

## Item Identification Logic

### In Database:
| Item Type | poQuantity | Flag |
|-----------|-----------|------|
| PO Item   | > 0       | - |
| Additional| 0         | - |

### In Memory (_ReceivingItem):
| Item Type | poQuantity | isAdditionalItem |
|-----------|-----------|------------------|
| PO Item   | > 0       | false |
| Additional| 0         | **true** ✅ |

### In UI:
| Item Type | Badge | Qty Label | Harga Label | Actions |
|-----------|-------|-----------|-------------|---------|
| PO Item   | -     | "Qty PO: X" | "Harga PO: Rp X" | - |
| Additional| 🟧 TAMBAHAN | "Item Tambahan" | "Harga Bebas" | ✏️ ❌ |

---

## Benefits

### Before Fix:
- ❌ Edit receiving → Item tambahan hilang
- ❌ Data inconsistent
- ❌ User bingung kenapa item hilang
- ❌ Harus re-create receiving dari awal

### After Fix:
- ✅ Edit receiving → Semua item muncul (PO + Additional)
- ✅ Item tambahan marked dengan badge
- ✅ Bisa edit quantity, harga, discount, tax
- ✅ Bisa tambah item baru lagi
- ✅ Bisa hapus item tambahan
- ✅ Data tetap konsisten

---

## Testing Checklist

### Create Mode (Unchanged):
- [ ] Create new receiving from PO
- [ ] Add additional items
- [ ] Save successfully
- [ ] Additional items saved with poQuantity=0

### Edit Mode (New):
- [ ] Edit existing receiving (without additional items)
- [ ] All PO items displayed correctly
- [ ] Can modify quantity, price, discount, tax
- [ ] Save successfully updates receiving

### Edit Mode with Additional Items:
- [ ] Edit receiving that has additional items
- [ ] Additional items displayed with badge "TAMBAHAN"
- [ ] Additional items have correct data (qty, price, discount, tax)
- [ ] Additional items show "Item Tambahan (Tidak di PO)" label
- [ ] Additional items show "Harga Bebas" label
- [ ] Edit button (✏️) works for additional items
- [ ] Can modify additional item quantity & price via dialog
- [ ] Delete button (❌) works for additional items
- [ ] Can add more additional items in edit mode
- [ ] Save successfully updates receiving with all items
- [ ] Reload edit → All items still there (including additional)

### Edge Cases:
- [ ] Edit receiving with only additional items (no PO items)
- [ ] Edit receiving, delete all additional items, save
- [ ] Edit receiving, add new additional item, save
- [ ] Edit receiving, modify PO item and additional item, save
- [ ] Cancel edit → No changes saved

---

## Related Files

- `lib/features/purchase/presentation/pages/receiving_form_page.dart` - Main edit support
- `lib/features/purchase/presentation/pages/receiving_history_page.dart` - Navigation logic
- `lib/features/purchase/presentation/bloc/receiving_event.dart` - UpdateReceivingEvent
- `lib/features/purchase/domain/entities/receiving.dart` - Receiving entity

---

## Notes

### Important Points:
1. **poQuantity = 0** is the marker for additional items in database
2. **isAdditionalItem flag** is runtime-only (not persisted)
3. **Dummy PurchaseItem** created for additional items with qty=0
4. **UpdateReceivingEvent** used for edit mode
5. **Original metadata preserved** (createdAt, receivingDate, receivedBy)

### Why Two Initialization Methods?
- `_initializeItems()`: Create mode - simple, from PO only
- `_initializeFromReceiving()`: Edit mode - complex, from receiving with additional item support

### Why Store Receiving in State?
- Need to pass it from ReceivingBloc listener → PurchaseBloc listener → Navigator
- Can't pass via event/state between different BLoCs
- Cleared after navigation to prevent memory leak

---

**Status**: ✅ IMPLEMENTED  
**Date**: October 17, 2025  
**Version**: 1.2  
**Priority**: HIGH - Critical for data consistency
