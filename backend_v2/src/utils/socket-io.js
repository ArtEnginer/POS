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
    io.emit(event, data);
  } else {
    console.warn(`⚠️ Cannot emit event "${event}" - Socket.IO not initialized`);
  }
};
