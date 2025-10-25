import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch.dart';

abstract class BranchRepository {
  Future<Either<Failure, List<Branch>>> getAllBranches();
  Future<Either<Failure, Branch>> getBranchById(String id);
  Future<Either<Failure, Branch>> createBranch(Branch branch);
  Future<Either<Failure, Branch>> updateBranch(Branch branch);
  Future<Either<Failure, void>> deleteBranch(String id);
  Future<Either<Failure, List<Branch>>> searchBranches(String query);
  Future<Either<Failure, Branch>> getCurrentBranch();
}
