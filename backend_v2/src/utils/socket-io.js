/**
 * Global Socket.IO instance holder
 * This avoids circular dependency issues
 */

let io = null;

export const setIO = (ioInstance) => {
  io = ioInstance;
};

export const getIO = () => {
  if (!io) {
    console.warn("⚠️ Socket.IO not initialized yet");
  }
  return io;
};

export const emitEvent = (event, data) => {
  if (io) {
    console.log(`📢 Broadcasting event: ${event}`);
    console.log(`   Data:`, JSON.stringify(data).substring(0, 200));
    io.emit(event, data); // Broadcast to ALL connected clients
    console.log(`✅ Event broadcasted successfully`);
  } else {
    console.warn(`⚠️ Cannot emit event "${event}" - Socket.IO not initialized`);
  }
};
