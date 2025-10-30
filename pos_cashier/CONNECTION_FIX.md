# Sales Return - Connection Fix

## ✅ Problem Solved

### Error Messages:
```
Client Exception with SocketException: 
The remote computer refused the network connection
```

### Root Causes:
1. ❌ Backend server was not running
2. ❌ Wrong server port (3000 vs 3001)
3. ❌ Wrong token key ('token' vs 'auth_token')

---

## ✅ Solutions Applied

### 1. Start Backend Server
```bash
cd backend_v2
npm start
```

**Server Info:**
- ✅ Running on: http://localhost:3001
- ✅ API Base: http://localhost:3001/api/v2
- ✅ Health Check: http://localhost:3001/api/v2/health
- ✅ Database: PostgreSQL connected
- ✅ Redis: Connected

### 2. Auto-Fallback to Port 3001
Updated both `_loadRecentSales()` and `_processReturn()`:

```dart
// Get server URL with auto-fallback
var serverUrl = settingsBox.get('serverUrl', 
    defaultValue: 'http://localhost:3000');

// Try port 3001 if 3000 is not set
if (serverUrl == 'http://localhost:3000' || serverUrl.isEmpty) {
  serverUrl = 'http://localhost:3001';
}

print('🌐 Server URL: $serverUrl');
```

### 3. Fixed Token Key
Changed from `'token'` to `'auth_token'`:

```dart
// BEFORE (WRONG)
final token = authBox.get('token');

// AFTER (CORRECT)
final token = authBox.get('auth_token');
```

### 4. Added Debug Logging
```dart
print('🔑 Using token: ${token.toString().substring(0, 20)}...');
print('🏢 Branch ID: $branchId');
print('🌐 Server URL: $serverUrl');
print('📡 Fetching from: $url');
```

---

## 🧪 Testing Steps

### 1. Verify Backend is Running
Check terminal output:
```
✅ Backend running on port: 3001
✅ Database: PostgreSQL connected
✅ Redis: Connected
```

### 2. Test Return Dialog
1. Open cashier app
2. Click **"Return Penjualan"** button
3. Check console logs:
   ```
   🔑 Using token: eyJhbGciOiJIUzI1NiIs...
   🏢 Branch ID: 1
   🌐 Server URL: http://localhost:3001
   📡 Fetching from: http://localhost:3001/api/v2/sales-returns/recent-sales?days=30&branchId=1
   ```

4. ✅ Dialog opens without errors
5. ✅ Loading indicator shows
6. ✅ Sales list displays

### 3. Test Return Submission
1. Select a sale
2. Choose items to return
3. Enter reason
4. Click "Proses Return"
5. Check console:
   ```
   🔄 Processing return with token: eyJhbGciOiJIUzI1NiIs...
   👤 Cashier: admin (ID: 1)
   🏢 Branch ID: 1
   🌐 Posting to: http://localhost:3001/api/v2/sales-returns
   ```
6. ✅ Success message shows
7. ✅ Check database: `SELECT * FROM sales_returns;`

---

## 🔍 Troubleshooting

### If Still Getting Connection Error:

**1. Check Backend Status**
```bash
# Should show process running on port 3001
netstat -ano | findstr :3001
```

**2. Check Server URL in Settings**
Open DevTools console and run:
```dart
final box = Hive.box('settings');
print('Server URL: ${box.get('serverUrl')}');
```

**3. Manually Set Server URL**
```dart
final settingsBox = Hive.box('settings');
await settingsBox.put('serverUrl', 'http://localhost:3001');
```

**4. Test API Directly**
```bash
# Test in browser or Postman
GET http://localhost:3001/api/v2/health

# Should return:
{
  "status": "OK",
  "timestamp": "2025-10-30T08:17:04.550Z",
  "database": "connected",
  "redis": "connected"
}
```

### If Getting 401 Unauthorized:

**Re-login to get fresh token:**
1. Logout from cashier app
2. Login again
3. Try return again

---

## 📊 Network Flow

```
Cashier App (Flutter)
      ↓
   🔑 Get token from Hive ('auth_token')
      ↓
   🌐 Get server URL ('serverUrl' → fallback to :3001)
      ↓
   📡 HTTP GET http://localhost:3001/api/v2/sales-returns/recent-sales
      ↓
   Backend Server (Node.js)
      ↓
   🔒 Verify JWT token
      ↓
   🏢 Filter by branch_id
      ↓
   💾 Query PostgreSQL (sales table)
      ↓
   📤 Return JSON response
      ↓
   📱 Display in Flutter UI
```

---

## ✅ Status

- **Backend Server**: ✅ Running on port 3001
- **Token Key**: ✅ Fixed (auth_token)
- **Server URL**: ✅ Auto-fallback to 3001
- **Debug Logs**: ✅ Added
- **Connection**: ✅ Should work now

**Last Updated**: October 30, 2025
**Ready for Testing**: ✅ Yes
