import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sale.dart';
import '../entities/pending_sale.dart';
import '../repositories/sale_repository.dart';

class GetAllSales {
  final SaleRepository repository;

  GetAllSales(this.repository);

  Future<Either<Failure, List<Sale>>> call() async {
    return await repository.getAllSales();
  }
}

class GetSaleById {
  final SaleRepository repository;

  GetSaleById(this.repository);

  Future<Either<Failure, Sale>> call(String id) async {
    return await repository.getSaleById(id);
  }
}

class GetSalesByDateRange {
  final SaleRepository repository;

  GetSalesByDateRange(this.repository);

  Future<Either<Failure, List<Sale>>> call(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await repository.getSalesByDateRange(startDate, endDate);
  }
}

class SearchSales {
  final SaleRepository repository;

  SearchSales(this.repository);

  Future<Either<Failure, List<Sale>>> call(String query) async {
    return await repository.searchSales(query);
  }
}

class CreateSale {
  final SaleRepository repository;

  CreateSale(this.repository);

  Future<Either<Failure, Sale>> call(Sale sale) async {
    return await repository.createSale(sale);
  }
}

class UpdateSale {
  final SaleRepository repository;

  UpdateSale(this.repository);

  Future<Either<Failure, Sale>> call(Sale sale) async {
    return await repository.updateSale(sale);
  }
}

class DeleteSale {
  final SaleRepository repository;

  DeleteSale(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteSale(id);
  }
}

class GenerateSaleNumber {
  final SaleRepository repository;

  GenerateSaleNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateSaleNumber();
  }
}

class GetDailySummary {
  final SaleRepository repository;

  GetDailySummary(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(DateTime date) async {
    return await repository.getDailySummary(date);
  }
}

// Pending Sale Use Cases
class SavePendingSale {
  final SaleRepository repository;

  SavePendingSale(this.repository);

  Future<Either<Failure, PendingSale>> call(PendingSale pendingSale) async {
    return await repository.savePendingSale(pendingSale);
  }
}

class GetPendingSales {
  final SaleRepository repository;

  GetPendingSales(this.repository);

  Future<Either<Failure, List<PendingSale>>> call() async {
    return await repository.getPendingSales();
  }
}

class GetPendingSaleById {
  final SaleRepository repository;

  GetPendingSaleById(this.repository);

  Future<Either<Failure, PendingSale>> call(String id) async {
    return await repository.getPendingSaleById(id);
  }
}

class DeletePendingSale {
  final SaleRepository repository;

  DeletePendingSale(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePendingSale(id);
  }
}

class GeneratePendingNumber {
  final SaleRepository repository;

  GeneratePendingNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generatePendingNumber();
  }
}
