import express from "express";
import { authenticateToken } from "../middleware/auth.js";
import {
  getAllSuppliers,
  getSupplierById,
  searchSuppliers,
  createSupplier,
  updateSupplier,
  deleteSupplier,
  generateSupplierCode,
} from "../controllers/supplierController.js";

const router = express.Router();

// Generate supplier code
router.get("/generate-code", authenticateToken, generateSupplierCode);

// Search suppliers
router.get("/search", authenticateToken, searchSuppliers);

// Get all suppliers
router.get("/", authenticateToken, getAllSuppliers);

// Get supplier by ID
router.get("/:id", authenticateToken, getSupplierById);

// Create supplier
router.post("/", authenticateToken, createSupplier);

// Update supplier
router.put("/:id", authenticateToken, updateSupplier);

// Delete supplier
router.delete("/:id", authenticateToken, deleteSupplier);

export default router;
