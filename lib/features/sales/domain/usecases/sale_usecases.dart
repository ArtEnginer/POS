import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sale.dart';
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
