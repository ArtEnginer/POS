import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  User _parseUserFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastLoginAt:
          json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'] as String)
              : null,
      lastLoginIp: json['last_login_ip'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      branchIds:
          (json['branch_ids'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) => e as int)
              .toList(),
    );
  }

  @override
  Future<UserListResult> getAllUsers({
    int limit = 10,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    int? branchId,
  }) async {
    try {
      final result = await remoteDataSource.getAllUsers(
        limit: limit,
        offset: offset,
        role: role,
        status: status,
        search: search,
        branchId: branchId,
      );

      final List<dynamic> dataList = result['data'] as List<dynamic>;
      final users =
          dataList
              .map((item) => _parseUserFromJson(item as Map<String, dynamic>))
              .toList();
      final total = result['total'] as int? ?? 0;

      return UserListResult(users: users, total: total);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> getUserById(int id) async {
    try {
      final result = await remoteDataSource.getUserById(id);
      return _parseUserFromJson(result['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? phone,
    List<int>? branchIds,
  }) async {
    try {
      final result = await remoteDataSource.createUser(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        branchIds: branchIds,
      );

      return _parseUserFromJson(result['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> updateUser({
    required int id,
    String? email,
    String? fullName,
    String? role,
    String? status,
    String? phone,
    List<int>? branchIds,
  }) async {
    try {
      final result = await remoteDataSource.updateUser(
        id: id,
        email: email,
        fullName: fullName,
        role: role,
        status: status,
        phone: phone,
        branchIds: branchIds,
      );

      return _parseUserFromJson(result['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(int id) async {
    try {
      await remoteDataSource.deleteUser(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required int id,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        id: id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required int id,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(id: id, newPassword: newPassword);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> assignBranches({
    required int id,
    required List<int> branchIds,
    int? defaultBranchId,
  }) async {
    try {
      await remoteDataSource.assignBranches(
        id: id,
        branchIds: branchIds,
        defaultBranchId: defaultBranchId,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserStats> getUserStats() async {
    try {
      final result = await remoteDataSource.getUserStats();
      final data = result['data'] as Map<String, dynamic>;

      return UserStats(
        totalUsers: data['total_users'] as int? ?? 0,
        activeUsers: data['active_users'] as int? ?? 0,
        inactiveUsers: data['inactive_users'] as int? ?? 0,
        suspendedUsers: data['suspended_users'] as int? ?? 0,
        superAdmins: data['super_admins'] as int? ?? 0,
        admins: data['admins'] as int? ?? 0,
        managers: data['managers'] as int? ?? 0,
        cashiers: data['cashiers'] as int? ?? 0,
        staff: data['staff'] as int? ?? 0,
      );
    } catch (e) {
      rethrow;
    }
  }
}
