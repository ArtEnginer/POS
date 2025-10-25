import express from "express";

// Import route modules
import productRoutes from "./productRoutes.js";
import saleRoutes from "./saleRoutes.js";
import purchaseRoutes from "./purchaseRoutes.js";
import customerRoutes from "./customerRoutes.js";
import supplierRoutes from "./supplierRoutes.js";
import branchRoutes from "./branchRoutes.js";
import userRoutes from "./userRoutes.js";
import authRoutes from "./authRoutes.js";
import syncRoutes from "./syncRoutes.js";
import reportRoutes from "./reportRoutes.js";

const router = express.Router();

// API Info
router.get("/", (req, res) => {
  res.json({
    name: "POS Enterprise API",
    version: process.env.API_VERSION || "v2",
    status: "running",
    endpoints: {
      auth: "/auth",
      users: "/users",
      branches: "/branches",
      products: "/products",
      customers: "/customers",
      suppliers: "/suppliers",
      sales: "/sales",
      purchases: "/purchases",
      sync: "/sync",
      reports: "/reports",
    },
  });
});

// Mount routes
router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/branches", branchRoutes);
router.use("/products", productRoutes);
router.use("/customers", customerRoutes);
router.use("/suppliers", supplierRoutes);
router.use("/sales", saleRoutes);
router.use("/purchases", purchaseRoutes);
router.use("/sync", syncRoutes);
router.use("/reports", reportRoutes);

export default router;
