import db from "../config/database.js";

// Get all purchases
export const getAllPurchases = async (req, res) => {
  try {
    const { limit = 1000, offset = 0, status } = req.query;

    let query = `
      SELECT p.*, s.name as supplier_name 
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.deleted_at IS NULL
    `;
    const params = [];
    let paramCount = 1;

    if (status) {
      query += ` AND p.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    query += ` ORDER BY p.created_at DESC LIMIT $${paramCount} OFFSET $${
      paramCount + 1
    }`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    // Fetch items for each purchase
    const purchasesWithItems = await Promise.all(
      result.rows.map(async (purchase) => {
        const itemsResult = await db.query(
          `SELECT * FROM purchase_items 
           WHERE purchase_id = $1 
           ORDER BY id`,
          [purchase.id]
        );
        return {
          ...purchase,
          items: itemsResult.rows,
        };
      })
    );

    res.json({
      success: true,
      data: purchasesWithItems,
    });
  } catch (error) {
    console.error("Error fetching purchases:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch purchases",
      error: error.message,
    });
  }
};

// Get purchase by ID with items
export const getPurchaseById = async (req, res) => {
  try {
    const { id } = req.params;

    // Get purchase header
    const purchaseResult = await db.query(
      `SELECT p.*, s.name as supplier_name 
       FROM purchases p
       LEFT JOIN suppliers s ON p.supplier_id = s.id
       WHERE p.id = $1 AND p.deleted_at IS NULL`,
      [id]
    );

    if (purchaseResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Purchase not found",
      });
    }

    // Get purchase items
    const itemsResult = await db.query(
      `SELECT * FROM purchase_items 
       WHERE purchase_id = $1 
       ORDER BY id`,
      [id]
    );

    const purchase = {
      ...purchaseResult.rows[0],
      items: itemsResult.rows,
    };

    res.json({
      success: true,
      data: purchase,
    });
  } catch (error) {
    console.error("Error fetching purchase:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch purchase",
      error: error.message,
    });
  }
};

// Search purchases
export const searchPurchases = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Search query is required",
      });
    }

    const result = await db.query(
      `SELECT p.*, s.name as supplier_name 
       FROM purchases p
       LEFT JOIN suppliers s ON p.supplier_id = s.id
       WHERE p.deleted_at IS NULL 
       AND (
         LOWER(p.purchase_number) LIKE LOWER($1) OR 
         LOWER(s.name) LIKE LOWER($1) OR
         LOWER(p.notes) LIKE LOWER($1)
       )
       ORDER BY p.created_at DESC`,
      [`%${q}%`]
    );

    // Fetch items for each purchase
    const purchasesWithItems = await Promise.all(
      result.rows.map(async (purchase) => {
        const itemsResult = await db.query(
          `SELECT * FROM purchase_items 
           WHERE purchase_id = $1 
           ORDER BY id`,
          [purchase.id]
        );
        return {
          ...purchase,
          items: itemsResult.rows,
        };
      })
    );

    res.json({
      success: true,
      data: purchasesWithItems,
    });
  } catch (error) {
    console.error("Error searching purchases:", error);
    res.status(500).json({
      success: false,
      message: "Failed to search purchases",
      error: error.message,
    });
  }
};

// Create new purchase
export const createPurchase = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const {
      purchase_number,
      branch_id,
      supplier_id,
      created_by,
      purchase_date,
      expected_date,
      status,
      subtotal,
      discount_amount,
      tax_amount,
      shipping_cost,
      total_amount,
      paid_amount,
      payment_terms,
      payment_method,
      notes,
      items,
    } = req.body;

    // Validate required fields
    if (!purchase_number || !branch_id || !created_by) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Purchase number, branch ID, and created by are required",
      });
    }

    // Convert string IDs to integers
    const branchIdInt = parseInt(branch_id);
    const createdByInt = parseInt(created_by);
    const supplierIdInt = supplier_id ? parseInt(supplier_id) : null;

    // Check if purchase number already exists
    const existingPurchase = await client.query(
      "SELECT id FROM purchases WHERE purchase_number = $1 AND deleted_at IS NULL",
      [purchase_number]
    );

    if (existingPurchase.rows.length > 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Purchase number already exists",
      });
    }

    // Insert purchase header
    const purchaseResult = await client.query(
      `INSERT INTO purchases (
        purchase_number, branch_id, supplier_id, created_by, 
        purchase_date, expected_date, status,
        subtotal, discount_amount, tax_amount, shipping_cost, 
        total_amount, paid_amount, payment_terms, payment_method, 
        notes, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW(), NOW())
      RETURNING *`,
      [
        purchase_number,
        branchIdInt,
        supplierIdInt,
        createdByInt,
        purchase_date || new Date(),
        expected_date || null,
        status || "draft",
        subtotal || 0,
        discount_amount || 0,
        tax_amount || 0,
        shipping_cost || 0,
        total_amount || 0,
        paid_amount || 0,
        payment_terms || null,
        payment_method || null,
        notes || null,
      ]
    );

    const purchaseId = purchaseResult.rows[0].id;

    // Insert purchase items
    if (items && items.length > 0) {
      for (const item of items) {
        const productIdInt = parseInt(item.product_id);

        await client.query(
          `INSERT INTO purchase_items (
            purchase_id, product_id, product_name, sku,
            quantity_ordered, quantity_received, unit_price,
            discount_amount, tax_amount, subtotal, total, notes, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())`,
          [
            purchaseId,
            productIdInt,
            item.product_name,
            item.sku,
            item.quantity_ordered,
            item.quantity_received || 0,
            item.unit_price,
            item.discount_amount || 0,
            item.tax_amount || 0,
            item.subtotal,
            item.total,
            item.notes || null,
          ]
        );
      }
    }

    await client.query("COMMIT");

    // Fetch complete purchase with items
    const completePurchase = await getPurchaseWithItems(purchaseId);

    res.status(201).json({
      success: true,
      data: completePurchase,
      message: "Purchase created successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error creating purchase:", error);
    console.error("Error details:", {
      message: error.message,
      stack: error.stack,
      code: error.code,
      detail: error.detail,
      constraint: error.constraint,
    });
    res.status(500).json({
      success: false,
      message: "Failed to create purchase",
      error: error.message,
      details: error.detail || null,
    });
  } finally {
    client.release();
  }
};

// Update purchase
export const updatePurchase = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const { id } = req.params;
    const {
      purchase_number,
      branch_id,
      supplier_id,
      purchase_date,
      expected_date,
      status,
      subtotal,
      discount_amount,
      tax_amount,
      shipping_cost,
      total_amount,
      paid_amount,
      payment_terms,
      payment_method,
      notes,
      items,
    } = req.body;

    // Check if purchase exists
    const existingPurchase = await client.query(
      "SELECT id, status FROM purchases WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingPurchase.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        message: "Purchase not found",
      });
    }

    // Check if purchase status allows editing (only draft, ordered, partial can be edited)
    const currentStatus = existingPurchase.rows[0].status.toLowerCase();
    const editableStatuses = ["draft", "ordered", "partial"];

    if (!editableStatuses.includes(currentStatus)) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: `Cannot edit purchase with status: ${currentStatus}. Only purchases with status ${editableStatuses.join(
          ", "
        )} can be edited.`,
      });
    }

    // Check if purchase number is duplicate (excluding current purchase)
    if (purchase_number) {
      const duplicateNumber = await client.query(
        "SELECT id FROM purchases WHERE purchase_number = $1 AND id != $2 AND deleted_at IS NULL",
        [purchase_number, id]
      );

      if (duplicateNumber.rows.length > 0) {
        await client.query("ROLLBACK");
        return res.status(400).json({
          success: false,
          message: "Purchase number already exists",
        });
      }
    }

    // Update purchase header
    const branchIdInt = branch_id ? parseInt(branch_id) : null;
    const supplierIdInt = supplier_id ? parseInt(supplier_id) : null;

    await client.query(
      `UPDATE purchases SET
        purchase_number = COALESCE($1, purchase_number),
        branch_id = COALESCE($2, branch_id),
        supplier_id = $3,
        purchase_date = COALESCE($4, purchase_date),
        expected_date = $5,
        status = COALESCE($6, status),
        subtotal = COALESCE($7, subtotal),
        discount_amount = COALESCE($8, discount_amount),
        tax_amount = COALESCE($9, tax_amount),
        shipping_cost = COALESCE($10, shipping_cost),
        total_amount = COALESCE($11, total_amount),
        paid_amount = COALESCE($12, paid_amount),
        payment_terms = $13,
        payment_method = $14,
        notes = $15,
        updated_at = NOW()
      WHERE id = $16`,
      [
        purchase_number,
        branchIdInt,
        supplierIdInt,
        purchase_date,
        expected_date || null,
        status,
        subtotal,
        discount_amount,
        tax_amount,
        shipping_cost,
        total_amount,
        paid_amount,
        payment_terms || null,
        payment_method || null,
        notes || null,
        id,
      ]
    );

    // Update items if provided
    if (items && items.length > 0) {
      // Delete existing items
      await client.query("DELETE FROM purchase_items WHERE purchase_id = $1", [
        id,
      ]);

      // Insert new items
      for (const item of items) {
        const productIdInt = parseInt(item.product_id);

        await client.query(
          `INSERT INTO purchase_items (
            purchase_id, product_id, product_name, sku,
            quantity_ordered, quantity_received, unit_price,
            discount_amount, tax_amount, subtotal, total, notes, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())`,
          [
            id,
            productIdInt,
            item.product_name,
            item.sku,
            item.quantity_ordered,
            item.quantity_received || 0,
            item.unit_price,
            item.discount_amount || 0,
            item.tax_amount || 0,
            item.subtotal,
            item.total,
            item.notes || null,
          ]
        );
      }
    }

    await client.query("COMMIT");

    // Fetch complete purchase with items
    const completePurchase = await getPurchaseWithItems(id);

    res.json({
      success: true,
      data: completePurchase,
      message: "Purchase updated successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error updating purchase:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update purchase",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

// Delete purchase (soft delete)
export const deletePurchase = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if purchase exists
    const existingPurchase = await db.query(
      "SELECT purchase_number, status FROM purchases WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingPurchase.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Purchase not found",
      });
    }

    // Check if purchase status allows deletion (only draft, ordered, partial can be deleted)
    const currentStatus = existingPurchase.rows[0].status.toLowerCase();
    const deletableStatuses = ["draft", "ordered", "partial"];

    if (!deletableStatuses.includes(currentStatus)) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete purchase with status: ${currentStatus}. Only purchases with status ${deletableStatuses.join(
          ", "
        )} can be deleted.`,
      });
    }

    // Soft delete with timestamp append to prevent unique constraint violation
    const timestamp = Date.now().toString();
    await db.query(
      `UPDATE purchases 
       SET deleted_at = NOW(),
           purchase_number = purchase_number || '_deleted_' || $2,
           updated_at = NOW()
       WHERE id = $1`,
      [id, timestamp]
    );

    res.json({
      success: true,
      message: "Purchase deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting purchase:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete purchase",
      error: error.message,
    });
  }
};

