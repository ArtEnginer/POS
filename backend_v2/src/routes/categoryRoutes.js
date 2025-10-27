import express from "express";
import {
  getAllCategories,
  getCategoryById,
  createCategory,
  updateCategory,
  deleteCategory,
} from "../controllers/categoryController.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// GET /api/v2/categories - Get all categories
router.get("/", getAllCategories);

// GET /api/v2/categories/:id - Get category by ID
router.get("/:id", getCategoryById);

// POST /api/v2/categories - Create new category
router.post("/", createCategory);

// PUT /api/v2/categories/:id - Update category
router.put("/:id", updateCategory);

// DELETE /api/v2/categories/:id - Delete category
router.delete("/:id", deleteCategory);

export default router;
