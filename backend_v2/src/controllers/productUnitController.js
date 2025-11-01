import db from "../config/database.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";

/**
 * Sanitize price value to match DECIMAL(15,2) database constraint
 * - Converts to number
 * - Rounds to 2 decimal places
 * - Validates max value
 * - Returns as STRING to avoid JavaScript number overflow in PostgreSQL binding
 * @param {*} price - Price value to sanitize
 * @param {boolean} allowNull - Whether null is allowed (default: true)
 * @returns {string|null} Sanitized price as string or null
 */
const sanitizePrice = (price, allowNull = true) => {
  // Handle null/undefined/empty
  if (price === null || price === undefined || price === "") {
    return allowNull ? null : "0";
  }

  // Convert to string first, then parse to handle large integers
  const str = String(price).trim();
  const num = parseFloat(str);

  if (isNaN(num)) return allowNull ? null : "0";
  if (num < 0) return "0"; // Negative prices not allowed

  // Check max value BEFORE rounding for DECIMAL(15,2): 9,999,999,999,999.99 (13 digits before decimal)
  if (num > 9999999999999.99) {
    throw new ValidationError(
      `Price too large. Maximum value: 9,999,999,999,999.99 (received: ${num})`
    );
  }

  // Round to 2 decimal places to match DECIMAL(15,2)
  const rounded = Math.round(num * 100) / 100;

  // Return as STRING with 2 decimal precision to avoid overflow in PostgreSQL parameter binding
  return rounded.toFixed(2);
};

/**
 * Get all units for a product
 */
export const getProductUnits = async (req, res) => {
  const { productId } = req.params;

  const result = await db.query(
    `SELECT pu.*, p.name as product_name, p.sku
     FROM product_units pu
     JOIN products p ON pu.product_id = p.id
     WHERE pu.product_id = $1 AND pu.deleted_at IS NULL
     ORDER BY pu.sort_order ASC, pu.conversion_value ASC`,
    [productId]
  );

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedUnits = result.rows.map((unit) => ({
    ...unit,
    id: unit.id.toString(),
    product_id: unit.product_id.toString(),
  }));

  res.json({
    success: true,
    data: formattedUnits,
  });
};

/**
 * Get product prices per branch for specific unit
 */
