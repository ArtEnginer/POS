import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/receiving.dart';
import '../../domain/repositories/receiving_repository.dart';
import '../datasources/receiving_local_data_source.dart';
import '../models/receiving_model.dart';

class ReceivingRepositoryImpl implements ReceivingRepository {
  final ReceivingLocalDataSource localDataSource;

  ReceivingRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Receiving>>> getAllReceivings() async {
    try {
      final receivings = await localDataSource.getAllReceivings();
      return Right(receivings);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get receivings: $e'));
    }
  }

  @override
  Future<Either<Failure, Receiving>> getReceivingById(String id) async {
    try {
      final receiving = await localDataSource.getReceivingById(id);
      return Right(receiving);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get receiving: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Receiving>>> getReceivingsByPurchaseId(
    String purchaseId,
  ) async {
    try {
      final receivings = await localDataSource.getReceivingsByPurchaseId(
        purchaseId,
      );
      return Right(receivings);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(
        DatabaseFailure(message: 'Failed to get receivings by purchase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Receiving>>> searchReceivings(
    String query,
  ) async {
    try {
      final receivings = await localDataSource.searchReceivings(query);
      return Right(receivings);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to search receivings: $e'));
    }
  }

  @override
  Future<Either<Failure, Receiving>> createReceiving(
    Receiving receiving,
  ) async {
    try {
      final receivingModel = ReceivingModel.fromEntity(receiving);
      final created = await localDataSource.createReceiving(receivingModel);
      return Right(created);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to create receiving: $e'));
    }
  }

  @override
  Future<Either<Failure, Receiving>> updateReceiving(
    Receiving receiving,
  ) async {
    try {
      final receivingModel = ReceivingModel.fromEntity(receiving);
      final updated = await localDataSource.updateReceiving(receivingModel);
      return Right(updated);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update receiving: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiving(String id) async {
    try {
      await localDataSource.deleteReceiving(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete receiving: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generateReceivingNumber() async {
    try {
      final number = await localDataSource.generateReceivingNumber();
      return Right(number);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(
        DatabaseFailure(message: 'Failed to generate receiving number: $e'),
      );
    }
  }
}
