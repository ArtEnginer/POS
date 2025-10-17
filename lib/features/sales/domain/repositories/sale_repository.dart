import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Either<Failure, List<Sale>>> getAllSales();
  Future<Either<Failure, Sale>> getSaleById(String id);
  Future<Either<Failure, List<Sale>>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Sale>>> searchSales(String query);
  Future<Either<Failure, Sale>> createSale(Sale sale);
  Future<Either<Failure, Sale>> updateSale(Sale sale);
  Future<Either<Failure, void>> deleteSale(String id);
  Future<Either<Failure, String>> generateSaleNumber();
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(DateTime date);
}
