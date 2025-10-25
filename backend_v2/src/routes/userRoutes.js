import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken, authorize } from "../middleware/auth.js";

const router = express.Router();

router.get(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get all users" });
  })
);

router.get(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get user by ID" });
  })
);

router.post(
  "/",
  authenticateToken,
  authorize("super_admin", "admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Create user" });
  })
);

router.put(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Update user" });
  })
);

router.delete(
  "/:id",
  authenticateToken,
  authorize("super_admin"),
  asyncHandler(async (req, res) => {
    res.json({ message: "Delete user" });
  })
);

export default router;
