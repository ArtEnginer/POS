import db from "../config/database.js";
import { cache } from "../config/redis.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";
import xlsx from "xlsx";
import fs from "fs";
import path from "path";
import { emitEvent } from "../utils/socket-io.js";

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
  let {
    page = 1,
    limit = 20,
    search = "",
    categoryId,
    isActive,
    branchId,
    sortBy = "created_at", // Default sort by created_at
    sortOrder = "desc", // Default descending (newest first)
  } = req.query;

  // Auto-filter by user's default branch if not super_admin
  if (!branchId && req.user.role !== "super_admin") {
    // Get user's default branch
    const userBranch = await db.query(
      `SELECT branch_id FROM user_branches 
       WHERE user_id = $1 AND is_default = true 
       LIMIT 1`,
      [req.user.id]
    );
    if (userBranch.rows.length > 0) {
      branchId = userBranch.rows[0].branch_id;
    }
  }

  const offset = (page - 1) * limit;

  // Map sortBy to actual database column names
  const sortColumnMap = {
    sku: "p.sku",
    barcode: "p.barcode",
    name: "p.name",
    stock: "total_quantity",
    created_at: "p.created_at",
  };

  const sortColumn = sortColumnMap[sortBy] || "p.created_at";
  const sortDirection = sortOrder.toLowerCase() === "asc" ? "ASC" : "DESC";

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

  // Add sorting and pagination
  query += ` ORDER BY ${sortColumn} ${sortDirection} LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

  // Execute query
  const result = await db.query(query, params);

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProducts = result.rows.map((product) => ({
    ...product,
    id: product.id.toString(),
    category_id: product.category_id ? product.category_id.toString() : null,
  }));

  res.json({
    success: true,
    data: formattedProducts,
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

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProduct = {
    ...product,
    id: product.id.toString(),
    category_id: product.category_id ? product.category_id.toString() : null,
  };

  res.json({
    success: true,
    data: formattedProduct,
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

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProduct = {
    ...result.rows[0],
    id: result.rows[0].id.toString(),
    category_id: result.rows[0].category_id
      ? result.rows[0].category_id.toString()
      : null,
  };

  res.json({
    success: true,
    data: formattedProduct,
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
    `SELECT p.id, p.sku, p.barcode, p.name, p.is_active, p.base_unit,
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

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProducts = result.rows.map((product) => ({
    ...product,
    id: product.id.toString(),
    category_id: product.category_id ? product.category_id.toString() : null,
  }));

  res.json({
    success: true,
    data: formattedProducts,
  });
};

/**
 * Get low stock products with pagination
 */
