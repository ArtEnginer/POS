# 🧹 FLUTTER APP CLEANUP - Backend V2 Migration

## 📋 Status: Migrasi dari MySQL ke Backend V2 (Node.js + PostgreSQL + Socket.IO)

---

## ❌ FILES TO DELETE (MySQL Legacy)

### 1. **MySQL Backend (Entire Folder)**
```
mysql_backend/
├── config/
├── controllers/
├── database/
├── middleware/
├── routes/
├── server.js
├── package.json
├── README.md
└── setup_database.js
```
**Action**: DELETE entire `mysql_backend/` folder

### 2. **Flutter MySQL Connectors**
```
lib/core/database/
├── mysql_connector.dart          ❌ DELETE
├── mysql_config_manager.dart     ❌ DELETE
├── hybrid_sync_manager.dart      ❌ DELETE
├── sync_status_migration.dart    ❌ DELETE
└── database_reset_page.dart      ❌ DELETE (if exists)
```

### 3. **Legacy Sync Manager**
```
lib/core/sync/
└── sync_manager.dart              ❌ DELETE
```

### 4. **SQLite Local Database** (KEEP for offline caching)
```
lib/core/database/
└── database_helper.dart           ✅ KEEP (for offline SQLite cache)
```

---

## 🔧 FILES TO UPDATE

### 1. **main.dart** ✅ DONE
- Removed MySQL initialization
- Removed sqflite FFI initialization
- Simplified to Backend V2 only

### 2. **injection_container.dart** 🔄 IN PROGRESS
- Remove all MySQL service registrations
- Remove syncManager and hybridSyncManager
- Keep only: ApiClient, AuthService, SocketService
- Update all repository constructors

### 3. **All Repository Implementations** 🔄 PENDING
Need to remove `syncManager` and `hybridSyncManager` parameters:

```dart
// ❌ OLD (MySQL Hybrid Sync)
ProductRepositoryImpl({
  required this.localDataSource,
  required this.syncManager,
  required this.hybridSyncManager,
})

// ✅ NEW (Backend V2 Only)
ProductRepositoryImpl({
  required this.localDataSource,
})
```

Files to update:
- `lib/features/product/data/repositories/product_repository_impl.dart`
- `lib/features/purchase/data/repositories/purchase_repository_impl.dart`
- `lib/features/supplier/data/repositories/supplier_repository_impl.dart`
- `lib/features/purchase/data/repositories/receiving_repository_impl.dart`
- `lib/features/purchase/data/repositories/purchase_return_repository_impl.dart`
- `lib/features/sales/data/repositories/sale_repository_impl.dart`
- `lib/features/customer/data/repositories/customer_repository_impl.dart`

### 4. **All Local Data Sources** 🔄 PENDING
Remove `hybridSyncManager` parameter:

```dart
// ❌ OLD
ProductLocalDataSourceImpl({
  required this.databaseHelper,
  required this.hybridSyncManager,
})

// ✅ NEW
ProductLocalDataSourceImpl({
  required this.databaseHelper,
})
```

Files to update:
- `lib/features/product/data/datasources/product_local_data_source.dart`
- `lib/features/purchase/data/datasources/purchase_local_data_source.dart`
- `lib/features/supplier/data/datasources/supplier_local_data_source.dart`
- `lib/features/purchase/data/datasources/receiving_local_data_source.dart`
- `lib/features/purchase/data/datasources/purchase_return_local_data_source.dart`
- `lib/features/sales/data/datasources/sale_local_data_source.dart`
- `lib/features/customer/data/datasources/customer_local_data_source.dart`

---

## 🏗️ NEW ARCHITECTURE

### Backend V2 Components (Already Implemented ✅)
1. **API Client** - REST API dengan JWT authentication
2. **Socket Service** - Real-time sync via Socket.IO
3. **Auth Service** - JWT token management dengan auto-refresh
4. **Branch Service** - Multi-branch/tenant support

### Data Flow
```
Flutter App (UI)
    ↓
BLoC (State Management)
    ↓
Use Cases (Business Logic)
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
┌─────────────────┬──────────────────┐
│  Local Cache    │  Remote API      │
│  (SQLite)       │  (Backend V2)    │
│  - Offline      │  - PostgreSQL    │
│  - Fast read    │  - Real source   │
└─────────────────┴──────────────────┘
```

