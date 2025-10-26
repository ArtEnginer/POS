import jwt from "jsonwebtoken";
import { UnauthorizedError, ForbiddenError } from "./errorHandler.js";
import { cache } from "../config/redis.js";
import logger from "../utils/logger.js";

/**
 * Verify JWT token middleware
 */
export const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1]; // Bearer TOKEN

    if (!token) {
      throw new UnauthorizedError("Access token required");
    }

    // Check if token is blacklisted
    const blacklisted = await cache.exists(`blacklist:${token}`);
    if (blacklisted) {
      throw new UnauthorizedError("Token has been revoked");
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user to request
    req.user = decoded;

    next();
  } catch (error) {
    if (error.name === "JsonWebTokenError") {
      next(new UnauthorizedError("Invalid token"));
    } else if (error.name === "TokenExpiredError") {
      next(new UnauthorizedError("Token expired"));
    } else {
      next(error);
    }
  }
};

/**
 * Verify API key for branch authentication
 */
export const authenticateBranch = async (req, res, next) => {
  try {
    const apiKey = req.headers["x-api-key"];

    if (!apiKey) {
      throw new UnauthorizedError("API key required");
    }

    // Verify API key from cache
    let branchId = await cache.get(`apikey:${apiKey}`);

    if (!branchId) {
      // Fetch from database if not in cache
      const { default: db } = await import("../config/database.js");
      const result = await db.query(
        "SELECT id FROM branches WHERE api_key = $1 AND is_active = true AND deleted_at IS NULL",
        [apiKey]
      );

      if (result.rows.length === 0) {
        throw new UnauthorizedError("Invalid API key");
      }

      branchId = result.rows[0].id.toString();

      // Cache for future use
      await cache.set(`apikey:${apiKey}`, branchId, 7 * 24 * 60 * 60);
    }

    // Attach branch to request
    req.branchId = branchId;

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Check user role middleware
 */
export const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new UnauthorizedError("User not authenticated"));
    }

    if (!allowedRoles.includes(req.user.role)) {
      logger.warn(
        `Unauthorized access attempt by user ${req.user.id} with role ${req.user.role}`
      );
      return next(new ForbiddenError("Insufficient permissions"));
    }

    next();
  };
};

/**
 * Check branch access middleware
 */
export const checkBranchAccess = async (req, res, next) => {
  try {
    const { branchId } = req.params;
    const userBranches = req.user.branches || [];

    // Super admin has access to all branches
    if (req.user.role === "super_admin") {
      return next();
    }

    // Check if user has access to this branch
    if (!userBranches.includes(parseInt(branchId))) {
      throw new ForbiddenError("No access to this branch");
    }

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Rate limiting per user
 */
export const userRateLimit = (maxRequests = 100, windowMs = 60000) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return next();
      }

      const key = `ratelimit:user:${req.user.id}`;
      const requests = await cache.incr(key);

      if (requests === 1) {
        await cache.expire(key, Math.floor(windowMs / 1000));
      }

      if (requests > maxRequests) {
        throw new Error("Rate limit exceeded");
      }

      // Add rate limit headers
      res.setHeader("X-RateLimit-Limit", maxRequests);
      res.setHeader(
        "X-RateLimit-Remaining",
        Math.max(0, maxRequests - requests)
      );
      res.setHeader("X-RateLimit-Reset", Date.now() + windowMs);

      next();
    } catch (error) {
      if (error.message === "Rate limit exceeded") {
        res.status(429).json({
          error: {
            message: "Too many requests, please try again later",
            status: 429,
          },
        });
      } else {
        next(error);
      }
    }
  };
};
