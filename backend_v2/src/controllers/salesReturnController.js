import db from "../config/database.js";

/**
 * Sales Returns Controller
 * Handle return penjualan dengan branch_id dan user_id
 */

// Create new return
export const createReturn = async (req, res) => {
  const client = await db.getClient();

  try {
    console.log(
      "📥 Received return request:",
      JSON.stringify(req.body, null, 2)
    );
    console.log("👤 User from token:", req.user);

    const {
      returnNumber,
      originalSaleId,
      originalInvoiceNumber,
      branchId,
      returnReason,
      totalRefund,
      refundMethod,
      customerId,
      customerName,
      cashierId,
      cashierName,
      items,
      notes,
    } = req.body;

    // Get user_id from JWT token
    const processedByUserId = req.user.id;

    console.log("✅ Parsed data:", {
      returnNumber,
      originalSaleId,
      branchId,
      processedByUserId,
      itemsCount: items?.length || 0,
    });

    // Validate required fields
    if (
      !returnNumber ||
      !originalSaleId ||
      !branchId ||
      !returnReason ||
      !items ||
      items.length === 0
    ) {
      console.log("❌ Validation failed - missing fields");
      return res.status(400).json({
        success: false,
        message: "Missing required fields",
      });
    }

    // Verify sale exists and belongs to the branch
    const saleCheck = await client.query(
      "SELECT id, branch_id, sale_number FROM sales WHERE id = $1 AND deleted_at IS NULL",
      [originalSaleId]
    );

    if (saleCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Original sale not found",
      });
    }

    // Convert both to integers for comparison
    const saleBranchId = parseInt(saleCheck.rows[0].branch_id);
    const requestBranchId = parseInt(branchId);

    console.log(
      `🔍 Branch comparison - Sale: ${saleBranchId}, Request: ${requestBranchId}`
    );

    if (saleBranchId !== requestBranchId) {
      return res.status(403).json({
        success: false,
        message: "Sale does not belong to this branch",
        details: `Sale branch: ${saleBranchId}, Request branch: ${requestBranchId}`,
      });
    }

    await client.query("BEGIN");

    // Insert sales_return
    const returnResult = await client.query(
      `INSERT INTO sales_returns (
        return_number,
        original_sale_id,
        original_invoice_number,
        branch_id,
        return_date,
        return_reason,
        total_refund,
        refund_method,
        customer_id,
        customer_name,
        cashier_id,
        cashier_name,
        processed_by_user_id,
        status,
        notes
      ) VALUES ($1, $2, $3, $4, NOW(), $5, $6, $7, $8, $9, $10, $11, $12, 'pending', $13)
      RETURNING *`,
      [
        returnNumber,
        originalSaleId,
        originalInvoiceNumber || saleCheck.rows[0].sale_number,
        branchId,
        returnReason,
        totalRefund || 0,
        refundMethod || "cash",
        customerId,
        customerName,
        cashierId,
        cashierName,
        processedByUserId,
        notes,
      ]
    );

    const returnId = returnResult.rows[0].id;

    // Insert return_items
    for (const item of items) {
      await client.query(
        `INSERT INTO return_items (
          return_id,
          product_id,
          product_name,
          quantity,
          unit_price,
          subtotal,
          reason
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          returnId,
          item.productId,
          item.productName,
          item.quantity,
          item.unitPrice,
          item.subtotal,
          item.reason,
        ]
      );

      // Update product stock (add back returned quantity)
      await client.query(
        `UPDATE product_stocks 
         SET quantity = quantity + $1,
             updated_at = NOW()
         WHERE product_id = $2 AND branch_id = $3`,
        [item.quantity, item.productId, branchId]
      );
    }

    await client.query("COMMIT");

    // Get complete return data with items
    const completeReturn = await client.query(
      "SELECT * FROM v_sales_returns_detail WHERE id = $1",
      [returnId]
    );

    res.status(201).json({
      success: true,
      message: "Return created successfully",
      data: completeReturn.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Error creating return:", error);
    console.error("📍 Stack trace:", error.stack);
    res.status(500).json({
      success: false,
      message: "Failed to create return",
      error: error.message,
      details: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  } finally {
    client.release();
  }
};

// Get all returns (with optional filters)
export const getReturns = async (req, res) => {
  try {
    const {
      branchId,
      status,
      startDate,
      endDate,
      limit = 100,
      offset = 0,
    } = req.query;

    let query = "SELECT * FROM v_sales_returns_detail WHERE 1=1";
    const params = [];
    let paramCount = 1;

    // Filter by branch (required for cashier role)
    if (branchId) {
      query += ` AND branch_id = $${paramCount}`;
      params.push(branchId);
      paramCount++;
    } else if (req.user.role === "cashier" && req.user.branchId) {
      // Auto-filter by user's branch for cashier
      query += ` AND branch_id = $${paramCount}`;
      params.push(req.user.branchId);
      paramCount++;
    }

    // Filter by status
    if (status) {
      query += ` AND status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    // Filter by date range
    if (startDate) {
      query += ` AND return_date >= $${paramCount}`;
      params.push(startDate);
      paramCount++;
    }

    if (endDate) {
      query += ` AND return_date <= $${paramCount}`;
      params.push(endDate);
      paramCount++;
    }

    // Order by latest first
    query += " ORDER BY return_date DESC";

    // Pagination
    query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    // Get total count
    let countQuery =
      "SELECT COUNT(*) FROM sales_returns WHERE deleted_at IS NULL";
    const countParams = [];
    let countParamCount = 1;

    if (branchId) {
      countQuery += ` AND branch_id = $${countParamCount}`;
      countParams.push(branchId);
      countParamCount++;
    } else if (req.user.role === "cashier" && req.user.branchId) {
      countQuery += ` AND branch_id = $${countParamCount}`;
      countParams.push(req.user.branchId);
      countParamCount++;
    }

    if (status) {
      countQuery += ` AND status = $${countParamCount}`;
      countParams.push(status);
      countParamCount++;
    }

    if (startDate) {
      countQuery += ` AND return_date >= $${countParamCount}`;
      countParams.push(startDate);
      countParamCount++;
    }

    if (endDate) {
      countQuery += ` AND return_date <= $${countParamCount}`;
      countParams.push(endDate);
    }

    const countResult = await db.query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: parseInt(offset) + result.rows.length < totalCount,
      },
    });
  } catch (error) {
    console.error("Error getting returns:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get returns",
      error: error.message,
    });
  }
};

