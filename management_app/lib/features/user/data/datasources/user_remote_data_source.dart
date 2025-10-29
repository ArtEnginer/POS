import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';

// Abstract
abstract class UserRemoteDataSource {
  Future<Map<String, dynamic>> getAllUsers({
    int limit = 10,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    int? branchId,
  });

  Future<Map<String, dynamic>> getUserById(int id);

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? phone,
    List<int>? branchIds,
  });

  Future<Map<String, dynamic>> updateUser({
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

  Future<Map<String, dynamic>> getUserStats();
}

// Implementation
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;
  final SocketService socketService;
  final AuthService authService;

  UserRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<Map<String, dynamic>> getAllUsers({
    int limit = 10,
    int offset = 0,
    String? role,
    String? status,
    String? search,
    int? branchId,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (branchId != null) queryParams['branchId'] = branchId.toString();

      final response = await apiClient.get(
        '/users',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch users');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch users');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      final response = await apiClient.get('/users/$id');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch user');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch user');
    }
  }

  @override
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? role,
    String? phone,
    List<int>? branchIds,
  }) async {
    try {
      final data = {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        if (branchIds != null) 'branch_ids': branchIds,
      };

      final response = await apiClient.post('/users', data: data);

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create user');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Failed to create user',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateUser({
    required int id,
    String? email,
    String? fullName,
    String? role,
    String? status,
    String? phone,
    List<int>? branchIds,
  }) async {
    try {
      final data = {
        if (email != null) 'email': email,
        if (fullName != null) 'full_name': fullName,
        if (role != null) 'role': role,
        if (status != null) 'status': status,
        if (phone != null) 'phone': phone,
        if (branchIds != null) 'branch_ids': branchIds,
      };

      final response = await apiClient.put('/users/$id', data: data);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update user');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Failed to update user',
      );
    }
  }

  @override
  Future<void> deleteUser(int id) async {
    try {
      final response = await apiClient.delete('/users/$id');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete user');
    }
  }

  @override
  Future<void> changePassword({
    required int id,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/users/$id/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change password');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Failed to change password',
      );
    }
  }

  @override
  Future<void> resetPassword({
    required int id,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/users/$id/reset-password',
        data: {'newPassword': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to reset password');
    }
  }

  @override
  Future<void> assignBranches({
    required int id,
    required List<int> branchIds,
    int? defaultBranchId,
  }) async {
    try {
      final data = {
        'branch_ids': branchIds,
        if (defaultBranchId != null) 'default_branch_id': defaultBranchId,
      };

      final response = await apiClient.post(
        '/users/$id/assign-branches',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to assign branches');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to assign branches');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await apiClient.get('/users/stats/summary');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch user stats');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch user stats');
    }
  }
}
