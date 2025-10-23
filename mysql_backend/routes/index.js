const express = require("express");
const router = express.Router();
const tableController = require("../controllers/tableController");
const queryController = require("../controllers/queryController");
const authMiddleware = require("../middleware/auth");

// Apply authentication to all routes
router.use(authMiddleware);

// Table routes
router.get("/tables/:table", tableController.query);
router.post("/tables/:table", tableController.insert);
router.post("/tables/:table/batch", tableController.batchInsert);
router.put("/tables/:table", tableController.update);
router.delete("/tables/:table", tableController.delete);

// Custom query
router.post("/query", queryController.execute);

module.exports = router;