export const getProductPrices = async (req, res) => {
  const { productId } = req.params;
  let { unitId, branchId } = req.query;

  // Auto-filter by user's default branch if not super_admin
  if (!branchId && req.user.role !== "super_admin") {
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

  let query = `
    SELECT pbp.*, 
           b.code as branch_code, 
           b.name as branch_name,
           pu.unit_name,
           pu.conversion_value,
           p.name as product_name,
           p.sku
    FROM product_branch_prices pbp
    JOIN branches b ON pbp.branch_id = b.id
    JOIN products p ON pbp.product_id = p.id
    LEFT JOIN product_units pu ON pbp.product_unit_id = pu.id
    WHERE pbp.product_id = $1 
    AND pbp.deleted_at IS NULL
    AND b.deleted_at IS NULL
  `;

  const params = [productId];
  let paramIndex = 2;

  if (unitId) {
    query += ` AND pbp.product_unit_id = $${paramIndex}`;
    params.push(unitId);
    paramIndex++;
  }

  if (branchId) {
    query += ` AND pbp.branch_id = $${paramIndex}`;
    params.push(branchId);
    paramIndex++;
  }

  query += ` ORDER BY b.name, pu.sort_order`;

  const result = await db.query(query, params);

  // Format response: convert IDs to strings for Flutter compatibility
  const formattedPrices = result.rows.map((price) => ({
    ...price,
    id: price.id.toString(),
    product_id: price.product_id.toString(),
    branch_id: price.branch_id.toString(),
    product_unit_id: price.product_unit_id
      ? price.product_unit_id.toString()
      : null,
  }));

  res.json({
    success: true,
    data: formattedPrices,
  });
};

/**
 * Create product unit
 */
export const createProductUnit = async (req, res) => {
  const { productId } = req.params;
  const {
    unitName,
    conversionValue,
    isBaseUnit,
    isPurchasable,
    isSellable,
    barcode,
    sortOrder,
  } = req.body;

  // Validate required fields
  if (!unitName || !conversionValue) {
    throw new ValidationError("Unit name and conversion value are required");
  }

  if (conversionValue <= 0) {
    throw new ValidationError("Conversion value must be greater than 0");
  }

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Check if product exists
    const productCheck = await client.query(
      "SELECT id FROM products WHERE id = $1 AND deleted_at IS NULL",
      [productId]
    );

    if (productCheck.rows.length === 0) {
      throw new NotFoundError("Product not found");
    }

    // If this is base unit, ensure no other base unit exists
    if (isBaseUnit) {
      const existingBase = await client.query(
        `SELECT id FROM product_units 
         WHERE product_id = $1 AND is_base_unit = TRUE AND deleted_at IS NULL`,
        [productId]
      );

      if (existingBase.rows.length > 0) {
        throw new ValidationError(
          "Product already has a base unit. Please update existing base unit instead."
        );
      }
    }

    // Create unit
    const unitResult = await client.query(
      `INSERT INTO product_units (
        product_id, unit_name, conversion_value, is_base_unit,
        is_purchasable, is_sellable, barcode, sort_order
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        productId,
        unitName.toUpperCase(),
        conversionValue,
        isBaseUnit || false,
        isPurchasable !== false,
        isSellable !== false,
        barcode,
        sortOrder || 0,
      ]
    );

    const unit = unitResult.rows[0];

    // Create default prices for all active branches (set to 0, user must input manually)
    const branches = await client.query(
      "SELECT id FROM branches WHERE is_active = TRUE AND deleted_at IS NULL"
    );

    // Insert default price records (all prices set to 0, user will update later)
    for (const branch of branches.rows) {
      await client.query(
        `INSERT INTO product_branch_prices (
          product_id, branch_id, product_unit_id, cost_price, selling_price
        ) VALUES ($1, $2, $3, 0, 0)
        ON CONFLICT (product_id, branch_id, product_unit_id) DO NOTHING`,
        [productId, branch.id, unit.id]
      );
    }

    await client.query("COMMIT");

    logger.info(
      `Product unit created: ${unit.id} (${unit.unit_name}) for product ${productId} by user ${req.user.id}`
    );

    // Format response: convert IDs to strings for Flutter compatibility
    const formattedUnit = {
      ...unit,
      id: unit.id.toString(),
      product_id: unit.product_id.toString(),
    };

    res.status(201).json({
      success: true,
      data: formattedUnit,
      message: "Product unit created successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to create product unit: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Update product unit
 */
export const updateProductUnit = async (req, res) => {
  const { productId, unitId } = req.params;
  const {
    unitName,
    conversionValue,
    isPurchasable,
    isSellable,
    barcode,
    sortOrder,
  } = req.body;

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Check if unit exists
    const existing = await client.query(
      `SELECT * FROM product_units 
       WHERE id = $1 AND product_id = $2 AND deleted_at IS NULL`,
      [unitId, productId]
    );

    if (existing.rows.length === 0) {
      throw new NotFoundError("Product unit not found");
    }

    const existingUnit = existing.rows[0];

    // Build update query
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (unitName !== undefined) {
      updates.push(`unit_name = $${paramIndex}`);
      values.push(unitName.toUpperCase());
      paramIndex++;
    }

    if (conversionValue !== undefined) {
      if (conversionValue <= 0) {
        throw new ValidationError("Conversion value must be greater than 0");
      }
      // Don't allow changing base unit conversion
      if (existingUnit.is_base_unit && conversionValue !== 1) {
        throw new ValidationError("Base unit conversion must be 1");
      }
      updates.push(`conversion_value = $${paramIndex}`);
      values.push(conversionValue);
      paramIndex++;
    }

    if (isPurchasable !== undefined) {
      updates.push(`is_purchasable = $${paramIndex}`);
      values.push(isPurchasable);
      paramIndex++;
    }

    if (isSellable !== undefined) {
      updates.push(`is_sellable = $${paramIndex}`);
      values.push(isSellable);
      paramIndex++;
    }

    if (barcode !== undefined) {
      updates.push(`barcode = $${paramIndex}`);
      values.push(barcode);
      paramIndex++;
    }

    if (sortOrder !== undefined) {
      updates.push(`sort_order = $${paramIndex}`);
      values.push(sortOrder);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new ValidationError("No fields to update");
    }

    // Update unit
    values.push(unitId, productId);
    const result = await client.query(
      `UPDATE product_units 
       SET ${updates.join(", ")}, updated_at = NOW()
       WHERE id = $${paramIndex} AND product_id = $${paramIndex + 1}
       RETURNING *`,
      values
    );

    const unit = result.rows[0];

    await client.query("COMMIT");

    logger.info(
      `Product unit updated: ${unitId} for product ${productId} by user ${req.user.id}`
    );

    // Format response: convert IDs to strings for Flutter compatibility
    const formattedUnit = {
      ...unit,
      id: unit.id.toString(),
      product_id: unit.product_id.toString(),
    };

    res.json({
      success: true,
      data: formattedUnit,
      message: "Product unit updated successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to update product unit: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Delete product unit (soft delete)
 */
export const deleteProductUnit = async (req, res) => {
  const { productId, unitId } = req.params;

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Check if unit exists and is not base unit
    const existing = await client.query(
      `SELECT * FROM product_units 
       WHERE id = $1 AND product_id = $2 AND deleted_at IS NULL`,
      [unitId, productId]
    );

    if (existing.rows.length === 0) {
      throw new NotFoundError("Product unit not found");
    }

    if (existing.rows[0].is_base_unit) {
      throw new ValidationError("Cannot delete base unit");
    }

    // Soft delete unit
    await client.query(
      "UPDATE product_units SET deleted_at = NOW() WHERE id = $1",
      [unitId]
    );

    // Soft delete associated prices
    await client.query(
      "UPDATE product_branch_prices SET deleted_at = NOW() WHERE product_unit_id = $1",
      [unitId]
    );

    await client.query("COMMIT");

    logger.info(
      `Product unit deleted: ${unitId} for product ${productId} by user ${req.user.id}`
    );

    res.json({
      success: true,
      message: "Product unit deleted successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to delete product unit: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Update product price for specific branch and unit
 */
export const updateProductPrice = async (req, res) => {
  const { productId } = req.params;
  let {
    branchId,
    unitId,
    costPrice,
    sellingPrice,
    wholesalePrice,
    memberPrice,
  } = req.body;

  if (!branchId || !unitId) {
    throw new ValidationError("Branch ID and Unit ID are required");
  }

  if (sellingPrice === undefined || sellingPrice < 0) {
    throw new ValidationError("Valid selling price is required");
  }

  // Log original values for debugging
  logger.info(
    `Updating price - Product: ${productId}, Branch: ${branchId}, Unit: ${unitId}, ` +
      `Cost: ${costPrice}, Selling: ${sellingPrice}, Wholesale: ${wholesalePrice}, Member: ${memberPrice}`
  );

  // Sanitize all prices to match DECIMAL(15,2) database constraint
  costPrice = sanitizePrice(costPrice, true); // Allow null
  sellingPrice = sanitizePrice(sellingPrice, false); // Required, default to 0
  wholesalePrice = sanitizePrice(wholesalePrice, true); // Allow null
  memberPrice = sanitizePrice(memberPrice, true); // Allow null

  // Log sanitized values for debugging
  logger.info(
    `Sanitized prices - Cost: ${costPrice}, Selling: ${sellingPrice}, ` +
      `Wholesale: ${wholesalePrice}, Member: ${memberPrice}`
  );

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Convert IDs to string first to avoid overflow in verification query
    const productIdStr = productId.toString();
    const branchIdStr = branchId.toString();
    const unitIdStr = unitId.toString();

    // Verify product, branch, and unit exist
    const checks = await client.query(
      `SELECT 
        (SELECT COUNT(*) FROM products WHERE id = $1::INTEGER AND deleted_at IS NULL) as product_exists,
        (SELECT COUNT(*) FROM branches WHERE id = $2::INTEGER AND deleted_at IS NULL) as branch_exists,
        (SELECT COUNT(*) FROM product_units WHERE id = $3::INTEGER AND product_id = $1::INTEGER AND deleted_at IS NULL) as unit_exists`,
      [productIdStr, branchIdStr, unitIdStr]
    );

    const { product_exists, branch_exists, unit_exists } = checks.rows[0];

    if (product_exists === "0") throw new NotFoundError("Product not found");
    if (branch_exists === "0") throw new NotFoundError("Branch not found");
    if (unit_exists === "0") throw new NotFoundError("Product unit not found");

    // Price values are already strings from sanitizePrice function
    // No need for additional conversion - use them directly
    const costPriceStr = costPrice; // Already string or null from sanitizePrice
    const sellingPriceStr = sellingPrice; // Already string or null from sanitizePrice
    const wholesalePriceStr = wholesalePrice; // Already string or null from sanitizePrice
    const memberPriceStr = memberPrice; // Already string or null from sanitizePrice

    // Upsert price with explicit type casting for all parameters
    const result = await client.query(
      `INSERT INTO product_branch_prices (
        product_id, branch_id, product_unit_id, 
        cost_price, selling_price, wholesale_price, member_price
      ) VALUES ($1::INTEGER, $2::INTEGER, $3::INTEGER, $4::DECIMAL(15,2), $5::DECIMAL(15,2), $6::DECIMAL(15,2), $7::DECIMAL(15,2))
      ON CONFLICT (product_id, branch_id, product_unit_id) 
      DO UPDATE SET
        cost_price = EXCLUDED.cost_price,
        selling_price = EXCLUDED.selling_price,
        wholesale_price = EXCLUDED.wholesale_price,
        member_price = EXCLUDED.member_price,
        updated_at = NOW(),
        deleted_at = NULL
      RETURNING *`,
      [
        productIdStr,
        branchIdStr,
        unitIdStr,
        costPriceStr,
        sellingPriceStr,
        wholesalePriceStr,
        memberPriceStr,
      ]
    );

    const price = result.rows[0];

    await client.query("COMMIT");

    logger.info(
      `Product price updated: Product ${productId}, Branch ${branchId}, Unit ${unitId} by user ${req.user.id}`
    );

    // Format response: convert IDs to strings for Flutter compatibility
    const formattedPrice = {
      ...price,
      id: price.id.toString(),
      product_id: price.product_id.toString(),
      branch_id: price.branch_id.toString(),
      product_unit_id: price.product_unit_id
        ? price.product_unit_id.toString()
        : null,
    };

    res.json({
      success: true,
      data: formattedPrice,
      message: "Product price updated successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to update product price: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Bulk update prices for a product across all branches
 */
export const bulkUpdatePrices = async (req, res) => {
  const { productId } = req.params;
  const { unitId, costPrice, sellingPrice, wholesalePrice, memberPrice } =
    req.body;

  if (!unitId) {
    throw new ValidationError("Unit ID is required");
  }

  if (sellingPrice === undefined || sellingPrice < 0) {
    throw new ValidationError("Valid selling price is required");
  }

  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    // Get all active branches
    const branches = await client.query(
      "SELECT id FROM branches WHERE is_active = TRUE AND deleted_at IS NULL"
    );

    let updated = 0;

    for (const branch of branches.rows) {
      await client.query(
        `INSERT INTO product_branch_prices (
          product_id, branch_id, product_unit_id, 
          cost_price, selling_price, wholesale_price, member_price
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (product_id, branch_id, product_unit_id) 
        DO UPDATE SET
          cost_price = EXCLUDED.cost_price,
          selling_price = EXCLUDED.selling_price,
          wholesale_price = EXCLUDED.wholesale_price,
          member_price = EXCLUDED.member_price,
          updated_at = NOW(),
          deleted_at = NULL`,
        [
          productId,
          branch.id,
          unitId,
          costPrice || 0,
          sellingPrice,
          wholesalePrice,
          memberPrice,
        ]
      );
      updated++;
    }

    await client.query("COMMIT");

    logger.info(
      `Bulk price update: Product ${productId}, Unit ${unitId}, ${updated} branches by user ${req.user.id}`
    );

    res.json({
      success: true,
      message: `Prices updated for ${updated} branches`,
      data: {
        updated,
        unitId: unitId.toString(),
        productId: productId.toString(),
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error(`Failed to bulk update prices: ${error.message}`);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Get product with all units and prices (comprehensive view)
 */
export const getProductComplete = async (req, res) => {
  const { productId } = req.params;
  const { branchId } = req.query;

  // Get product basic info
  const productResult = await db.query(
    `SELECT p.*, c.name as category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     WHERE p.id = $1 AND p.deleted_at IS NULL`,
    [productId]
  );

  if (productResult.rows.length === 0) {
    throw new NotFoundError("Product not found");
  }

  const product = productResult.rows[0];

  // Get all units
  const unitsResult = await db.query(
    `SELECT * FROM product_units 
     WHERE product_id = $1 AND deleted_at IS NULL
     ORDER BY sort_order ASC`,
    [productId]
  );

  // Get prices per branch per unit
  let pricesQuery = `
    SELECT pbp.*, b.code as branch_code, b.name as branch_name,
           pu.unit_name, pu.conversion_value
    FROM product_branch_prices pbp
    JOIN branches b ON pbp.branch_id = b.id
    LEFT JOIN product_units pu ON pbp.product_unit_id = pu.id
    WHERE pbp.product_id = $1 AND pbp.deleted_at IS NULL
  `;

  const pricesParams = [productId];

  if (branchId) {
    pricesQuery += " AND pbp.branch_id = $2";
    pricesParams.push(branchId);
  }

  pricesQuery += " ORDER BY b.name, pu.sort_order";

  const pricesResult = await db.query(pricesQuery, pricesParams);

  res.json({
    success: true,
    data: {
      ...product,
      units: unitsResult.rows,
      prices: pricesResult.rows,
    },
  });
};
