import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

// Placeholder routes - implement controllers sesuai kebutuhan

router.get(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get all purchases" });
  })
);

router.get(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get purchase by ID" });
  })
);

router.post(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Create purchase" });
  })
);

router.put(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Update purchase" });
  })
);

router.delete(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Delete purchase" });
  })
);

export default router;
