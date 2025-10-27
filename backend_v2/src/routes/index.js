import express from "express";

// Import route modules
import productRoutes from "./productRoutes.js";
import categoryRoutes from "./categoryRoutes.js";
import saleRoutes from "./saleRoutes.js";
import purchaseRoutes from "./purchaseRoutes.js";
import receivingRoutes from "./receivingRoutes.js";
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
      categories: "/categories",
      customers: "/customers",
      suppliers: "/suppliers",
      sales: "/sales",
      purchases: "/purchases",
      receivings: "/receivings",
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
router.use("/categories", categoryRoutes);
router.use("/customers", customerRoutes);
router.use("/suppliers", supplierRoutes);
router.use("/sales", saleRoutes);
router.use("/purchases", purchaseRoutes);
router.use("/receivings", receivingRoutes);
router.use("/sync", syncRoutes);
router.use("/reports", reportRoutes);

export default router;
