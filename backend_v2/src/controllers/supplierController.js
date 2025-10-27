import pool from "../config/database.js";

// Get all suppliers
export const getAllSuppliers = async (req, res) => {
  try {
    const { limit = 1000, offset = 0 } = req.query;

    const result = await pool.query(
      `SELECT * FROM suppliers 
       WHERE deleted_at IS NULL 
       ORDER BY created_at DESC 
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error fetching suppliers:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch suppliers",
      error: error.message,
    });
  }
};

// Get supplier by ID
export const getSupplierById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "SELECT * FROM suppliers WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Supplier not found",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error("Error fetching supplier:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch supplier",
      error: error.message,
    });
  }
};

// Search suppliers
export const searchSuppliers = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Search query is required",
      });
    }

    const result = await pool.query(
      `SELECT * FROM suppliers 
       WHERE deleted_at IS NULL 
       AND (
         LOWER(name) LIKE LOWER($1) OR 
         LOWER(code) LIKE LOWER($1) OR 
         LOWER(email) LIKE LOWER($1) OR 
         LOWER(phone) LIKE LOWER($1)
       )
       ORDER BY name ASC`,
      [`%${q}%`]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error searching suppliers:", error);
    res.status(500).json({
      success: false,
      message: "Failed to search suppliers",
      error: error.message,
    });
  }
};

// Create new supplier
export const createSupplier = async (req, res) => {
  try {
    const {
      code,
      name,
      email,
      phone,
      address,
      city,
      tax_id,
      payment_terms,
      credit_limit,
      current_balance,
      is_active,
      notes,
    } = req.body;

    // Validate required fields
    if (!code || !name) {
      return res.status(400).json({
        success: false,
        message: "Code and name are required",
      });
    }

    // Check if code already exists
    const existingSupplier = await pool.query(
      "SELECT id FROM suppliers WHERE code = $1 AND deleted_at IS NULL",
      [code]
    );

    if (existingSupplier.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Supplier code already exists",
      });
    }

    const result = await pool.query(
      `INSERT INTO suppliers (
        code, name, email, phone, address, city, 
        tax_id, payment_terms, credit_limit, current_balance, 
        is_active, notes, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
      RETURNING *`,
      [
        code,
        name,
        email || null,
        phone || null,
        address || null,
        city || null,
        tax_id || null,
        payment_terms || null,
        credit_limit || 0,
        current_balance || 0,
        is_active !== undefined ? is_active : true,
        notes || null,
      ]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: "Supplier created successfully",
    });
  } catch (error) {
    console.error("Error creating supplier:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create supplier",
      error: error.message,
    });
  }
};

// Update supplier
export const updateSupplier = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      code,
      name,
      email,
      phone,
      address,
      city,
      tax_id,
      payment_terms,
      credit_limit,
      current_balance,
      is_active,
      notes,
    } = req.body;

    // Validate required fields
    if (!code || !name) {
      return res.status(400).json({
        success: false,
        message: "Code and name are required",
      });
    }

    // Check if supplier exists
    const existingSupplier = await pool.query(
      "SELECT id FROM suppliers WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingSupplier.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Supplier not found",
      });
    }

    // Check if code already exists (excluding current supplier)
    const duplicateCode = await pool.query(
      "SELECT id FROM suppliers WHERE code = $1 AND id != $2 AND deleted_at IS NULL",
      [code, id]
    );

    if (duplicateCode.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Supplier code already exists",
      });
    }

    const result = await pool.query(
      `UPDATE suppliers SET
        code = $1,
        name = $2,
        email = $3,
        phone = $4,
        address = $5,
        city = $6,
        tax_id = $7,
        payment_terms = $8,
        credit_limit = $9,
        current_balance = $10,
        is_active = $11,
        notes = $12,
        updated_at = NOW()
      WHERE id = $13 AND deleted_at IS NULL
      RETURNING *`,
      [
        code,
        name,
        email || null,
        phone || null,
        address || null,
        city || null,
        tax_id || null,
        payment_terms || null,
        credit_limit || 0,
        current_balance || 0,
        is_active !== undefined ? is_active : true,
        notes || null,
        id,
      ]
    );

    res.json({
      success: true,
      data: result.rows[0],
      message: "Supplier updated successfully",
    });
  } catch (error) {
    console.error("Error updating supplier:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update supplier",
      error: error.message,
    });
  }
};

// Delete supplier (soft delete)
export const deleteSupplier = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if supplier exists
    const existingSupplier = await pool.query(
      "SELECT code FROM suppliers WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingSupplier.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Supplier not found",
      });
    }

    // Soft delete with timestamp append to code to prevent unique constraint violation
    const timestamp = Date.now().toString();
    await pool.query(
      `UPDATE suppliers 
       SET deleted_at = NOW(),
           code = code || '_deleted_' || $2,
           updated_at = NOW()
       WHERE id = $1`,
      [id, timestamp]
    );

    res.json({
      success: true,
      message: "Supplier deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting supplier:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete supplier",
      error: error.message,
    });
  }
};

// Generate supplier code
export const generateSupplierCode = async (req, res) => {
  try {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, "0");

    // Get the latest supplier code for current month
    const result = await pool.query(
      `SELECT code FROM suppliers 
       WHERE code LIKE $1 
       ORDER BY code DESC 
       LIMIT 1`,
      [`SUPP${year}${month}%`]
    );

    let nextNumber = 1;
    if (result.rows.length > 0) {
      const lastCode = result.rows[0].code;
      const lastNumber = parseInt(lastCode.slice(-4));
      nextNumber = lastNumber + 1;
    }

    const code = `SUPP${year}${month}${nextNumber.toString().padStart(4, "0")}`;

    res.json({
      success: true,
      data: { code },
    });
  } catch (error) {
    console.error("Error generating supplier code:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate supplier code",
      error: error.message,
    });
  }
};
