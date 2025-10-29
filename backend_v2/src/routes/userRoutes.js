import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";
import * as userController from "../controllers/userController.js";
import {
  validateCreateUser,
  validateUpdateUser,
  validateChangePassword,
  validateResetPassword,
  validateAssignBranches,
  validateListUsers,
} from "../middleware/userValidator.js";

const router = express.Router();

// Get all users (with pagination and filtering)
router.get(
  "/",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  validateListUsers,
  asyncHandler(userController.getAllUsers)
);

// Get user statistics
router.get(
  "/stats/summary",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(userController.getUserStats)
);

// Get user by ID
router.get("/:id", authenticateToken, asyncHandler(userController.getUserById));

// Create new user
router.post(
  "/",
  authenticateToken,
  authorize("super_admin", "admin"),
  validateCreateUser,
  asyncHandler(userController.createUser)
);

// Update user
router.put(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin"),
  validateUpdateUser,
  asyncHandler(userController.updateUser)
);

// Change password (self)
router.post(
  "/:id/change-password",
  authenticateToken,
  validateChangePassword,
  asyncHandler(userController.changePassword)
);

// Reset password (admin only)
router.post(
  "/:id/reset-password",
  authenticateToken,
  authorize("super_admin", "admin"),
  validateResetPassword,
  asyncHandler(userController.resetPassword)
);

// Assign branches to user
router.post(
  "/:id/assign-branches",
  authenticateToken,
  authorize("super_admin", "admin"),
  validateAssignBranches,
  asyncHandler(userController.assignBranches)
);

// Delete user (soft delete)
router.delete(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(userController.deleteUser)
);

export default router;
