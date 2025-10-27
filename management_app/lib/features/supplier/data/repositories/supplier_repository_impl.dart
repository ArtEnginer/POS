import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_remote_data_source.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;

  SupplierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Supplier>>> getSuppliers({
    String? searchQuery,
    bool? isActive,
  }) async {
    try {
      List<SupplierModel> suppliers;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        suppliers = await remoteDataSource.searchSuppliers(searchQuery);
      } else {
        suppliers = await remoteDataSource.getAllSuppliers();
      }

      // Filter by isActive if provided
      if (isActive != null) {
        suppliers = suppliers.where((s) => s.isActive == isActive).toList();
      }

      return Right(suppliers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    try {
      final supplier = await remoteDataSource.getSupplierById(id);
      return Right(supplier);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createSupplier(Supplier supplier) async {
    try {
      final supplierModel = SupplierModel.fromEntity(supplier);
      await remoteDataSource.createSupplier(supplierModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSupplier(Supplier supplier) async {
    try {
      final supplierModel = SupplierModel.fromEntity(supplier);
      await remoteDataSource.updateSupplier(supplierModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      await remoteDataSource.deleteSupplier(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
