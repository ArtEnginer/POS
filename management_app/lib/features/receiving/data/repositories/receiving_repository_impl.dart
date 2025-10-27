import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/receiving.dart';
import '../../domain/repositories/receiving_repository.dart';
import '../datasources/receiving_remote_data_source.dart';
import '../models/receiving_model.dart';

class ReceivingRepositoryImpl implements ReceivingRepository {
  final ReceivingRemoteDataSource remoteDataSource;

  ReceivingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Receiving>>> getAllReceivings() async {
    try {
      final receivings = await remoteDataSource.getAllReceivings();
      return Right(receivings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get receivings: $e'));
    }
  }

  @override
  Future<Either<Failure, Receiving>> getReceivingById(String id) async {
    try {
      final receiving = await remoteDataSource.getReceivingById(id);
      return Right(receiving);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get receiving: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Receiving>>> getReceivingsByPurchaseId(
    String purchaseId,
  ) async {
    try {
      // Gunakan search dengan parameter purchase_id
      final receivings = await remoteDataSource.searchReceivings(
        'purchase_id:$purchaseId',
      );
      return Right(receivings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to get receivings by purchase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Receiving>>> searchReceivings(
    String query,
  ) async {
    try {
      final receivings = await remoteDataSource.searchReceivings(query);
      return Right(receivings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search receivings: $e'));
    }
  }

  @override
  Future<Either<Failure, Receiving>> createReceiving(
    Receiving receiving,
  ) async {
    try {
      final receivingModel = ReceivingModel.fromEntity(receiving);
      final created = await remoteDataSource.createReceiving(receivingModel);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Receiving>> updateReceiving(
    Receiving receiving,
  ) async {
    try {
      final receivingModel = ReceivingModel.fromEntity(receiving);
      final updated = await remoteDataSource.updateReceiving(receivingModel);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiving(String id) async {
    try {
      await remoteDataSource.deleteReceiving(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateReceivingNumber() async {
    try {
      final number = await remoteDataSource.generateReceivingNumber();
      return Right(number);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to generate receiving number: $e'),
      );
    }
  }
}
