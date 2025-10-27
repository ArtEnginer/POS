import db from "../config/database.js";

// Helper function to get receiving with items
async function getReceivingWithItems(receivingId) {
  const receivingResult = await db.query(
    `SELECT r.*, s.name as supplier_name
     FROM receivings r
     LEFT JOIN suppliers s ON r.supplier_id = s.id
     WHERE r.id = $1 AND r.deleted_at IS NULL`,
    [receivingId]
  );

  if (receivingResult.rows.length === 0) {
    return null;
  }

  const receiving = receivingResult.rows[0];

  const itemsResult = await db.query(
    `SELECT * FROM receiving_items WHERE receiving_id = $1`,
    [receivingId]
  );

  receiving.items = itemsResult.rows;
  return receiving;
}

// Get all receivings
export const getAllReceivings = async (req, res) => {
  try {
    const { limit = 1000, offset = 0, status, purchase_id } = req.query;

    let query = `
      SELECT r.*, s.name as supplier_name
      FROM receivings r
      LEFT JOIN suppliers s ON r.supplier_id = s.id
      WHERE r.deleted_at IS NULL
    `;
    const params = [];
    let paramCount = 1;

    if (status) {
      query += ` AND r.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (purchase_id) {
      query += ` AND r.purchase_id = $${paramCount}`;
      params.push(purchase_id);
      paramCount++;
    }

    query += ` ORDER BY r.created_at DESC LIMIT $${paramCount} OFFSET $${
      paramCount + 1
    }`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error fetching receivings:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch receivings",
      error: error.message,
    });
  }
};

// Get receiving by ID
export const getReceivingById = async (req, res) => {
  try {
    const { id } = req.params;

    const receiving = await getReceivingWithItems(id);

    if (!receiving) {
      return res.status(404).json({
        success: false,
        message: "Receiving not found",
      });
    }

    res.json({
      success: true,
      data: receiving,
    });
  } catch (error) {
    console.error("Error fetching receiving:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch receiving",
      error: error.message,
    });
  }
};

// Search receivings
export const searchReceivings = async (req, res) => {
  try {
    const { q } = req.query;

    const result = await db.query(
      `SELECT r.*, s.name as supplier_name
       FROM receivings r
       LEFT JOIN suppliers s ON r.supplier_id = s.id
       WHERE r.deleted_at IS NULL
       AND (r.receiving_number ILIKE $1 OR r.invoice_number ILIKE $1)
       ORDER BY r.created_at DESC`,
      [`%${q}%`]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error searching receivings:", error);
    res.status(500).json({
      success: false,
      message: "Failed to search receivings",
      error: error.message,
    });
  }
};

// Create new receiving
export const createReceiving = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const {
      receiving_number,
      purchase_id,
      purchase_number,
      supplier_id,
      supplier_name,
      receiving_date,
      invoice_number,
      delivery_order_number,
      vehicle_number,
      driver_name,
      subtotal,
      item_discount,
      item_tax,
      total_discount,
      total_tax,
      total,
      status,
      notes,
      received_by,
      items,
    } = req.body;

    // Validate required fields
    if (!receiving_number || !purchase_id) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Receiving number and purchase ID are required",
      });
    }

    // Convert IDs to integers
    const purchaseIdInt = parseInt(purchase_id);
    const supplierIdInt = supplier_id ? parseInt(supplier_id) : null;
    const receivedByInt = received_by ? parseInt(received_by) : null;

    // Check if receiving number already exists
    const existingReceiving = await client.query(
      "SELECT id FROM receivings WHERE receiving_number = $1 AND deleted_at IS NULL",
      [receiving_number]
    );

    if (existingReceiving.rows.length > 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        success: false,
        message: "Receiving number already exists",
      });
    }

    // Insert receiving header
    const receivingResult = await client.query(
      `INSERT INTO receivings (
        receiving_number, purchase_id, purchase_number,
        supplier_id, supplier_name, receiving_date,
        invoice_number, delivery_order_number, vehicle_number, driver_name,
        subtotal, item_discount, item_tax, total_discount, total_tax, total,
        status, notes, received_by, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, NOW(), NOW())
      RETURNING *`,
      [
        receiving_number,
        purchaseIdInt,
        purchase_number,
        supplierIdInt,
        supplier_name,
        receiving_date || new Date(),
        invoice_number || null,
        delivery_order_number || null,
        vehicle_number || null,
        driver_name || null,
        subtotal || 0,
        item_discount || 0,
        item_tax || 0,
        total_discount || 0,
        total_tax || 0,
        total || 0,
        status || "completed",
        notes || null,
        receivedByInt,
      ]
    );

    const receivingId = receivingResult.rows[0].id;

    // Insert receiving items
    if (items && items.length > 0) {
      for (const item of items) {
        const productIdInt = parseInt(item.product_id);
        const purchaseItemIdInt = item.purchase_item_id
          ? parseInt(item.purchase_item_id)
          : null;

        await client.query(
          `INSERT INTO receiving_items (
            receiving_id, purchase_item_id, product_id, product_name,
            po_quantity, po_price, received_quantity, received_price,
            discount, discount_type, tax, tax_type, subtotal, total, notes, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW())`,
          [
            receivingId,
            purchaseItemIdInt,
            productIdInt,
            item.product_name,
            item.po_quantity || 0,
            item.po_price || 0,
            item.received_quantity,
            item.received_price,
            item.discount || 0,
            item.discount_type || "AMOUNT",
            item.tax || 0,
            item.tax_type || "AMOUNT",
            item.subtotal,
            item.total,
            item.notes || null,
          ]
        );

        // Update product stock (add received quantity)
        // Assuming branch_id from purchase
        const purchaseData = await client.query(
          "SELECT branch_id FROM purchases WHERE id = $1",
          [purchaseIdInt]
        );
        const branchId = purchaseData.rows[0]?.branch_id;

        if (branchId) {
          // Check if product stock exists
          const stockCheck = await client.query(
            "SELECT id, quantity FROM product_stocks WHERE product_id = $1 AND branch_id = $2",
            [productIdInt, branchId]
          );

          if (stockCheck.rows.length > 0) {
            // Update existing stock
            await client.query(
              "UPDATE product_stocks SET quantity = quantity + $1, updated_at = NOW() WHERE product_id = $2 AND branch_id = $3",
              [item.received_quantity, productIdInt, branchId]
            );
          } else {
            // Insert new stock record
            await client.query(
              "INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity, updated_at) VALUES ($1, $2, $3, 0, NOW())",
              [productIdInt, branchId, item.received_quantity]
            );
          }
        }
      }
    }

    // Update purchase status based on received quantities
    // (You can implement logic here to set status to 'partial' or 'received')

    await client.query("COMMIT");

    // Fetch complete receiving with items
    const completeReceiving = await getReceivingWithItems(receivingId);

    res.status(201).json({
      success: true,
      data: completeReceiving,
      message: "Receiving created successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error creating receiving:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create receiving",
      error: error.message,
      details: error.detail || null,
    });
  } finally {
    client.release();
  }
};

// Update receiving
export const updateReceiving = async (req, res) => {
  const client = await db.getClient();

  try {
    await client.query("BEGIN");

    const { id } = req.params;
    const {
      receiving_date,
      invoice_number,
      delivery_order_number,
      vehicle_number,
      driver_name,
      subtotal,
      item_discount,
      item_tax,
      total_discount,
      total_tax,
      total,
      status,
      notes,
      items,
    } = req.body;

    // Update receiving header
    await client.query(
      `UPDATE receivings SET
        receiving_date = COALESCE($1, receiving_date),
        invoice_number = $2,
        delivery_order_number = $3,
        vehicle_number = $4,
        driver_name = $5,
        subtotal = COALESCE($6, subtotal),
        item_discount = COALESCE($7, item_discount),
        item_tax = COALESCE($8, item_tax),
        total_discount = COALESCE($9, total_discount),
        total_tax = COALESCE($10, total_tax),
        total = COALESCE($11, total),
        status = COALESCE($12, status),
        notes = $13,
        updated_at = NOW()
      WHERE id = $14`,
      [
        receiving_date,
        invoice_number || null,
        delivery_order_number || null,
        vehicle_number || null,
        driver_name || null,
        subtotal,
        item_discount,
        item_tax,
        total_discount,
        total_tax,
        total,
        status,
        notes || null,
        id,
      ]
    );

    // Update items if provided
    if (items && items.length > 0) {
      // Delete existing items
      await client.query(
        "DELETE FROM receiving_items WHERE receiving_id = $1",
        [id]
      );

      // Insert new items
      for (const item of items) {
        const productIdInt = parseInt(item.product_id);
        const purchaseItemIdInt = item.purchase_item_id
          ? parseInt(item.purchase_item_id)
          : null;

        await client.query(
          `INSERT INTO receiving_items (
            receiving_id, purchase_item_id, product_id, product_name,
            po_quantity, po_price, received_quantity, received_price,
            discount, discount_type, tax, tax_type, subtotal, total, notes, created_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW())`,
          [
            id,
            purchaseItemIdInt,
            productIdInt,
            item.product_name,
            item.po_quantity || 0,
            item.po_price || 0,
            item.received_quantity,
            item.received_price,
            item.discount || 0,
            item.discount_type || "AMOUNT",
            item.tax || 0,
            item.tax_type || "AMOUNT",
            item.subtotal,
            item.total,
            item.notes || null,
          ]
        );
      }
    }

    await client.query("COMMIT");

    // Fetch updated receiving
    const updatedReceiving = await getReceivingWithItems(id);

    res.json({
      success: true,
      data: updatedReceiving,
      message: "Receiving updated successfully",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error updating receiving:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update receiving",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

// Delete receiving
export const deleteReceiving = async (req, res) => {
  try {
    const { id } = req.params;

    // Soft delete
    await db.query(
      "UPDATE receivings SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1",
      [id]
    );

    res.json({
      success: true,
      message: "Receiving deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting receiving:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete receiving",
      error: error.message,
    });
  }
};

// Generate receiving number
export const generateReceivingNumber = async (req, res) => {
  try {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, "0");
    const day = now.getDate().toString().padStart(2, "0");

    // Get the latest receiving number for current date
    const result = await db.query(
      `SELECT receiving_number FROM receivings 
       WHERE receiving_number LIKE $1 
       ORDER BY receiving_number DESC 
       LIMIT 1`,
      [`RCV${year}${month}${day}%`]
    );

    let nextNumber = 1;
    if (result.rows.length > 0) {
      const lastNumber = result.rows[0].receiving_number;
      const lastNum = parseInt(lastNumber.slice(-4));
      nextNumber = lastNum + 1;
    }

    const receivingNumber = `RCV${year}${month}${day}${nextNumber
      .toString()
      .padStart(4, "0")}`;

    res.json({
      success: true,
      data: { receiving_number: receivingNumber },
    });
  } catch (error) {
    console.error("Error generating receiving number:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate receiving number",
      error: error.message,
    });
  }
};
