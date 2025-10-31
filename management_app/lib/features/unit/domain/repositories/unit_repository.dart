import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/error/failures.dart';
import '../entities/unit.dart';

abstract class UnitRepository {
  Future<Either<Failure, List<Unit>>> getAllUnits();
  Future<Either<Failure, Unit>> getUnitById(String id);
  Future<Either<Failure, Unit>> createUnit(Unit unit);
  Future<Either<Failure, Unit>> updateUnit(String id, Unit unit);
  Future<Either<Failure, void>> deleteUnit(String id);
}
