# Sales Return - ONLINE MODE

## Overview
Fitur Return Penjualan sekarang **HARUS ONLINE** dan mengambil data langsung dari server (tidak dari Hive lokal).

## Changes Made

### 1. Backend API ✅

**New Endpoint:**
```
GET /api/v2/sales-returns/recent-sales?days=30&branchId=1
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "123",
      "invoiceNumber": "INV-20251030-001",
      "branchId": 1,
      "customerId": null,
      "customerName": "Walk-in Customer",
      "cashierId": "1",
      "cashierName": "John Doe",
      "subtotal": 100000,
      "discount": 0,
      "tax": 0,
      "total": 100000,
      "paymentMethod": "cash",
      "paidAmount": 100000,
      "changeAmount": 0,
      "status": "completed",
      "notes": "",
      "items": [
        {
          "id": "456",
          "productId": 1,
          "productName": "Product A",
          "sku": "SKU-001",
          "quantity": 2,
          "unitPrice": 50000,
          "discount": 0,
          "tax": 0,
          "subtotal": 100000,
          "total": 100000
        }
      ],
      "createdAt": "2025-10-30T10:00:00Z",
      "isSynced": true,
      "syncedAt": "2025-10-30T10:00:00Z"
    }
  ],
  "count": 1
}
```

**Features:**
- ✅ Fetch completed sales from last N days (default 30)
- ✅ Filter by branch (automatic for cashier role)
- ✅ Include all sale items
- ✅ JWT authentication required
- ✅ Auto-filter by user's branch for cashier role

**Controller:** `backend_v2/src/controllers/salesReturnController.js`
```javascript
export const getRecentSalesForReturn = async (req, res) => {
  // Fetch sales from last 30 days
  // Filter by branch
  // Include all items
  // Return formatted data
}
```

**Routes:** `backend_v2/src/routes/salesReturns.js`
```javascript
router.get('/recent-sales', authenticateToken, salesReturnController.getRecentSalesForReturn);
```

### 2. Frontend Changes ✅

**File:** `pos_cashier/lib/features/cashier/presentation/widgets/sales_return_dialog.dart`

**Key Changes:**

1. **Import http package:**
   ```dart
   import 'package:http/http.dart' as http;
   import 'dart:convert';
   ```

2. **New State Variables:**
   ```dart
   bool _isLoadingSales = false;
   String? _errorMessage;
   ```

3. **Load from API instead of Hive:**
   ```dart
   Future<void> _loadRecentSales() async {
     // Get auth token
     final token = authBox.get('token');
     final branchId = branch?['id'];
     
     // Get server URL from settings
     final serverUrl = settingsBox.get('serverUrl');
     
     // Fetch from API
     final url = Uri.parse('$serverUrl/api/v2/sales-returns/recent-sales?days=30&branchId=$branchId');
     
     final response = await http.get(url, headers: {
       'Authorization': 'Bearer $token',
       'Content-Type': 'application/json',
     }).timeout(Duration(seconds: 10));
     
     // Parse and setState
   }
   ```

4. **Loading States:**
   - Loading indicator while fetching
   - Error message with retry button
   - Empty state if no sales

5. **Error Handling:**
   - Connection timeout (10 seconds)
   - 401 Unauthorized (session expired)
   - Server errors
   - Network errors

### 3. UI States

**Loading:**
```
┌─────────────────────────────┐
│  🔄 Loading...              │
│  Memuat data dari server... │
└─────────────────────────────┘
```

**Error:**
```
┌─────────────────────────────┐
│  ☁️❌ Gagal memuat data     │
│  Error: Connection timeout  │
│  [🔄 Coba Lagi]             │
└─────────────────────────────┘
```

**Empty:**
```
┌─────────────────────────────┐
│  📭 Tidak ada penjualan     │
│  dalam 30 hari terakhir     │
└─────────────────────────────┘
```

**Success:**
```
┌─────────────────────────────┐
│  ✅ INV-20251030-001        │
│  📅 30 Okt 2025 10:00       │
│  💰 Rp 100.000              │
└─────────────────────────────┘
```

## Requirements

### Must Have Internet Connection ✅
- Return feature now requires active internet
- Data fetched from server in real-time
- No offline mode for returns

### Server Must Be Running ✅
- Backend server must be accessible
- Port: 3000 or 3001 (configurable in settings)
- JWT token must be valid

## Testing

### 1. Start Backend Server
```bash
cd backend_v2
npm start
```

### 2. Run Cashier App
```bash
cd pos_cashier
flutter run -d windows
```

### 3. Test Flow
1. Login to cashier app
2. Click "Return Penjualan" button in header
3. Wait for sales to load from server (loading indicator)
4. Select a sale from the list
5. Choose items to return
6. Enter reason
7. Select refund method
8. Click "Proses Return"

### 4. Test Error Scenarios
- ❌ Server down → Should show error with retry
- ❌ No internet → Connection timeout
- ❌ Invalid token → Session expired message
- ❌ No sales → Empty state

## API Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v2/sales-returns/recent-sales` | GET | ✅ | Get recent sales for return |
| `/api/v2/sales-returns` | POST | ✅ | Create return |
| `/api/v2/sales-returns` | GET | ✅ | List all returns |
| `/api/v2/sales-returns/:id` | GET | ✅ | Get return detail |
| `/api/v2/sales-returns/:id/status` | PATCH | ✅ | Update return status |
| `/api/v2/sales-returns/sale/:saleId` | GET | ✅ | Get returns by sale |

## Security

- ✅ JWT authentication required
- ✅ Branch validation (cashier can only see their branch)
- ✅ User role-based filtering
- ✅ Token expiry handling
- ✅ Timeout protection (10s)

## Next Steps

1. ✅ Test return creation API
2. ⏳ Sync return to backend after local save
3. ⏳ Add return history view
4. ⏳ Print return receipt
5. ⏳ Return analytics

## Notes

- **NO OFFLINE MODE**: Returns must be processed online
- **Data Source**: Always from server, never from local Hive
- **Real-time**: Sales data is fetched fresh every time dialog opens
- **Branch Filter**: Automatic for cashier role
- **Date Range**: Default 30 days (configurable via query param)

---
**Last Updated:** October 30, 2025
**Status:** ✅ Implementation Complete - Ready for Testing
