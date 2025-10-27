import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/purchase_repository.dart';

class ReceivePurchase {
  final PurchaseRepository repository;

  ReceivePurchase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.receivePurchase(id);
  }
}
