import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

router.get(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get all suppliers" });
  })
);

router.get(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get supplier by ID" });
  })
);

router.post(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Create supplier" });
  })
);

router.put(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Update supplier" });
  })
);

router.delete(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Delete supplier" });
  })
);

export default router;
