import express from "express";
import salesReturnController from "../controllers/salesReturnController.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

/**
 * Sales Returns Routes
 * All routes require authentication
 */

// Get recent sales for return (must be before /:id route)
router.get(
  "/recent-sales",
  authenticateToken,
  salesReturnController.getRecentSalesForReturn
);

// Create new return
router.post("/", authenticateToken, salesReturnController.createReturn);

// Get all returns (with filters)
router.get("/", authenticateToken, salesReturnController.getReturns);

// Get single return by ID
router.get("/:id", authenticateToken, salesReturnController.getReturnById);

// Update return status
router.patch(
  "/:id/status",
  authenticateToken,
  salesReturnController.updateReturnStatus
);

// Get returns by original sale ID
router.get(
  "/sale/:saleId",
  authenticateToken,
  salesReturnController.getReturnsBySaleId
);

export default router;
