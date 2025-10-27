import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/supplier_model.dart';

abstract class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getAllSuppliers();
  Future<SupplierModel> getSupplierById(String id);
  Future<List<SupplierModel>> searchSuppliers(String query);
  Future<SupplierModel> createSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
  Future<String> generateSupplierCode();
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  SupplierRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<SupplierModel>> getAllSuppliers() async {
    try {
      final response = await apiClient.get(
        '/suppliers',
        queryParameters: {
          'limit': 1000, // Get all suppliers
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => SupplierModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load suppliers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String id) async {
    try {
      final response = await apiClient.get('/suppliers/$id');

      if (response.statusCode == 200) {
        return SupplierModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load supplier',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    try {
      final response = await apiClient.get(
        '/suppliers/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => SupplierModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search suppliers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<SupplierModel> createSupplier(SupplierModel supplier) async {
    try {
      final response = await apiClient.post(
        '/suppliers',
        data: supplier.toJson(),
      );

      if (response.statusCode == 201) {
        final newSupplier = SupplierModel.fromJson(response.data['data']);

        // Emit supplier created event via Socket.IO
        _emitSupplierUpdate('created', newSupplier);

        return newSupplier;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to create supplier',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    try {
      final response = await apiClient.put(
        '/suppliers/${supplier.id}',
        data: supplier.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedSupplier = SupplierModel.fromJson(response.data['data']);

        // Emit supplier updated event via Socket.IO
        _emitSupplierUpdate('updated', updatedSupplier);

        return updatedSupplier;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update supplier',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      final response = await apiClient.delete('/suppliers/$id');

      if (response.statusCode == 200) {
        // Emit supplier deleted event via Socket.IO
        _emitSupplierDelete(id);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to delete supplier',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> generateSupplierCode() async {
    try {
      final response = await apiClient.get('/suppliers/generate-code');

      if (response.statusCode == 200) {
        return response.data['data']['code'] as String;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to generate supplier code',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  // Helper methods for Socket.IO events
  void _emitSupplierUpdate(String action, SupplierModel supplier) {
    if (socketService.isConnected) {
      socketService.emit('supplier:update', {
        'action': action,
        'supplierId': supplier.id,
        'supplier': supplier.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitSupplierDelete(String supplierId) {
    if (socketService.isConnected) {
      socketService.emit('supplier:update', {
        'action': 'deleted',
        'supplierId': supplierId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
