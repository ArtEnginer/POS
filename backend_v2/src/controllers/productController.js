import db from "../config/database.js";
import { cache } from "../config/redis.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";

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

  let query = `
    SELECT p.*, c.name as category_name,
           ps.quantity as stock_quantity,
           ps.available_quantity
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN product_stocks ps ON p.id = ps.product_id
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

  if (branchId) {
    query += ` AND (ps.branch_id = $${paramIndex} OR ps.branch_id IS NULL)`;
    params.push(branchId);
    paramIndex++;
  }

  // Get total count
  const countQuery = `SELECT COUNT(DISTINCT p.id) FROM (${query}) p`;
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

  // Try cache first
  const cacheKey = `product:${id}`;
  const cached = await cache.get(cacheKey);

  if (cached) {
    return res.json({
      success: true,
      data: cached,
      cached: true,
    });
  }

  const result = await db.query(
    `SELECT p.*, c.name as category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     WHERE p.id = $1 AND p.deleted_at IS NULL`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  const product = result.rows[0];

  // Cache for 1 hour
  await cache.set(cacheKey, product, 3600);

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

  const result = await db.query(
    `SELECT p.*, c.name as category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
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
  const { q, limit = 10 } = req.query;

  if (!q) {
    throw new ValidationError("Search query required");
  }

  const result = await db.query(
    `SELECT id, sku, barcode, name, selling_price, is_active
     FROM products
     WHERE deleted_at IS NULL
     AND (name ILIKE $1 OR sku ILIKE $1 OR barcode ILIKE $1)
     ORDER BY name
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

  const result = await db.query(
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

  const product = result.rows[0];

  // Clear product cache
  await cache.delPattern("products:*");

  logger.info(`Product created: ${product.id} by user ${req.user.id}`);

  res.status(201).json({
    success: true,
    data: product,
    message: "Product created successfully",
  });
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

  // Check if stock record exists
  const existing = await db.query(
    "SELECT * FROM product_stocks WHERE product_id = $1 AND branch_id = $2",
    [id, branchId]
  );

  let result;

  if (existing.rows.length === 0) {
    // Create new stock record
    result = await db.query(
      `INSERT INTO product_stocks (product_id, branch_id, quantity)
       VALUES ($1, $2, $3) RETURNING *`,
      [id, branchId, quantity]
    );
  } else {
    // Update existing record
    let newQuantity = quantity;

    if (operation === "add") {
      newQuantity = existing.rows[0].quantity + quantity;
    } else if (operation === "subtract") {
      newQuantity = existing.rows[0].quantity - quantity;
    }

    result = await db.query(
      `UPDATE product_stocks 
       SET quantity = $1, updated_at = NOW()
       WHERE product_id = $2 AND branch_id = $3
       RETURNING *`,
      [newQuantity, id, branchId]
    );
  }

  // Clear cache
  await cache.delPattern(`stock:*:${id}`);

  logger.info(
    `Stock updated for product ${id} at branch ${branchId} by user ${req.user.id}`
  );

  res.json({
    success: true,
    data: result.rows[0],
    message: "Stock updated successfully",
  });
};
