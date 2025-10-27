import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<Either<Failure, List<Purchase>>> getAllPurchases();
  Future<Either<Failure, Purchase>> getPurchaseById(String id);
  Future<Either<Failure, List<Purchase>>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Purchase>>> searchPurchases(String query);
  Future<Either<Failure, Purchase>> createPurchase(Purchase purchase);
  Future<Either<Failure, Purchase>> updatePurchase(Purchase purchase);
  Future<Either<Failure, void>> deletePurchase(String id);
  Future<Either<Failure, String>> generatePurchaseNumber();
  Future<Either<Failure, void>> receivePurchase(String id);
}
