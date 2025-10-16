import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receiving.dart';
import '../repositories/receiving_repository.dart';

// ========== GET ALL RECEIVINGS ==========
class GetAllReceivings {
  final ReceivingRepository repository;

  GetAllReceivings(this.repository);

  Future<Either<Failure, List<Receiving>>> call() async {
    return await repository.getAllReceivings();
  }
}

// ========== GET RECEIVING BY ID ==========
class GetReceivingById {
  final ReceivingRepository repository;

  GetReceivingById(this.repository);

  Future<Either<Failure, Receiving>> call(String id) async {
    return await repository.getReceivingById(id);
  }
}

// ========== GET RECEIVINGS BY PURCHASE ID ==========
class GetReceivingsByPurchaseId {
  final ReceivingRepository repository;

  GetReceivingsByPurchaseId(this.repository);

  Future<Either<Failure, List<Receiving>>> call(String purchaseId) async {
    return await repository.getReceivingsByPurchaseId(purchaseId);
  }
}

// ========== SEARCH RECEIVINGS ==========
class SearchReceivings {
  final ReceivingRepository repository;

  SearchReceivings(this.repository);

  Future<Either<Failure, List<Receiving>>> call(String query) async {
    return await repository.searchReceivings(query);
  }
}

// ========== CREATE RECEIVING ==========
class CreateReceiving {
  final ReceivingRepository repository;

  CreateReceiving(this.repository);

  Future<Either<Failure, Receiving>> call(Receiving receiving) async {
    return await repository.createReceiving(receiving);
  }
}

// ========== UPDATE RECEIVING ==========
class UpdateReceiving {
  final ReceivingRepository repository;

  UpdateReceiving(this.repository);

  Future<Either<Failure, Receiving>> call(Receiving receiving) async {
    return await repository.updateReceiving(receiving);
  }
}

// ========== DELETE RECEIVING ==========
class DeleteReceiving {
  final ReceivingRepository repository;

  DeleteReceiving(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteReceiving(id);
  }
}

// ========== GENERATE RECEIVING NUMBER ==========
class GenerateReceivingNumber {
  final ReceivingRepository repository;

  GenerateReceivingNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateReceivingNumber();
  }
}
