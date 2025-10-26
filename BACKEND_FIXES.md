# Backend Fixes Required

## 1. Product API - Branch Filtering Issue

### Problem

API endpoint `/api/v2/products` menggunakan `LEFT JOIN product_stocks` dengan filter `branchId`, yang menyebabkan produk yang tidak punya stock di branch tertentu tidak muncul dalam hasil.

**Current Query:**

```sql
SELECT p.*, c.name as category_name,
       ps.quantity as stock_quantity,
       ps.available_quantity
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN product_stocks ps ON p.id = ps.product_id
WHERE p.deleted_at IS NULL
AND (ps.branch_id = $branchId OR ps.branch_id IS NULL)
```

**Consequence:** Jika PostgreSQL punya 6 produk tapi hanya 2 yang punya stock di branch user, maka hanya 2 yang tampil.

### Solution

Pisahkan query untuk **Management** vs **POS**:

#### Management (Get All Products)

Tidak perlu filter branch - tampilkan semua produk:

```sql
SELECT p.*, c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.deleted_at IS NULL
ORDER BY p.created_at DESC
```

#### POS (Get Products with Stock)

Filter berdasarkan stock yang tersedia di branch:

```sql
SELECT p.*, c.name as category_name,
       COALESCE(ps.quantity, 0) as stock_quantity,
       COALESCE(ps.available_quantity, 0) as available_quantity
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN product_stocks ps ON p.id = ps.product_id AND ps.branch_id = $branchId
WHERE p.deleted_at IS NULL
  AND p.is_active = true
  AND (ps.available_quantity > 0 OR p.is_trackable = false)
ORDER BY p.name ASC
```

### Implementation

Modify `backend_v2/src/controllers/productController.js`:

```javascript
export const getAllProducts = async (req, res) => {
  const {
    page = 1,
    limit = 20,
    search = "",
    categoryId,
    isActive,
    branchId,
    forPos = false, // New parameter to differentiate
  } = req.query;

  const offset = (page - 1) * limit;

  let query;

  if (forPos && branchId) {
    // POS mode: Filter by stock availability
    query = `
      SELECT p.*, c.name as category_name,
             COALESCE(ps.quantity, 0) as stock_quantity,
             COALESCE(ps.available_quantity, 0) as available_quantity
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN product_stocks ps ON p.id = ps.product_id AND ps.branch_id = $1
      WHERE p.deleted_at IS NULL
        AND p.is_active = true
    `;
  } else {
    // Management mode: Get all products
    query = `
      SELECT p.*, c.name as category_name,
             ps.quantity as stock_quantity,
             ps.available_quantity
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN product_stocks ps ON p.id = ps.product_id
      WHERE p.deleted_at IS NULL
    `;
  }

  // Rest of filters...
};
```

## 2. Product Stock Initialization

### Problem

Produk baru yang dibuat tidak otomatis punya entry di `product_stocks` untuk setiap branch.

### Solution

Saat create product, otomatis create stock entry untuk semua branch:

```javascript
export const createProduct = async (req, res) => {
  const client = await db.connect();

  try {
    await client.query('BEGIN');

    // Create product
    const productResult = await client.query(
      'INSERT INTO products (...) VALUES (...) RETURNING *',
      [...]
    );

    const product = productResult.rows[0];

    // Get all branches
    const branchesResult = await client.query(
      'SELECT id FROM branches WHERE deleted_at IS NULL'
    );

    // Create stock entry for each branch
    for (const branch of branchesResult.rows) {
      await client.query(
        `INSERT INTO product_stocks
         (product_id, branch_id, quantity, available_quantity)
         VALUES ($1, $2, 0, 0)`,
        [product.id, branch.id]
      );
    }

    await client.query('COMMIT');
    res.json({ success: true, data: product });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
```

## 3. Frontend Quick Fix (Already Applied)

Modified `lib/features/product/data/datasources/product_remote_data_source.dart`:

- Removed `branchId` parameter from getAllProducts()
- Increased limit to 1000 to bypass pagination
- This ensures management features show ALL products

## Testing Checklist

- [ ] Test GET `/api/v2/products` tanpa branchId → harus return semua 6 produk
- [ ] Test GET `/api/v2/products?branchId=X` → harus return semua produk dengan stock info untuk branch X
- [ ] Test GET `/api/v2/products?forPos=true&branchId=X` → hanya produk dengan stock > 0 di branch X
- [ ] Test create product → harus auto-create stock entries untuk semua branch
- [ ] Test frontend setelah backend fix → harus tampil semua 6 produk
