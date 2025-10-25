import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_local_data_source.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource localDataSource;

  SupplierRepositoryImpl({required this.localDataSource});

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
      // Guard removed
      // Guard removed

      final supplierModel = SupplierModel.fromEntity(supplier);
      await localDataSource.insertSupplier(supplierModel);

      // Add to sync queue
      // Temporarily disabled

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
      // Guard removed
      // Guard removed

      final supplierModel = SupplierModel.fromEntity(supplier);
      await localDataSource.updateSupplier(supplierModel);

      // Add to sync queue
      // Temporarily disabled

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
      // Guard removed
      // Guard removed

      await localDataSource.deleteSupplier(id);

      // Add to sync queue
      // Temporarily disabled

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