// Get single return by ID
export const getReturnById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      "SELECT * FROM v_sales_returns_detail WHERE id = $1",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Return not found",
      });
    }

    // Check branch access for cashier
    if (req.user.role === "cashier" && req.user.branchId) {
      if (result.rows[0].branch_id !== req.user.branchId) {
        return res.status(403).json({
          success: false,
          message: "Access denied",
        });
      }
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error("Error getting return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get return",
      error: error.message,
    });
  }
};

// Update return status
export const updateReturnStatus = async (req, res) => {
  const client = await db.getClient();

  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!["pending", "processed", "completed", "cancelled"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status value",
      });
    }

    // Check if return exists
    const returnCheck = await client.query(
      "SELECT * FROM sales_returns WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (returnCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Return not found",
      });
    }

    // Check branch access for cashier
    if (req.user.role === "cashier" && req.user.branchId) {
      if (returnCheck.rows[0].branch_id !== req.user.branchId) {
        return res.status(403).json({
          success: false,
          message: "Access denied",
        });
      }
    }

    await client.query("BEGIN");

    // Update status
    await client.query(
      "UPDATE sales_returns SET status = $1, updated_at = NOW() WHERE id = $2",
      [status, id]
    );

    await client.query("COMMIT");

    // Get updated return
    const updated = await client.query(
      "SELECT * FROM v_sales_returns_detail WHERE id = $1",
      [id]
    );

    res.json({
      success: true,
      message: "Return status updated",
      data: updated.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error updating return status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update return status",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

// Get returns by original sale ID
export const getReturnsBySaleId = async (req, res) => {
  try {
    const { saleId } = req.params;

    const result = await db.query(
      "SELECT * FROM v_sales_returns_detail WHERE original_sale_id = $1 ORDER BY return_date DESC",
      [saleId]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error getting returns by sale:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get returns",
      error: error.message,
    });
  }
};

// Get recent sales for return (with pagination and search)
export const getRecentSalesForReturn = async (req, res) => {
  try {
    const {
      days = 30,
      branchId,
      page = 1,
      limit = 20,
      search = "",
    } = req.query;

    console.log("📥 getRecentSalesForReturn params:", {
      days,
      branchId,
      page,
      limit,
      search,
      userRole: req.user?.role,
      userBranchId: req.user?.branchId,
    });

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = `
      SELECT 
        s.id,
        s.sale_number as invoice_number,
        s.sale_date as created_at,
        s.branch_id,
        s.customer_id,
        c.name as customer_name,
        s.cashier_id,
        u.full_name as cashier_name,
        s.subtotal,
        s.discount_amount,
        s.tax_amount,
        s.total_amount,
        s.paid_amount,
        s.change_amount,
        s.payment_method,
        s.status,
        s.notes,
        (
          SELECT json_agg(
            json_build_object(
              'id', si.id,
              'productId', si.product_id,
              'productName', si.product_name,
              'sku', si.sku,
              'quantity', si.quantity,
              'unitPrice', si.unit_price,
              'discountAmount', si.discount_amount,
              'discountPercentage', si.discount_percentage,
              'taxAmount', si.tax_amount,
              'taxPercentage', si.tax_percentage,
              'subtotal', si.subtotal,
              'total', si.total,
              'costPrice', si.cost_price
            )
          )
          FROM sale_items si
          WHERE si.sale_id = s.id
        ) as items
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN users u ON s.cashier_id = u.id
      WHERE s.deleted_at IS NULL
        AND s.status = 'completed'
        AND s.sale_date >= NOW() - INTERVAL '${parseInt(days)} days'
    `;

    const params = [];
    let paramCount = 1;

    // Filter by branch
    if (branchId) {
      query += ` AND s.branch_id = $${paramCount}`;
      params.push(branchId);
      paramCount++;
    } else if (req.user.role === "cashier" && req.user.branchId) {
      query += ` AND s.branch_id = $${paramCount}`;
      params.push(req.user.branchId);
      paramCount++;
    }

    // Search filter
    if (search && search.trim() !== "") {
      query += ` AND (
        s.sale_number ILIKE $${paramCount} OR
        c.name ILIKE $${paramCount} OR
        u.full_name ILIKE $${paramCount}
      )`;
      params.push(`%${search.trim()}%`);
      paramCount++;
    }

    // Count total records (before pagination)
    const countQuery = query.replace(
      /SELECT .* FROM sales s/,
      "SELECT COUNT(DISTINCT s.id) FROM sales s"
    );
    const countResult = await db.query(countQuery, params);
    const totalRecords = parseInt(countResult.rows[0].count);

    // Add sorting and pagination
    query += ` ORDER BY s.sale_date DESC LIMIT $${paramCount} OFFSET $${
      paramCount + 1
    }`;
    params.push(parseInt(limit), offset);

    console.log("📊 Executing query with params:", params);
    const result = await db.query(query, params);

    console.log(
      `✅ Found ${result.rows.length} sales out of ${totalRecords} total`
    );

    // Transform to match frontend model
    const sales = result.rows.map((row) => ({
      id: row.id.toString(),
      invoiceNumber: row.invoice_number,
      branchId: row.branch_id,
      customerId: row.customer_id,
      customerName: row.customer_name || "Walk-in Customer",
      cashierId: row.cashier_id.toString(),
      cashierName: row.cashier_name,

      // Financial details - LENGKAP
      subtotal: parseFloat(row.subtotal),
      discount: parseFloat(row.discount_amount || 0),
      discountPercentage: parseFloat(row.discount_percentage || 0),
      tax: parseFloat(row.tax_amount || 0),
      total: parseFloat(row.total_amount),
      paidAmount: parseFloat(row.paid_amount || 0),
      changeAmount: parseFloat(row.change_amount || 0),

      // Cost & Profit
      totalCost: parseFloat(row.total_cost || 0),
      grossProfit: parseFloat(row.gross_profit || 0),
      profitMargin: parseFloat(row.profit_margin || 0),

      // Payment & Status
      paymentMethod: row.payment_method,
      paymentReference: row.payment_reference,
      status: row.status,

      // Additional info
      notes: row.notes,
      cashierLocation: row.cashier_location,
      deviceInfo: row.device_info,

      // Items with complete details
      items: (row.items || []).map((item) => ({
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        quantity: parseFloat(item.quantity),
        unitPrice: parseFloat(item.unitPrice),
        discountAmount: parseFloat(item.discountAmount || 0),
        discountPercentage: parseFloat(item.discountPercentage || 0),
        taxAmount: parseFloat(item.taxAmount || 0),
        taxPercentage: parseFloat(item.taxPercentage || 0), // ← ADDED
        subtotal: parseFloat(item.subtotal),
        total: parseFloat(item.total || item.subtotal),
        costPrice: parseFloat(item.costPrice || 0),
        notes: item.notes,
      })),

      createdAt: row.created_at,
      isSynced: true,
      syncedAt: row.created_at,
    }));

    res.json({
      success: true,
      data: sales,
      total: totalRecords,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(totalRecords / parseInt(limit)),
    });
  } catch (error) {
    console.error("Error getting recent sales:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get recent sales",
      error: error.message,
    });
  }
};

