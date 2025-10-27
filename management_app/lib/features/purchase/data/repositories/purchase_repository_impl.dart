import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_data_source.dart';
import '../models/purchase_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource remoteDataSource;

  PurchaseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Purchase>>> getAllPurchases() async {
    try {
      final purchases = await remoteDataSource.getAllPurchases();
      return Right(purchases);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Purchase>> getPurchaseById(String id) async {
    try {
      final purchase = await remoteDataSource.getPurchaseById(id);
      return Right(purchase);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Purchase>>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all purchases and filter by date range
      final purchases = await remoteDataSource.getAllPurchases();
      final filtered =
          purchases.where((p) {
            return p.purchaseDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                p.purchaseDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
      return Right(filtered);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Purchase>>> searchPurchases(String query) async {
    try {
      final purchases = await remoteDataSource.searchPurchases(query);
      return Right(purchases);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Purchase>> createPurchase(Purchase purchase) async {
    try {
      final purchaseModel = PurchaseModel.fromEntity(purchase);
      final created = await remoteDataSource.createPurchase(purchaseModel);
      return Right(created);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Purchase>> updatePurchase(Purchase purchase) async {
    try {
      final purchaseModel = PurchaseModel.fromEntity(purchase);
      final updated = await remoteDataSource.updatePurchase(purchaseModel);
      return Right(updated);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchase(String id) async {
    try {
      await remoteDataSource.deletePurchase(id);
      return const Right(null);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generatePurchaseNumber() async {
    try {
      final purchaseNumber = await remoteDataSource.generatePurchaseNumber();
      return Right(purchaseNumber);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> receivePurchase(String id) async {
    try {
      // Update status to 'received'
      await remoteDataSource.updatePurchaseStatus(id, 'received');
      return const Right(null);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
