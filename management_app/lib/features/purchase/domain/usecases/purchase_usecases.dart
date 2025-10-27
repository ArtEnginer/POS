import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';

class GetAllPurchases {
  final PurchaseRepository repository;

  GetAllPurchases(this.repository);

  Future<Either<Failure, List<Purchase>>> call() async {
    return await repository.getAllPurchases();
  }
}

class GetPurchaseById {
  final PurchaseRepository repository;

  GetPurchaseById(this.repository);

  Future<Either<Failure, Purchase>> call(String id) async {
    return await repository.getPurchaseById(id);
  }
}

class GetPurchasesByDateRange {
  final PurchaseRepository repository;

  GetPurchasesByDateRange(this.repository);

  Future<Either<Failure, List<Purchase>>> call(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await repository.getPurchasesByDateRange(startDate, endDate);
  }
}

class SearchPurchases {
  final PurchaseRepository repository;

  SearchPurchases(this.repository);

  Future<Either<Failure, List<Purchase>>> call(String query) async {
    return await repository.searchPurchases(query);
  }
}

class CreatePurchase {
  final PurchaseRepository repository;

  CreatePurchase(this.repository);

  Future<Either<Failure, Purchase>> call(Purchase purchase) async {
    return await repository.createPurchase(purchase);
  }
}

class UpdatePurchase {
  final PurchaseRepository repository;

  UpdatePurchase(this.repository);

  Future<Either<Failure, Purchase>> call(Purchase purchase) async {
    return await repository.updatePurchase(purchase);
  }
}

class DeletePurchase {
  final PurchaseRepository repository;

  DeletePurchase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePurchase(id);
  }
}

class GeneratePurchaseNumber {
  final PurchaseRepository repository;

  GeneratePurchaseNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generatePurchaseNumber();
  }
}

class ReceivePurchase {
  final PurchaseRepository repository;

  ReceivePurchase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.receivePurchase(id);
  }
}
