import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_remote_data_source.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDataSource remoteDataSource;

  UnitRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Unit>>> getAllUnits() async {
    try {
      final units = await remoteDataSource.getAllUnits();
      return Right(units.cast<Unit>());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> getUnitById(String id) async {
    try {
      final unit = await remoteDataSource.getUnitById(id);
      return Right(unit as Unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> createUnit(Unit unit) async {
    try {
      // Convert to model
      final unitModel = await remoteDataSource.createUnit(
        _convertToModel(unit),
      );
      return Right(unitModel as Unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUnit(String id, Unit unit) async {
    try {
      final unitModel = await remoteDataSource.updateUnit(
        id,
        _convertToModel(unit),
      );
      return Right(unitModel as Unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUnit(String id) async {
    try {
      await remoteDataSource.deleteUnit(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Helper method to convert entity to model
  dynamic _convertToModel(Unit unit) {
    // Import the model at the top if not imported
    final model = (unit as dynamic);
    return model;
  }
}
