import express from "express";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import {
  asyncHandler,
  UnauthorizedError,
  ValidationError,
} from "../middleware/errorHandler.js";
import db from "../config/database.js";
import { cache } from "../config/redis.js";

const router = express.Router();

/**
 * @route   POST /api/v2/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post(
  "/login",
  asyncHandler(async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
      throw new ValidationError("Username and password required");
    }

    // Get user from database
    const result = await db.query(
      `SELECT id, username, email, password_hash, full_name, role, status 
     FROM users 
     WHERE username = $1 AND deleted_at IS NULL`,
      [username]
    );

    if (result.rows.length === 0) {
      throw new UnauthorizedError("Invalid credentials");
    }

    const user = result.rows[0];

    // Check if user is active
    if (user.status !== "active") {
      throw new UnauthorizedError("Account is inactive");
    }

    // Verify password
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      throw new UnauthorizedError("Invalid credentials");
    }

    // Get user's branches
    const branchesResult = await db.query(
      `SELECT ub.branch_id, ub.is_default, b.code, b.name, b.api_key
       FROM user_branches ub
       JOIN branches b ON b.id = ub.branch_id
       WHERE ub.user_id = $1 AND b.is_active = true AND b.deleted_at IS NULL
       ORDER BY ub.is_default DESC, b.name ASC`,
      [user.id]
    );

    const userBranches = branchesResult.rows;

    // Get default branch or first available branch
    let defaultBranch =
      userBranches.find((b) => b.is_default) || userBranches[0];

    // If no branches assigned, super_admin gets access to all branches
    if (!defaultBranch && user.role === "super_admin") {
      const allBranchesResult = await db.query(
        `SELECT id as branch_id, code, name, api_key, true as is_default
         FROM branches 
         WHERE is_active = true AND deleted_at IS NULL
         ORDER BY is_head_office DESC, name ASC
         LIMIT 1`
      );

      if (allBranchesResult.rows.length > 0) {
        defaultBranch = allBranchesResult.rows[0];
      }
    }

    if (!defaultBranch) {
      throw new UnauthorizedError("No branch assigned to user");
    }

    // Generate tokens with branch info
    const accessToken = jwt.sign(
      {
        id: user.id,
        username: user.username,
        role: user.role,
        branchId: defaultBranch.branch_id.toString(),
        branches: userBranches.map((b) => b.branch_id),
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRATION || "15m" }
    );

    const refreshToken = jwt.sign(
      { id: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRATION || "7d" }
    );

    // Store refresh token in Redis
    await cache.set(`refresh_token:${user.id}`, refreshToken, 7 * 24 * 60 * 60);

    // Cache API key for branch authentication
    await cache.set(
      `apikey:${defaultBranch.api_key}`,
      defaultBranch.branch_id.toString(),
      7 * 24 * 60 * 60
    );

    // Update last login
    await db.query(
      "UPDATE users SET last_login_at = NOW(), last_login_ip = $1 WHERE id = $2",
      [req.ip, user.id]
    );

    res.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        branchId: defaultBranch.branch_id.toString(),
        branches: userBranches.map((b) => ({
          id: b.branch_id,
          code: b.code,
          name: b.name,
          isDefault: b.is_default,
        })),
      },
      branch: {
        id: defaultBranch.branch_id.toString(),
        code: defaultBranch.code,
        name: defaultBranch.name,
      },
      tokens: {
        accessToken,
        refreshToken,
      },
    });
  })
);

/**
 * @route   POST /api/v2/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post(
  "/refresh",
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      throw new ValidationError("Refresh token required");
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    // Check if token exists in Redis
    const storedToken = await cache.get(`refresh_token:${decoded.id}`);
    if (storedToken !== refreshToken) {
      throw new UnauthorizedError("Invalid refresh token");
    }

    // Get user
    const result = await db.query(
      "SELECT id, username, role FROM users WHERE id = $1 AND status = $2",
      [decoded.id, "active"]
    );

    if (result.rows.length === 0) {
      throw new UnauthorizedError("User not found");
    }

    const user = result.rows[0];

    // Get user's branches for token
    const branchesResult = await db.query(
      `SELECT ub.branch_id, ub.is_default
       FROM user_branches ub
       WHERE ub.user_id = $1`,
      [user.id]
    );

    const userBranches = branchesResult.rows;
    const defaultBranch =
      userBranches.find((b) => b.is_default) || userBranches[0];

    // Generate new access token
    const accessToken = jwt.sign(
      {
        id: user.id,
        username: user.username,
        role: user.role,
        branchId: defaultBranch ? defaultBranch.branch_id.toString() : null,
        branches: userBranches.map((b) => b.branch_id),
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRATION || "15m" }
    );

    res.json({
      success: true,
      tokens: {
        accessToken,
        refreshToken,
      },
    });
  })
);

/**
 * @route   POST /api/v2/auth/logout
 * @desc    Logout user
 * @access  Private
 */
