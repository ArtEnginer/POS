# 🧪 TESTING GUIDE - POS Enterprise

## Test API Endpoints

### 1. Health Check
```powershell
curl http://localhost:3001/api/v2/health
```

Expected response:
```json
{
  "status": "OK",
  "timestamp": "2025-10-24T...",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

---

## 🔐 Authentication Tests

### 2. Login
```powershell
curl -X POST http://localhost:3001/api/v2/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"username\":\"admin\",\"password\":\"admin123\"}'
```

Expected response:
```json
{
  "success": true,
  "user": {
    "id": 1,
    "username": "admin",
    "fullName": "System Administrator",
    "role": "super_admin"
  },
  "tokens": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

Save the `accessToken` untuk request berikutnya!

### 3. Refresh Token
```powershell
$refreshToken = "YOUR_REFRESH_TOKEN"

curl -X POST http://localhost:3001/api/v2/auth/refresh `
  -H "Content-Type: application/json" `
  -d "{\"refreshToken\":\"$refreshToken\"}"
```

### 4. Logout
```powershell
$accessToken = "YOUR_ACCESS_TOKEN"
$refreshToken = "YOUR_REFRESH_TOKEN"

curl -X POST http://localhost:3001/api/v2/auth/logout `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d "{\"refreshToken\":\"$refreshToken\"}"
```

---

## 📦 Product Tests

### 5. Get All Products
```powershell
$accessToken = "YOUR_ACCESS_TOKEN"

curl -H "Authorization: Bearer $accessToken" `
  http://localhost:3001/api/v2/products
```

### 6. Search Products
```powershell
curl -H "Authorization: Bearer $accessToken" `
  "http://localhost:3001/api/v2/products/search?q=laptop&limit=10"
```

### 7. Create Product
```powershell
curl -X POST http://localhost:3001/api/v2/products `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d '{
    \"sku\": \"PROD001\",
    \"barcode\": \"1234567890123\",
    \"name\": \"Test Product\",
    \"description\": \"Test product description\",
    \"categoryId\": 1,
    \"unit\": \"PCS\",
    \"costPrice\": 10000,
    \"sellingPrice\": 15000,
    \"minStock\": 10,
    \"reorderPoint\": 20
  }'
```

### 8. Get Product by ID
```powershell
curl -H "Authorization: Bearer $accessToken" `
  http://localhost:3001/api/v2/products/1
```

### 9. Update Product
```powershell
curl -X PUT http://localhost:3001/api/v2/products/1 `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d '{
    \"sellingPrice\": 16000,
    \"minStock\": 15
  }'
```

### 10. Get Low Stock Products
```powershell
curl -H "Authorization: Bearer $accessToken" `
  "http://localhost:3001/api/v2/products/low-stock?branchId=1"
```

---

## 🛒 Sales Tests

### 11. Create Sale
```powershell
curl -X POST http://localhost:3001/api/v2/sales `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d '{
    \"saleNumber\": \"SALE-20251024-001\",
    \"branchId\": 1,
    \"customerId\": null,
    \"items\": [
      {
        \"productId\": 1,
        \"productName\": \"Test Product\",
        \"sku\": \"PROD001\",
        \"quantity\": 2,
        \"unitPrice\": 15000,
        \"subtotal\": 30000,
        \"total\": 30000
      }
    ],
    \"subtotal\": 30000,
    \"totalAmount\": 30000,
    \"paidAmount\": 30000,
    \"paymentMethod\": \"cash\"
  }'
```

### 12. Get Today's Sales
```powershell
curl -H "Authorization: Bearer $accessToken" `
  "http://localhost:3001/api/v2/sales/today?branchId=1"
```

### 13. Get Sales Summary
```powershell
curl -H "Authorization: Bearer $accessToken" `
  "http://localhost:3001/api/v2/sales/summary?branchId=1&startDate=2025-10-01&endDate=2025-10-31"
```

---

## 🏢 Branch Tests

### 14. Get All Branches
```powershell
curl -H "Authorization: Bearer $accessToken" `
  http://localhost:3001/api/v2/branches
```

### 15. Create Branch
```powershell
curl -X POST http://localhost:3001/api/v2/branches `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d '{
    \"code\": \"BR001\",
    \"name\": \"Branch 1\",
    \"address\": \"Jl. Example No. 123\",
    \"city\": \"Jakarta\",
    \"phone\": \"021-12345678\",
    \"email\": \"branch1@pos.com\"
  }'
```

---

## 🔄 Sync Tests

### 16. Push Sync Data
```powershell
curl -X POST http://localhost:3001/api/v2/sync/push `
  -H "Authorization: Bearer $accessToken" `
  -H "Content-Type: application/json" `
  -d '{
    \"entity\": \"product\",
    \"operation\": \"create\",
    \"data\": {
      \"id\": 1,
      \"name\": \"Test Product\"
    }
  }'
```

### 17. Pull Sync Data
```powershell
curl -H "Authorization: Bearer $accessToken" `
  "http://localhost:3001/api/v2/sync/pull?entity=product&lastSync=2025-10-24T00:00:00Z"
```

