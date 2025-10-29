# BRANCH FEATURE - IMPLEMENTATION GUIDE

## Daftar Isi
1. [Overview](#overview)
2. [Fitur-Fitur](#fitur-fitur)
3. [Arsitektur](#arsitektur)
4. [Struktur File](#struktur-file)
5. [Penggunaan](#penggunaan)
6. [API Endpoints](#api-endpoints)
7. [State Management](#state-management)
8. [Integrasi dengan App](#integrasi-dengan-app)

## Overview

Fitur Branch adalah modul manajemen cabang yang memungkinkan pengelolaan multi-cabang untuk sistem POS. Fitur ini mendukung:
- **Operasi CRUD**: Tambah, ubah, hapus cabang
- **Search & Filter**: Cari cabang berdasarkan nama atau kode
- **Manajemen Status**: Aktif/Tidak Aktif
- **Tipe Cabang**: Kantor Pusat (HQ) vs Cabang
- **Real-time Sync**: Sinkronisasi dengan backend via Socket.IO

---

## Fitur-Fitur

### 1. ✅ List Cabang (BranchListPage)
- Tampilkan semua cabang dalam list
- Search/filter cabang
- Indikasi status (aktif/tidak aktif)
- Indikasi tipe cabang (HQ/Branch)
- Action menu: Edit, Hapus, Lihat Detail

### 2. ✅ Tambah/Edit Cabang (BranchFormPage)
- Form dengan validasi lengkap
- Field: Kode, Nama, Tipe, Alamat, Telepon, Email
- Toggle status aktif/tidak aktif
- Simpan ke backend via API

### 3. ✅ Detail Cabang (BranchDetailPage)
- Modal dialog menampilkan detail lengkap
- Informasi: nama, kode, alamat, telepon, email
- Timestamps: dibuat dan diperbarui
- Read-only view

### 4. ✅ Search Cabang
- Search real-time
- Query API untuk hasil yang akurat
- Clear/reset pencarian

### 5. ✅ Delete Cabang
- Konfirmasi sebelum hapus
- Delete via API
- Refresh list setelah delete

---

## Arsitektur

```
features/branch/
├── data/
│   ├── datasources/
│   │   └── branch_remote_data_source.dart       # API calls
│   ├── repositories/
│   │   └── branch_repository_impl.dart          # Data repository impl
│   └── data.dart                                # Export file
├── domain/
│   ├── entities/
│   │   └── branch.dart                          # Data model
│   ├── repositories/
│   │   └── branch_repository.dart               # Repository interface
│   ├── usecases/
│   │   └── branch_usecases.dart                 # Business logic
│   └── domain.dart                              # Export file
└── presentation/
    ├── bloc/
    │   └── branch_bloc.dart                     # BLoC logic
    ├── pages/
    │   ├── branch_list_page.dart                # List screen
    │   ├── branch_form_page.dart                # Form screen
    │   └── branch_detail_page.dart              # Detail dialog
    ├── widgets/
    │   ├── branch_list_item.dart                # List item widget
    │   └── branch_search_widget.dart            # Search widget
    └── presentation.dart                        # Export file
```

### Clean Architecture
- **Domain Layer**: Entities, Repositories (abstract), Use Cases
- **Data Layer**: Data Sources, Repository Implementation
- **Presentation Layer**: BLoC, Pages, Widgets

---

## Struktur File

### 1. **branch.dart** (Entity)
```dart
class Branch extends Equatable {
  final String id;
  final String code;          // Kode unik cabang
  final String name;          // Nama cabang
  final String address;       // Alamat
  final String phone;         // Nomor telepon
  final String? email;        // Email (optional)
  final String type;          // 'HQ' atau 'BRANCH'
  final bool isActive;        // Status aktif
  final String? parentBranchId; // ID cabang induk (untuk branch dari HQ)
  final String? apiKey;       // API key untuk branch
  final Map<String, dynamic>? settings; // Pengaturan branch
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Helper getters
  bool get isHQ => type == 'HQ';
  bool get isBranch => type == 'BRANCH';
}
```

### 2. **branch_repository.dart** (Interface)
```dart
abstract class BranchRepository {
  Future<Either<Failure, List<Branch>>> getAllBranches();
  Future<Either<Failure, Branch>> getBranchById(String id);
  Future<Either<Failure, Branch>> createBranch(Branch branch);
  Future<Either<Failure, Branch>> updateBranch(Branch branch);
  Future<Either<Failure, void>> deleteBranch(String id);
  Future<Either<Failure, List<Branch>>> searchBranches(String query);
  Future<Either<Failure, Branch>> getCurrentBranch();
}
```

### 3. **branch_usecases.dart** (Business Logic)
Tersedia 7 use cases:
- `GetAllBranches`: Ambil semua cabang
- `GetBranchById`: Ambil detail cabang
- `CreateBranch`: Buat cabang baru
- `UpdateBranch`: Update cabang
- `DeleteBranch`: Hapus cabang
- `SearchBranches`: Cari cabang
- `GetCurrentBranch`: Ambil cabang aktif saat ini

### 4. **branch_bloc.dart** (State Management)

**Events:**
- `LoadBranches`: Load semua cabang
- `LoadBranchById`: Load detail cabang
- `CreateBranchEvent`: Buat cabang
- `UpdateBranchEvent`: Update cabang
- `DeleteBranchEvent`: Hapus cabang
- `SearchBranchesEvent`: Cari cabang
- `LoadCurrentBranch`: Load cabang aktif

**States:**
- `BranchInitial`: Initial state
- `BranchLoading`: Sedang loading
- `BranchesLoaded`: List cabang loaded
- `BranchLoaded`: Detail cabang loaded
- `BranchCreated`: Cabang berhasil dibuat
- `BranchUpdated`: Cabang berhasil diupdate
- `BranchDeleted`: Cabang berhasil dihapus
- `CurrentBranchLoaded`: Cabang aktif loaded
- `BranchError`: Terjadi error

### 5. **BranchListPage** (Presentation)
- Menampilkan list cabang dengan search
- FloatingActionButton untuk tambah cabang
- Menu untuk edit/delete/lihat detail
- Error handling dan empty state

### 6. **BranchFormPage** (Presentation)
- Form untuk tambah/edit cabang
- Validasi input (required fields)
- Dropdown untuk tipe cabang
- Checkbox untuk status aktif
- Submit ke BLoC untuk save

### 7. **BranchDetailPage** (Presentation)
- Dialog menampilkan detail cabang
- Informasi lengkap (alamat, telepon, email, dll)
- Read-only display
- Close button untuk menutup dialog

---

## Penggunaan

### Import
```dart
// Menggunakan export file
import 'package:pos_management/features/branch/presentation/presentation.dart';

// Atau direct import
import 'package:pos_management/features/branch/presentation/pages/branch_list_page.dart';
import 'package:pos_management/features/branch/presentation/bloc/branch_bloc.dart';
```

### Navigasi ke Branch List
```dart
// Di routing atau navigation
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const BranchListPage(),
  ),
);

// Atau dengan named route
Navigator.pushNamed(context, '/branches');
```

### BLoC Usage
```dart
// Load semua cabang
BlocProvider.of<BranchBloc>(context).add(LoadBranches());

// Search cabang
BlocProvider.of<BranchBloc>(context).add(
  SearchBranchesEvent('Jakarta'),
);

// Buat cabang baru
BlocProvider.of<BranchBloc>(context).add(
  CreateBranchEvent(newBranch),
);

// Update cabang
BlocProvider.of<BranchBloc>(context).add(
  UpdateBranchEvent(updatedBranch),
);

// Hapus cabang
BlocProvider.of<BranchBloc>(context).add(
  DeleteBranchEvent(branchId),
);
```

### Mendengarkan State Changes
```dart
BlocListener<BranchBloc, BranchState>(
  listener: (context, state) {
    if (state is BranchCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cabang berhasil ditambahkan')),
      );
    } else if (state is BranchError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  },
  child: // widget
)
```

### BLoC Builder untuk UI
```dart
BlocBuilder<BranchBloc, BranchState>(
  builder: (context, state) {
    if (state is BranchLoading) {
      return const CircularProgressIndicator();
    }
    
    if (state is BranchError) {
      return Text('Error: ${state.message}');
    }
    
    if (state is BranchesLoaded) {
      return ListView.builder(
        itemCount: state.branches.length,
        itemBuilder: (context, index) {
          final branch = state.branches[index];
          return ListTile(title: Text(branch.name));
        },
      );
    }
    
    return const SizedBox.shrink();
  },
)
```

---

## API Endpoints

Semua endpoint melalui Backend V2 (Node.js + PostgreSQL + Socket.IO):

```
Base URL: http://localhost:3001/api/v2
WebSocket: ws://localhost:3001
```

### Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| `GET` | `/branches` | Ambil semua cabang |
| `GET` | `/branches/:id` | Ambil detail cabang |
| `GET` | `/branches/current` | Ambil cabang aktif saat ini |
| `GET` | `/branches/search?q=query` | Search cabang |
| `POST` | `/branches` | Buat cabang baru |
| `PUT` | `/branches/:id` | Update cabang |
| `DELETE` | `/branches/:id` | Hapus cabang |

### Request/Response Examples

#### Create Branch
```json
POST /branches
Content-Type: application/json

{
  "code": "BR001",
  "name": "Cabang Jakarta Pusat",
  "address": "Jl. Sudirman No. 1, Jakarta Pusat",
  "phone": "021-1234567",
  "email": "jakarta@company.com",
  "type": "BRANCH",
  "is_active": true
}

Response (201):
{
  "data": {
    "id": "uuid-1234",
    "code": "BR001",
    "name": "Cabang Jakarta Pusat",
    ...
    "created_at": "2025-01-10T10:00:00Z",
    "updated_at": "2025-01-10T10:00:00Z"
  }
}
```

---

## State Management

### BLoC Pattern
Branch menggunakan **BLoC (Business Logic Component)** untuk state management:

1. **Events**: User actions (LoadBranches, CreateBranch, dll)
2. **BLoC**: Menangani events dan emit states
3. **States**: UI states (Loading, Loaded, Error, dll)
4. **UI**: Listen ke states dan rebuild

### Flow Diagram
```
User Action
    ↓
Event (e.g., LoadBranches)
    ↓
BLoC (Process event, call use case)
    ↓
State (e.g., BranchesLoaded)
    ↓
UI (Rebuild with new state)
```

### Error Handling
```dart
// Domain layer
Either<Failure, List<Branch>> getAllBranches()

// Data layer - Handle exceptions
try {
  final branches = await remoteDataSource.getAllBranches();
  return Right(branches);
} on ServerException catch (e) {
  return Left(ServerFailure(message: e.message));
} on NetworkException catch (e) {
  return Left(NetworkFailure(message: e.message));
}

// Presentation layer - Show error
if (state is BranchError) {
  return Center(child: Text('Error: ${state.message}'));
}
```

---

## Integrasi dengan App

### 1. Tambah di Injection Container
Sudah ada di `lib/injection_container.dart`:
```dart
// ========== Features - Branch ==========
sl.registerFactory(() => BranchBloc(...));
sl.registerLazySingleton(() => GetAllBranches(sl()));
// ... use cases
sl.registerLazySingleton<BranchRepository>(...);
sl.registerLazySingleton<BranchRemoteDataSource>(...);
```

### 2. Tambah BLocProvider di Main App
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => sl<BranchBloc>()),
    // ... other blocs
  ],
  child: MyApp(),
)
```

### 3. Tambah Route
```dart
routes: {
  '/branches': (context) => const BranchListPage(),
  // ... other routes
}
```

### 4. Tambah Menu/Navigation
```dart
// Di Dashboard atau Navigation menu
ListTile(
  leading: const Icon(Icons.store),
  title: const Text('Kelola Cabang'),
  onTap: () => Navigator.pushNamed(context, '/branches'),
),
```

---

## Socket.IO Real-time Events

Branch mendukung real-time updates via Socket.IO:

```dart
// Socket events (dari backend)
static const String branchUpdate = 'branch:update';
static const String branchCreate = 'branch:create';
static const String branchDelete = 'branch:delete';

// Mendengarkan di Socket Service
socketService.on(ApiConstants.branchUpdate, (data) {
  // Handle update
});
```

---

## Testing

### Unit Test Example
```dart
test('getBranches returns list of branches', () async {
  // Arrange
  final branches = [mockBranch1, mockBranch2];
  when(mockRepository.getAllBranches())
      .thenAnswer((_) async => Right(branches));

  // Act
  final result = await usecase.call();

  // Assert
  expect(result, Right(branches));
});
```

### Widget Test Example
```dart
testWidgets('BranchListPage shows branches', (tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (context) => mockBranchBloc,
      child: MaterialApp(home: const BranchListPage()),
    ),
  );

  expect(find.byType(ListView), findsOneWidget);
});
```

---

## Troubleshooting

### Error: Branch tidak tampil
- Check internet connection
- Verify API backend running at `http://localhost:3001`
- Check BLoC initialization di GetIt

### Error: Form submit gagal
- Validate semua field required
- Check API endpoint di ApiConstants
- Check authentication token valid

### Error: Real-time update tidak bekerja
- Check Socket.IO service initialized
- Verify socket URL di ApiConstants
- Check backend socket emitting events

---

## Next Steps (Future Enhancements)

1. **Branch Reports**: Laporan per cabang (sales, inventory, dll)
2. **Branch Transfer**: Transfer inventory antar cabang
3. **Branch Settings**: Pengaturan spesifik per cabang
4. **Bulk Operations**: Tambah/edit/hapus multiple branches
5. **Export/Import**: Export cabang ke CSV, import dari file
6. **Audit Log**: Tracking perubahan branch
7. **Multi-language**: Support multiple languages
8. **Offline Support**: Cache branches locally (POS App)

---

## Referensi

- **BLoC Pattern**: https://bloclibrary.dev/
- **Clean Architecture**: https://resocoder.com/clean-architecture-tdd/
- **Dartz (Either/Right)**: https://pub.dev/packages/dartz
- **Backend API**: `/backend_v2/IMPLEMENTATION_GUIDE.md`

---

**Last Updated**: October 29, 2025
**Status**: ✅ Complete
**Version**: 1.0.0
