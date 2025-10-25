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

    // Generate tokens
    const accessToken = jwt.sign(
      {
        id: user.id,
        username: user.username,
        role: user.role,
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

    // Generate new access token
    const accessToken = jwt.sign(
      {
        id: user.id,
        username: user.username,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRATION || "15m" }
    );

    res.json({
      success: true,
      accessToken,
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

export default router;
