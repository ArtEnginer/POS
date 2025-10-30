import express from "express";
import {
  getCashierSettings,
  updateCashierSettings,
  getBranchCashierSettings,
  deleteCashierSettings,
} from "../controllers/cashierSettingsController.js";
import { protect } from "../middleware/auth.js";
import { checkRole } from "../middleware/checkRole.js";

const router = express.Router();

// All routes require authentication
router.use(protect);

// Get current user's cashier settings
router.get("/", getCashierSettings);

// Update current user's cashier settings
router.put("/", updateCashierSettings);

// Delete current user's cashier settings
router.delete("/", deleteCashierSettings);

// Get all cashier settings for a branch (admin only)
router.get(
  "/branch/:branchId",
  checkRole(["super_admin", "admin", "manager"]),
  getBranchCashierSettings
);

export default router;
