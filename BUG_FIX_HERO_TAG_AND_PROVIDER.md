# Bug Fix: Hero Tag Conflicts & Provider Context Issues

## Tanggal
17 Oktober 2025

## Masalah yang Ditemukan

### 1. Hero Tag Conflicts
**Error:**
```
There are multiple heroes that share the same tag within a subtree.
<default FloatingActionButton tag>
```

**Penyebab:**
- Semua FloatingActionButton dalam IndexedStack menggunakan default hero tag
- IndexedStack mempertahankan semua halaman dalam memori, sehingga Flutter mendeteksi multiple heroes dengan tag yang sama

**Dampak:**
- Warning di console
- Tidak crash tapi dapat menyebabkan masalah animasi hero

### 2. Provider Context Error
**Error:**
```
Error: Could not find the correct Provider<CustomerBloc> above this Builder Widget
```

**Penyebab:**
- Dialog builder menggunakan `context` yang sama dengan parent, causing context shadowing
- Dialog's builder context tidak memiliki akses ke CustomerBloc

**Dampak:**
- Error saat mencoba menghapus customer dari dalam dialog

## Solusi yang Diterapkan

### 1. Unique Hero Tags untuk Semua FABs

#### File yang Dimodifikasi:

**a. customer_list_page.dart**
```dart
floatingActionButton: FloatingActionButton.extended(
  heroTag: 'add_customer_fab',  // ← ADDED
  onPressed: () { ... },
  icon: const Icon(Icons.add),
  label: const Text('Tambah Customer'),
)
```

**b. sale_list_page.dart**
```dart
floatingActionButton: FloatingActionButton.extended(
  heroTag: 'add_sale_fab',  // ← ADDED
  onPressed: () { ... },
  icon: const Icon(Icons.add),
  label: const Text('Transaksi Baru'),
)
```

**c. supplier_list_page.dart**
```dart
floatingActionButton: FloatingActionButton.extended(
  heroTag: 'add_supplier_fab',  // ← ADDED
  onPressed: () { ... },
  icon: const Icon(Icons.add),
  label: const Text('Tambah Supplier'),
)
```

**d. purchase_list_page.dart**
```dart
floatingActionButton: FloatingActionButton.extended(
  heroTag: 'add_purchase_fab',  // ← ADDED
  onPressed: () { ... },
  icon: const Icon(Icons.add),
  label: const Text('Pembelian Baru'),
)
```

### 2. Dialog Context Fix

#### customer_list_page.dart - _showDeleteDialog

**Sebelum:**
```dart
void _showDeleteDialog(String id, String name) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(  // ← Shadowing parent context
      // ...
      onPressed: () {
        Navigator.pop(context);  // ← Using dialog context
        context.read<CustomerBloc>()  // ← ERROR: context doesn't have BLoC
            .add(DeleteCustomerEvent(id));
      },
    ),
  );
}
```

**Sesudah:**
```dart
void _showDeleteDialog(String id, String name) {
  showDialog(
    context: context,  // ← Parent context (has BLoC)
    builder: (dialogContext) => AlertDialog(  // ← Different name
      // ...
      onPressed: () {
        Navigator.pop(dialogContext);  // ← Use dialog context for navigation
        context.read<CustomerBloc>()  // ← Use parent context for BLoC
            .add(DeleteCustomerEvent(id));
      },
    ),
  );
}
```

## Penjelasan Teknis

### Hero Tag Pattern
- **Problem:** IndexedStack keeps all pages alive simultaneously
- **Solution:** Each FAB needs unique `heroTag` parameter
- **Pattern:** Use descriptive tags like `'add_[feature]_fab'`

### Dialog Context Pattern
- **Problem:** Dialog builder creates new context without BLoC access
- **Solution:** Use different variable name for dialog context, keep reference to parent context
- **Pattern:**
  ```dart
  showDialog(
    context: context,  // Parent context with BLoC
    builder: (dialogContext) => AlertDialog(
      // Use dialogContext for dialog operations
      // Use context for BLoC operations
    ),
  );
  ```

## Testing Checklist

- [x] Compile tanpa error (`flutter analyze`)
- [x] Hero tag warnings hilang
- [x] Customer page dapat diakses
- [x] Customer list loading berhasil
- [x] Add customer button berfungsi
- [ ] Edit customer berfungsi
- [ ] Delete customer berfungsi (dialog context fix)
- [ ] Search customer berfungsi
- [ ] Navigasi antar halaman tanpa error
- [ ] Semua FAB di halaman lain berfungsi

## Files Modified

1. `lib/features/customer/presentation/pages/customer_list_page.dart`
   - Added `heroTag: 'add_customer_fab'`
   - Fixed dialog context in `_showDeleteDialog`

2. `lib/features/sales/presentation/pages/sale_list_page.dart`
   - Added `heroTag: 'add_sale_fab'`

3. `lib/features/supplier/presentation/pages/supplier_list_page.dart`
   - Added `heroTag: 'add_supplier_fab'`

4. `lib/features/purchase/presentation/pages/purchase_list_page.dart`
   - Added `heroTag: 'add_purchase_fab'`

## Lessons Learned

1. **IndexedStack Consideration:**
   - All child widgets are kept in memory
   - Must handle hero tags carefully
   - Each Hero widget needs unique tag within the stack

2. **Dialog Context Management:**
   - Dialog builder receives new context
   - Parent context must be preserved for BLoC access
   - Use descriptive variable names to avoid confusion

3. **Best Practices:**
   - Always assign unique heroTag to FABs in multi-page apps
   - Use different context variable names in dialogs
   - Test all CRUD operations after context-related changes

## Related Documents

- `CUSTOMER_MASTER_FEATURES.md` - Customer feature documentation
- `RECEIVING_FORM_REBUILD.md` - IndexedStack architecture pattern
- `dashboard_page.dart` - IndexedStack implementation

## Next Steps

1. Test delete customer functionality
2. Verify all other list pages work correctly
3. Monitor for any remaining context-related issues
4. Consider adding heroTag to other Hero widgets if issues arise
