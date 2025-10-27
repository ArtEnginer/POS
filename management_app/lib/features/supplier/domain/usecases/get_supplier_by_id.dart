import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSupplierById {
  final SupplierRepository repository;

  GetSupplierById(this.repository);

  Future<Either<Failure, Supplier>> call(String id) async {
    return await repository.getSupplierById(id);
  }
}
