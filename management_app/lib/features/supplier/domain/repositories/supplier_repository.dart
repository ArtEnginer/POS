import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getSuppliers({
    String? searchQuery,
    bool? isActive,
  });

  Future<Either<Failure, Supplier>> getSupplierById(String id);

  Future<Either<Failure, void>> createSupplier(Supplier supplier);

  Future<Either<Failure, void>> updateSupplier(Supplier supplier);

  Future<Either<Failure, void>> deleteSupplier(String id);
}
