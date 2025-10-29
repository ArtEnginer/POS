import { query as dbQuery, getClient } from "../config/database.js";
import bcrypt from "bcryptjs";
import logger from "../utils/logger.js";

// Get all users with pagination and filtering
export const getAllUsers = async (req, res) => {
  try {
    const {
      limit = 10,
      offset = 0,
      role,
      status,
      search,
      branchId,
    } = req.query;

    let query = `
      SELECT 
        u.id,
        u.username,
        u.email,
        u.full_name,
        u.role,
        u.status,
        u.phone,
        u.avatar_url,
        u.last_login_at,
        u.created_at,
        u.updated_at,
        ARRAY_AGG(DISTINCT ub.branch_id) as branch_ids
      FROM users u
      LEFT JOIN user_branches ub ON u.id = ub.user_id
      WHERE u.deleted_at IS NULL
    `;

    const params = [];
    let paramIndex = 1;

    // BRANCH-BASED ACCESS CONTROL
    // Super Admin: See all users from all branches
    // Admin/Manager: Only see users in their assigned branches
    if (req.user.role !== "super_admin") {
      // Get current user's branches
      const userBranches = await dbQuery(
        `SELECT branch_id FROM user_branches WHERE user_id = $1`,
        [req.user.id]
      );

      if (userBranches.rows.length === 0) {
        // User has no branches assigned - return empty
        return res.json({
          success: true,
          data: [],
          pagination: {
            total: 0,
            limit: parseInt(limit),
            offset: parseInt(offset),
          },
        });
      }

      const branchIds = userBranches.rows.map((row) => row.branch_id);
      query += ` AND ub.branch_id = ANY($${paramIndex})`;
      params.push(branchIds);
      paramIndex++;
    }

    // Filter by specific branch (optional, for super_admin)
    if (branchId) {
      query += ` AND ub.branch_id = $${paramIndex}`;
      params.push(branchId);
      paramIndex++;
    }

    // Filter by role
    if (role) {
      query += ` AND u.role = $${paramIndex}`;
      params.push(role);
      paramIndex++;
    }

    // Filter by status
    if (status) {
      query += ` AND u.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    // Search by username, email, or full_name
    if (search) {
      query += ` AND (
        u.username ILIKE $${paramIndex} OR 
        u.email ILIKE $${paramIndex} OR 
        u.full_name ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    query += ` GROUP BY u.id ORDER BY u.created_at DESC LIMIT $${paramIndex} OFFSET $${
      paramIndex + 1
    }`;
    params.push(limit, offset);

    const result = await dbQuery(query, params);

    // Get total count with same branch filtering
    let countQuery = `
      SELECT COUNT(DISTINCT u.id) as total 
      FROM users u
      LEFT JOIN user_branches ub ON u.id = ub.user_id
      WHERE u.deleted_at IS NULL
    `;
    let countParams = [];
    let countParamIndex = 1;

    // Apply same branch filtering for count
    if (req.user.role !== "super_admin") {
      const userBranches = await dbQuery(
        `SELECT branch_id FROM user_branches WHERE user_id = $1`,
        [req.user.id]
      );

      if (userBranches.rows.length > 0) {
        const branchIds = userBranches.rows.map((row) => row.branch_id);
        countQuery += ` AND ub.branch_id = ANY($${countParamIndex})`;
        countParams.push(branchIds);
        countParamIndex++;
      }
    }

    if (branchId) {
      countQuery += ` AND ub.branch_id = $${countParamIndex}`;
      countParams.push(branchId);
      countParamIndex++;
    }

    if (role) {
      countQuery += ` AND u.role = $${countParamIndex}`;
      countParams.push(role);
      countParamIndex++;
    }

    if (status) {
      countQuery += ` AND u.status = $${countParamIndex}`;
      countParams.push(status);
      countParamIndex++;
    }

    if (search) {
      countQuery += ` AND (u.username ILIKE $${countParamIndex} OR u.email ILIKE $${countParamIndex} OR u.full_name ILIKE $${countParamIndex})`;
      countParams.push(`%${search}%`);
      countParamIndex++;
    }

    const countResult = await dbQuery(countQuery, countParams);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        page: Math.floor(parseInt(offset) / parseInt(limit)) + 1,
      },
    });
  } catch (error) {
    logger.error("Error fetching users:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
      error: error.message,
    });
  }
};

