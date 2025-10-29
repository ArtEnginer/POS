import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class GetAllPurchaseReturns {
  final PurchaseReturnRepository repository;

  GetAllPurchaseReturns(this.repository);

  Future<Either<Failure, List<PurchaseReturn>>> call() async {
    return await repository.getAllPurchaseReturns();
  }
}
