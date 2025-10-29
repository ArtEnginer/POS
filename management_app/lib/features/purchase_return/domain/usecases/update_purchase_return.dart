import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class UpdatePurchaseReturn {
  final PurchaseReturnRepository repository;

  UpdatePurchaseReturn(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(
    PurchaseReturn purchaseReturn,
  ) async {
    return await repository.updatePurchaseReturn(purchaseReturn);
  }
}
