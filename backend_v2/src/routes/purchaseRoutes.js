import express from "express";
import { authenticateToken } from "../middleware/auth.js";
import {
  getAllPurchases,
  getPurchaseById,
  searchPurchases,
  createPurchase,
  updatePurchase,
  deletePurchase,
  generatePurchaseNumber,
  updatePurchaseStatus,
} from "../controllers/purchaseController.js";

const router = express.Router();

// Generate purchase number
router.get("/generate-number", authenticateToken, generatePurchaseNumber);

// Search purchases
router.get("/search", authenticateToken, searchPurchases);

// Get all purchases
router.get("/", authenticateToken, getAllPurchases);

// Get purchase by ID
router.get("/:id", authenticateToken, getPurchaseById);

// Create purchase
router.post("/", authenticateToken, createPurchase);

// Update purchase
router.put("/:id", authenticateToken, updatePurchase);

// Update purchase status
router.patch("/:id/status", authenticateToken, updatePurchaseStatus);

// Delete purchase
router.delete("/:id", authenticateToken, deletePurchase);

export default router;