// Get user by ID
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await dbQuery(
      `
      SELECT 
        u.id,
        u.username,
        u.email,
        u.full_name,
        u.role,
        u.status,
        u.phone,
        u.avatar_url,
        u.last_login_at,
        u.last_login_ip,
        u.created_at,
        u.updated_at,
        ARRAY_AGG(DISTINCT ub.branch_id) as branch_ids
      FROM users u
      LEFT JOIN user_branches ub ON u.id = ub.user_id
      WHERE u.id = $1 AND u.deleted_at IS NULL
      GROUP BY u.id
      `,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    logger.error("Error fetching user:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch user",
      error: error.message,
    });
  }
};

// Create new user
export const createUser = async (req, res) => {
  const client = await getClient();
  try {
    const {
      username,
      email,
      password,
      full_name,
      role = "cashier",
      phone,
      branch_ids = [],
    } = req.body;

    // Validation
    if (!username || !email || !password || !full_name) {
      return res.status(400).json({
        success: false,
        message: "Username, email, password, and full_name are required",
      });
    }

    // BRANCH-BASED ACCESS CONTROL FOR CREATE
    // Admin/Manager can only create users in their own branches
    if (req.user.role !== "super_admin") {
      const userBranches = await client.query(
        `SELECT branch_id FROM user_branches WHERE user_id = $1`,
        [req.user.id]
      );

      if (userBranches.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: "You are not assigned to any branch",
        });
      }

      const allowedBranchIds = userBranches.rows.map((row) => row.branch_id);

      // Check if all requested branch_ids are in user's allowed branches
      if (branch_ids && branch_ids.length > 0) {
        const invalidBranches = branch_ids.filter(
          (branchId) => !allowedBranchIds.includes(branchId)
        );

        if (invalidBranches.length > 0) {
          return res.status(403).json({
            success: false,
            message: `You can only assign users to your own branches. Invalid branches: ${invalidBranches.join(
              ", "
            )}`,
          });
        }
      } else {
        // If no branches specified, assign to user's first branch
        branch_ids.push(allowedBranchIds[0]);
      }
    }

    // Check if username or email already exists
    const existCheck = await client.query(
      `SELECT id FROM users WHERE (username = $1 OR email = $2) AND deleted_at IS NULL`,
      [username, email]
    );

    if (existCheck.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Username or email already exists",
      });
    }

    await client.query("BEGIN");

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    const createResult = await client.query(
      `
      INSERT INTO users (username, email, password_hash, full_name, role, phone, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'active')
      RETURNING 
        id, username, email, full_name, role, status, phone, 
        avatar_url, created_at, updated_at
      `,
      [username, email, passwordHash, full_name, role, phone || null]
    );

    const userId = createResult.rows[0].id;

    // Assign branches if provided
    if (branch_ids && branch_ids.length > 0) {
      for (let i = 0; i < branch_ids.length; i++) {
        await client.query(
          `
          INSERT INTO user_branches (user_id, branch_id, is_default)
          VALUES ($1, $2, $3)
          ON CONFLICT (user_id, branch_id) DO NOTHING
          `,
          [userId, branch_ids[i], i === 0]
        );
      }
    }

    await client.query("COMMIT");

    logger.info(`User ${username} created by ${req.user.username}`);

    res.status(201).json({
      success: true,
      message: "User created successfully",
      data: createResult.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error("Error creating user:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create user",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

// Update user
export const updateUser = async (req, res) => {
  const client = await getClient();
  try {
    const { id } = req.params;
    const { email, full_name, role, status, phone, branch_ids } = req.body;

    // Check if user exists
    const userCheck = await client.query(
      `SELECT u.*, ARRAY_AGG(DISTINCT ub.branch_id) as branch_ids 
       FROM users u
       LEFT JOIN user_branches ub ON u.id = ub.user_id
       WHERE u.id = $1 AND u.deleted_at IS NULL
       GROUP BY u.id`,
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const currentUser = userCheck.rows[0];

    // BRANCH-BASED ACCESS CONTROL FOR UPDATE
    // Admin/Manager can only update users in their own branches
    if (req.user.role !== "super_admin") {
      const requesterBranches = await client.query(
        `SELECT branch_id FROM user_branches WHERE user_id = $1`,
        [req.user.id]
      );

      if (requesterBranches.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: "You are not assigned to any branch",
        });
      }

      const allowedBranchIds = requesterBranches.rows.map(
        (row) => row.branch_id
      );

      // Check if target user is in requester's branches
      const targetUserBranches = currentUser.branch_ids.filter(
        (b) => b !== null
      );
      const hasCommonBranch = targetUserBranches.some((branchId) =>
        allowedBranchIds.includes(branchId)
      );

      if (!hasCommonBranch) {
        return res.status(403).json({
          success: false,
          message: "You can only update users in your own branches",
        });
      }

      // Check if trying to assign branches outside of allowed branches
      if (branch_ids && branch_ids.length > 0) {
        const invalidBranches = branch_ids.filter(
          (branchId) => !allowedBranchIds.includes(branchId)
        );

        if (invalidBranches.length > 0) {
          return res.status(403).json({
            success: false,
            message: `You can only assign users to your own branches. Invalid branches: ${invalidBranches.join(
              ", "
            )}`,
          });
        }
      }
    }

    // Check role hierarchy - can't modify super_admin unless requester is super_admin
    if (currentUser.role === "super_admin" && req.user.role !== "super_admin") {
      return res.status(403).json({
        success: false,
        message: "Cannot modify super_admin user",
      });
    }

    // Check if new email already exists (if email is being changed)
    if (email && email !== currentUser.email) {
      const emailCheck = await client.query(
        `SELECT id FROM users WHERE email = $1 AND id != $2 AND deleted_at IS NULL`,
        [email, id]
      );

      if (emailCheck.rows.length > 0) {
        return res.status(409).json({
          success: false,
          message: "Email already exists",
        });
      }
    }

    await client.query("BEGIN");

    // Update user
    const updateResult = await client.query(
      `
      UPDATE users
      SET 
        email = COALESCE($1, email),
        full_name = COALESCE($2, full_name),
        role = COALESCE($3, role),
        status = COALESCE($4, status),
        phone = COALESCE($5, phone),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $6
      RETURNING 
        id, username, email, full_name, role, status, phone, 
        avatar_url, created_at, updated_at
      `,
      [
        email || null,
        full_name || null,
        role || null,
        status || null,
        phone || null,
        id,
      ]
    );

    // Update branches if provided
    if (branch_ids && Array.isArray(branch_ids)) {
      // Delete existing branch assignments
      await client.query(`DELETE FROM user_branches WHERE user_id = $1`, [id]);

      // Add new branch assignments
      for (let i = 0; i < branch_ids.length; i++) {
        await client.query(
          `
          INSERT INTO user_branches (user_id, branch_id, is_default)
          VALUES ($1, $2, $3)
          `,
          [id, branch_ids[i], i === 0]
        );
      }
    }

    await client.query("COMMIT");

    logger.info(`User ${currentUser.username} updated by ${req.user.username}`);

    res.json({
      success: true,
      message: "User updated successfully",
      data: updateResult.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");
    logger.error("Error updating user:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update user",
      error: error.message,
    });
  } finally {
    client.release();
  }
};

// Delete user (soft delete)
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if user exists with branches
    const userCheck = await dbQuery(
      `SELECT u.*, ARRAY_AGG(DISTINCT ub.branch_id) as branch_ids 
       FROM users u
       LEFT JOIN user_branches ub ON u.id = ub.user_id
       WHERE u.id = $1 AND u.deleted_at IS NULL
       GROUP BY u.id`,
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const user = userCheck.rows[0];

    // BRANCH-BASED ACCESS CONTROL FOR DELETE
    // Admin/Manager can only delete users in their own branches
    if (req.user.role !== "super_admin") {
      const requesterBranches = await dbQuery(
        `SELECT branch_id FROM user_branches WHERE user_id = $1`,
        [req.user.id]
      );

      if (requesterBranches.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: "You are not assigned to any branch",
        });
      }

      const allowedBranchIds = requesterBranches.rows.map(
        (row) => row.branch_id
      );

      // Check if target user is in requester's branches
      const targetUserBranches = user.branch_ids.filter((b) => b !== null);
      const hasCommonBranch = targetUserBranches.some((branchId) =>
        allowedBranchIds.includes(branchId)
      );

      if (!hasCommonBranch) {
        return res.status(403).json({
          success: false,
          message: "You can only delete users in your own branches",
        });
      }
    }

    // Prevent deleting super_admin unless requester is super_admin
    if (user.role === "super_admin" && req.user.role !== "super_admin") {
      return res.status(403).json({
        success: false,
        message: "Cannot delete super_admin user",
      });
    }

    // Soft delete user
    await dbQuery(
      `UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [id]
    );

    logger.info(`User ${user.username} deleted by ${req.user.username}`);

    res.json({
      success: true,
      message: "User deleted successfully",
    });
  } catch (error) {
    logger.error("Error deleting user:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete user",
      error: error.message,
    });
  }
};

// Change password
export const changePassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password and new password are required",
      });
    }

    // Check if user exists
    const userCheck = await dbQuery(
      `SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL`,
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const user = userCheck.rows[0];

    // Verify current password
    const isPasswordValid = await bcrypt.compare(
      currentPassword,
      user.password_hash
    );
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const newPasswordHash = await bcrypt.hash(newPassword, salt);

    // Update password
    await dbQuery(
      `UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
      [newPasswordHash, id]
    );

    logger.info(`Password changed for user ${user.username}`);

    res.json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    logger.error("Error changing password:", error);
    res.status(500).json({
      success: false,
      message: "Failed to change password",
      error: error.message,
    });
  }
};

