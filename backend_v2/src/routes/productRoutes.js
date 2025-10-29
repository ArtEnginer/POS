import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";
import { upload } from "../middleware/upload.js";
import * as productController from "../controllers/productController.js";

const router = express.Router();

/**
 * @route   DELETE /api/v2/products/cache/clear
 * @desc    Clear product cache (all or specific product)
 * @access  Private (Admin)
 */
router.delete(
  "/cache/clear/:productId?",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(productController.clearProductCache)
);

/**
 * @route   GET /api/v2/products
 * @desc    Get all products with pagination and filters
 * @access  Private
 */
router.get(
  "/",
  authenticateToken,
  asyncHandler(productController.getAllProducts)
);

/**
 * @route   GET /api/v2/products/search
 * @desc    Search products
 * @access  Private
 */
router.get(
  "/search",
  authenticateToken,
  asyncHandler(productController.searchProducts)
);

/**
 * @route   GET /api/v2/products/low-stock
 * @desc    Get low stock products
 * @access  Private
 */
router.get(
  "/low-stock",
  authenticateToken,
  asyncHandler(productController.getLowStockProducts)
);

/**
 * @route   GET /api/v2/products/import/template
 * @desc    Download import template
 * @access  Private
 */
router.get(
  "/import/template",
  authenticateToken,
  asyncHandler(productController.downloadImportTemplate)
);

/**
 * @route   POST /api/v2/products/import
 * @desc    Import products from Excel/CSV
 * @access  Private (Admin, Manager)
 */
router.post(
  "/import",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  upload.single("file"),
  asyncHandler(productController.importProducts)
);

/**
 * @route   GET /api/v2/products/barcode/:barcode
 * @desc    Get product by barcode
 * @access  Private
 */
router.get(
  "/barcode/:barcode",
  authenticateToken,
  asyncHandler(productController.getProductByBarcode)
);

/**
 * @route   GET /api/v2/products/:id
 * @desc    Get product by ID
 * @access  Private
 */
router.get(
  "/:id",
  authenticateToken,
  asyncHandler(productController.getProductById)
);

/**
 * @route   POST /api/v2/products
 * @desc    Create new product
 * @access  Private (Admin, Manager)
 */
router.post(
  "/",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(productController.createProduct)
);

/**
 * @route   PUT /api/v2/products/:id
 * @desc    Update product
 * @access  Private (Admin, Manager)
 */
router.put(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(productController.updateProduct)
);

/**
 * @route   DELETE /api/v2/products/:id
 * @desc    Delete product (soft delete)
 * @access  Private (Admin)
 */
router.delete(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(productController.deleteProduct)
);

/**
 * @route   GET /api/v2/products/:id/stock
 * @desc    Get product stock by branch
 * @access  Private
 */
router.get(
  "/:id/stock",
  authenticateToken,
  asyncHandler(productController.getProductStock)
);

/**
 * @route   PUT /api/v2/products/:id/stock
 * @desc    Update product stock
 * @access  Private (Admin, Manager)
 */
router.put(
  "/:id/stock",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(productController.updateProductStock)
);

export default router;
