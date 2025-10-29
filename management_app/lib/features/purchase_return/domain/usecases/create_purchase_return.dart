import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class CreatePurchaseReturn {
  final PurchaseReturnRepository repository;

  CreatePurchaseReturn(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(
    PurchaseReturn purchaseReturn,
  ) async {
    return await repository.createPurchaseReturn(purchaseReturn);
  }
}