// Reset password (admin only)
export const resetPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword) {
      return res.status(400).json({
        success: false,
        message: "New password is required",
      });
    }

    // Check if user exists
    const userCheck = await dbQuery(
      `SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL`,
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const user = userCheck.rows[0];

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    // Update password
    await dbQuery(
      `UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
      [passwordHash, id]
    );

    logger.info(
      `Password reset for user ${user.username} by ${req.user.username}`
    );

    res.json({
      success: true,
      message: "Password reset successfully",
    });
  } catch (error) {
    logger.error("Error resetting password:", error);
    res.status(500).json({
      success: false,
      message: "Failed to reset password",
      error: error.message,
    });
  }
};

// Assign branches to user
export const assignBranches = async (req, res) => {
  try {
    const { id } = req.params;
    const { branch_ids, default_branch_id } = req.body;

    if (!Array.isArray(branch_ids) || branch_ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: "branch_ids array is required",
      });
    }

    // Check if user exists
    const userCheck = await dbQuery(
      `SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL`,
      [id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Delete existing branch assignments
    await dbQuery(`DELETE FROM user_branches WHERE user_id = $1`, [id]);

    // Add new branch assignments
    for (let i = 0; i < branch_ids.length; i++) {
      const isDefault = default_branch_id
        ? branch_ids[i] === default_branch_id
        : i === 0;
      await dbQuery(
        `
        INSERT INTO user_branches (user_id, branch_id, is_default)
        VALUES ($1, $2, $3)
        `,
        [id, branch_ids[i], isDefault]
      );
    }

    logger.info(`Branches assigned to user ${id} by ${req.user.username}`);

    res.json({
      success: true,
      message: "Branches assigned successfully",
    });
  } catch (error) {
    logger.error("Error assigning branches:", error);
    res.status(500).json({
      success: false,
      message: "Failed to assign branches",
      error: error.message,
    });
  }
};

// Get user statistics
export const getUserStats = async (req, res) => {
  try {
    const stats = await dbQuery(`
      SELECT 
        COUNT(*) as total_users,
        SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_users,
        SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive_users,
        SUM(CASE WHEN status = 'suspended' THEN 1 ELSE 0 END) as suspended_users,
        SUM(CASE WHEN role = 'super_admin' THEN 1 ELSE 0 END) as super_admins,
        SUM(CASE WHEN role = 'admin' THEN 1 ELSE 0 END) as admins,
        SUM(CASE WHEN role = 'manager' THEN 1 ELSE 0 END) as managers,
        SUM(CASE WHEN role = 'cashier' THEN 1 ELSE 0 END) as cashiers,
        SUM(CASE WHEN role = 'staff' THEN 1 ELSE 0 END) as staff
      FROM users
      WHERE deleted_at IS NULL
    `);

    res.json({
      success: true,
      data: stats.rows[0],
    });
  } catch (error) {
    logger.error("Error fetching user stats:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch user statistics",
      error: error.message,
    });
  }
};
