import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CreateSupplier {
  final SupplierRepository repository;

  CreateSupplier(this.repository);

  Future<Either<Failure, void>> call(Supplier supplier) async {
    return await repository.createSupplier(supplier);
  }
}
