# 🔧 Troubleshooting: Real-Time Sync Not Working

## Problem

POS Cashier tidak auto-update saat product/category diubah di Management App.

---

## ✅ Solution: Fixed Circular Dependency

### Root Cause

**Circular dependency** antara `server.js` ↔ `productController.js`:

- `productController.js` import `io` dari `server.js`
- `server.js` import routes yang include `productController.js`
- Result: `io` is `undefined` saat controller di-load!

### Fix Applied

**1. Created Global IO Helper** (`utils/socket-io.js`):

```javascript
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
    console.warn(`⚠️ Cannot emit event "${event}"`);
  }
};
```

**2. Updated server.js**:

```javascript
import { setIO } from "./utils/socket-io.js";

// After initializing Socket.IO
initializeSocketIO(io);
setIO(io); // Set global instance
```

**3. Updated Controllers**:

```javascript
// OLD (Circular dependency ❌)
import { io } from "../server.js";
io.emit("product:created", {...});

// NEW (No circular dependency ✅)
import { emitEvent } from "../utils/socket-io.js";
emitEvent("product:created", {...});
```

---

## 🧪 Testing Steps

### Step 1: Start Backend

```bash
cd backend_v2
npm run dev
```

**Expected Output:**

```
✅ Socket.IO handlers initialized
✅ Socket.IO instance set globally  ← PENTING!
🚀 POS Enterprise API Server
Port: 3001
```

### Step 2: Start POS Cashier

```bash
cd pos_cashier
flutter run -d windows
```

**Expected Console Log:**

```
🔌 Connecting to Socket.IO: http://localhost:3001
✅ Socket connected - Server ONLINE
```

### Step 3: Test Real-Time Sync

**Option A: Via Management App**

```bash
cd management_app
flutter run -d windows

# Edit product via UI
# POS should auto-update!
```

**Option B: Via API (Postman/curl)**

```bash
# Update product via API
curl -X PUT http://localhost:3001/api/v2/products/123 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Coca Cola 500ml (Updated)",
    "sellingPrice": 9000
  }'
```

**POS Cashier Console (Should Show):**

```
📦 Real-time event: Product UPDATED
   Data: {action: 'updated', product: {...}}
✅ Product updated in local DB: Coca Cola 500ml (Updated)
```

---

## 🔍 Debugging Checklist

### ✅ Backend Check

**1. Socket.IO Initialized?**

```bash
# Backend console should show:
✅ Socket.IO instance set globally
```

**2. Event Emitted?**

```bash
# After updating product, backend should log:
📢 WebSocket event emitted: product:updated for 123
```

**3. Connected Clients?**

```javascript
// Add to server.js (optional debug):
setInterval(() => {
  console.log(`Connected clients: ${io.engine.clientsCount}`);
}, 10000);
```

### ✅ Frontend Check

**1. Socket Connected?**

```dart
// POS Cashier console should show:
✅ Socket connected - Server ONLINE
```

**2. Event Listener Registered?**

```dart
// Check if _setupDatabaseEventListeners() was called
print('Setting up database event listeners...');
```

**3. Event Received?**

```dart
// Should log when event arrives:
📦 Real-time event: Product UPDATED
```

---

## 🚨 Common Issues

### Issue 1: "Socket.IO not initialized yet"

**Symptom:**

```
⚠️ Cannot emit event "product:updated" - Socket.IO not initialized
```

**Solution:**

- Check `server.js` has `setIO(io)` AFTER `initializeSocketIO(io)`
- Make sure server started successfully

### Issue 2: Frontend tidak receive events

**Symptom:**

- Backend emit event ✅
- Frontend socket connected ✅
- No console log di frontend ❌

**Solution:**

```dart
// Check socket_service.dart
void _setupDatabaseEventListeners() {
  if (_socket == null) {
    print('❌ Socket is null!'); // Add this debug
    return;
  }

  _socket!.on('product:created', (data) async {
    print('📦 Event received!'); // Add this debug
    await _handleProductCreated(data);
  });
}
```

