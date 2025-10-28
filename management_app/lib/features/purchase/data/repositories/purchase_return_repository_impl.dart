import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase_return.dart';
import '../../domain/repositories/purchase_return_repository.dart';
// import '../datasources/purchase_return_local_data_source.dart';
import '../models/purchase_return_model.dart';

class PurchaseReturnRepositoryImpl implements PurchaseReturnRepository {
  final PurchaseReturnLocalDataSource localDataSource;

  PurchaseReturnRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<PurchaseReturn>>> getAllPurchaseReturns() async {
    try {
      final result = await localDataSource.getAllPurchaseReturns();
      return Right(result);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> getPurchaseReturnById(
    String id,
  ) async {
    try {
      final result = await localDataSource.getPurchaseReturnById(id);
      return Right(result);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseReturn>>> getPurchaseReturnsByReceivingId(
    String receivingId,
  ) async {
    try {
      final result = await localDataSource.getPurchaseReturnsByReceivingId(
        receivingId,
      );
      return Right(result);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseReturn>>> searchPurchaseReturns(
    String query,
  ) async {
    try {
      final result = await localDataSource.searchPurchaseReturns(query);
      return Right(result);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> createPurchaseReturn(
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase return harus online
      // Guard removed
      // Guard removed

      final model = PurchaseReturnModel.fromEntity(purchaseReturn);
      final result = await localDataSource.createPurchaseReturn(model);

      // Add to sync queue
      // Temporarily disabled

      return Right(result);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> updatePurchaseReturn(
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase return harus online
      // Guard removed
      // Guard removed

      final model = PurchaseReturnModel.fromEntity(purchaseReturn);
      final result = await localDataSource.updatePurchaseReturn(model);

      // Add to sync queue
      // Temporarily disabled

      return Right(result);
    } on app_exceptions.OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseReturn(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen purchase return harus online
      // Guard removed
      // Guard removed

      await localDataSource.deletePurchaseReturn(id);

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
  Future<Either<Failure, String>> generateReturnNumber() async {
    try {
      final result = await localDataSource.generateReturnNumber();
      return Right(result);
    } on app_exceptions.DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}
