import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken } from "../middleware/auth.js";
import * as saleController from "../controllers/saleController.js";

const router = express.Router();

/**
 * @route   GET /api/v2/sales
 * @desc    Get all sales with pagination and filters
 * @access  Private
 */
router.get("/", authenticateToken, asyncHandler(saleController.getAllSales));

/**
 * @route   GET /api/v2/sales/today
 * @desc    Get today's sales
 * @access  Private
 */
router.get(
  "/today",
  authenticateToken,
  asyncHandler(saleController.getTodaySales)
);

/**
 * @route   GET /api/v2/sales/summary
 * @desc    Get sales summary
 * @access  Private
 */
router.get(
  "/summary",
  authenticateToken,
  asyncHandler(saleController.getSalesSummary)
);

/**
 * @route   GET /api/v2/sales/:id
 * @desc    Get sale by ID
 * @access  Private
 */
router.get("/:id", authenticateToken, asyncHandler(saleController.getSaleById));

/**
 * @route   POST /api/v2/sales
 * @desc    Create new sale
 * @access  Private
 */
router.post("/", authenticateToken, asyncHandler(saleController.createSale));

/**
 * @route   PUT /api/v2/sales/:id
 * @desc    Update sale
 * @access  Private
 */
router.put("/:id", authenticateToken, asyncHandler(saleController.updateSale));

/**
 * @route   DELETE /api/v2/sales/:id
 * @desc    Cancel sale
 * @access  Private
 */
router.delete(
  "/:id",
  authenticateToken,
  asyncHandler(saleController.cancelSale)
);

/**
 * @route   POST /api/v2/sales/:id/refund
 * @desc    Refund sale
 * @access  Private
 */
router.post(
  "/:id/refund",
  authenticateToken,
  asyncHandler(saleController.refundSale)
);

export default router;
