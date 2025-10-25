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
      // ✅ ONLINE-ONLY: Fitur manajemen receiving harus online
      // Guard removed
      // Guard removed

      final receivingModel = ReceivingModel.fromEntity(receiving);
      final created = await localDataSource.createReceiving(receivingModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(created);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Receiving>> updateReceiving(
    Receiving receiving,
  ) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen receiving harus online
      // Guard removed
      // Guard removed

      final receivingModel = ReceivingModel.fromEntity(receiving);
      final updated = await localDataSource.updateReceiving(receivingModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(updated);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiving(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen receiving harus online
      // Guard removed
      // Guard removed

      await localDataSource.deleteReceiving(id);

      // Add to sync queue
      // Temporarily disabled

      return const Right(null);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
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
