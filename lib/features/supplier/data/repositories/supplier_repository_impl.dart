import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/utils/online_only_guard.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_local_data_source.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource localDataSource;
  final SyncManager syncManager;
  final HybridSyncManager hybridSyncManager;

  SupplierRepositoryImpl({
    required this.localDataSource,
    required this.syncManager,
    required this.hybridSyncManager,
  });

  @override
  Future<Either<Failure, List<Supplier>>> getSuppliers({
    String? searchQuery,
    bool? isActive,
  }) async {
    try {
      final suppliers = await localDataSource.getSuppliers(
        searchQuery: searchQuery,
        isActive: isActive,
      );
      return Right(suppliers);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    try {
      final supplier = await localDataSource.getSupplierById(id);
      return Right(supplier);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createSupplier(Supplier supplier) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen supplier harus online
      final guard = OnlineOnlyGuard(syncManager: hybridSyncManager);
      await guard.requireOnline('Manajemen Supplier');

      final supplierModel = SupplierModel.fromEntity(supplier);
      await localDataSource.insertSupplier(supplierModel);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'suppliers',
        recordId: supplier.id,
        operation: 'INSERT',
        data: supplierModel.toJson(),
      );

      return const Right(null);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSupplier(Supplier supplier) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen supplier harus online
      final guard = OnlineOnlyGuard(syncManager: hybridSyncManager);
      await guard.requireOnline('Manajemen Supplier');

      final supplierModel = SupplierModel.fromEntity(supplier);
      await localDataSource.updateSupplier(supplierModel);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'suppliers',
        recordId: supplier.id,
        operation: 'UPDATE',
        data: supplierModel.toJson(),
      );

      return const Right(null);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen supplier harus online
      final guard = OnlineOnlyGuard(syncManager: hybridSyncManager);
      await guard.requireOnline('Manajemen Supplier');

      await localDataSource.deleteSupplier(id);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'suppliers',
        recordId: id,
        operation: 'DELETE',
        data: {'id': id},
      );

      return const Right(null);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
