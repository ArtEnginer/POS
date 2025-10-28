import db from "../config/database.js";
import { cache } from "../config/redis.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";

/**
 * Clear product cache (for development/debugging)
 */
export const clearProductCache = async (req, res) => {
  try {
    const { productId } = req.params;

    if (productId) {
      // Clear specific product cache
      const deleted = await cache.del(`product:${productId}`);
      logger.info(
        `Cleared cache for product ${productId}, deleted: ${deleted}`
      );
      return res.json({
        success: true,
        message: `Cache cleared for product ${productId}`,
        deleted,
      });
    } else {
      // Clear all product-related caches
      const keys = await cache.keys("product:*");
      if (keys.length > 0) {
        await cache.del(...keys);
      }
      logger.info(`Cleared ${keys.length} product cache entries`);
      return res.json({
        success: true,
        message: `Cleared ${keys.length} product cache entries`,
      });
    }
  } catch (error) {
    logger.error("Error clearing cache:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to clear cache",
      error: error.message,
    });
  }
};

/**
 * Get all products with pagination and filters
 */
export const getAllProducts = async (req, res) => {
  const {
    page = 1,
    limit = 20,
    search = "",
    categoryId,
    isActive,
    branchId,
  } = req.query;

  const offset = (page - 1) * limit;

  // FIX: Use aggregate to avoid duplicate rows from multi-branch stocks
  let query = `
    SELECT p.*, c.name as category_name,
           COALESCE(stock_agg.total_quantity, 0) as stock_quantity,
           COALESCE(stock_agg.total_available, 0) as available_quantity,
           stock_agg.branch_stocks
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN (
      SELECT 
        product_id,
        ${
          branchId
            ? `MAX(CASE WHEN branch_id = ${parseInt(
                branchId
              )} THEN quantity ELSE 0 END)`
            : "SUM(quantity)"
        } as total_quantity,
        ${
          branchId
            ? `MAX(CASE WHEN branch_id = ${parseInt(
                branchId
              )} THEN available_quantity ELSE 0 END)`
            : "SUM(available_quantity)"
        } as total_available,
        jsonb_agg(
          jsonb_build_object(
            'branchId', branch_id,
            'quantity', quantity,
            'reservedQuantity', reserved_quantity,
            'availableQuantity', available_quantity
          )
        ) as branch_stocks
      FROM product_stocks
      ${branchId ? `WHERE branch_id = ${parseInt(branchId)}` : ""}
      GROUP BY product_id
    ) stock_agg ON p.id = stock_agg.product_id
    WHERE p.deleted_at IS NULL
  `;

  const params = [];
  let paramIndex = 1;

  if (search) {
    query += ` AND (p.name ILIKE $${paramIndex} OR p.sku ILIKE $${paramIndex} OR p.barcode ILIKE $${paramIndex})`;
    params.push(`%${search}%`);
    paramIndex++;
  }

  if (categoryId) {
    query += ` AND p.category_id = $${paramIndex}`;
    params.push(categoryId);
    paramIndex++;
  }

  if (isActive !== undefined) {
    query += ` AND p.is_active = $${paramIndex}`;
    params.push(isActive === "true");
    paramIndex++;
  }

  // Get total count (without stocks to avoid duplicates)
  const countQuery = `
    SELECT COUNT(*) 
    FROM products p 
    WHERE p.deleted_at IS NULL
    ${
      search
        ? `AND (p.name ILIKE $1 OR p.sku ILIKE $1 OR p.barcode ILIKE $1)`
        : ""
    }
    ${categoryId ? `AND p.category_id = $${search ? 2 : 1}` : ""}
    ${
      isActive !== undefined
        ? `AND p.is_active = $${
            search && categoryId ? 3 : search || categoryId ? 2 : 1
          }`
        : ""
    }
  `;
  const countResult = await db.query(countQuery, params);
  const total = parseInt(countResult.rows[0].count);

  // Add pagination
  query += ` ORDER BY p.created_at DESC LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

  // Execute query
  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
};

/**
 * Get product by ID
 */
export const getProductById = async (req, res) => {
  const { id } = req.params;

  // DISABLED CACHE FOR DEVELOPMENT - enable later with proper cache invalidation
  // const cacheKey = `product:${id}`;
  // const cached = await cache.get(cacheKey);
  // if (cached) {
  //   return res.json({ success: true, data: cached, cached: true });
  // }

  // FIX: Include branch_stocks in single product query
  const result = await db.query(
    `SELECT p.*, c.name as category_name,
            COALESCE(stock_agg.total_quantity, 0) as stock_quantity,
            COALESCE(stock_agg.total_available, 0) as available_quantity,
            stock_agg.branch_stocks
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     LEFT JOIN (
       SELECT 
         product_id,
         SUM(quantity) as total_quantity,
         SUM(available_quantity) as total_available,
         jsonb_agg(
           jsonb_build_object(
             'branchId', branch_id,
             'quantity', quantity,
             'reservedQuantity', reserved_quantity,
             'availableQuantity', available_quantity
           )
         ) as branch_stocks
       FROM product_stocks
       GROUP BY product_id
     ) stock_agg ON p.id = stock_agg.product_id
     WHERE p.id = $1 AND p.deleted_at IS NULL`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  const product = result.rows[0];

  // DISABLED CACHE: await cache.set(cacheKey, product, 10);

  res.json({
    success: true,
    data: product,
  });
};

/**
 * Get product by barcode
 */
export const getProductByBarcode = async (req, res) => {
  const { barcode } = req.params;
  const { branchId } = req.query;

  const result = await db.query(
    `SELECT p.*, c.name as category_name,
            COALESCE(stock_agg.total_quantity, 0) as stock_quantity,
            COALESCE(stock_agg.total_available, 0) as available_quantity,
            stock_agg.branch_stocks
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     LEFT JOIN (
       SELECT 
         product_id,
         ${
           branchId
             ? `MAX(CASE WHEN branch_id = ${parseInt(
                 branchId
               )} THEN quantity ELSE 0 END)`
             : "SUM(quantity)"
         } as total_quantity,
         ${
           branchId
             ? `MAX(CASE WHEN branch_id = ${parseInt(
                 branchId
               )} THEN available_quantity ELSE 0 END)`
             : "SUM(available_quantity)"
         } as total_available,
         jsonb_agg(
           jsonb_build_object(
             'branchId', branch_id,
             'quantity', quantity,
             'reservedQuantity', reserved_quantity,
             'availableQuantity', available_quantity
           )
         ) as branch_stocks
       FROM product_stocks
       ${branchId ? `WHERE branch_id = ${parseInt(branchId)}` : ""}
       GROUP BY product_id
     ) stock_agg ON p.id = stock_agg.product_id
     WHERE p.barcode = $1 AND p.deleted_at IS NULL`,
    [barcode]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
};

/**
 * Search products
 */
export const searchProducts = async (req, res) => {
  const { q, limit = 10, branchId } = req.query;

  if (!q) {
    throw new ValidationError("Search query required");
  }

  const result = await db.query(
    `SELECT p.id, p.sku, p.barcode, p.name, p.selling_price, p.is_active, p.cost_price, p.unit,
            COALESCE(stock_agg.total_quantity, 0) as stock_quantity,
            COALESCE(stock_agg.total_available, 0) as available_quantity,
            stock_agg.branch_stocks
     FROM products p
     LEFT JOIN (
       SELECT 
         product_id,
         ${
           branchId
             ? `MAX(CASE WHEN branch_id = ${parseInt(
                 branchId
               )} THEN quantity ELSE 0 END)`
             : "SUM(quantity)"
         } as total_quantity,
         ${
           branchId
             ? `MAX(CASE WHEN branch_id = ${parseInt(
                 branchId
               )} THEN available_quantity ELSE 0 END)`
             : "SUM(available_quantity)"
         } as total_available,
         jsonb_agg(
           jsonb_build_object(
             'branchId', branch_id,
             'quantity', quantity,
             'reservedQuantity', reserved_quantity,
             'availableQuantity', available_quantity
           )
         ) as branch_stocks
       FROM product_stocks
       ${branchId ? `WHERE branch_id = ${parseInt(branchId)}` : ""}
       GROUP BY product_id
     ) stock_agg ON p.id = stock_agg.product_id
     WHERE p.deleted_at IS NULL
     AND (p.name ILIKE $1 OR p.sku ILIKE $1 OR p.barcode ILIKE $1)
     ORDER BY p.name
     LIMIT $2`,
    [`%${q}%`, limit]
  );

  res.json({
    success: true,
    data: result.rows,
  });
};

/**
 * Get low stock products
 */
export const getLowStockProducts = async (req, res) => {
  const { branchId } = req.query;

  let query = `
    SELECT p.*, ps.quantity, ps.available_quantity
    FROM products p
    INNER JOIN product_stocks ps ON p.id = ps.product_id
    WHERE p.deleted_at IS NULL
    AND p.is_trackable = true
    AND ps.available_quantity <= p.reorder_point
  `;

  const params = [];
  if (branchId) {
    query += " AND ps.branch_id = $1";
    params.push(branchId);
  }

  query += " ORDER BY ps.available_quantity ASC";

  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows,
  });
};

/**
 * Create new product
 */
export const createProduct = async (req, res) => {
  const {
    sku,
    barcode,
    name,
    description,
    categoryId,
    unit,
    costPrice,
    sellingPrice,
    minStock,
    maxStock,
    reorderPoint,
    imageUrl,
    attributes,
    taxRate,
    discountPercentage,
  } = req.body;

  // Validate required fields
  if (!sku || !name || !sellingPrice) {
    throw new ValidationError("SKU, name, and selling price are required");
  }

  // Use transaction to ensure product and stock records are created together
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Insert product
    const productResult = await client.query(
      `INSERT INTO products (
        sku, barcode, name, description, category_id, unit,
        cost_price, selling_price, min_stock, max_stock, reorder_point,
        image_url, attributes, tax_rate, discount_percentage
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *`,
      [
        sku,
        barcode,
        name,
        description,
        categoryId,
        unit || "PCS",
        costPrice || 0,
        sellingPrice,
        minStock || 0,
        maxStock || 0,
        reorderPoint || 0,
        imageUrl,
        attributes || {},
        taxRate || 0,
        discountPercentage || 0,
      ]
    );

    const product = productResult.rows[0];

    // FIX: Auto-create initial stock records for all active branches
    const branchesResult = await client.query(
      "SELECT id FROM branches WHERE is_active = true AND deleted_at IS NULL"
    );

    logger.info(
      `Creating stock records for product ${product.id} in ${branchesResult.rows.length} branches`
    );

    for (const branch of branchesResult.rows) {
      await client.query(
        `INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity)
         VALUES ($1, $2, 0, 0)`,
        [product.id, branch.id]
      );
    }

    await client.query("COMMIT");

    // Clear product cache
    await cache.delPattern("products:*");

    logger.info(
      `Product created: ${product.id} (${product.name}) by user ${req.user.id}`
    );

    res.status(201).json({
      success: true,
      data: product,
      message: "Product created successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to create product: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Update product
 */
export const updateProduct = async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  // Check if product exists
  const existing = await db.query(
    "SELECT id FROM products WHERE id = $1 AND deleted_at IS NULL",
    [id]
  );

  if (existing.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  // Map camelCase to snake_case for PostgreSQL
  const fieldMapping = {
    sku: "sku",
    barcode: "barcode",
    name: "name",
    description: "description",
    categoryId: "category_id",
    unit: "unit",
    costPrice: "cost_price",
    sellingPrice: "selling_price",
    minStock: "min_stock",
    maxStock: "max_stock",
    reorderPoint: "reorder_point",
    isActive: "is_active",
    isTrackable: "is_trackable",
    imageUrl: "image_url",
    attributes: "attributes",
    taxRate: "tax_rate",
    discountPercentage: "discount_percentage",
  };

  // Build update query with proper field mapping
  const fields = [];
  const values = [];
  let paramIndex = 2; // Start from 2 because $1 is for id

  Object.keys(updates).forEach((key) => {
    const dbField = fieldMapping[key];
    if (dbField) {
      fields.push(`${dbField} = $${paramIndex}`);
      values.push(updates[key]);
      paramIndex++;
    }
  });

  if (fields.length === 0) {
    throw new ValidationError("No valid fields to update");
  }

  const setClause = fields.join(", ");

  const result = await db.query(
    `UPDATE products SET ${setClause}, updated_at = NOW() WHERE id = $1 RETURNING *`,
    [id, ...values]
  );

  const product = result.rows[0];

  // Clear cache
  await cache.del(`product:${id}`);
  await cache.delPattern("products:*");

  logger.info(`Product updated: ${id} by user ${req.user.id}`);

  res.json({
    success: true,
    data: product,
    message: "Product updated successfully",
  });
};

/**
 * Delete product (soft delete)
 */
export const deleteProduct = async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    "UPDATE products SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
    [id]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  // Clear cache
  await cache.del(`product:${id}`);
  await cache.delPattern("products:*");

  logger.info(`Product deleted: ${id} by user ${req.user.id}`);

  res.json({
    success: true,
    message: "Product deleted successfully",
  });
};

/**
 * Get product stock
 */
export const getProductStock = async (req, res) => {
  const { id } = req.params;
  const { branchId } = req.query;

  let query = `
    SELECT ps.*, b.name as branch_name
    FROM product_stocks ps
    INNER JOIN branches b ON ps.branch_id = b.id
    WHERE ps.product_id = $1
  `;

  const params = [id];

  if (branchId) {
    query += " AND ps.branch_id = $2";
    params.push(branchId);
  }

  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows,
  });
};

/**
 * Update product stock
 */
export const updateProductStock = async (req, res) => {
  const { id } = req.params;
  const { branchId, quantity, operation = "set" } = req.body;

  if (!branchId || quantity === undefined) {
    throw new ValidationError("Branch ID and quantity are required");
  }

  // Validate quantity
  if (typeof quantity !== "number" || isNaN(quantity)) {
    throw new ValidationError("Quantity must be a valid number");
  }

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Check if stock record exists
    const existing = await client.query(
      "SELECT * FROM product_stocks WHERE product_id = $1 AND branch_id = $2",
      [id, branchId]
    );

    let result;
    let oldQuantity = 0;
    let newQuantity = quantity;

    if (existing.rows.length === 0) {
      // Create new stock record
      result = await client.query(
        `INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity)
         VALUES ($1, $2, $3, 0) RETURNING *`,
        [id, branchId, quantity]
      );
      newQuantity = quantity;
    } else {
      oldQuantity = existing.rows[0].quantity;

      // Calculate new quantity based on operation
      if (operation === "add") {
        newQuantity = oldQuantity + quantity;
      } else if (operation === "subtract") {
        newQuantity = oldQuantity - quantity;
      }
      // else operation === 'set', use quantity as-is

      // FIX: Validate stock cannot be negative
      if (newQuantity < 0) {
        throw new ValidationError(
          `Stock cannot be negative. Current: ${oldQuantity}, Requested: ${quantity}, Result: ${newQuantity}`
        );
      }

      // Update stock
      result = await client.query(
        `UPDATE product_stocks 
         SET quantity = $1, updated_at = NOW()
         WHERE product_id = $2 AND branch_id = $3
         RETURNING *`,
        [newQuantity, id, branchId]
      );
    }

    const stock = result.rows[0];

    // FIX: Create audit log
    await client.query(
      `INSERT INTO audit_logs (
        user_id, branch_id, action, entity_type, entity_id, 
        old_data, new_data, ip_address, user_agent
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        req.user.id,
        branchId,
        "stock_update",
        "product_stock",
        id,
        JSON.stringify({ quantity: oldQuantity }),
        JSON.stringify({ quantity: newQuantity, operation }),
        req.ip,
        req.headers["user-agent"],
      ]
    );

    await client.query("COMMIT");

    // Clear cache
    await cache.delPattern(`stock:*:${id}`);
    await cache.delPattern("products:*");

    logger.info(
      `Stock updated: Product ${id} at Branch ${branchId}: ${oldQuantity} → ${newQuantity} (${operation}) by user ${req.user.id}`
    );

    res.json({
      success: true,
      data: stock,
      message: "Stock updated successfully",
      details: {
        oldQuantity,
        newQuantity,
        operation,
        difference: newQuantity - oldQuantity,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to update stock: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};
