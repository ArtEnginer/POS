import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/pending_sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_local_data_source.dart';
import '../models/sale_model.dart';
import '../models/pending_sale_model.dart';

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
      // User-friendly message jika transaksi tidak ditemukan
      if (e.message.contains('Transaksi tidak ditemukan')) {
        return Left(CacheFailure(message: 'Transaksi tidak ditemukan'));
      }
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

      // Add to sync queue for automatic sync
      // Temporarily disabled

      return Right(createdSale);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Sale>> updateSale(Sale sale) async {
    try {
      final saleModel = SaleModel.fromEntity(sale);
      final updatedSale = await localDataSource.updateSale(saleModel);

      // Add to sync queue for automatic sync
      // Temporarily disabled

      return Right(updatedSale);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSale(String id) async {
    try {
      await localDataSource.deleteSale(id);

      // Add to sync queue for automatic sync
      // Temporarily disabled

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
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

  // Pending Sale Methods Implementation
  @override
  Future<Either<Failure, PendingSale>> savePendingSale(
    PendingSale pendingSale,
  ) async {
    try {
      final pendingSaleModel = PendingSaleModel.fromEntity(pendingSale);
      final savedPendingSale = await localDataSource.savePendingSale(
        pendingSaleModel,
      );
      return Right(savedPendingSale);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PendingSale>>> getPendingSales() async {
    try {
      final pendingSales = await localDataSource.getPendingSales();
      return Right(pendingSales);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, PendingSale>> getPendingSaleById(String id) async {
    try {
      final pendingSale = await localDataSource.getPendingSaleById(id);
      return Right(pendingSale);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePendingSale(String id) async {
    try {
      await localDataSource.deletePendingSale(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generatePendingNumber() async {
    try {
      final number = await localDataSource.generatePendingNumber();
      return Right(number);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
