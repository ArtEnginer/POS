import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';
import '../repositories/purchase_return_repository.dart';

class SearchPurchaseReturns {
  final PurchaseReturnRepository repository;

  SearchPurchaseReturns(this.repository);

  Future<Either<Failure, List<PurchaseReturn>>> call(String query) async {
    return await repository.searchPurchaseReturns(query);
  }
}
