import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/purchase_return_repository.dart';

class DeletePurchaseReturn {
  final PurchaseReturnRepository repository;

  DeletePurchaseReturn(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePurchaseReturn(id);
  }
}
