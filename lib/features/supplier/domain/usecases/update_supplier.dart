import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class UpdateSupplier {
  final SupplierRepository repository;

  UpdateSupplier(this.repository);

  Future<Either<Failure, void>> call(Supplier supplier) async {
    return await repository.updateSupplier(supplier);
  }
}
