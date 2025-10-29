import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";
import {
  getAllBranches,
  getBranchById,
  getCurrentBranch,
  searchBranches,
  createBranch,
  updateBranch,
  deleteBranch,
  generateBranchCode,
} from "../controllers/branchController.js";

const router = express.Router();

/**
 * @route   GET /api/v2/branches
 * @desc    Get all branches
 * @access  Private
 */
router.get("/", authenticateToken, asyncHandler(getAllBranches));

/**
 * @route   GET /api/v2/branches/search
 * @desc    Search branches
 * @access  Private
 */
router.get("/search", authenticateToken, asyncHandler(searchBranches));

/**
 * @route   GET /api/v2/branches/current
 * @desc    Get current user's branch
 * @access  Private
 */
router.get("/current", authenticateToken, asyncHandler(getCurrentBranch));

/**
 * @route   GET /api/v2/branches/generate-code
 * @desc    Generate branch code
 * @access  Private (Super Admin)
 */
router.get(
  "/generate-code",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(generateBranchCode)
);

/**
 * @route   GET /api/v2/branches/:id
 * @desc    Get branch by ID
 * @access  Private
 */
router.get("/:id", authenticateToken, asyncHandler(getBranchById));

/**
 * @route   POST /api/v2/branches
 * @desc    Create new branch
 * @access  Private (Super Admin)
 */
router.post(
  "/",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(createBranch)
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
  asyncHandler(updateBranch)
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
  asyncHandler(deleteBranch)
);

export default router;
