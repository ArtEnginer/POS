import express from "express";
import {
  getAllUnits,
  getUnitById,
  createUnit,
  updateUnit,
  deleteUnit,
} from "../controllers/unitController.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

/**
 * @route   GET /api/v2/units
 * @desc    Get all units
 * @access  Private
 */
router.get("/", getAllUnits);

/**
 * @route   GET /api/v2/units/:id
 * @desc    Get unit by ID
 * @access  Private
 */
router.get("/:id", getUnitById);

/**
 * @route   POST /api/v2/units
 * @desc    Create new unit
 * @access  Private
 */
router.post("/", createUnit);

/**
 * @route   PUT /api/v2/units/:id
 * @desc    Update unit
 * @access  Private
 */
router.put("/:id", updateUnit);

/**
 * @route   DELETE /api/v2/units/:id
 * @desc    Delete unit (soft delete)
 * @access  Private
 */
router.delete("/:id", deleteUnit);

export default router;
