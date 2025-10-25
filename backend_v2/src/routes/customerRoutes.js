import express from "express";
import { asyncHandler } from "../middleware/errorHandler.js";
import { authenticateToken } from "../middleware/auth.js";

const router = express.Router();

router.get(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get all customers" });
  })
);

router.get(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Get customer by ID" });
  })
);

router.post(
  "/",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Create customer" });
  })
);

router.put(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Update customer" });
  })
);

router.delete(
  "/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    res.json({ message: "Delete customer" });
  })
);

export default router;
