import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class UpdatePurchaseReturnStatus {
  final PurchaseReturnRepository repository;

  UpdatePurchaseReturnStatus(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(String id, String status) async {
    return await repository.updatePurchaseReturnStatus(id, status);
  }
}