### Issue 3: Circular dependency error

**Symptom:**

```
Error: Cannot access 'io' before initialization
```

**Solution:**

- Make sure using `emitEvent()` from `utils/socket-io.js`
- NOT importing `io` directly from `server.js`

---

## 📊 Testing Matrix

| Test Case        | Backend Emits | Frontend Receives | Hive Updated | UI Refreshes |
| ---------------- | ------------- | ----------------- | ------------ | ------------ |
| Product Created  | ✅            | ✅                | ✅           | ✅           |
| Product Updated  | ✅            | ✅                | ✅           | ✅           |
| Product Deleted  | ✅            | ✅                | ✅           | ✅           |
| Category Created | ✅            | ✅                | ✅           | ✅           |
| Category Updated | ✅            | ✅                | ✅           | ✅           |
| Category Deleted | ✅            | ✅                | ✅           | ✅           |

---

## 🎯 Manual Testing Script

### Test Product Update

**1. Get Auth Token:**

```bash
curl -X POST http://localhost:3001/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

**2. Update Product:**

```bash
curl -X PUT http://localhost:3001/api/v2/products/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product UPDATED",
    "sellingPrice": 99999
  }'
```

**3. Watch POS Cashier Console:**

```
Expected Output:
📦 Real-time event: Product UPDATED
   Data: {...}
✅ Product updated in local DB: Test Product UPDATED
```

**4. Check Hive:**

```dart
// In POS Cashier Dev Tools
final product = productsBox.get('1');
print(product['name']); // Should be "Test Product UPDATED"
print(product['selling_price']); // Should be 99999.0
```

---

## 📝 Code Verification

### ✅ File: `backend_v2/src/utils/socket-io.js`

```javascript
// Should exist with setIO() and emitEvent()
export const setIO = (ioInstance) => { ... }
export const emitEvent = (event, data) => { ... }
```

### ✅ File: `backend_v2/src/server.js`

```javascript
import { setIO } from "./utils/socket-io.js";

// In startServer():
initializeSocketIO(io);
setIO(io); // ← Must exist!
```

### ✅ File: `backend_v2/src/controllers/productController.js`

```javascript
import { emitEvent } from "../utils/socket-io.js"; // ← Not from server.js!

// In createProduct():
emitEvent("product:created", {...}); // ← Using helper
```

### ✅ File: `pos_cashier/lib/core/socket/socket_service.dart`

```dart
void _setupDatabaseEventListeners() {
  _socket!.on('product:created', _handleProductCreated);
  _socket!.on('product:updated', _handleProductUpdated);
  _socket!.on('product:deleted', _handleProductDeleted);
}
```

---

## 🎓 Quick Debug Commands

### Backend Console

```javascript
// Check io instance
console.log("IO instance:", typeof getIO()); // Should be 'object'

// Test emit manually
emitEvent("test:event", { message: "Hello POS!" });
```

### Frontend Console

```dart
// Check socket status
print('Socket connected: ${socketService.isConnected}');

// Manual emit (for testing)
socketService._socket?.emit('ping');
```

### Network Debug

```bash
# Check WebSocket connection
# In browser dev tools or Wireshark:
# Should see: ws://localhost:3001/socket.io/?EIO=4&transport=websocket
```

---

## ✅ Success Indicators

When everything works correctly:

**Backend:**

```
✅ Socket.IO instance set globally
📢 WebSocket event emitted: product:updated for 123
Connected clients: 1
```

**Frontend:**

```
✅ Socket connected - Server ONLINE
📦 Real-time event: Product UPDATED
✅ Product updated in local DB: Coca Cola 500ml
```

**Result:**

- Product name updates instantly in POS UI
- No page reload needed
- Latency < 100ms

---

**Status**: 🔧 FIXED  
**Root Cause**: Circular dependency  
**Solution**: Global IO helper pattern  
**Last Updated**: October 30, 2025
