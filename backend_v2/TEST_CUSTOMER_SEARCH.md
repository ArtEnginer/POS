# Test Customer Search Endpoint

## 📋 Endpoint Information
- **URL**: `GET /api/v2/customers/search`
- **Query Parameter**: `q` (customer code, name, phone, or email)
- **Authentication**: Required (Bearer Token)

## 🧪 Testing Steps

### Step 1: Start the Server
```bash
cd backend_v2
npm run dev
```

### Step 2: Login to Get Token
```bash
curl -X POST http://localhost:3001/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "user": {...},
  "branch": {...},
  "tokens": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

Copy the `accessToken` value.

### Step 3: Test Customer Search

#### Test 1: Search by Exact Code
```bash
curl -X GET "http://localhost:3001/api/v2/customers/search?q=CUST-001" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "CUST-001",
      "name": "Budi Santoso",
      "email": "budi@example.com",
      "phone": "081234560001",
      ...
    }
  ]
}
```

#### Test 2: Search by Partial Name
```bash
curl -X GET "http://localhost:3001/api/v2/customers/search?q=Budi" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Test 3: Search by Phone
```bash
curl -X GET "http://localhost:3001/api/v2/customers/search?q=081234560001" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 🐛 Common Issues & Solutions

### Issue 1: 404 Not Found
**Possible Causes:**
1. Server not running
2. Route not registered
3. Wrong URL or base path

**Solution:**
- Check server is running: `http://localhost:3001/api/v2/health`
- Verify route in logs when server starts
- Check `src/routes/index.js` has `router.use("/customers", customerRoutes);`

### Issue 2: 401 Unauthorized
**Cause:** Missing or invalid token

**Solution:**
- Login again to get fresh token
- Make sure `Authorization: Bearer TOKEN` header is included
- Check token hasn't expired

### Issue 3: Empty Results
**Cause:** Customer doesn't exist or database not seeded

**Solution:**
```bash
# Run database setup/seed
npm run db:setup
```

## 📊 Check Database Directly

### Connect to PostgreSQL
```bash
psql -U postgres -d pos_enterprise_db
```

### Query Customers
```sql
-- List all customers
SELECT * FROM customers WHERE deleted_at IS NULL;

-- Search by code
SELECT * FROM customers WHERE code = 'CUST-001' AND deleted_at IS NULL;

-- Count customers
SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL;
```

## 🔍 Debug Logs

When you call the search endpoint, you should see logs like:
```
🔍 Search customers called with query: "CUST-001"
🔍 Trying exact match for: "CUST-001"
✅ Customer exact match found: CUST-001 - 1 results
```

If you don't see these logs, the endpoint is not being called.

## 📱 Frontend Testing (Flutter)

Make sure:
1. Server is running on `http://localhost:3001`
2. App is connected (check Online/Offline indicator)
3. Token is valid (user is logged in)

Check Flutter console for detailed error messages.

## ✅ Verification Checklist

- [ ] Server running on port 3001
- [ ] Database seeded with customer data
- [ ] Can login and get access token
- [ ] Can call `/api/v2/customers/search?q=CUST-001` with token
- [ ] Getting 200 response with customer data
- [ ] Flutter app shows Online status
- [ ] Flutter app can find customer by code
