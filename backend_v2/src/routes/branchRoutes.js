import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";

const router = express.Router();

/**
 * @route   GET /api/v2/branches
 * @desc    Get all branches
 * @access  Private
 */
router.get(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    // TODO: Implement controller
    res.json({ message: "Get all branches" });
  })
);

/**
 * @route   GET /api/v2/branches/:id
 * @desc    Get branch by ID
 * @access  Private
 */
router.get(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get branch by ID" });
  })
);

/**
 * @route   POST /api/v2/branches
 * @desc    Create new branch
 * @access  Private (Super Admin)
 */
router.post(
  "/",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Create branch" });
  })
);

/**
 * @route   PUT /api/v2/branches/:id
 * @desc    Update branch
 * @access  Private (Super Admin)
 */
router.put(
  "/:id",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Update branch" });
  })
);

/**
 * @route   DELETE /api/v2/branches/:id
 * @desc    Delete branch
 * @access  Private (Super Admin)
 */
router.delete(
  "/:id",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Delete branch" });
  })
);

export default router;
