# Data Mapping: Flutter POS Cashier → Backend V2 PostgreSQL

## 🗄️ Database Schema Mapping

### Sale (Transaction Header)

| Flutter (Hive)     | Backend (PostgreSQL)  | Type     | Required | Notes                               |
| ------------------ | --------------------- | -------- | -------- | ----------------------------------- |
| `invoice_number`   | `sale_number`         | String   | ✅       | Invoice/receipt number              |
| -                  | `branch_id`           | Integer  | ✅       | From `AppConstants.currentBranchId` |
| `customer_id`      | `customer_id`         | Integer  | ❌       | Null for walk-in customers          |
| `cashier_id`       | `cashier_id`          | Integer  | ✅       | Auto from `req.user.id` (JWT)       |
| `subtotal`         | `subtotal`            | Decimal  | ✅       | Total before discount/tax           |
| `discount`         | `discount_amount`     | Decimal  | ✅       | Total discount in Rupiah            |
| -                  | `discount_percentage` | Decimal  | ❌       | Set to 0 (not used)                 |
| `tax`              | `tax_amount`          | Decimal  | ✅       | Tax/PPN amount                      |
| `total`            | `total_amount`        | Decimal  | ✅       | Final total after discount+tax      |
| `paid`             | `paid_amount`         | Decimal  | ✅       | Amount customer paid                |
| `change`           | `change_amount`       | Decimal  | ✅       | Change returned                     |
| `payment_method`   | `payment_method`      | String   | ✅       | cash/debit/credit/qris              |
| -                  | `payment_reference`   | String   | ❌       | For non-cash payment                |
| `note`             | `notes`               | String   | ❌       | Additional notes                    |
| `transaction_date` | `created_at`          | DateTime | ✅       | Auto timestamp                      |

---

### Sale Items (Line Items)

| Flutter (Hive)    | Backend (PostgreSQL)  | Type    | Required | Calculation                                    |
| ----------------- | --------------------- | ------- | -------- | ---------------------------------------------- |
| -                 | `sale_id`             | Integer | ✅       | Auto from parent sale                          |
| `product.id`      | `product_id`          | Integer | ✅       | Product reference                              |
| `product.name`    | `product_name`        | String  | ✅       | Snapshot for history                           |
| `product.barcode` | `sku`                 | String  | ✅       | Barcode/SKU                                    |
| `quantity`        | `quantity`            | Decimal | ✅       | Items sold                                     |
| `product.price`   | `unit_price`          | Decimal | ✅       | Price per unit                                 |
| `discountAmount`  | `discount_amount`     | Decimal | ✅       | **Calculated**: `subtotal * (discount% / 100)` |
| `discount`        | `discount_percentage` | Decimal | ✅       | Discount % for this item                       |
| -                 | `tax_amount`          | Decimal | ✅       | Set to 0 (tax on header)                       |
| `subtotal`        | `subtotal`            | Decimal | ✅       | **Calculated**: `unit_price * quantity`        |
| `total`           | `total`               | Decimal | ✅       | **Calculated**: `subtotal - discount_amount`   |
| `note`            | `notes`               | String  | ❌       | Item-specific notes                            |

---

## 📝 Flutter Model Structure

### CartItemModel

```dart
class CartItemModel {
  final ProductModel product;
  final int quantity;
  final double discount;        // Percentage (e.g., 10 = 10%)
  final String? note;

  // Calculated getters
  double get subtotal => product.price * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'discount': discount,           // Percentage
      'discount_amount': discountAmount, // Rupiah
      'subtotal': subtotal,           // Rupiah
      'total': total,                 // Rupiah
      'note': note,
    };
  }
}
```

### SaleModel

```dart
class SaleModel {
  final String id;                    // UUID
  final String invoiceNumber;         // INV-20251029-001
  final DateTime transactionDate;
  final List<CartItemModel> items;
  final double subtotal;              // Sum of all items subtotal
  final double discount;              // Global discount (Rupiah)
  final double tax;                   // Tax/PPN (Rupiah)
  final double total;                 // subtotal - discount + tax
  final double paid;
  final double change;
  final String paymentMethod;         // cash/debit/credit/qris
  final String? customerId;
  final String? customerName;
  final String cashierId;
  final String cashierName;
  final String? note;
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;
}
```

---

## 🔄 Data Transformation (API Service)

### syncSale() Transformation

```dart
// INPUT: SaleModel.toJson()
{
  "invoice_number": "INV-20251029-001",
  "items": [
    {
      "product": { "id": 1, "name": "Aqua 600ml", "price": 3500, "barcode": "8992761111" },
      "quantity": 2,
      "discount": 10,              // 10%
      "discount_amount": 700,      // CALCULATED
      "subtotal": 7000,            // CALCULATED
      "total": 6300,               // CALCULATED
      "note": null
    }
  ],
  "subtotal": 7000,
  "discount": 500,
  "tax": 0,
  "total": 6500,
  "paid": 10000,
  "change": 3500,
  "payment_method": "cash",
  "customer_id": null,
  "note": null
}

// OUTPUT: Backend V2 Format
{
  "saleNumber": "INV-20251029-001",
  "branchId": "3",                    // From AppConstants
  "customerId": null,
  "items": [
    {
      "productId": 1,
      "productName": "Aqua 600ml",
      "sku": "8992761111",
      "quantity": 2,
      "unitPrice": 3500,
      "discountAmount": 700,          // CALCULATED from discount%
      "discountPercentage": 10,
      "taxAmount": 0,
      "subtotal": 7000,               // CALCULATED: unitPrice * quantity
      "total": 6300,                  // CALCULATED: subtotal - discountAmount
      "notes": null
    }
  ],
  "subtotal": 7000,
  "discountAmount": 500,
  "discountPercentage": 0,
  "taxAmount": 0,
  "totalAmount": 6500,
  "paidAmount": 10000,
  "changeAmount": 3500,
  "paymentMethod": "cash",
  "paymentReference": null,
  "notes": null
}
```

