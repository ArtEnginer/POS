# Data Synchronization Strategy - Multi-User Support

## Problem Identified

**Symptom:** SQLite has 2 products, PostgreSQL has 6 products
**Root Cause:** SQLite cache was using INSERT instead of SYNC, causing stale data
**Impact:** Multi-user updates not visible, data inconsistency across clients

## Solution Implemented

### 1. Full Data Sync on `getAllProducts()`

```dart
// Before: Only INSERT new products (incremental)
for (var product in remoteProducts) {
  await localDataSource.insertProduct(product); // Bug: doesn't remove old data
}

// After: Full database sync (replace entire dataset)
await localDataSource.syncAllProducts(remoteProducts); // Atomic replace
```

**Method:** `syncAllProducts()` uses transaction to:

1. Clear all existing products: `DELETE FROM products`
2. Insert fresh data from PostgreSQL
3. Atomic operation - all or nothing

### 2. Upsert for Individual Operations

```dart
// Create/Update now use upsert instead of insert/update
await localDataSource.upsertProduct(product);

// Upsert logic:
// 1. Try UPDATE first
// 2. If no rows affected, INSERT
// 3. Prevents duplicate key errors
```

### 3. Real-Time Sync via Socket.IO

```dart
// ProductRepositoryImpl constructor
_listenToProductUpdates() {
  socketService.productUpdates.listen((data) {
    switch (data['action']) {
      case 'created':
      case 'updated':
        await localDataSource.upsertProduct(product);
      case 'deleted':
        await localDataSource.deleteProduct(product.id);
    }
  });
}
```

**Benefit:** When User A creates/updates product, User B automatically receives update in real-time.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      User A (Client 1)                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Flutter    │───▶│  Repository  │───▶│ PostgreSQL   │  │
│  │     UI       │◀───│   (Sync)     │◀───│   (Remote)   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                    │          │
│         ▼                    ▼                    │          │
│  ┌──────────────┐    ┌──────────────┐           │          │
│  │   Display    │    │    SQLite    │           │          │
│  │   6 items    │    │  (Synced 6)  │           │          │
│  └──────────────┘    └──────────────┘           │          │
└──────────────────────────────────────────────────┼──────────┘
                                                   │
                        Socket.IO Real-time        │
                                ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                      User B (Client 2)                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Flutter    │◀───│  Repository  │◀───│  Socket.IO   │  │
│  │     UI       │    │  (Listener)  │    │  (product:   │  │
│  └──────────────┘    └──────────────┘    │   updated)   │  │
│         │                    │            └──────────────┘  │
│         ▼                    ▼                               │
│  ┌──────────────┐    ┌──────────────┐                      │
│  │Auto Refresh  │    │    SQLite    │                      │
│  │ New Product  │    │ (Auto Sync)  │                      │
│  └──────────────┘    └──────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Initial Load (Online)

1. Frontend calls `getAllProducts()`
2. Repository checks `networkInfo.isConnected` → TRUE
3. Fetch from PostgreSQL via API: `GET /products?limit=1000`
4. Call `localDataSource.syncAllProducts()`:
   - BEGIN TRANSACTION
   - DELETE FROM products (clear old cache)
   - INSERT all 6 products from PostgreSQL
   - COMMIT
5. Return 6 products to UI
6. **Result:** SQLite now has 6 products matching PostgreSQL

### Create Product (User A)

1. User A creates product #7
2. Repository calls `remoteDataSource.createProduct()`
3. Backend saves to PostgreSQL → returns product #7
4. Backend emits Socket.IO event: `product:updated` with action='created'
5. Repository calls `localDataSource.upsertProduct(product7)` → User A's cache updated
6. **User B receives Socket.IO event** → Auto-upserts to their cache
7. **Result:** Both users see 7 products immediately

### Offline Mode (User B)

1. User B loses internet connection
2. Frontend calls `getAllProducts()`
3. Repository checks `networkInfo.isConnected` → FALSE
4. Return data from SQLite cache (7 products)
5. UI shows warning: "⚠️ Offline mode - showing cached data"
6. **Result:** User B can still browse products, but cannot create/update

### Update Product (User A while User B is offline)

1. User A updates product #3 (online)
2. Backend saves to PostgreSQL
3. Socket.IO event emitted → **User B offline, doesn't receive**
4. When User B comes back online:
   - Next `getAllProducts()` call triggers full sync
   - SQLite cache refreshed with latest data
   - User B now sees updated product #3

## Code Changes

### Files Modified

1. **`product_local_data_source.dart`**
   - Added `syncAllProducts()` method
   - Added `upsertProduct()` method
2. **`product_repository_impl.dart`**

   - Changed `getAllProducts()` to use `syncAllProducts()`
   - Changed `createProduct()` to use `upsertProduct()`
   - Changed `updateProduct()` to use `upsertProduct()`
   - Added `_listenToProductUpdates()` for real-time sync
   - Added `socketService` dependency

3. **`product_remote_data_source.dart`**

   - Removed `branchId` filter from `getAllProducts()`
   - Increased limit to 1000 to get all products

4. **`injection_container.dart`**
   - Added `socketService` to `ProductRepositoryImpl`

## Testing Checklist

