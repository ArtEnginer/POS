import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch.dart';
import '../repositories/branch_repository.dart';

class GetAllBranches {
  final BranchRepository repository;

  GetAllBranches(this.repository);

  Future<Either<Failure, List<Branch>>> call() async {
    return await repository.getAllBranches();
  }
}

class GetBranchById {
  final BranchRepository repository;

  GetBranchById(this.repository);

  Future<Either<Failure, Branch>> call(String id) async {
    return await repository.getBranchById(id);
  }
}

class CreateBranch {
  final BranchRepository repository;

  CreateBranch(this.repository);

  Future<Either<Failure, Branch>> call(Branch branch) async {
    return await repository.createBranch(branch);
  }
}

class UpdateBranch {
  final BranchRepository repository;

  UpdateBranch(this.repository);

  Future<Either<Failure, Branch>> call(Branch branch) async {
    return await repository.updateBranch(branch);
  }
}

class DeleteBranch {
  final BranchRepository repository;

  DeleteBranch(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteBranch(id);
  }
}

class SearchBranches {
  final BranchRepository repository;

  SearchBranches(this.repository);

  Future<Either<Failure, List<Branch>>> call(String query) async {
    return await repository.searchBranches(query);
  }
}

class GetCurrentBranch {
  final BranchRepository repository;

  GetCurrentBranch(this.repository);

  Future<Either<Failure, Branch>> call() async {
    return await repository.getCurrentBranch();
  }
}
