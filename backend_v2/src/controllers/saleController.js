import db from "../config/database.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";

/**
 * Get all sales
 */
export const getAllSales = async (req, res) => {
  const {
    page = 1,
    limit = 20,
    startDate,
    endDate,
    status,
    branchId,
    cashierId,
  } = req.query;

  const offset = (page - 1) * limit;

  let query = `
    SELECT s.*, u.full_name as cashier_name, c.name as customer_name,
           b.name as branch_name
    FROM sales s
    LEFT JOIN users u ON s.cashier_id = u.id
    LEFT JOIN customers c ON s.customer_id = c.id
    LEFT JOIN branches b ON s.branch_id = b.id
    WHERE s.deleted_at IS NULL
  `;

  const params = [];
  let paramIndex = 1;

  if (startDate) {
    query += ` AND s.sale_date >= $${paramIndex}`;
    params.push(startDate);
    paramIndex++;
  }

  if (endDate) {
    query += ` AND s.sale_date <= $${paramIndex}`;
    params.push(endDate);
    paramIndex++;
  }

  if (status) {
    query += ` AND s.status = $${paramIndex}`;
    params.push(status);
    paramIndex++;
  }

  if (branchId) {
    query += ` AND s.branch_id = $${paramIndex}`;
    params.push(branchId);
    paramIndex++;
  }

  if (cashierId) {
    query += ` AND s.cashier_id = $${paramIndex}`;
    params.push(cashierId);
    paramIndex++;
  }

  // Get total count
  const countQuery = `SELECT COUNT(*) FROM (${query}) s`;
  const countResult = await db.query(countQuery, params);
  const total = parseInt(countResult.rows[0].count);

  // Add pagination
  query += ` ORDER BY s.sale_date DESC LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

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
 * Get sale by ID
 */
export const getSaleById = async (req, res) => {
  const { id } = req.params;

  const saleResult = await db.query(
    `SELECT s.*, u.full_name as cashier_name, c.name as customer_name,
            b.name as branch_name
     FROM sales s
     LEFT JOIN users u ON s.cashier_id = u.id
     LEFT JOIN customers c ON s.customer_id = c.id
     LEFT JOIN branches b ON s.branch_id = b.id
     WHERE s.id = $1 AND s.deleted_at IS NULL`,
    [id]
  );

  if (saleResult.rows.length === 0) {
    throw new NotFoundError("Sale not found");
  }

  const sale = saleResult.rows[0];

  // Get sale items
  const itemsResult = await db.query(
    `SELECT * FROM sale_items WHERE sale_id = $1`,
    [id]
  );

  sale.items = itemsResult.rows;

  res.json({
    success: true,
    data: sale,
  });
};

/**
 * Get today's sales
 */
export const getTodaySales = async (req, res) => {
  const { branchId } = req.query;

  let query = `
    SELECT * FROM sales
    WHERE DATE(sale_date) = CURRENT_DATE
    AND deleted_at IS NULL
  `;

  const params = [];
  if (branchId) {
    query += " AND branch_id = $1";
    params.push(branchId);
  }

  query += " ORDER BY sale_date DESC";

  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows,
  });
};

/**
 * Get sales summary
 */
export const getSalesSummary = async (req, res) => {
  const { startDate, endDate, branchId } = req.query;

  let query = `
    SELECT 
      COUNT(*) as total_transactions,
      SUM(total_amount) as total_sales,
      SUM(paid_amount) as total_paid,
      AVG(total_amount) as average_sale,
      SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
      SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_count
    FROM sales
    WHERE deleted_at IS NULL
  `;

  const params = [];
  let paramIndex = 1;

  if (startDate) {
    query += ` AND sale_date >= $${paramIndex}`;
    params.push(startDate);
    paramIndex++;
  }

  if (endDate) {
    query += ` AND sale_date <= $${paramIndex}`;
    params.push(endDate);
    paramIndex++;
  }

  if (branchId) {
    query += ` AND branch_id = $${paramIndex}`;
    params.push(branchId);
    paramIndex++;
  }

  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows[0],
  });
};

/**
 * Create new sale
 */
export const createSale = async (req, res) => {
  const {
    saleNumber,
    branchId,
    customerId,
    items,
    subtotal,
    discountAmount,
    discountPercentage,
    taxAmount,
    totalAmount,
    paidAmount,
    changeAmount,
    paymentMethod,
    paymentReference,
    notes,
  } = req.body;

  // Validate
  if (!saleNumber || !branchId || !items || items.length === 0) {
    throw new ValidationError("Sale number, branch ID, and items are required");
  }

  // Use transaction
  await db.transaction(async (client) => {
    // Insert sale
    const saleResult = await client.query(
      `INSERT INTO sales (
        sale_number, branch_id, customer_id, cashier_id,
        subtotal, discount_amount, discount_percentage, tax_amount,
        total_amount, paid_amount, change_amount,
        payment_method, payment_reference, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        saleNumber,
        branchId,
        customerId,
        req.user.id,
        subtotal,
        discountAmount || 0,
        discountPercentage || 0,
        taxAmount || 0,
        totalAmount,
        paidAmount,
        changeAmount || 0,
        paymentMethod,
        paymentReference,
        notes,
      ]
    );

    const sale = saleResult.rows[0];

    // Insert sale items
    for (const item of items) {
      await client.query(
        `INSERT INTO sale_items (
          sale_id, product_id, product_name, sku, quantity,
          unit_price, discount_amount, discount_percentage, tax_amount,
          subtotal, total, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          sale.id,
          item.productId,
          item.productName,
          item.sku,
          item.quantity,
          item.unitPrice,
          item.discountAmount || 0,
          item.discountPercentage || 0,
          item.taxAmount || 0,
          item.subtotal,
          item.total,
          item.notes,
        ]
      );

      // Update product stock
      await client.query(
        `UPDATE product_stocks
         SET quantity = quantity - $1, updated_at = NOW()
         WHERE product_id = $2 AND branch_id = $3`,
        [item.quantity, item.productId, branchId]
      );
    }

    logger.info(`Sale created: ${sale.id} by user ${req.user.id}`);

    res.status(201).json({
      success: true,
      data: sale,
      message: "Sale created successfully",
    });
  });
};

/**
 * Update sale
 */
export const updateSale = async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  // Check if sale exists and is not completed
  const existing = await db.query(
    "SELECT * FROM sales WHERE id = $1 AND deleted_at IS NULL",
    [id]
  );

  if (existing.rows.length === 0) {
    throw new NotFoundError("Sale not found");
  }

  if (existing.rows[0].status === "completed") {
    throw new ValidationError("Cannot update completed sale");
  }

  // Build update query
  const fields = Object.keys(updates);
  const values = Object.values(updates);

  const setClause = fields
    .map((field, index) => `${field} = $${index + 2}`)
    .join(", ");

  const result = await db.query(
    `UPDATE sales SET ${setClause}, updated_at = NOW() WHERE id = $1 RETURNING *`,
    [id, ...values]
  );

  logger.info(`Sale updated: ${id} by user ${req.user.id}`);

  res.json({
    success: true,
    data: result.rows[0],
    message: "Sale updated successfully",
  });
};

/**
 * Cancel sale
 */
export const cancelSale = async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `UPDATE sales SET status = 'cancelled', updated_at = NOW()
     WHERE id = $1 AND deleted_at IS NULL
     RETURNING *`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Sale not found");
  }

  // TODO: Restore stock

  logger.info(`Sale cancelled: ${id} by user ${req.user.id}`);

  res.json({
    success: true,
    data: result.rows[0],
    message: "Sale cancelled successfully",
  });
};

/**
 * Refund sale
 */
export const refundSale = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const result = await db.query(
    `UPDATE sales SET status = 'refunded', notes = $2, updated_at = NOW()
     WHERE id = $1 AND status = 'completed' AND deleted_at IS NULL
     RETURNING *`,
    [id, reason]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Sale not found or cannot be refunded");
  }

  // TODO: Restore stock and process refund

  logger.info(`Sale refunded: ${id} by user ${req.user.id}`);

  res.json({
    success: true,
    data: result.rows[0],
    message: "Sale refunded successfully",
  });
};
