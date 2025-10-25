import logger from "../utils/logger.js";

/**
 * Initialize Socket.IO handlers
 */
export const initializeSocketIO = (io) => {
  // Middleware for Socket.IO authentication
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      const branchId = socket.handshake.auth.branchId;

      if (!branchId) {
        return next(new Error("Branch ID required"));
      }

      // TODO: Verify token jika diperlukan

      socket.branchId = branchId;
      socket.userId = socket.handshake.auth.userId;

      next();
    } catch (error) {
      logger.error("Socket authentication error:", error);
      next(error);
    }
  });

  // Connection handler
  io.on("connection", (socket) => {
    logger.info(`Socket connected: ${socket.id} (Branch: ${socket.branchId})`);

    // Join branch room
    socket.join(`branch:${socket.branchId}`);

    // Join user room if userId exists
    if (socket.userId) {
      socket.join(`user:${socket.userId}`);
    }

    // Emit connection success
    socket.emit("connected", {
      socketId: socket.id,
      branchId: socket.branchId,
      timestamp: new Date().toISOString(),
    });

    // ========== EVENT HANDLERS ==========

    /**
     * Ping/Pong for connection health check
     */
    socket.on("ping", () => {
      socket.emit("pong", { timestamp: new Date().toISOString() });
    });

    /**
     * Sync request from branch
     */
    socket.on("sync:request", async (data) => {
      try {
        logger.info(`Sync request from branch ${socket.branchId}:`, data);

        // TODO: Process sync request

        socket.emit("sync:response", {
          success: true,
          message: "Sync completed",
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        logger.error("Sync request error:", error);
        socket.emit("sync:error", {
          error: error.message,
        });
      }
    });

    /**
     * Product update notification
     */
    socket.on("product:update", async (data) => {
      try {
        logger.info(`Product update from branch ${socket.branchId}:`, data);

        // Broadcast to other branches (exclude sender)
        socket.to(`branch:${socket.branchId}`).emit("product:updated", {
          ...data,
          branchId: socket.branchId,
          timestamp: new Date().toISOString(),
        });

        // Broadcast to all other branches if multi-branch sync enabled
        if (process.env.ENABLE_MULTI_BRANCH === "true") {
          socket.broadcast.emit("product:updated", {
            ...data,
            branchId: socket.branchId,
            timestamp: new Date().toISOString(),
          });
        }
      } catch (error) {
        logger.error("Product update error:", error);
      }
    });

    /**
     * Stock update notification
     */
    socket.on("stock:update", async (data) => {
      try {
        logger.info(`Stock update from branch ${socket.branchId}:`, data);

        // Broadcast to HQ and other branches
        io.emit("stock:updated", {
          ...data,
          branchId: socket.branchId,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        logger.error("Stock update error:", error);
      }
    });

    /**
     * Sale completed notification
     */
    socket.on("sale:completed", async (data) => {
      try {
        logger.info(`Sale completed at branch ${socket.branchId}:`, data);

        // Broadcast to HQ for real-time dashboard
        io.to("branch:1").emit("sale:new", {
          // Branch 1 = HQ
          ...data,
          branchId: socket.branchId,
          timestamp: new Date().toISOString(),
        });

        // Update stock for all branches
        io.emit("stock:updated", {
          productId: data.productId,
          quantity: data.quantity,
          branchId: socket.branchId,
          type: "sale",
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        logger.error("Sale completed error:", error);
      }
    });

    /**
     * Real-time notification
     */
    socket.on("notification:send", async (data) => {
      try {
        const { targetBranch, targetUser, message, type } = data;

        if (targetBranch) {
          io.to(`branch:${targetBranch}`).emit("notification:received", {
            message,
            type,
            from: socket.branchId,
            timestamp: new Date().toISOString(),
          });
        }

        if (targetUser) {
          io.to(`user:${targetUser}`).emit("notification:received", {
            message,
            type,
            from: socket.userId,
            timestamp: new Date().toISOString(),
          });
        }
      } catch (error) {
        logger.error("Notification send error:", error);
      }
    });

    /**
     * Disconnect handler
     */
    socket.on("disconnect", (reason) => {
      logger.info(`Socket disconnected: ${socket.id} (Reason: ${reason})`);
    });

    /**
     * Error handler
     */
    socket.on("error", (error) => {
      logger.error(`Socket error (${socket.id}):`, error);
    });
  });

  // ========== UTILITY FUNCTIONS ==========

  /**
   * Broadcast to specific branch
   */
  io.toBranch = (branchId, event, data) => {
    io.to(`branch:${branchId}`).emit(event, data);
  };

  /**
   * Broadcast to specific user
   */
  io.toUser = (userId, event, data) => {
    io.to(`user:${userId}`).emit(event, data);
  };

  /**
   * Broadcast to all branches except one
   */
  io.toAllExcept = (excludeBranchId, event, data) => {
    io.sockets.sockets.forEach((socket) => {
      if (socket.branchId !== excludeBranchId) {
        socket.emit(event, data);
      }
    });
  };

  /**
   * Get connected clients count
   */
  io.getConnectionCount = () => {
    return io.engine.clientsCount;
  };

  /**
   * Get connections by branch
   */
  io.getBranchConnections = (branchId) => {
    const room = io.sockets.adapter.rooms.get(`branch:${branchId}`);
    return room ? room.size : 0;
  };

  logger.info("Socket.IO handlers initialized");

  return io;
};

/**
 * Helper function to emit events from outside Socket.IO context
 */
export const emitEvent = (io, event, data) => {
  if (io) {
    io.emit(event, data);
  }
};

export const emitToBranch = (io, branchId, event, data) => {
  if (io) {
    io.to(`branch:${branchId}`).emit(event, data);
  }
};

export const emitToUser = (io, userId, event, data) => {
  if (io) {
    io.to(`user:${userId}`).emit(event, data);
  }
};
