import express from "express";
import dashboardController from "../controllers/dashboardController.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

// All dashboard routes require authentication
router.use(authenticateToken);

/**
 * @route   GET /api/v2/dashboard/overview
 * @desc    Get dashboard overview statistics
 * @access  Private
 */
router.get("/overview", dashboardController.getOverview);

export default router;
