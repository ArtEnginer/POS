import '../entities/user.dart';

abstract class UserRepository {
  Future<UserListResult> getAllUsers({
    int limit = 10,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    int? branchId,
  });

  Future<User> getUserById(int id);

  Future<User> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? phone,
    List<int>? branchIds,
  });

  Future<User> updateUser({
    required int id,
    String? email,
    String? fullName,
    String? role,
    String? status,
    String? phone,
    List<int>? branchIds,
  });

  Future<void> deleteUser(int id);

  Future<void> changePassword({
    required int id,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> resetPassword({required int id, required String newPassword});

  Future<void> assignBranches({
    required int id,
    required List<int> branchIds,
    int? defaultBranchId,
  });

  Future<UserStats> getUserStats();
}
