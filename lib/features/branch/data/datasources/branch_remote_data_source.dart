import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/error/exceptions.dart';
import '../../domain/entities/branch.dart';

abstract class BranchRemoteDataSource {
  Future<List<Branch>> getAllBranches();
  Future<Branch> getBranchById(String id);
  Future<Branch> createBranch(Branch branch);
  Future<Branch> updateBranch(Branch branch);
  Future<void> deleteBranch(String id);
  Future<List<Branch>> searchBranches(String query);
  Future<Branch> getCurrentBranch();
}

class BranchRemoteDataSourceImpl implements BranchRemoteDataSource {
  final ApiClient apiClient;

  BranchRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<Branch>> getAllBranches() async {
    try {
      final response = await apiClient.get(ApiConstants.branches);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => Branch.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to load branches',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Branch> getBranchById(String id) async {
    try {
      final response = await apiClient.get('${ApiConstants.branches}/$id');

      if (response.statusCode == 200) {
        return Branch.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Failed to load branch',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Branch> createBranch(Branch branch) async {
    try {
      final response = await apiClient.post(
        ApiConstants.branches,
        data: branch.toJson(),
      );

      if (response.statusCode == 201) {
        return Branch.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Failed to create branch',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Branch> updateBranch(Branch branch) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.branches}/${branch.id}',
        data: branch.toJson(),
      );

      if (response.statusCode == 200) {
        return Branch.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Failed to update branch',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteBranch(String id) async {
    try {
      final response = await apiClient.delete('${ApiConstants.branches}/$id');

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to delete branch',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Branch>> searchBranches(String query) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.branches}/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => Branch.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to search branches',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Branch> getCurrentBranch() async {
    try {
      final response = await apiClient.get('${ApiConstants.branches}/current');

      if (response.statusCode == 200) {
        return Branch.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Failed to load current branch',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
