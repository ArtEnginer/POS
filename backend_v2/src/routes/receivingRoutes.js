import express from "express";
import {
  getAllReceivings,
  getReceivingById,
  searchReceivings,
  createReceiving,
  updateReceiving,
  deleteReceiving,
  generateReceivingNumber,
} from "../controllers/receivingController.js";

const router = express.Router();

// GET routes
router.get("/", getAllReceivings);
router.get("/search", searchReceivings);
router.get("/generate-number", generateReceivingNumber);
router.get("/:id", getReceivingById);

// POST routes
router.post("/", createReceiving);

// PUT routes
router.put("/:id", updateReceiving);

// DELETE routes
router.delete("/:id", deleteReceiving);

export default router;
