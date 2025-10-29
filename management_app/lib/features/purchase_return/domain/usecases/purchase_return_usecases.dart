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

class GetPurchaseReturnById {
  final PurchaseReturnRepository repository;

  GetPurchaseReturnById(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(String id) async {
    return await repository.getPurchaseReturnById(id);
  }
}

class GetPurchaseReturnsByReceivingId {
  final PurchaseReturnRepository repository;

  GetPurchaseReturnsByReceivingId(this.repository);

  Future<Either<Failure, List<PurchaseReturn>>> call(String receivingId) async {
    return await repository.getPurchaseReturnsByReceivingId(receivingId);
  }
}

class SearchPurchaseReturns {
  final PurchaseReturnRepository repository;

  SearchPurchaseReturns(this.repository);

  Future<Either<Failure, List<PurchaseReturn>>> call(String query) async {
    return await repository.searchPurchaseReturns(query);
  }
}

class CreatePurchaseReturn {
  final PurchaseReturnRepository repository;

  CreatePurchaseReturn(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(
    PurchaseReturn purchaseReturn,
  ) async {
    return await repository.createPurchaseReturn(purchaseReturn);
  }
}

class UpdatePurchaseReturn {
  final PurchaseReturnRepository repository;

  UpdatePurchaseReturn(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(
    PurchaseReturn purchaseReturn,
  ) async {
    return await repository.updatePurchaseReturn(purchaseReturn);
  }
}

class UpdatePurchaseReturnStatus {
  final PurchaseReturnRepository repository;

  UpdatePurchaseReturnStatus(this.repository);

  Future<Either<Failure, PurchaseReturn>> call(String id, String status) async {
    return await repository.updatePurchaseReturnStatus(id, status);
  }
}

class DeletePurchaseReturn {
  final PurchaseReturnRepository repository;

  DeletePurchaseReturn(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePurchaseReturn(id);
  }
}

class GenerateReturnNumber {
  final PurchaseReturnRepository repository;

  GenerateReturnNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateReturnNumber();
  }
}
