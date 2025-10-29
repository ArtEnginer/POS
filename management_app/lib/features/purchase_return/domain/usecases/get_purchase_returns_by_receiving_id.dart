import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class GetPurchaseReturnsByReceivingId {
  final PurchaseReturnRepository repository;

  GetPurchaseReturnsByReceivingId(this.repository);

  Future<Either<Failure, List<PurchaseReturn>>> call(String receivingId) async {
    return await repository.getPurchaseReturnsByReceivingId(receivingId);
  }
}
