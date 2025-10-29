import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/error/failures.dart';
import '../../domain/entities/purchase_return.dart';
import '../../domain/repositories/purchase_return_repository.dart';
import '../datasources/purchase_return_remote_data_source.dart';
import '../models/purchase_return_model.dart';

/// Purchase Return Repository Implementation - ONLINE ONLY
/// Management app MUST be online to manage purchase returns
class PurchaseReturnRepositoryImpl implements PurchaseReturnRepository {
  final PurchaseReturnRemoteDataSource remoteDataSource;

  PurchaseReturnRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PurchaseReturn>>> getAllPurchaseReturns() async {
    try {
      final result = await remoteDataSource.getAllPurchaseReturns();
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> getPurchaseReturnById(
    String id,
  ) async {
    try {
      final result = await remoteDataSource.getPurchaseReturnById(id);
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseReturn>>> getPurchaseReturnsByReceivingId(
    String receivingId,
  ) async {
    try {
      final result = await remoteDataSource.getPurchaseReturnsByReceivingId(
        receivingId,
      );
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseReturn>>> searchPurchaseReturns(
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchPurchaseReturns(query);
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> createPurchaseReturn(
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      final model = PurchaseReturnModel.fromEntity(purchaseReturn);
      final result = await remoteDataSource.createPurchaseReturn(model);
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> updatePurchaseReturn(
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      final model = PurchaseReturnModel.fromEntity(purchaseReturn);
      final result = await remoteDataSource.updatePurchaseReturn(model);
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseReturn>> updatePurchaseReturnStatus(
    String id,
    String status,
  ) async {
    try {
      final result = await remoteDataSource.updatePurchaseReturnStatus(
        id,
        status,
      );
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseReturn(String id) async {
    try {
      await remoteDataSource.deletePurchaseReturn(id);
      return const Right(null);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateReturnNumber() async {
    try {
      final result = await remoteDataSource.generateReturnNumber();
      return Right(result);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
