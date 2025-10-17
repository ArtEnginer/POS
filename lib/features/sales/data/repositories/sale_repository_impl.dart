import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_local_data_source.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleLocalDataSource localDataSource;

  SaleRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Sale>>> getAllSales() async {
    try {
      final sales = await localDataSource.getAllSales();
      return Right(sales);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Sale>> getSaleById(String id) async {
    try {
      final sale = await localDataSource.getSaleById(id);
      return Right(sale);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Sale>>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sales = await localDataSource.getSalesByDateRange(
        startDate,
        endDate,
      );
      return Right(sales);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Sale>>> searchSales(String query) async {
    try {
      final sales = await localDataSource.searchSales(query);
      return Right(sales);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Sale>> createSale(Sale sale) async {
    try {
      final saleModel = SaleModel.fromEntity(sale);
      final createdSale = await localDataSource.createSale(saleModel);
      return Right(createdSale);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Sale>> updateSale(Sale sale) async {
    try {
      final saleModel = SaleModel.fromEntity(sale);
      final updatedSale = await localDataSource.updateSale(saleModel);
      return Right(updatedSale);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSale(String id) async {
    try {
      await localDataSource.deleteSale(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> generateSaleNumber() async {
    try {
      final number = await localDataSource.generateSaleNumber();
      return Right(number);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDailySummary(
    DateTime date,
  ) async {
    try {
      final summary = await localDataSource.getDailySummary(date);
      return Right(summary);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
