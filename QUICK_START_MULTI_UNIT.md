# Quick Start - Multi-Unit & Branch Pricing

## 🚀 Setup Instructions

### 1. Run Database Migration

```powershell
cd backend_v2
node run_multi_unit_migration.js
```

**Expected Output:**
```
🚀 Connecting to database...
✅ Connected to database
📄 Reading migration file...
⚙️  Running migration...
✅ Migration completed successfully!

📊 Migration Summary:
   - Created table: product_units
   - Created table: product_branch_prices
   - Created view: v_product_units_prices
   - Migrated existing products with base units
   - Created default prices for all branches

🎉 Your system now supports:
   ✓ Multi-unit conversion (PCS, BOX, DUS, etc.)
   ✓ Branch-specific pricing
   ✓ Different cost/selling prices per branch and unit
```

### 2. Restart Backend Server

```powershell
cd backend_v2
npm start
```

### 3. Test Flutter App

```powershell
cd management_app
flutter run -d windows
```

## 📱 UI Features

### Product List Page
- ✅ Multi-unit indicator badge (shows number of units)
- ✅ Branch-specific pricing indicator badge
- Located in category column

### Product Detail Page
- ✅ **Units Section**: Displays all units with conversion values
  - Shows base unit
  - Conversion formula
  - Unit status (purchasable/sellable)
  
- ✅ **Pricing Section**: Matrix view of prices per branch
  - Grouped by branch
  - Shows cost price, selling price, and margin
  - Color-coded margins

### Product Form Page
- ⏳ Units Management (Coming Soon)
- ⏳ Pricing Management (Coming Soon)

## 🧪 Testing Guide

### Test 1: Create Multi-Unit Product

```bash
# 1. Login and get token
curl -X POST http://localhost:3000/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Save the token
TOKEN="your_token_here"

# 2. Create a product (or use existing product ID)
PRODUCT_ID=1

# 3. Add BOX unit (1 BOX = 10 PCS)
curl -X POST http://localhost:3000/api/v2/products/$PRODUCT_ID/units \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "unitName": "BOX",
    "conversionValue": 10,
    "isPurchasable": true,
    "isSellable": true,
    "sortOrder": 1
  }'

# 4. Add DUS unit (1 DUS = 100 PCS)
curl -X POST http://localhost:3000/api/v2/products/$PRODUCT_ID/units \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "unitName": "DUS",
    "conversionValue": 100,
    "isPurchasable": true,
    "isSellable": true,
    "sortOrder": 2
  }'
```

### Test 2: Set Branch-Specific Pricing

```bash
# Get branch IDs first
curl http://localhost:3000/api/v2/branches \
  -H "Authorization: Bearer $TOKEN"

# Set price for BOX unit in branch 1
curl -X PUT http://localhost:3000/api/v2/products/$PRODUCT_ID/prices \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "branchId": "1",
    "unitId": "2",
    "costPrice": 45000,
    "sellingPrice": 65000,
    "wholesalePrice": 60000
  }'
```

### Test 3: View in Flutter App

1. Open Management App
2. Go to Product List
3. Look for badges:
   - 🔵 Blue badge with number = Multi-unit product
   - 🟢 Green store icon = Branch-specific pricing
4. Click product to see detail
5. Scroll down to see:
   - **Satuan Produk** section (if has multiple units)
   - **Harga Per Cabang** section (if has custom prices)

## 🎯 Visual Indicators

### Product List
```
┌────────────────────────────────────────────┐
│ SKU    │ Name              │ Category      │
├────────────────────────────────────────────┤
│ PRD001 │ Coca Cola         │ Beverage [3] 🏪│
│ PRD002 │ Aqua              │ Beverage      │
└────────────────────────────────────────────┘
         [3] = 3 units       🏪 = Branch pricing
```

### Product Detail - Units Section
```
┌──────────────────────────────────────────────┐
│ Satuan Produk (3 Unit)                       │
├──────────┬─────────────────┬─────────────────┤
│ Satuan   │ Konversi        │ Status          │
├──────────┼─────────────────┼─────────────────┤
│ PCS ✓    │ 1 (Base)        │ [BASE]          │
│ BOX      │ 1 = 10 PCS      │                 │
│ DUS      │ 1 = 100 PCS     │                 │
└──────────┴─────────────────┴─────────────────┘
ℹ️ Unit dasar: PCS. Semua stok dihitung dalam PCS.
```

### Product Detail - Pricing Section
```
┌─────────────────────────────────────────────────────┐
│ Harga Per Cabang (2 Cabang)                        │
├─────────────────────────────────────────────────────┤
│ 🏪 Jakarta Pusat                                    │
├──────┬──────────────┬──────────────┬───────────────┤
│ Unit │ Beli         │ Jual         │ Margin        │
├──────┼──────────────┼──────────────┼───────────────┤
│ PCS  │ Rp 5.000     │ Rp 7.000     │ 40.0%         │
│ BOX  │ Rp 45.000    │ Rp 65.000    │ 44.4%         │
│ DUS  │ Rp 450.000   │ Rp 640.000   │ 42.2%         │
└──────┴──────────────┴──────────────┴───────────────┘
```

## ⚙️ Configuration

### Backend API Base URL
Edit `management_app/lib/core/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api/v2';
```

### Enable Debug Mode
```dart
static const bool enableLogging = true;
```

## 🐛 Troubleshooting

### Issue: Migration failed
**Solution:**
```powershell
# Check database connection
psql -h localhost -U postgres -d pos_enterprise

# Verify tables exist
\dt product_units
\dt product_branch_prices
```

### Issue: Cannot see units/prices in Flutter
**Solution:**
1. Make sure backend is running
2. Check API response includes units and prices:
```bash
curl http://localhost:3000/api/v2/products/1/complete \
  -H "Authorization: Bearer $TOKEN"
```
3. Refresh product list in app

### Issue: Badge not showing
**Solution:**
- Badges only show if:
  - `units.length > 1` (multi-unit badge)
  - `prices.isNotEmpty` (pricing badge)
- Product must be fetched with complete data

## 📚 Next Steps

1. ✅ Test migration on development DB
2. ✅ Verify UI displays correctly
3. ⏳ Implement Units Management Form
4. ⏳ Implement Pricing Management Form
5. ⏳ Test with cashier app integration
6. ⏳ Deploy to staging
7. ⏳ User acceptance testing

## 💡 Pro Tips

1. **Always backup database before migration**
   ```bash
   pg_dump -U postgres pos_enterprise > backup_before_multiunit.sql
   ```

2. **Use bulk pricing update for same price across branches**
   ```bash
   curl -X PUT http://localhost:3000/api/v2/products/$PRODUCT_ID/prices/bulk \
     -H "Authorization: Bearer $TOKEN" \
     -d '{"unitId":"2","costPrice":45000,"sellingPrice":65000}'
   ```

3. **View raw data with SQL**
   ```sql
   -- See all units and prices for a product
   SELECT * FROM v_product_units_prices WHERE product_id = 1;
   ```

## 📞 Support

Jika ada issue, check:
1. Backend logs di terminal
2. Flutter logs dengan `flutter logs`
3. Database dengan `psql`
4. API response dengan curl/Postman

---

**Last Updated**: 2025-11-01
**Version**: 1.0.0