---

## ✅ Validation Rules

### Sale Level

- ✅ `saleNumber` must be unique
- ✅ `branchId` must exist in branches table
- ✅ `items` array must not be empty
- ✅ `totalAmount` must match calculated total
- ✅ `paidAmount` must be ≥ `totalAmount`
- ✅ `changeAmount` = `paidAmount - totalAmount`

### Item Level

- ✅ `productId` must exist in products table
- ✅ `quantity` must be > 0
- ✅ `unitPrice` must be > 0
- ✅ `subtotal` must match `unitPrice * quantity`
- ✅ `discountAmount` must be ≤ `subtotal`
- ✅ `total` must match `subtotal - discountAmount`

---

## 🧮 Calculation Examples

### Example 1: Single Item, No Discount

```
Product: Aqua 600ml (Rp 3,500)
Quantity: 2

Item Subtotal = 3,500 × 2 = Rp 7,000
Item Discount = 0%
Item Total = Rp 7,000

Sale Subtotal = Rp 7,000
Sale Discount = Rp 0
Sale Tax = Rp 0
Sale Total = Rp 7,000
```

### Example 2: Single Item, 10% Discount

```
Product: Aqua 600ml (Rp 3,500)
Quantity: 2
Item Discount: 10%

Item Subtotal = 3,500 × 2 = Rp 7,000
Item Discount Amount = 7,000 × 10% = Rp 700
Item Total = 7,000 - 700 = Rp 6,300

Sale Subtotal = Rp 7,000
Sale Discount = Rp 0 (global)
Sale Tax = Rp 0
Sale Total = Rp 6,300
```

### Example 3: Multiple Items + Global Discount

```
Item 1: Aqua 600ml (Rp 3,500) × 2 = Rp 7,000
Item 2: Indomie (Rp 2,500) × 3 = Rp 7,500

Sale Subtotal = 7,000 + 7,500 = Rp 14,500
Sale Discount = Rp 500 (global discount)
Sale Tax = Rp 0
Sale Total = 14,500 - 500 = Rp 14,000
```

---

## 🔧 Backend Database Schema

### sales table

```sql
CREATE TABLE sales (
  id SERIAL PRIMARY KEY,
  sale_number VARCHAR(50) UNIQUE NOT NULL,
  branch_id INTEGER NOT NULL REFERENCES branches(id),
  customer_id INTEGER REFERENCES customers(id),
  cashier_id INTEGER NOT NULL REFERENCES users(id),
  subtotal DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  total_amount DECIMAL(15,2) NOT NULL,
  paid_amount DECIMAL(15,2) NOT NULL,
  change_amount DECIMAL(15,2) DEFAULT 0,
  payment_method VARCHAR(20) NOT NULL,
  payment_reference VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### sale_items table

```sql
CREATE TABLE sale_items (
  id SERIAL PRIMARY KEY,
  sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  product_name VARCHAR(255) NOT NULL,
  sku VARCHAR(100),
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  subtotal DECIMAL(15,2) NOT NULL,  -- REQUIRED!
  total DECIMAL(15,2) NOT NULL,     -- REQUIRED!
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🐛 Common Issues & Fixes

### ❌ "null value in column 'subtotal' violates not-null constraint"

**Cause**: Item data tidak menyertakan `subtotal` field  
**Fix**:

```dart
// CartItemModel.toJson() must include:
'subtotal': subtotal,  // Calculated: price * quantity
'total': total,        // Calculated: subtotal - discount_amount
```

### ❌ "type '\_Map<dynamic, dynamic>' is not a subtype"

**Cause**: Hive data type tidak match  
**Fix**: Use safe type checking

```dart
if (data is Map<String, dynamic>) {
  return Model.fromJson(data);
} else if (data is Map) {
  return Model.fromJson(Map<String, dynamic>.from(data));
}
```

### ❌ "401 Unauthorized" saat sync

**Cause**: Token tidak di-set di header  
**Fix**:

```dart
await authService.login(username, password);
// Token otomatis di-set ke API service
```

---

## 📊 Testing Checklist

- [ ] Create sale with 1 item, no discount
- [ ] Create sale with 1 item, 10% discount
- [ ] Create sale with multiple items
- [ ] Create sale with global discount
- [ ] Verify all fields in PostgreSQL
- [ ] Check sale_items.subtotal is NOT NULL
- [ ] Check sale_items.total is NOT NULL
- [ ] Verify calculations match

---

**Last Updated**: October 29, 2025  
**Status**: ✅ Fixed - All fields now properly calculated and sent
