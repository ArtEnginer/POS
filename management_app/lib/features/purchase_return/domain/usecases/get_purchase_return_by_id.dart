import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class GetPurchaseReturnById {
  final PurchaseReturnRepository repository;

  GetPurchaseReturnById(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(String id) async {
    return await repository.getPurchaseReturnById(id);
  }
}