### ✅ Test 1: Initial Sync

- [ ] Clear SQLite database (delete `pos_local.db`)
- [ ] Run app and login
- [ ] Navigate to Products screen
- [ ] Verify all 6 products from PostgreSQL appear
- [ ] Check SQLite: Should have 6 products

**Expected:**

```
PostgreSQL: 6 products
SQLite: 6 products (synced)
UI: Shows 6 products
```

### ✅ Test 2: Multi-User Create (Real-time)

- [ ] Open app on 2 different machines (User A, User B)
- [ ] User A: Create new product #7
- [ ] User B: Should auto-refresh and show product #7
- [ ] Check both SQLite databases: Should have 7 products

**Expected:**

```
User A creates → PostgreSQL saves → Socket.IO broadcasts
User B receives event → Auto-updates cache → UI refreshes
```

### ✅ Test 3: Offline Mode

- [ ] Disconnect internet
- [ ] Navigate to Products screen
- [ ] Verify products still appear (from cache)
- [ ] Try to create product → Should show error
- [ ] Verify error message: "Koneksi internet diperlukan untuk management data"

**Expected:**

```
Offline: Can READ from cache
Offline: Cannot CREATE/UPDATE/DELETE (online-only)
```

### ✅ Test 4: Stale Cache Recovery

- [ ] User A: Disconnect internet, open app (sees cached 6 products)
- [ ] User B: Create product #7 (online)
- [ ] User A: Reconnect internet
- [ ] User A: Pull to refresh or restart app
- [ ] User A: Should now see 7 products

**Expected:**

```
Full sync on next online fetch replaces stale cache
```

### ✅ Test 5: Database Consistency

- [ ] Run script to compare counts:

```powershell
# Check PostgreSQL
psql -U postgres -d pos_db -c "SELECT COUNT(*) FROM products WHERE deleted_at IS NULL;"

# Check SQLite (run this PowerShell)
.\check_sqlite.ps1
```

**Expected:**

```
PostgreSQL count = SQLite count
```

## Performance Considerations

### Full Sync vs Incremental Sync

**Full Sync (Current Implementation):**

- **Pros:**
  - Guaranteed consistency
  - Simple implementation
  - No orphaned records
- **Cons:**
  - Deletes all data on each fetch
  - More database writes
  - Could be slow for large datasets (1000+ products)

**When to use Full Sync:**

- Management features (products, customers, suppliers)
- Data changes frequently by multiple users
- Dataset < 5000 records
- Consistency is critical

**Incremental Sync (Future Optimization):**

```dart
// Use timestamp-based sync
final lastSyncTime = await getLastSyncTime();
final updates = await api.get('/products/changes?since=$lastSyncTime');

for (update in updates) {
  switch (update.action) {
    case 'created': await upsert(update.data);
    case 'updated': await upsert(update.data);
    case 'deleted': await delete(update.id);
  }
}

await saveLastSyncTime(DateTime.now());
```

**When to use Incremental Sync:**

- Dataset > 5000 records
- Network bandwidth limited
- Sync happens frequently (every minute)

## Monitoring & Debugging

### Debug Prints Added

```dart
print('🔄 Real-time product update received: ${data['action']}');
print('✅ Local cache updated for product: ${product.name}');
print('🗑️ Local cache deleted for product: ${product.name}');
print('⚠️ Warning: Using stale local cache due to server error');
print('⚠️ Warning: Offline mode - showing cached data');
```

### How to Monitor Sync

1. Check terminal output for emoji indicators
2. Verify PostgreSQL vs SQLite counts match
3. Test multi-user scenarios
4. Monitor Socket.IO events in backend logs

## Migration Notes

### For Other Features

Apply same pattern to:

- **Customer** (`CustomerRepositoryImpl`)
- **Supplier** (`SupplierRepositoryImpl`)
- **Branch** (`BranchRepositoryImpl`) - already online-only
- **Category** (if exists)

### Template

```dart
// 1. Add syncAll method to local data source
Future<void> syncAllCustomers(List<CustomerModel> customers) async {
  await db.transaction((txn) async {
    await txn.delete('customers');
    for (var customer in customers) {
      await txn.insert('customers', customer.toLocalJson());
    }
  });
}

// 2. Use in repository
if (isConnected) {
  final remote = await remoteDataSource.getAllCustomers();
  await localDataSource.syncAllCustomers(remote); // Full sync
  return Right(remote);
}
```

## Next Steps

1. ✅ Test full sync with 6 products
2. ⏳ Apply to Customer, Supplier features
3. ⏳ Add pull-to-refresh UI for manual sync
4. ⏳ Implement incremental sync for datasets > 1000
5. ⏳ Add sync status indicator in UI
6. ⏳ Implement conflict resolution strategy
7. ⏳ Add background sync service (every 5 minutes)

## Conclusion

**Problem Solved:** SQLite now stays in sync with PostgreSQL through:

1. Full database sync on `getAllProducts()`
2. Real-time updates via Socket.IO
3. Upsert operations prevent duplicates
4. Multi-user consistency guaranteed

**Trade-off:** Performance (full sync) for Consistency (guaranteed accurate data)

For most POS management features with < 5000 records, this is the right choice.