// Generate purchase number
export const generatePurchaseNumber = async (req, res) => {
  try {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, "0");

    // Get the latest purchase number for current month
    const result = await db.query(
      `SELECT purchase_number FROM purchases 
       WHERE purchase_number LIKE $1 
       ORDER BY purchase_number DESC 
       LIMIT 1`,
      [`PO${year}${month}%`]
    );

    let nextNumber = 1;
    if (result.rows.length > 0) {
      const lastNumber = result.rows[0].purchase_number;
      const lastNum = parseInt(lastNumber.slice(-4));
      nextNumber = lastNum + 1;
    }

    const purchaseNumber = `PO${year}${month}${nextNumber
      .toString()
      .padStart(4, "0")}`;

    res.json({
      success: true,
      data: { purchase_number: purchaseNumber },
    });
  } catch (error) {
    console.error("Error generating purchase number:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate purchase number",
      error: error.message,
    });
  }
};

// Update purchase status
export const updatePurchaseStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: "Status is required",
      });
    }

    // Validate status
    const validStatuses = [
      "draft",
      "ordered",
      "received",
      "partial",
      "cancelled",
    ];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status. Must be one of: " + validStatuses.join(", "),
      });
    }

    const result = await db.query(
      `UPDATE purchases 
       SET status = $1, updated_at = NOW()
       WHERE id = $2 AND deleted_at IS NULL
       RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Purchase not found",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: "Purchase status updated successfully",
    });
  } catch (error) {
    console.error("Error updating purchase status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update purchase status",
      error: error.message,
    });
  }
};

// Helper function to get purchase with items
async function getPurchaseWithItems(purchaseId) {
  const purchaseResult = await db.query(
    `SELECT p.*, s.name as supplier_name 
     FROM purchases p
     LEFT JOIN suppliers s ON p.supplier_id = s.id
     WHERE p.id = $1`,
    [purchaseId]
  );

  const itemsResult = await db.query(
    `SELECT * FROM purchase_items 
     WHERE purchase_id = $1 
     ORDER BY id`,
    [purchaseId]
  );

  return {
    ...purchaseResult.rows[0],
    items: itemsResult.rows,
  };
}