### 18. Get Sync Status
```powershell
curl -H "Authorization: Bearer $accessToken" `
  http://localhost:3001/api/v2/sync/status
```

---

## 🧪 Socket.IO Tests

### Test Socket Connection (Node.js)

Create file `test-socket.js`:

```javascript
import { io } from 'socket.io-client';

const socket = io('http://localhost:3001', {
  auth: {
    token: 'YOUR_ACCESS_TOKEN',
    branchId: 1,
    userId: 1
  }
});

socket.on('connect', () => {
  console.log('✓ Connected:', socket.id);
  
  // Test ping
  socket.emit('ping');
});

socket.on('pong', (data) => {
  console.log('✓ Pong received:', data);
});

socket.on('connected', (data) => {
  console.log('✓ Connection confirmed:', data);
});

socket.on('product:updated', (data) => {
  console.log('✓ Product updated:', data);
});

socket.on('stock:updated', (data) => {
  console.log('✓ Stock updated:', data);
});

socket.on('disconnect', () => {
  console.log('✗ Disconnected');
});

socket.on('error', (error) => {
  console.error('✗ Error:', error);
});

// Test emit after 2 seconds
setTimeout(() => {
  console.log('\n--- Testing emit events ---');
  
  socket.emit('product:update', {
    productId: 1,
    name: 'Updated Product'
  });
  
  socket.emit('stock:update', {
    productId: 1,
    quantity: 100
  });
}, 2000);

// Keep alive
process.on('SIGINT', () => {
  console.log('\nClosing socket...');
  socket.disconnect();
  process.exit(0);
});
```

Run:
```powershell
node test-socket.js
```

---

## 🗄️ Database Tests

### Query Database
```powershell
# Connect to PostgreSQL
psql -U pos_user -d pos_enterprise

# View tables
\dt

# Count records
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sales;
SELECT COUNT(*) FROM users;

# View recent sales
SELECT * FROM sales ORDER BY sale_date DESC LIMIT 10;

# View product stock
SELECT p.name, ps.quantity, ps.available_quantity, b.name as branch
FROM products p
JOIN product_stocks ps ON p.id = ps.product_id
JOIN branches b ON ps.branch_id = b.id;

# Exit
\q
```

---

## 📊 Performance Tests

### Using Apache Bench
```powershell
# Install Apache Bench (comes with Apache)
choco install apache-httpd

# Test health endpoint
ab -n 1000 -c 10 http://localhost:3001/api/v2/health

# Test products endpoint (with auth)
# Create file with auth header first
echo "Authorization: Bearer YOUR_TOKEN" > headers.txt
ab -n 1000 -c 10 -H @headers.txt http://localhost:3001/api/v2/products
```

### Using Artillery
```powershell
# Install Artillery
npm install -g artillery

# Create test file: load-test.yml
# Run load test
artillery run load-test.yml
```

Example `load-test.yml`:
```yaml
config:
  target: "http://localhost:3001"
  phases:
    - duration: 60
      arrivalRate: 10
  variables:
    accessToken: "YOUR_ACCESS_TOKEN"

scenarios:
  - name: "API Load Test"
    flow:
      - get:
          url: "/api/v2/health"
      - get:
          url: "/api/v2/products"
          headers:
            Authorization: "Bearer {{ accessToken }}"
```

---

## ✅ Test Checklist

- [ ] Health check responds OK
- [ ] Login successful
- [ ] Token refresh works
- [ ] Logout successful
- [ ] Can create product
- [ ] Can get products list
- [ ] Can search products
- [ ] Can update product
- [ ] Can get product stock
- [ ] Can create sale
- [ ] Can get sales list
- [ ] Can get today's sales
- [ ] Socket.IO connects
- [ ] Socket.IO receives events
- [ ] Database has data
- [ ] Redis caching works
- [ ] Performance acceptable (<100ms)

---

## 🐛 Common Issues & Solutions

### 1. Cannot connect to API
```powershell
# Check if server is running
pm2 status

# Check logs
pm2 logs

# Restart server
pm2 restart all
```

### 2. 401 Unauthorized
- Token expired → Login again
- Invalid token → Check Bearer token format
- No token → Add Authorization header

### 3. 500 Internal Server Error
```powershell
# Check server logs
pm2 logs pos-api --err

# Check database connection
psql -U pos_user -d pos_enterprise

# Check Redis
redis-cli ping
```

### 4. Slow Response
```powershell
# Check server load
pm2 monit

# Check database connections
# In psql:
SELECT count(*) FROM pg_stat_activity;

# Check Redis
redis-cli INFO stats
```

---

## 📝 Notes

- Ganti `YOUR_ACCESS_TOKEN` dengan token yang didapat dari login
- Ganti `YOUR_REFRESH_TOKEN` dengan refresh token
- API rate limit: 100 requests per 15 minutes
- Token expiry: 15 minutes (access token)
- Refresh token expiry: 7 days

---

**Happy Testing! 🧪**