router.post(
  "/logout",
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    const authHeader = req.headers["authorization"];
    const accessToken = authHeader && authHeader.split(" ")[1];

    if (refreshToken) {
      const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, {
        ignoreExpiration: true,
      });
      await cache.del(`refresh_token:${decoded.id}`);
    }

    if (accessToken) {
      // Blacklist access token
      await cache.set(`blacklist:${accessToken}`, "1", 15 * 60); // 15 minutes
    }

    res.json({
      success: true,
      message: "Logged out successfully",
    });
  })
);

/**
 * @route   POST /api/v2/auth/change-password
 * @desc    Change user password
 * @access  Private
 */
router.post(
  "/change-password",
  asyncHandler(async (req, res) => {
    // TODO: Implement password change
    res.json({ message: "Change password" });
  })
);

/**
 * @route   POST /api/v2/auth/switch-branch
 * @desc    Switch user's active branch
 * @access  Private
 */
router.post(
  "/switch-branch",
  asyncHandler(async (req, res) => {
    const { branchId } = req.body;
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1];

    if (!token) {
      throw new UnauthorizedError("Access token required");
    }

    if (!branchId) {
      throw new ValidationError("Branch ID required");
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if user has access to this branch
    const accessResult = await db.query(
      `SELECT ub.id, b.code, b.name, b.api_key
       FROM user_branches ub
       JOIN branches b ON b.id = ub.branch_id
       WHERE ub.user_id = $1 AND ub.branch_id = $2 AND b.is_active = true`,
      [decoded.id, parseInt(branchId)]
    );

    if (accessResult.rows.length === 0 && decoded.role !== "super_admin") {
      throw new ForbiddenError("No access to this branch");
    }

    // If super admin and no access, allow anyway
    let branch;
    if (accessResult.rows.length > 0) {
      branch = accessResult.rows[0];
    } else {
      // Get branch for super admin
      const branchResult = await db.query(
        "SELECT id, code, name, api_key FROM branches WHERE id = $1 AND is_active = true",
        [parseInt(branchId)]
      );

      if (branchResult.rows.length === 0) {
        throw new ValidationError("Branch not found");
      }

      branch = branchResult.rows[0];
    }

    // Get all user branches for token
    const branchesResult = await db.query(
      `SELECT branch_id FROM user_branches WHERE user_id = $1`,
      [decoded.id]
    );

    // Generate new tokens with new branch
    const accessToken = jwt.sign(
      {
        id: decoded.id,
        username: decoded.username,
        role: decoded.role,
        branchId: branchId.toString(),
        branches: branchesResult.rows.map((b) => b.branch_id),
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRATION || "15m" }
    );

    const refreshToken = jwt.sign(
      { id: decoded.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRATION || "7d" }
    );

    // Store new refresh token
    await cache.set(
      `refresh_token:${decoded.id}`,
      refreshToken,
      7 * 24 * 60 * 60
    );

    // Cache API key
    await cache.set(
      `apikey:${branch.api_key}`,
      branchId.toString(),
      7 * 24 * 60 * 60
    );

    res.json({
      success: true,
      branch: {
        id: branchId.toString(),
        code: branch.code,
        name: branch.name,
      },
      tokens: {
        accessToken,
        refreshToken,
      },
    });
  })
);

export default router;
