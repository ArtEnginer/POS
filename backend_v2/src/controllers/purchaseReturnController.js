import db from "../config/database.js";

/**
 * Get all purchase returns
 * @route GET /api/v2/purchase-returns
 */
export const getAllPurchaseReturns = async (req, res) => {
  try {
    const { limit = 1000, offset = 0, receiving_id } = req.query;

    let query = `
      SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    if (receiving_id) {
      query += ` AND pr.receiving_id = $${paramCount}`;
      params.push(receiving_id);
      paramCount++;
    }

    query += ` ORDER BY pr.created_at DESC LIMIT $${paramCount} OFFSET $${
      paramCount + 1
    }`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    // Fetch items for each return
    const returnsWithItems = await Promise.all(
      result.rows.map(async (purchaseReturn) => {
        const itemsResult = await db.query(
          `SELECT 
            pri.*,
            p.name as product_name,
            p.sku
          FROM purchase_return_items pri
          LEFT JOIN products p ON pri.product_id = p.id
          WHERE pri.return_id = $1
          ORDER BY pri.id`,
          [purchaseReturn.id]
        );

        return {
          ...purchaseReturn,
          items: itemsResult.rows,
        };
      })
    );

    res.json({
      success: true,
      data: returnsWithItems,
      count: returnsWithItems.length,
    });
  } catch (error) {
    console.error("Error fetching purchase returns:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch purchase returns",
      error: error.message,
    });
  }
};

/**
 * Get purchase return by ID
 * @route GET /api/v2/purchase-returns/:id
 */
export const getPurchaseReturnById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE pr.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Purchase return not found",
      });
    }

    // Get return items
    const itemsResult = await db.query(
      `SELECT 
        pri.*,
        p.name as product_name,
        p.sku
      FROM purchase_return_items pri
      LEFT JOIN products p ON pri.product_id = p.id
      WHERE pri.return_id = $1
      ORDER BY pri.id`,
      [id]
    );

    const purchaseReturn = {
      ...result.rows[0],
      items: itemsResult.rows,
    };

    res.json({
      success: true,
      data: purchaseReturn,
    });
  } catch (error) {
    console.error("Error fetching purchase return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch purchase return",
      error: error.message,
    });
  }
};

/**
 * Get purchase returns by receiving ID
 * @route GET /api/v2/purchase-returns/receiving/:receivingId
 */
export const getPurchaseReturnsByReceiving = async (req, res) => {
  try {
    const { receivingId } = req.params;

    const result = await db.query(
      `SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE pr.receiving_id = $1
      ORDER BY pr.created_at DESC`,
      [receivingId]
    );

    // Fetch items for each return
    const returnsWithItems = await Promise.all(
      result.rows.map(async (purchaseReturn) => {
        const itemsResult = await db.query(
          `SELECT 
            pri.*,
            p.name as product_name,
            p.sku
          FROM purchase_return_items pri
          LEFT JOIN products p ON pri.product_id = p.id
          WHERE pri.return_id = $1
          ORDER BY pri.id`,
          [purchaseReturn.id]
        );

        return {
          ...purchaseReturn,
          items: itemsResult.rows,
        };
      })
    );

    res.json({
      success: true,
      data: returnsWithItems,
      count: returnsWithItems.length,
    });
  } catch (error) {
    console.error("Error fetching purchase returns by receiving:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch purchase returns",
      error: error.message,
    });
  }
};

/**
 * Search purchase returns
 * @route GET /api/v2/purchase-returns/search
 */
export const searchPurchaseReturns = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Search query is required",
      });
    }

    const result = await db.query(
      `SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE pr.return_number ILIKE $1
         OR r.receiving_number ILIKE $1
         OR p.purchase_number ILIKE $1
         OR s.name ILIKE $1
      ORDER BY pr.created_at DESC
      LIMIT 100`,
      [`%${q}%`]
    );

    // Fetch items for each return
    const returnsWithItems = await Promise.all(
      result.rows.map(async (purchaseReturn) => {
        const itemsResult = await db.query(
          `SELECT 
            pri.*,
            p.name as product_name,
            p.sku
          FROM purchase_return_items pri
          LEFT JOIN products p ON pri.product_id = p.id
          WHERE pri.return_id = $1
          ORDER BY pri.id`,
          [purchaseReturn.id]
        );

        return {
          ...purchaseReturn,
          items: itemsResult.rows,
        };
      })
    );

    res.json({
      success: true,
      data: returnsWithItems,
      count: returnsWithItems.length,
    });
  } catch (error) {
    console.error("Error searching purchase returns:", error);
    res.status(500).json({
      success: false,
      message: "Failed to search purchase returns",
      error: error.message,
    });
  }
};

/**
 * Create purchase return
 * @route POST /api/v2/purchase-returns
 */
export const createPurchaseReturn = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const {
      return_number,
      receiving_id,
      purchase_id,
      supplier_id,
      return_date,
      subtotal,
      total_discount,
      total_tax,
      total,
      reason,
      notes,
      returned_by,
      items,
    } = req.body;

    // Validate required fields
    if (
      !return_number ||
      !receiving_id ||
      !purchase_id ||
      !items ||
      items.length === 0
    ) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message:
          "Missing required fields: return_number, receiving_id, purchase_id, items",
      });
    }

    // Check if receiving exists
    const receivingCheck = await client.query(
      "SELECT id, purchase_number FROM receivings WHERE id = $1",
      [receiving_id]
    );

    if (receivingCheck.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Receiving not found",
      });
    }

    // Insert purchase return
    const returnResult = await client.query(
      `INSERT INTO purchase_returns (
        return_number,
        receiving_id,
        purchase_id,
        supplier_id,
        return_date,
        subtotal,
        total_discount,
        total_tax,
        total,
        reason,
        notes,
        returned_by,
        sync_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        return_number,
        receiving_id,
        purchase_id,
        supplier_id,
        return_date || new Date(),
        subtotal,
        total_discount || 0,
        total_tax || 0,
        total,
        reason,
        notes,
        returned_by || null, // Convert empty string to null for integer field
        "pending",
      ]
    );

    const returnId = returnResult.rows[0].id;

    // Insert return items and update stock
    const insertedItems = [];
    for (const item of items) {
      const itemResult = await client.query(
        `INSERT INTO purchase_return_items (
          return_id,
          receiving_item_id,
          product_id,
          product_name,
          received_quantity,
          return_quantity,
          price,
          discount,
          discount_type,
          tax,
          tax_type,
          subtotal,
          total,
          reason,
          notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        RETURNING *`,
        [
          returnId,
          item.receiving_item_id,
          item.product_id,
          item.product_name,
          item.received_quantity,
          item.return_quantity,
          item.price,
          item.discount || 0,
          item.discount_type || "AMOUNT",
          item.tax || 0,
          item.tax_type || "AMOUNT",
          item.subtotal,
          item.total,
          item.reason,
          item.notes,
        ]
      );

      insertedItems.push(itemResult.rows[0]);

      // Update stock - reduce quantity (because we're returning items)
      // First, get branch_id from receiving
      const receivingData = await client.query(
        `SELECT r.id, p.branch_id 
         FROM receivings r
         JOIN purchases p ON r.purchase_id = p.id
         WHERE r.id = $1`,
        [receiving_id]
      );

      if (receivingData.rows.length > 0) {
        const branchId = receivingData.rows[0].branch_id;

        // Check if product stock exists
        const stockCheck = await client.query(
          "SELECT id, quantity FROM product_stocks WHERE product_id = $1 AND branch_id = $2",
          [item.product_id, branchId]
        );

        if (stockCheck.rows.length > 0) {
          // Update existing stock - subtract return quantity
          await client.query(
            "UPDATE product_stocks SET quantity = quantity - $1, updated_at = CURRENT_TIMESTAMP WHERE product_id = $2 AND branch_id = $3",
            [item.return_quantity, item.product_id, branchId]
          );
        }
      }
    }

    await client.query("COMMIT");

    // Fetch complete return data
    const completeReturn = await db.query(
      `SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE pr.id = $1`,
      [returnId]
    );

    res.status(201).json({
      success: true,
      message: "Purchase return created successfully",
      data: {
        ...completeReturn.rows[0],
        items: insertedItems,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error creating purchase return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create purchase return",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

/**
 * Update purchase return
 * @route PUT /api/v2/purchase-returns/:id
 */
export const updatePurchaseReturn = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const { id } = req.params;
    const {
      return_number,
      receiving_id,
      purchase_id,
      supplier_id,
      return_date,
      subtotal,
      total_discount,
      total_tax,
      total,
      reason,
      notes,
      returned_by,
      items,
    } = req.body;

    // Check if return exists
    const returnCheck = await client.query(
      "SELECT id FROM purchase_returns WHERE id = $1",
      [id]
    );

    if (returnCheck.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Purchase return not found",
      });
    }

    // Update purchase return
    await client.query(
      `UPDATE purchase_returns SET
        return_number = $1,
        receiving_id = $2,
        purchase_id = $3,
        supplier_id = $4,
        return_date = $5,
        subtotal = $6,
        total_discount = $7,
        total_tax = $8,
        total = $9,
        reason = $10,
        notes = $11,
        returned_by = $12,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $13`,
      [
        return_number,
        receiving_id,
        purchase_id,
        supplier_id,
        return_date,
        subtotal,
        total_discount || 0,
        total_tax || 0,
        total,
        reason,
        notes,
        returned_by || null, // Convert empty string to null for integer field
        id,
      ]
    );

    // Delete old items
    await client.query(
      "DELETE FROM purchase_return_items WHERE return_id = $1",
      [id]
    );

    // Insert new items
    const insertedItems = [];
    for (const item of items) {
      const itemResult = await client.query(
        `INSERT INTO purchase_return_items (
          return_id,
          receiving_item_id,
          product_id,
          product_name,
          received_quantity,
          return_quantity,
          price,
          discount,
          discount_type,
          tax,
          tax_type,
          subtotal,
          total,
          reason,
          notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        RETURNING *`,
        [
          id,
          item.receiving_item_id,
          item.product_id,
          item.product_name,
          item.received_quantity,
          item.return_quantity,
          item.price,
          item.discount || 0,
          item.discount_type || "AMOUNT",
          item.tax || 0,
          item.tax_type || "AMOUNT",
          item.subtotal,
          item.total,
          item.reason,
          item.notes,
        ]
      );

      insertedItems.push(itemResult.rows[0]);
    }

    await client.query("COMMIT");

    // Fetch updated return data
    const updatedReturn = await db.query(
      `SELECT 
        pr.*,
        r.receiving_number,
        p.purchase_number,
        s.name as supplier_name,
        u.full_name as returned_by_name
      FROM purchase_returns pr
      LEFT JOIN receivings r ON pr.receiving_id = r.id
      LEFT JOIN purchases p ON pr.purchase_id = p.id
      LEFT JOIN suppliers s ON pr.supplier_id = s.id
      LEFT JOIN users u ON pr.returned_by = u.id
      WHERE pr.id = $1`,
      [id]
    );

    res.json({
      success: true,
      message: "Purchase return updated successfully",
      data: {
        ...updatedReturn.rows[0],
        items: insertedItems,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error updating purchase return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update purchase return",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

/**
 * Delete purchase return
 * @route DELETE /api/v2/purchase-returns/:id
 */
export const deletePurchaseReturn = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const { id } = req.params;

    // Check if return exists
    const returnCheck = await client.query(
      "SELECT id FROM purchase_returns WHERE id = $1",
      [id]
    );

    if (returnCheck.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Purchase return not found",
      });
    }

    // Get return items before deleting (to restore stock)
    const itemsResult = await client.query(
      "SELECT * FROM purchase_return_items WHERE return_id = $1",
      [id]
    );

    // Get branch_id from receiving
    const returnData = await client.query(
      `SELECT r.id, p.branch_id 
       FROM purchase_returns pr
       JOIN receivings r ON pr.receiving_id = r.id
       JOIN purchases p ON r.purchase_id = p.id
       WHERE pr.id = $1`,
      [id]
    );

    if (returnData.rows.length > 0) {
      const branchId = returnData.rows[0].branch_id;

      // Restore stock for each item
      for (const item of itemsResult.rows) {
        await client.query(
          `UPDATE product_stocks 
           SET quantity = quantity + $1, updated_at = CURRENT_TIMESTAMP 
           WHERE product_id = $2 AND branch_id = $3`,
          [item.return_quantity, item.product_id, branchId]
        );
      }
    }

    // Delete return items
    await client.query(
      "DELETE FROM purchase_return_items WHERE return_id = $1",
      [id]
    );

    // Delete return
    await client.query("DELETE FROM purchase_returns WHERE id = $1", [id]);

    await client.query("COMMIT");

    res.json({
      success: true,
      message: "Purchase return deleted successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error deleting purchase return:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete purchase return",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

/**
 * Generate return number
 * @route GET /api/v2/purchase-returns/generate-number
 */
export const generateReturnNumber = async (req, res) => {
  try {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, "0");

    // Get the latest return number for current month
    const result = await db.query(
      `SELECT return_number FROM purchase_returns 
       WHERE return_number LIKE $1 
       ORDER BY return_number DESC 
       LIMIT 1`,
      [`RTN${year}${month}%`]
    );

    let nextNumber = 1;
    if (result.rows.length > 0) {
      const lastNumber = result.rows[0].return_number;
      const lastNum = parseInt(lastNumber.slice(-4));
      nextNumber = lastNum + 1;
    }

    const returnNumber = `RTN${year}${month}${nextNumber
      .toString()
      .padStart(4, "0")}`;

    res.json({
      success: true,
      data: { return_number: returnNumber },
    });
  } catch (error) {
    console.error("Error generating return number:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate return number",
      error: error.message,
    });
  }
};

/**
 * Update purchase return status
 * @route PATCH /api/v2/purchase-returns/:id/status
 */
export const updatePurchaseReturnStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // Validate status
    const validStatuses = ["DRAFT", "APPROVED", "COMPLETED", "CANCELLED"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
      });
    }

    // Update status column
    const result = await db.query(
      `UPDATE purchase_returns 
       SET status = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $2 
       RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Purchase return not found",
      });
    }

    res.json({
      success: true,
      message: `Purchase return status updated to ${status}`,
      data: result.rows[0],
    });
  } catch (error) {
    console.error("Error updating purchase return status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update purchase return status",
      error: error.message,
    });
  }
};