### Sync Strategy (NEW)
- **Real-time**: Socket.IO push notifications
- **On-demand**: Direct API calls when online
- **Offline cache**: SQLite for read-only when offline
- **NO hybrid sync**: Backend V2 is single source of truth

---

## 📦 DEPENDENCIES TO REMOVE

Update `pubspec.yaml`:

```yaml
dependencies:
  # ❌ REMOVE (MySQL related)
  # mysql1: ^0.20.0
  # mysql_client: ^0.0.27
  
  # ✅ KEEP (Backend V2)
  dio: ^5.7.0                    # REST API
  socket_io_client: ^2.0.3+1     # Real-time sync
  jwt_decoder: ^2.0.1            # JWT parsing
  shared_preferences: ^2.3.3     # Token storage
  
  # ✅ KEEP (Offline cache)
  sqflite: ^2.3.3+2              # Local SQLite
  path: ^1.9.0
```

---

## ✅ COMPLETED TASKS

1. ✅ Backend V2 setup (Node.js + PostgreSQL + Redis + Socket.IO)
2. ✅ Auth system with JWT
3. ✅ Branch management feature
4. ✅ Socket.IO real-time integration
5. ✅ Dashboard widgets (BranchSwitcher, ConnectionStatus, Notifications)
6. ✅ Product & Sales entities updated with branchId
7. ✅ Login page with branch selection
8. ✅ main.dart cleaned up
9. ✅ AuthService fixed for Backend V2 response structure

---

## 🔄 TODO - CLEANUP STEPS

### Step 1: Delete MySQL Files
```bash
# Delete entire MySQL backend folder
rm -rf mysql_backend/

# Delete MySQL Flutter files
rm lib/core/database/mysql_connector.dart
rm lib/core/database/mysql_config_manager.dart
rm lib/core/database/hybrid_sync_manager.dart
rm lib/core/database/sync_status_migration.dart
rm lib/core/sync/sync_manager.dart
```

### Step 2: Update Repository Implementations
For each file, remove syncManager and hybridSyncManager:
1. Remove from constructor parameters
2. Remove from class fields
3. Remove all method calls to syncManager/hybridSyncManager
4. Keep only localDataSource operations

### Step 3: Update Local Data Sources
For each file:
1. Remove hybridSyncManager from constructor
2. Remove from class fields
3. Remove all sync operations
4. Keep only SQLite operations for offline cache

### Step 4: Clean injection_container.dart
1. Remove all syncManager registrations
2. Remove all hybridSyncManager references
3. Update all repository registrations
4. Update all data source registrations

### Step 5: Test & Verify
```bash
flutter clean
flutter pub get
flutter run -d windows
```

---

## 📚 DOCUMENTATION FILES

Keep and update:
- `FLUTTER_V2_MIGRATION_STATUS.md` - Overall migration status
- `MULTI_BRANCH_COMPLETE.md` - Multi-branch implementation guide
- `FLUTTER_SECURITY_UPDATE.md` - Security changes documentation
- `backend_v2/API.md` - Backend API documentation
- `backend_v2/ARCHITECTURE.md` - Backend architecture
- `backend_v2/DEPLOYMENT.md` - Deployment guide

Delete:
- Any MySQL-related documentation in `mysql_backend/`

---

## 🎯 FINAL ARCHITECTURE

```
POS System v2.0
│
├── Frontend (Flutter)
│   ├── UI Layer (Pages/Widgets)
│   ├── State Management (BLoC)
│   ├── Domain Layer (Entities/Use Cases)
│   ├── Data Layer (Repositories)
│   └── Services
│       ├── AuthService (JWT)
│       ├── ApiClient (REST)
│       ├── SocketService (Real-time)
│       └── DatabaseHelper (SQLite cache)
│
└── Backend v2 (Node.js)
    ├── Express REST API
    ├── PostgreSQL Database
    ├── Redis Cache
    ├── Socket.IO Server
    ├── JWT Authentication
    └── Multi-tenant/Branch Support
```

---

**Last Updated**: 2024-10-24
**Status**: 🔄 Cleanup In Progress
**Backend**: ✅ Fully Operational
**Flutter**: 🔄 Removing MySQL Legacy Code
