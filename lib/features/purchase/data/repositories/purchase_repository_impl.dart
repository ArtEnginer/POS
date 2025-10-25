import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_local_data_source.dart';
import '../models/purchase_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseLocalDataSource localDataSource;

  PurchaseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Purchase>>> getAllPurchases() async {
    try {
      final purchases = await localDataSource.getAllPurchases();
      return Right(purchases);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Purchase>> getPurchaseById(String id) async {
    try {
      final purchase = await localDataSource.getPurchaseById(id);
      return Right(purchase);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Purchase>>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final purchases = await localDataSource.getPurchasesByDateRange(
        startDate,
        endDate,
      );
      return Right(purchases);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Purchase>>> searchPurchases(String query) async {
    try {
      final purchases = await localDataSource.searchPurchases(query);
      return Right(purchases);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Purchase>> createPurchase(Purchase purchase) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase harus online

      final purchaseModel = PurchaseModel.fromEntity(purchase);
      await localDataSource.insertPurchase(purchaseModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(purchase);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Purchase>> updatePurchase(Purchase purchase) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase harus online
      // Guard removed
      // Guard removed

      final purchaseModel = PurchaseModel.fromEntity(purchase);
      await localDataSource.updatePurchase(purchaseModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(purchase);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchase(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase harus online
      // Guard removed
      // Guard removed

      await localDataSource.deletePurchase(id);

      // Add to sync queue
      // Temporarily disabled

      return const Right(null);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generatePurchaseNumber() async {
    try {
      final purchaseNumber = await localDataSource.generatePurchaseNumber();
      return Right(purchaseNumber);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> receivePurchase(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase harus online
      // Guard removed
      // Guard removed

      await localDataSource.receivePurchase(id);

      // Add to sync queue
      // Temporarily disabled

      return const Right(null);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
