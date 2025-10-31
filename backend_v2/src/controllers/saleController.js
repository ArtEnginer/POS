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

  // Get total count (fixed: use different alias to avoid conflict)
  const countQuery = `SELECT COUNT(*) FROM (${query}) AS sales_count`;
  const countResult = await db.query(countQuery, params);
  const total = parseInt(countResult.rows[0].count);

  // Add pagination
  query += ` ORDER BY s.sale_date DESC LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

  const result = await db.query(query, params);

  // Fetch items for each sale
  const salesWithItems = await Promise.all(
    result.rows.map(async (sale) => {
      const itemsResult = await db.query(
        `SELECT si.*, p.name as product_name, p.sku
         FROM sale_items si
         LEFT JOIN products p ON si.product_id = p.id
         WHERE si.sale_id = $1
         ORDER BY si.id`,
        [sale.id]
      );

      // Fetch returns for this sale
      const returnsResult = await db.query(
        `SELECT sr.*, 
                u.full_name as processed_by_name,
                (SELECT JSON_AGG(
                  JSON_BUILD_OBJECT(
                    'id', ri.id,
                    'productId', ri.product_id,
                    'productName', ri.product_name,
                    'quantity', ri.quantity,
                    'unitPrice', ri.unit_price,
                    'subtotal', ri.subtotal
                  )
                ) FROM return_items ri
                  WHERE ri.return_id = sr.id
                ) as items
         FROM sales_returns sr
         LEFT JOIN users u ON sr.processed_by_user_id = u.id
         WHERE sr.original_sale_id = $1 AND sr.status IN ('processed', 'completed')
         ORDER BY sr.return_date DESC`,
        [sale.id]
      );

      return {
        id: sale.id,
        invoiceNumber: sale.sale_number,
        branchId: sale.branch_id,
        branchName: sale.branch_name,
        customerId: sale.customer_id,
        customerName: sale.customer_name,
        cashierId: sale.cashier_id,
        cashierName: sale.cashier_name,
        createdAt: sale.sale_date || sale.created_at,
        status: sale.status,

        // Financial details
        subtotal: parseFloat(sale.subtotal),
        discount: parseFloat(sale.discount_amount || 0),
        discountPercentage: parseFloat(sale.discount_percentage || 0),
        tax: parseFloat(sale.tax_amount || 0),
        total: parseFloat(sale.total_amount),
        rounding: parseFloat(sale.rounding || 0),
        grandTotal: parseFloat(sale.grand_total || sale.total_amount),
        paidAmount: parseFloat(sale.paid_amount || 0),
        changeAmount: parseFloat(sale.change_amount || 0),

        // Cost & Profit
        totalCost: parseFloat(sale.total_cost || 0),
        grossProfit: parseFloat(sale.gross_profit || 0),
        profitMargin: parseFloat(sale.profit_margin || 0),

        // Payment
        paymentMethod: sale.payment_method,
        paymentReference: sale.payment_reference,

        // Additional info
        notes: sale.notes,
        cashierLocation: sale.cashier_location,
        deviceInfo: sale.device_info,

        // Items with complete details
        items: itemsResult.rows.map((item) => ({
          productId: item.product_id,
          productName: item.product_name,
          sku: item.sku,
          quantity: parseFloat(item.quantity),
          unitPrice: parseFloat(item.unit_price),
          discountAmount: parseFloat(item.discount_amount || 0),
          discountPercentage: parseFloat(item.discount_percentage || 0),
          taxAmount: parseFloat(item.tax_amount || 0),
          taxPercentage: parseFloat(item.tax_percentage || 0), // ← ADDED
          subtotal: parseFloat(item.subtotal),
          total: parseFloat(item.total),
          costPrice: parseFloat(item.cost_price || 0),
          totalCost: parseFloat(item.total_cost || 0),
          itemProfit: parseFloat(item.item_profit || 0),
          notes: item.notes,
        })),

        // Returns data
        returns: returnsResult.rows.map((ret) => ({
          id: ret.id,
          returnNumber: ret.return_number,
          returnDate: ret.return_date,
          reason: ret.return_reason,
          refundAmount: parseFloat(ret.total_refund || 0),
          status: ret.status,
          processedBy: ret.processed_by_user_id,
          processedByName: ret.processed_by_name,
          items: ret.items || [],
        })),
      };
    })
  );

  res.json({
    success: true,
    data: salesWithItems,
    total,
    page: parseInt(page),
    limit: parseInt(limit),
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
    rounding,
    grandTotal,
    paidAmount,
    changeAmount,
    paymentMethod,
    paymentReference,
    notes,
    cashierLocation,
    deviceInfo,
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
        total_amount, rounding, grand_total, paid_amount, change_amount,
        payment_method, payment_reference, notes,
        cashier_location, device_info
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
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
        rounding || 0,
        grandTotal || totalAmount,
        paidAmount,
        changeAmount || 0,
        paymentMethod,
        paymentReference,
        notes,
        cashierLocation || null,
        deviceInfo || {},
      ]
    );

    const sale = saleResult.rows[0];

    // Insert sale items
    for (const item of items) {
      // Get product cost_price if not provided
      let costPrice = item.costPrice || 0;
      if (!item.costPrice) {
        const productResult = await client.query(
          "SELECT cost_price FROM products WHERE id = $1",
          [item.productId]
        );
        if (productResult.rows.length > 0) {
          costPrice = productResult.rows[0].cost_price || 0;
        }
      }

      await client.query(
        `INSERT INTO sale_items (
          sale_id, branch_id, product_id, product_name, sku, quantity,
          unit_price, cost_price, discount_amount, discount_percentage, 
          tax_amount, tax_percentage, subtotal, total, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
        [
          sale.id,
          branchId, // ← ADDED: branch_id for sale_items
          item.productId,
          item.productName,
          item.sku,
          item.quantity,
          item.unitPrice,
          costPrice,
          item.discountAmount || 0,
          item.discountPercentage || 0,
          item.taxAmount || 0,
          item.taxPercentage || 0, // ← ADDED: tax_percentage
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