export const getLowStockProducts = async (req, res) => {
  const { branchId, page = 1, limit = 20, search = "" } = req.query;

  const offset = (page - 1) * limit;

  let query = `
    SELECT p.*, ps.quantity, ps.available_quantity, ps.branch_id,
           c.name as category_name
    FROM products p
    INNER JOIN product_stocks ps ON p.id = ps.product_id
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.deleted_at IS NULL
    AND p.is_trackable = true
    AND ps.available_quantity <= p.reorder_point
  `;

  const params = [];
  let paramIndex = 1;

  if (branchId) {
    query += ` AND ps.branch_id = $${paramIndex}`;
    params.push(branchId);
    paramIndex++;
  }

  if (search) {
    query += ` AND (p.name ILIKE $${paramIndex} OR p.sku ILIKE $${paramIndex} OR p.barcode ILIKE $${paramIndex})`;
    params.push(`%${search}%`);
    paramIndex++;
  }

  // Get total count
  const countQuery = `
    SELECT COUNT(*) 
    FROM products p
    INNER JOIN product_stocks ps ON p.id = ps.product_id
    WHERE p.deleted_at IS NULL
    AND p.is_trackable = true
    AND ps.available_quantity <= p.reorder_point
    ${branchId ? `AND ps.branch_id = $1` : ""}
    ${
      search
        ? `AND (p.name ILIKE $${branchId ? 2 : 1} OR p.sku ILIKE $${
            branchId ? 2 : 1
          } OR p.barcode ILIKE $${branchId ? 2 : 1})`
        : ""
    }
  `;

  const countParams = [];
  if (branchId) countParams.push(branchId);
  if (search) countParams.push(`%${search}%`);

  const countResult = await db.query(countQuery, countParams);
  const total = parseInt(countResult.rows[0].count);

  // Add sorting and pagination
  query += ` ORDER BY ps.available_quantity ASC LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

  const result = await db.query(query, params);

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProducts = result.rows.map((product) => ({
    ...product,
    id: product.id.toString(),
    category_id: product.category_id ? product.category_id.toString() : null,
    branch_id: product.branch_id ? product.branch_id.toString() : null,
  }));

  res.json({
    success: true,
    data: formattedProducts,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / limit),
    },
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
    baseUnit,
    minStock,
    maxStock,
    reorderPoint,
    imageUrl,
    attributes,
    taxRate,
    discountPercentage,
  } = req.body;

  // Validate required fields
  if (!sku || !name) {
    throw new ValidationError("SKU and name are required");
  }

  // Use transaction to ensure product and stock records are created together
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Insert product (without cost_price and selling_price)
    const productResult = await client.query(
      `INSERT INTO products (
        sku, barcode, name, description, category_id, base_unit,
        min_stock, max_stock, reorder_point,
        image_url, attributes, tax_rate, discount_percentage
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        sku,
        barcode,
        name,
        description,
        categoryId,
        baseUnit || "PCS",
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

    // 🚀 EMIT REAL-TIME EVENT: Product Created
    emitEvent("product:created", {
      action: "created",
      product: product,
      timestamp: new Date().toISOString(),
    });
    logger.info(
      `📢 WebSocket event emitted: product:created for ${product.id}`
    );

    // Format response: convert IDs to strings for Flutter compatibility
    const formattedProduct = {
      ...product,
      id: product.id.toString(),
      category_id: product.category_id ? product.category_id.toString() : null,
    };

    res.status(201).json({
      success: true,
      data: formattedProduct,
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
    baseUnit: "base_unit",
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

  // 🚀 EMIT REAL-TIME EVENT: Product Updated
  emitEvent("product:updated", {
    action: "updated",
    product: product,
    timestamp: new Date().toISOString(),
  });
  logger.info(`📢 WebSocket event emitted: product:updated for ${id}`);

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedProduct = {
    ...product,
    id: product.id.toString(),
    category_id: product.category_id ? product.category_id.toString() : null,
  };

  res.json({
    success: true,
    data: formattedProduct,
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

  // 🚀 EMIT REAL-TIME EVENT: Product Deleted
  emitEvent("product:deleted", {
    action: "deleted",
    productId: id,
    timestamp: new Date().toISOString(),
  });
  logger.info(`📢 WebSocket event emitted: product:deleted for ${id}`);

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

/**
 * Import products from Excel/CSV file
 */
export const importProducts = async (req, res) => {
  if (!req.file) {
    throw new ValidationError("No file uploaded");
  }

  const filePath = req.file.path;
  const client = await db.getClient();

  try {
    // Read the Excel/CSV file
    const workbook = xlsx.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = xlsx.utils.sheet_to_json(worksheet);

    if (data.length === 0) {
      throw new ValidationError("File is empty or invalid format");
    }

    logger.info(`Starting import of ${data.length} rows`);

    // Get all active branches ONCE (outside transaction)
    const branchesResult = await client.query(
      "SELECT id FROM branches WHERE is_active = true AND deleted_at IS NULL"
    );
    const branches = branchesResult.rows;

    // Get all existing SKUs ONCE to avoid repeated queries
    const existingSKUsResult = await client.query(
      "SELECT sku FROM products WHERE deleted_at IS NULL"
    );
    const existingSKUs = new Set(existingSKUsResult.rows.map((row) => row.sku));

    const results = {
      success: [],
      errors: [],
      skipped: [],
    };

    // Process in batches of 100 to avoid long-running transactions
    const BATCH_SIZE = 100;
    const totalBatches = Math.ceil(data.length / BATCH_SIZE);

    for (let batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      const startIdx = batchIndex * BATCH_SIZE;
      const endIdx = Math.min(startIdx + BATCH_SIZE, data.length);
      const batch = data.slice(startIdx, endIdx);

      logger.info(
        `Processing batch ${batchIndex + 1}/${totalBatches} (rows ${
          startIdx + 1
        }-${endIdx})`
      );

      await client.query("BEGIN");

      try {
        for (let i = 0; i < batch.length; i++) {
          const row = batch[i];
          const rowNumber = startIdx + i + 2; // Excel rows start at 1, header is row 1

          try {
            // Validate required fields
            const sku = String(row.SKU || row.sku || row.Sku || "").trim();
            const name = String(
              row.Nama || row.Name || row.name || row.NAMA || ""
            ).trim();

            if (!sku || !name) {
              results.errors.push({
                row: rowNumber,
                sku: sku || "(empty)",
                error: `Missing required fields (SKU and Name)`,
              });
              continue;
            }

            // Check if exists
            if (existingSKUs.has(sku)) {
              results.skipped.push({
                row: rowNumber,
                sku,
                reason: "Product already exists",
              });
              continue;
            }

            // Parse other fields
            const barcode = String(row.Barcode || row.barcode || sku).trim();
            const description =
              String(
                row.Deskripsi || row.Description || row.description || ""
              ).trim() || null;
            const categoryId =
              row["Category ID"] || row.categoryId || row.category_id || null;
            const baseUnit = String(
              row.Satuan ||
                row["Base Unit"] ||
                row.Unit ||
                row.unit ||
                row.baseUnit ||
                "PCS"
            ).trim();
            const minStock =
              parseInt(
                String(
                  row["Min Stock"] || row.minStock || row.min_stock || 0
                ).replace(/[^\d]/g, "")
              ) || 0;
            const maxStock =
              parseInt(
                String(
                  row["Max Stock"] || row.maxStock || row.max_stock || 0
                ).replace(/[^\d]/g, "")
              ) || 0;
            const reorderPoint =
              parseInt(
                String(
                  row["Reorder Point"] ||
                    row.reorderPoint ||
                    row.reorder_point ||
                    0
                ).replace(/[^\d]/g, "")
              ) || 0;
            const taxRate =
              parseFloat(
                String(
                  row["Tax Rate"] || row.taxRate || row.tax_rate || 0
                ).replace(/[^\d.-]/g, "")
              ) || 0;
            const discountPercentage =
              parseFloat(
                String(
                  row["Discount"] || row.discount || row.discountPercentage || 0
                ).replace(/[^\d.-]/g, "")
              ) || 0;

            // Insert product
            const productResult = await client.query(
              `INSERT INTO products (
                sku, barcode, name, description, category_id, base_unit,
                min_stock, max_stock, reorder_point,
                tax_rate, discount_percentage, is_active
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
              RETURNING id, sku, name`,
              [
                sku,
                barcode,
                name,
                description,
                categoryId,
                baseUnit,
                minStock,
                maxStock,
                reorderPoint,
                taxRate,
                discountPercentage,
              ]
            );

            const product = productResult.rows[0];

            // Batch insert stock records
            if (branches.length > 0) {
              const stockValues = branches
                .map((branch) => `(${product.id}, ${branch.id}, 0, 0)`)
                .join(", ");
              await client.query(
                `INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity)
                 VALUES ${stockValues}`
              );
            }

            existingSKUs.add(sku);

            results.success.push({
              row: rowNumber,
              id: product.id,
              sku: product.sku,
              name: product.name,
            });
          } catch (error) {
            results.errors.push({
              row: rowNumber,
              sku: row.SKU || row.sku || "(unknown)",
              error: error.message,
            });
          }
        }

        await client.query("COMMIT");
        logger.info(
          `Batch ${batchIndex + 1}/${totalBatches} completed: ${
            results.success.length
          } total success`
        );
      } catch (error) {
        await client.query("ROLLBACK");
        logger.error(`Batch ${batchIndex + 1} failed: ${error.message}`);
        throw error;
      }
    }

    // Clean up uploaded file
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    // Clear cache
    await cache.delPattern("products:*");

    logger.info(
      `Products imported: ${results.success.length} success, ${results.errors.length} errors, ${results.skipped.length} skipped by user ${req.user.id}`
    );

    res.json({
      success: true,
      message: `Import completed: ${results.success.length} products added`,
      data: {
        total: data.length,
        imported: results.success.length,
        errors: results.errors.length,
        skipped: results.skipped.length,
      },
      details: results,
    });
  } catch (error) {
    await client.query("ROLLBACK");

    // Clean up uploaded file on error
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    logger.error(`Failed to import products: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Download product import template
 */
export const downloadImportTemplate = async (req, res) => {
  try {
    // Create template with sample data
    const template = [
      {
        SKU: "PRD001",
        Barcode: "1234567890123",
        Nama: "Contoh Produk 1",
        Deskripsi: "Deskripsi produk",
        "Category ID": "",
        Satuan: "PCS",
        "Harga Beli": 10000,
        "Harga Jual": 15000,
        "Min Stock": 10,
        "Max Stock": 100,
        "Reorder Point": 20,
        "Tax Rate": 0,
        Discount: 0,
      },
      {
        SKU: "PRD002",
        Barcode: "1234567890124",
        Nama: "Contoh Produk 2",
        Deskripsi: "Deskripsi produk 2",
        "Category ID": "",
        Satuan: "BOX",
        "Harga Beli": 50000,
        "Harga Jual": 75000,
        "Min Stock": 5,
        "Max Stock": 50,
        "Reorder Point": 10,
        "Tax Rate": 11,
        Discount: 5,
      },
    ];

    // Create workbook and worksheet
    const wb = xlsx.utils.book_new();
    const ws = xlsx.utils.json_to_sheet(template);

    // Set column widths
    ws["!cols"] = [
      { wch: 10 }, // SKU
      { wch: 15 }, // Barcode
      { wch: 25 }, // Nama
      { wch: 30 }, // Deskripsi
      { wch: 12 }, // Category ID
      { wch: 10 }, // Satuan
      { wch: 12 }, // Harga Beli
      { wch: 12 }, // Harga Jual
      { wch: 10 }, // Min Stock
      { wch: 10 }, // Max Stock
      { wch: 12 }, // Reorder Point
      { wch: 10 }, // Tax Rate
      { wch: 10 }, // Discount
    ];

    xlsx.utils.book_append_sheet(wb, ws, "Products");

    // Generate buffer
    const buffer = xlsx.write(wb, { type: "buffer", bookType: "xlsx" });

    // Send file
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );
    res.setHeader(
      "Content-Disposition",
      "attachment; filename=template_import_produk.xlsx"
    );

    res.send(buffer);

    logger.info(`Template downloaded by user ${req.user.id}`);
  } catch (error) {
    logger.error(`Failed to generate template: ${error.message}`);
    throw error;
  }
};
