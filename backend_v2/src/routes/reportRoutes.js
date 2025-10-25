import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";

const router = express.Router();

/**
 * @route   GET /api/v2/reports/sales
 * @desc    Get sales report
 * @access  Private
 */
router.get(
  "/sales",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Sales report" });
  })
);

/**
 * @route   GET /api/v2/reports/inventory
 * @desc    Get inventory report
 * @access  Private
 */
router.get(
  "/inventory",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Inventory report" });
  })
);

/**
 * @route   GET /api/v2/reports/profit-loss
 * @desc    Get profit & loss report
 * @access  Private
 */
router.get(
  "/profit-loss",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Profit & loss report" });
  })
);

export default router;
