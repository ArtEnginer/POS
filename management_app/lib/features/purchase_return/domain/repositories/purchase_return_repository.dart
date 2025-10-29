import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase_return.dart';

abstract class PurchaseReturnRepository {
  Future<Either<Failure, List<PurchaseReturn>>> getAllPurchaseReturns();
  Future<Either<Failure, PurchaseReturn>> getPurchaseReturnById(String id);
  Future<Either<Failure, List<PurchaseReturn>>> getPurchaseReturnsByReceivingId(
    String receivingId,
  );
  Future<Either<Failure, List<PurchaseReturn>>> searchPurchaseReturns(
    String query,
  );
  Future<Either<Failure, PurchaseReturn>> createPurchaseReturn(
    PurchaseReturn purchaseReturn,
  );
  Future<Either<Failure, PurchaseReturn>> updatePurchaseReturn(
    PurchaseReturn purchaseReturn,
  );
  Future<Either<Failure, PurchaseReturn>> updatePurchaseReturnStatus(
    String id,
    String status,
  );
  Future<Either<Failure, void>> deletePurchaseReturn(String id);
  Future<Either<Failure, String>> generateReturnNumber();
}
