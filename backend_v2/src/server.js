import express from "express";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { createServer } from "http";
import { Server } from "socket.io";
import dotenv from "dotenv";

// Import configurations
import db from "./config/database.js";
import redis, { connectRedis } from "./config/redis.js";
import logger from "./utils/logger.js";

// Import middleware
import { errorHandler } from "./middleware/errorHandler.js";
import { notFoundHandler } from "./middleware/notFoundHandler.js";

// Import routes
import routes from "./routes/index.js";

// Import socket handlers
import { initializeSocketIO } from "./socket/index.js";
import { setIO } from "./utils/socket-io.js";

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.SOCKET_IO_ORIGINS || "*",
    methods: ["GET", "POST"],
    credentials: true,
  },
  path: process.env.SOCKET_IO_PATH || "/socket.io",
});

const PORT = process.env.PORT || 3001;
const API_VERSION = process.env.API_VERSION || "v2";

// ========== MIDDLEWARE ==========

// Security
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  })
);

// CORS
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "*",
    credentials: true,
  })
);

// Compression
app.use(compression());

// Body parser
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// Logging
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
} else {
  app.use(morgan("combined", { stream: logger.stream }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: "Too many requests from this IP, please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting untuk health check
    return req.path === `/api/${API_VERSION}/health`;
  },
});

app.use(`/api/${API_VERSION}`, limiter);

// ========== ROUTES ==========

// Health check endpoint
app.get(`/api/${API_VERSION}/health`, async (req, res) => {
  try {
    const dbHealth = await db.healthCheck();
    const redisHealth = await redis.healthCheck();

    const health = {
      status: "OK",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV,
      version: API_VERSION,
      services: {
        database: dbHealth ? "connected" : "disconnected",
        redis: redisHealth ? "connected" : "disconnected",
        socketio: io.engine.clientsCount > 0 ? "active" : "idle",
      },
      stats: {
        dbPool: db.getPoolStats(),
        socketConnections: io.engine.clientsCount,
      },
    };

    const statusCode = dbHealth && redisHealth ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    logger.error("Health check error:", error);
    res.status(503).json({
      status: "ERROR",
      message: "Service unhealthy",
      error: error.message,
    });
  }
});

// API routes
app.use(`/api/${API_VERSION}`, routes);

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    name: "POS Enterprise API",
    version: API_VERSION,
    status: "running",
    documentation: `/api/${API_VERSION}/docs`,
  });
});

// ========== ERROR HANDLING ==========

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// ========== INITIALIZATION ==========

const startServer = async () => {
  try {
    // Connect to Redis
    logger.info("Connecting to Redis...");
    await connectRedis();

    // Check database connection
    logger.info("Checking database connection...");
    const dbHealthy = await db.healthCheck();
    if (!dbHealthy) {
      throw new Error("Database connection failed");
    }

    // Initialize Socket.IO
    logger.info("Initializing Socket.IO...");
    initializeSocketIO(io);

    // Set global io instance untuk digunakan di controllers
    setIO(io);
    logger.info("✅ Socket.IO instance set globally");

    // Start server
    httpServer.listen(PORT, () => {
      logger.info("=".repeat(60));
      logger.info(`🚀 POS Enterprise API Server`);
      logger.info("=".repeat(60));
      logger.info(`Environment: ${process.env.NODE_ENV || "development"}`);
      logger.info(`Port: ${PORT}`);
      logger.info(`API Version: ${API_VERSION}`);
      logger.info(`Database: ${process.env.DB_NAME}@${process.env.DB_HOST}`);
      logger.info(`Redis: ${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`);
      logger.info(`Process ID: ${process.pid}`);
      logger.info("=".repeat(60));
      logger.info(`API URL: http://localhost:${PORT}/api/${API_VERSION}`);
      logger.info(
        `Health Check: http://localhost:${PORT}/api/${API_VERSION}/health`
      );
      logger.info(
        `Socket.IO: ws://localhost:${PORT}${process.env.SOCKET_IO_PATH}`
      );
      logger.info("=".repeat(60));
    });
  } catch (error) {
    logger.error("Failed to start server:", error);
    process.exit(1);
  }
};

// ========== GRACEFUL SHUTDOWN ==========

const gracefulShutdown = async (signal) => {
  logger.info(`\n${signal} signal received: starting graceful shutdown`);

  // Stop accepting new connections
  httpServer.close(async () => {
    logger.info("HTTP server closed");

    try {
      // Close Socket.IO
      io.close(() => {
        logger.info("Socket.IO closed");
      });

      // Close database connections
      await db.closePool();
      logger.info("Database pool closed");

      // Close Redis connections
      await redis.close();
      logger.info("Redis connections closed");

      logger.info("Graceful shutdown completed");
      process.exit(0);
    } catch (error) {
      logger.error("Error during graceful shutdown:", error);
      process.exit(1);
    }
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    logger.error("Forcing shutdown after timeout");
    process.exit(1);
  }, 30000);
};

// Handle termination signals
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

// Handle uncaught errors
process.on("uncaughtException", (error) => {
  logger.error("Uncaught Exception:", error);
  gracefulShutdown("uncaughtException");
});

process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled Rejection at:", promise);
  logger.error("Rejection reason:", JSON.stringify(reason, null, 2));
  if (reason && reason.stack) {
    logger.error("Stack trace:", reason.stack);
  }
  gracefulShutdown("unhandledRejection");
});

// Start the server
startServer();

// No need to export io anymore - use getIO() from utils/socket-io.js
export { app, httpServer };