/**
 * Delete return (soft delete)
 */
export const deleteReturn = async (req, res) => {
  const client = await db.getClient();

  try {
    const { id } = req.params;
    const userId = req.user.id;

    console.log(`🗑️  Delete return request: ID=${id}, User=${userId}`);

    await client.query("BEGIN");

    // Get return details
    const returnResult = await client.query(
      `SELECT sr.*, 
              (SELECT JSON_AGG(
                JSON_BUILD_OBJECT(
                  'product_id', ri.product_id,
                  'quantity', ri.quantity
                )
              ) FROM return_items ri WHERE ri.return_id = sr.id) as items
       FROM sales_returns sr
       WHERE sr.id = $1 AND sr.deleted_at IS NULL`,
      [id]
    );

    if (returnResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Return not found",
      });
    }

    const returnData = returnResult.rows[0];

    // Check if already processed/completed
    if (returnData.status === "completed") {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Cannot delete completed return",
      });
    }

    // Restore stock for each item
    if (returnData.items && Array.isArray(returnData.items)) {
      for (const item of returnData.items) {
        await client.query(
          `UPDATE product_stocks
           SET quantity = quantity - $1, updated_at = NOW()
           WHERE product_id = $2 AND branch_id = $3`,
          [item.quantity, item.product_id, returnData.branch_id]
        );
      }
    }

    // Soft delete return
    await client.query(
      `UPDATE sales_returns
       SET deleted_at = NOW(), updated_at = NOW()
       WHERE id = $1`,
      [id]
    );

    await client.query("COMMIT");

    console.log(`✅ Return ${id} deleted successfully`);

    res.json({
      success: true,
      message: "Return deleted successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error deleting return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete return",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

export default {
  createReturn,
  getReturns,
  getReturnById,
  updateReturnStatus,
  getReturnsBySaleId,
  getRecentSalesForReturn,
  deleteReturn,
};
