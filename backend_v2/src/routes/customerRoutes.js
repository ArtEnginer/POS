import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";
import * as customerController from "../controllers/customerController.js";

const router = express.Router();

/**
 * @route   GET /api/v2/customers
 * @desc    Get all customers with pagination and filters
 * @access  Private
 */
router.get(
  "/",
  authenticateToken,
  asyncHandler(customerController.getAllCustomers)
);

/**
 * @route   GET /api/v2/customers/search
 * @desc    Search customers
 * @access  Private
 */
router.get(
  "/search",
  authenticateToken,
  asyncHandler(customerController.searchCustomers)
);

/**
 * @route   GET /api/v2/customers/generate-code
 * @desc    Generate unique customer code
 * @access  Private
 */
router.get(
  "/generate-code",
  authenticateToken,
  asyncHandler(customerController.generateCustomerCode)
);

/**
 * @route   GET /api/v2/customers/:id
 * @desc    Get customer by ID
 * @access  Private
 */
router.get(
  "/:id",
  authenticateToken,
  asyncHandler(customerController.getCustomerById)
);

/**
 * @route   POST /api/v2/customers
 * @desc    Create new customer
 * @access  Private (Admin, Manager)
 */
router.post(
  "/",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(customerController.createCustomer)
);

/**
 * @route   PUT /api/v2/customers/:id
 * @desc    Update customer
 * @access  Private (Admin, Manager)
 */
router.put(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin", "manager"),
  asyncHandler(customerController.updateCustomer)
);

/**
 * @route   DELETE /api/v2/customers/:id
 * @desc    Delete customer (soft delete)
 * @access  Private (Admin)
 */
router.delete(
  "/:id",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(customerController.deleteCustomer)
);

export default router;
