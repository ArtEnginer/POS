# Units & Pricing Management - Integration Guide

## Overview
Dokumentasi ini menjelaskan cara mengintegrasikan Units Management dan Pricing Management widgets ke dalam Product Form Page.

## Files Created
1. `lib/features/product/presentation/widgets/product_units_form_tab.dart`
2. `lib/features/product/presentation/widgets/product_pricing_form_tab.dart`

## Integration Steps

### Step 1: Add Tab Controller to ProductFormPage

Update `_ProductFormPageState` class:

```dart
class _ProductFormPageState extends State<ProductFormPage> 
    with SingleTickerProviderStateMixin {  // ← Add mixin
  
  // ... existing fields ...
  
  // Add these fields:
  late TabController _tabController;
  List<Map<String, dynamic>> _productUnits = [];
  List<Map<String, dynamic>> _productPrices = [];
  
  @override
  void initState() {
    super.initState();
    
    // ... existing init code ...
    
    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

### Step 2: Update Build Method

Replace the current `SingleChildScrollView` with `TabBarView`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(icon: Icon(Icons.info), text: 'Informasi'),
          Tab(icon: Icon(Icons.inventory_2), text: 'Units'),
          Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Basic Info (existing form)
        _buildBasicInfoTab(),
        
        // Tab 2: Units Management
        ProductUnitsFormTab(
          productId: widget.product?.id,
          initialUnits: widget.product?.units,
          onUnitsChanged: (units) {
            setState(() => _productUnits = units);
          },
        ),
        
        // Tab 3: Pricing Management
        ProductPricingFormTab(
          productId: widget.product?.id,
          initialPrices: widget.product?.prices,
          units: _productUnits,
          onPricesChanged: (prices) {
            setState(() => _productPrices = prices);
          },
        ),
      ],
    ),
    bottomNavigationBar: _buildSaveButton(),
  );
}
```

### Step 3: Extract Basic Info to Method

Move existing form to a method:

```dart
Widget _buildBasicInfoTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... all existing form fields ...
          // (everything currently in body)
        ],
      ),
    ),
  );
}
```

### Step 4: Update Save Button

Move save buttons to persistent bottom bar:

```dart
Widget _buildSaveButton() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    child: Row(
      children: [
        // Info Text
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Units: ${_productUnits.length}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Prices: ${_productPrices.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        
        // Buttons
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                  : const Text('Simpan'),
        ),
      ],
    ),
  );
}
```

### Step 5: Update Save Logic

Modify `_saveProduct` method to include units and prices:

```dart
void _saveProduct() async {
  if (!_formKey.currentState!.validate()) {
    // Show error and switch to basic info tab if validation fails
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mohon lengkapi informasi dasar produk'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Validate units
  if (_productUnits.isEmpty) {
    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Minimal harus ada 1 unit'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Build product data
  final productData = {
    'barcode': _barcodeController.text,
    'sku': _skuController.text,
    'name': _nameController.text,
    'description': _descriptionController.text,
    'categoryId': _selectedCategoryId,
    'unit': _selectedUnit,
    'costPrice': double.tryParse(_costPriceController.text) ?? 0,
    'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0,
    'stock': double.tryParse(_stockController.text) ?? 0,
    'minStock': double.tryParse(_minStockController.text) ?? 0,
    'maxStock': double.tryParse(_maxStockController.text),
    'reorderPoint': double.tryParse(_reorderPointController.text),
    'taxRate': double.tryParse(_taxRateController.text) ?? 0,
    'discountPercentage': double.tryParse(_discountController.text) ?? 0,
    'isActive': _isActive,
    
    // Add units and prices
    'units': _productUnits,
    'prices': _productPrices,
  };

  // Save to backend
  if (widget.product != null) {
    _productBloc.add(
      event.UpdateProduct(
        id: widget.product!.id,
        product: Product.fromJson(productData),
      ),
    );
  } else {
    _productBloc.add(
      event.CreateProduct(product: Product.fromJson(productData)),
    );
  }
}
```

### Step 6: Add Imports

Add imports at the top of `product_form_page.dart`:

```dart
import '../widgets/product_units_form_tab.dart';
import '../widgets/product_pricing_form_tab.dart';
```

## Backend API Updates Required

### 1. Create/Update Product Endpoint
Endpoint harus dapat menerima nested data:

```javascript
POST/PUT /api/products
{
  "name": "Product A",
  "sku": "PROD-001",
  // ... other fields ...
  "units": [
    {
      "unitName": "PCS",
      "conversionValue": 1,
      "isBaseUnit": true,
      "canSell": true,
      "canPurchase": true,
      "barcode": ""
    },
    {
      "unitName": "BOX",
      "conversionValue": 10,
      "isBaseUnit": false,
      "canSell": true,
      "canPurchase": true,
      "barcode": "BOX123"
    }
  ],
  "prices": [
    {
      "branchId": "1",
      "productUnitId": null,
      "costPrice": 3000,
      "sellingPrice": 5000,
      "wholesalePrice": 4500,
      "memberPrice": 4800,
      "isActive": true
    }
  ]
}
```

### 2. Backend Controller Logic

```javascript
// productController.js
async createProduct(req, res) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // 1. Insert product
    const productResult = await client.query(
      'INSERT INTO products (...) VALUES (...) RETURNING id',
      [...]
    );
    const productId = productResult.rows[0].id;
    
    // 2. Insert units
    if (req.body.units && req.body.units.length > 0) {
      for (const unit of req.body.units) {
        await client.query(
          `INSERT INTO product_units 
           (product_id, unit_name, conversion_value, is_base_unit, 
            can_sell, can_purchase, barcode, sort_order)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            productId,
            unit.unitName,
            unit.conversionValue,
            unit.isBaseUnit,
            unit.canSell,
            unit.canPurchase,
            unit.barcode,
            unit.sortOrder || 0
          ]
        );
      }
    }
    
    // 3. Insert prices
    if (req.body.prices && req.body.prices.length > 0) {
      for (const price of req.body.prices) {
        await client.query(
          `INSERT INTO product_branch_prices 
           (product_id, branch_id, product_unit_id, cost_price, 
            selling_price, wholesale_price, member_price, 
            margin_percentage, is_active)
           VALUES ($1, $2, $3, $4, $5, $6, $7, 
                   ((($5 - $4) / $4) * 100), $8)`,
          [
            productId,
            price.branchId,
            price.productUnitId,
            price.costPrice,
            price.sellingPrice,
            price.wholesalePrice,
            price.memberPrice,
            price.isActive !== false
          ]
        );
      }
    }
    
    await client.query('COMMIT');
    res.status(201).json({
      success: true,
      data: { id: productId }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({
      success: false,
      message: error.message
    });
  } finally {
    client.release();
  }
}
```

## Validation Rules

### Units Validation
- ✅ Minimal 1 unit
- ✅ Harus ada 1 unit dasar (isBaseUnit = true)
- ✅ Unit dasar harus conversionValue = 1
- ✅ Nama unit tidak boleh kosong
- ✅ Conversion value > 0

### Prices Validation
- ✅ Cost price >= 0
- ✅ Selling price >= 0
- ✅ Wholesale price (if set) <= selling price
- ✅ Member price (if set) <= selling price
- ✅ Unique combination of branchId + productUnitId

## Testing Checklist

- [ ] Create product dengan 1 unit dasar
- [ ] Create product dengan multiple units
- [ ] Edit product - add unit baru
- [ ] Edit product - delete unit
- [ ] Edit product - change base unit
- [ ] Create product dengan pricing untuk 1 branch
- [ ] Create product dengan pricing untuk multiple branches
- [ ] Bulk add pricing untuk 3 branches × 2 units = 6 entries
- [ ] Edit pricing - update prices
- [ ] Edit pricing - delete price entry
- [ ] Filter pricing by branch
- [ ] Filter pricing by unit
- [ ] Validate margin calculation
- [ ] Save and verify data in database
- [ ] Check Product Detail Page displays units & prices correctly

## Known Limitations

1. **Async Data**: Units harus di-save dulu sebelum prices (karena prices reference unit IDs)
2. **Validation**: Frontend validation saja tidak cukup, backend harus validate juga
3. **Performance**: Jika produk punya banyak units × banyak branches, form bisa jadi lambat
4. **UX**: Jika user switch tab tanpa save, changes bisa hilang

## Future Improvements

- [ ] Add "Save as Draft" functionality
- [ ] Add confirmation dialog saat switch tab dengan unsaved changes
- [ ] Add undo/redo capability
- [ ] Add template pricing (copy from similar product)
- [ ] Add Excel import for bulk units & pricing setup

---

**Last Updated**: November 2024
**Developer**: Angga/GitHub Copilot
