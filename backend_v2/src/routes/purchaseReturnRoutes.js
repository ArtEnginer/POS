import express from "express";
import { authenticateToken } from "../middleware/auth.js";
import {
  getAllPurchaseReturns,
  getPurchaseReturnById,
  getPurchaseReturnsByReceiving,
  searchPurchaseReturns,
  createPurchaseReturn,
  updatePurchaseReturn,
  updatePurchaseReturnStatus,
  deletePurchaseReturn,
  generateReturnNumber,
} from "../controllers/purchaseReturnController.js";

const router = express.Router();

// Generate return number
router.get("/generate-number", authenticateToken, generateReturnNumber);

// Search purchase returns
router.get("/search", authenticateToken, searchPurchaseReturns);

// Get purchase returns by receiving ID
router.get(
  "/receiving/:receivingId",
  authenticateToken,
  getPurchaseReturnsByReceiving
);

// Update purchase return status
router.patch("/:id/status", authenticateToken, updatePurchaseReturnStatus);

// Get all purchase returns
router.get("/", authenticateToken, getAllPurchaseReturns);

// Get purchase return by ID
router.get("/:id", authenticateToken, getPurchaseReturnById);

// Create purchase return
router.post("/", authenticateToken, createPurchaseReturn);

// Update purchase return
router.put("/:id", authenticateToken, updatePurchaseReturn);

// Delete purchase return
router.delete("/:id", authenticateToken, deletePurchaseReturn);

export default router;
