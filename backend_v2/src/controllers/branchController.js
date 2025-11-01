import pool from "../config/database.js";

// Get all branches
export const getAllBranches = async (req, res) => {
  try {
    const { limit = 1000, offset = 0 } = req.query;

    let query = `SELECT * FROM branches WHERE deleted_at IS NULL`;
    const params = [];
    let paramIndex = 1;

    // Auto-filter by user's branches if not super_admin
    if (req.user && req.user.role !== "super_admin") {
      query = `
        SELECT b.* FROM branches b
        INNER JOIN user_branches ub ON b.id = ub.branch_id
        WHERE b.deleted_at IS NULL 
        AND ub.user_id = $${paramIndex}
      `;
      params.push(req.user.id);
      paramIndex++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${
      paramIndex + 1
    }`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error("Error fetching branches:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch branches",
      error: error.message,
    });
  }
};

// Get branch by ID
export const getBranchById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "SELECT * FROM branches WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Branch not found",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error("Error fetching branch:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch branch",
      error: error.message,
    });
  }
};

// Get current branch (for authenticated user)
export const getCurrentBranch = async (req, res) => {
  try {
    const { branchId } = req.user;

    const result = await pool.query(
      "SELECT * FROM branches WHERE id = $1 AND deleted_at IS NULL",
      [branchId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Current branch not found",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error("Error fetching current branch:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch current branch",
      error: error.message,
    });
  }
};

// Search branches
export const searchBranches = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Search query is required",
      });
    }

    const result = await pool.query(
      `SELECT * FROM branches 
       WHERE deleted_at IS NULL 
       AND (
         LOWER(name) LIKE LOWER($1) OR 
         LOWER(code) LIKE LOWER($1) OR 
         LOWER(address) LIKE LOWER($1) OR 
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
    console.error("Error searching branches:", error);
    res.status(500).json({
      success: false,
      message: "Failed to search branches",
      error: error.message,
    });
  }
};

// Create new branch
export const createBranch = async (req, res) => {
  try {
    const {
      code,
      name,
      email,
      phone,
      address,
      type,
      is_active,
      parent_branch_id,
      api_key,
      settings,
    } = req.body;

    // Validate required fields
    if (!code || !name || !address || !phone || !type) {
      return res.status(400).json({
        success: false,
        message: "Code, name, address, phone, and type are required",
      });
    }

    // Validate type
    if (!["HQ", "BRANCH"].includes(type)) {
      return res.status(400).json({
        success: false,
        message: "Type must be either HQ or BRANCH",
      });
    }

    // Check if code already exists
    const existingBranch = await pool.query(
      "SELECT id FROM branches WHERE code = $1 AND deleted_at IS NULL",
      [code]
    );

    if (existingBranch.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Branch code already exists",
      });
    }

    const result = await pool.query(
      `INSERT INTO branches (
        code, name, address, phone, email,
        type, is_active, parent_branch_id, api_key, settings,
        created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
      RETURNING *`,
      [
        code,
        name,
        address,
        phone,
        email || null,
        type,
        is_active !== undefined ? is_active : true,
        parent_branch_id || null,
        api_key || null,
        settings ? JSON.stringify(settings) : null,
      ]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: "Branch created successfully",
    });
  } catch (error) {
    console.error("Error creating branch:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create branch",
      error: error.message,
    });
  }
};

// Update branch
export const updateBranch = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      code,
      name,
      email,
      phone,
      address,
      type,
      is_active,
      parent_branch_id,
      api_key,
      settings,
    } = req.body;

    // Validate required fields
    if (!code || !name || !address || !phone || !type) {
      return res.status(400).json({
        success: false,
        message: "Code, name, address, phone, and type are required",
      });
    }

    // Validate type
    if (!["HQ", "BRANCH"].includes(type)) {
      return res.status(400).json({
        success: false,
        message: "Type must be either HQ or BRANCH",
      });
    }

    // Check if branch exists
    const existingBranch = await pool.query(
      "SELECT id FROM branches WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingBranch.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Branch not found",
      });
    }

    // Check if code already exists (excluding current branch)
    const duplicateCode = await pool.query(
      "SELECT id FROM branches WHERE code = $1 AND id != $2 AND deleted_at IS NULL",
      [code, id]
    );

    if (duplicateCode.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Branch code already exists",
      });
    }

    const result = await pool.query(
      `UPDATE branches SET
        code = $1,
        name = $2,
        address = $3,
        phone = $4,
        email = $5,
        type = $6,
        is_active = $7,
        parent_branch_id = $8,
        api_key = $9,
        settings = $10,
        updated_at = NOW()
      WHERE id = $11 AND deleted_at IS NULL
      RETURNING *`,
      [
        code,
        name,
        address,
        phone,
        email || null,
        type,
        is_active !== undefined ? is_active : true,
        parent_branch_id || null,
        api_key || null,
        settings ? JSON.stringify(settings) : null,
        id,
      ]
    );

    res.json({
      success: true,
      data: result.rows[0],
      message: "Branch updated successfully",
    });
  } catch (error) {
    console.error("Error updating branch:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update branch",
      error: error.message,
    });
  }
};

// Delete branch (soft delete)
export const deleteBranch = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if branch exists
    const existingBranch = await pool.query(
      "SELECT code FROM branches WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingBranch.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Branch not found",
      });
    }

    // Soft delete with timestamp append to code to prevent unique constraint violation
    const timestamp = Date.now().toString();
    await pool.query(
      `UPDATE branches 
       SET deleted_at = NOW(),
           code = code || '_deleted_' || $2,
           updated_at = NOW()
       WHERE id = $1`,
      [id, timestamp]
    );

    res.json({
      success: true,
      message: "Branch deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting branch:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete branch",
      error: error.message,
    });
  }
};

// Generate branch code
export const generateBranchCode = async (req, res) => {
  try {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, "0");

    // Get the latest branch code for current month
    const result = await pool.query(
      `SELECT code FROM branches 
       WHERE code LIKE $1 
       ORDER BY code DESC 
       LIMIT 1`,
      [`BR${year}${month}%`]
    );

    let nextNumber = 1;
    if (result.rows.length > 0) {
      const lastCode = result.rows[0].code;
      const lastNumber = parseInt(lastCode.slice(-4));
      nextNumber = lastNumber + 1;
    }

    const code = `BR${year}${month}${nextNumber.toString().padStart(4, "0")}`;

    res.json({
      success: true,
      data: { code },
    });
  } catch (error) {
    console.error("Error generating branch code:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate branch code",
      error: error.message,
    });
  }
};
