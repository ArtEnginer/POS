import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/unit_model.dart';

abstract class UnitRemoteDataSource {
  Future<List<UnitModel>> getAllUnits();
  Future<UnitModel> getUnitById(String id);
  Future<UnitModel> createUnit(UnitModel unit);
  Future<UnitModel> updateUnit(String id, UnitModel unit);
  Future<void> deleteUnit(String id);
}

class UnitRemoteDataSourceImpl implements UnitRemoteDataSource {
  final dynamic apiClient;

  UnitRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<UnitModel>> getAllUnits() async {
    try {
      final response = await apiClient.get('/units');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => UnitModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to fetch units',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<UnitModel> getUnitById(String id) async {
    try {
      final response = await apiClient.get('/units/$id');

      if (response.statusCode == 200) {
        return UnitModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to fetch unit',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<UnitModel> createUnit(UnitModel unit) async {
    try {
      final response = await apiClient.post(
        '/units',
        data: unit.toCreateJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UnitModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to create unit',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<UnitModel> updateUnit(String id, UnitModel unit) async {
    try {
      final response = await apiClient.put(
        '/units/$id',
        data: unit.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        return UnitModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update unit',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteUnit(String id) async {
    try {
      final response = await apiClient.delete('/units/$id');

      if (response.statusCode != 200) {
        throw app_exceptions.ServerException(
          message: 'Failed to delete unit',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }
}
