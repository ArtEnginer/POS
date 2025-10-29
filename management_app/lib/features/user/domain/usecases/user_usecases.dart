import '../entities/user.dart';
import '../repositories/user_repository.dart';

// Get All Users Use Case
class GetAllUsersUseCase {
  final UserRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<UserListResult> call({
    int limit = 10,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    int? branchId,
  }) async {
    return repository.getAllUsers(
      limit: limit,
      offset: offset,
      role: role,
      status: status,
      search: search,
      branchId: branchId,
    );
  }
}

// Get User By ID Use Case
class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  Future<User> call(int id) async {
    return repository.getUserById(id);
  }
}

// Create User Use Case
class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<User> call({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? phone,
    List<int>? branchIds,
  }) async {
    return repository.createUser(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      branchIds: branchIds,
    );
  }
}

// Update User Use Case
class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<User> call({
    required int id,
    String? email,
    String? fullName,
    String? role,
    String? status,
    String? phone,
    List<int>? branchIds,
  }) async {
    return repository.updateUser(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      status: status,
      phone: phone,
      branchIds: branchIds,
    );
  }
}

// Delete User Use Case
class DeleteUserUseCase {
  final UserRepository repository;

  DeleteUserUseCase(this.repository);

  Future<void> call(int id) async {
    return repository.deleteUser(id);
  }
}

// Change Password Use Case
class ChangePasswordUseCase {
  final UserRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<void> call({
    required int id,
    required String currentPassword,
    required String newPassword,
  }) async {
    return repository.changePassword(
      id: id,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

// Reset Password Use Case
class ResetPasswordUseCase {
  final UserRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> call({required int id, required String newPassword}) async {
    return repository.resetPassword(id: id, newPassword: newPassword);
  }
}

// Assign Branches Use Case
class AssignBranchesUseCase {
  final UserRepository repository;

  AssignBranchesUseCase(this.repository);

  Future<void> call({
    required int id,
    required List<int> branchIds,
    int? defaultBranchId,
  }) async {
    return repository.assignBranches(
      id: id,
      branchIds: branchIds,
      defaultBranchId: defaultBranchId,
    );
  }
}

// Get User Stats Use Case
class GetUserStatsUseCase {
  final UserRepository repository;

  GetUserStatsUseCase(this.repository);

  Future<UserStats> call() async {
    return repository.getUserStats();
  }
}
