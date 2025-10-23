const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const bodyParser = require("body-parser");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "50mb" }));

// Database connection
const db = require("./config/database");

// Test database connection
db.getConnection()
  .then((connection) => {
    console.log("✓ MySQL Database connected successfully");
    connection.release();
  })
  .catch((err) => {
    console.error("✗ MySQL connection error:", err);
    process.exit(1);
  });

// Routes
app.use("/api/v1", require("./routes"));

// Health check
app.get("/api/v1/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);
  res.status(err.status || 500).json({
    error: {
      message: err.message || "Internal Server Error",
      status: err.status || 500,
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      message: "Endpoint not found",
      status: 404,
    },
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`   Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`   Database: ${process.env.DB_NAME}@${process.env.DB_HOST}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM signal received: closing HTTP server");
  db.end();
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT signal received: closing HTTP server");
  db.end();
  process.exit(0);
});
