import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliers {
  final SupplierRepository repository;

  GetSuppliers(this.repository);

  Future<Either<Failure, List<Supplier>>> call({
    String? searchQuery,
    bool? isActive,
  }) async {
    return await repository.getSuppliers(
      searchQuery: searchQuery,
      isActive: isActive,
    );
  }
}
