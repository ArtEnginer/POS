import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/receiving_model.dart';

abstract class ReceivingRemoteDataSource {
  Future<List<ReceivingModel>> getAllReceivings();
  Future<ReceivingModel> getReceivingById(String id);
  Future<List<ReceivingModel>> searchReceivings(String query);
  Future<ReceivingModel> createReceiving(ReceivingModel receiving);
  Future<ReceivingModel> updateReceiving(ReceivingModel receiving);
  Future<void> deleteReceiving(String id);
  Future<String> generateReceivingNumber();
}

class ReceivingRemoteDataSourceImpl implements ReceivingRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  ReceivingRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<ReceivingModel>> getAllReceivings() async {
    try {
      final response = await apiClient.get(
        '/receivings',
        queryParameters: {'limit': 1000},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ReceivingModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load receivings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ReceivingModel> getReceivingById(String id) async {
    try {
      final response = await apiClient.get('/receivings/$id');

      if (response.statusCode == 200) {
        return ReceivingModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load receiving',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ReceivingModel>> searchReceivings(String query) async {
    try {
      final response = await apiClient.get(
        '/receivings/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ReceivingModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search receivings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ReceivingModel> createReceiving(ReceivingModel receiving) async {
    try {
      final response = await apiClient.post(
        '/receivings',
        data: receiving.toJson(),
      );

      if (response.statusCode == 201) {
        final newReceiving = ReceivingModel.fromJson(response.data['data']);

        // Emit receiving created event via Socket.IO
        _emitReceivingUpdate('created', newReceiving);

        return newReceiving;
      } else {
        throw app_exceptions.ServerException(
          message: response.data['message'] ?? 'Failed to create receiving',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ReceivingModel> updateReceiving(ReceivingModel receiving) async {
    try {
      final response = await apiClient.put(
        '/receivings/${receiving.id}',
        data: receiving.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedReceiving = ReceivingModel.fromJson(response.data['data']);

        // Emit receiving updated event via Socket.IO
        _emitReceivingUpdate('updated', updatedReceiving);

        return updatedReceiving;
      } else {
        throw app_exceptions.ServerException(
          message: response.data['message'] ?? 'Failed to update receiving',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteReceiving(String id) async {
    try {
      final response = await apiClient.delete('/receivings/$id');

      if (response.statusCode == 200) {
        // Emit receiving deleted event via Socket.IO
        _emitReceivingDelete(id);
      } else {
        throw app_exceptions.ServerException(
          message: response.data['message'] ?? 'Failed to delete receiving',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> generateReceivingNumber() async {
    try {
      final response = await apiClient.get('/receivings/generate-number');

      if (response.statusCode == 200) {
        return response.data['data']['receiving_number'] as String;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to generate receiving number',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  // Helper methods for Socket.IO events
  void _emitReceivingUpdate(String action, ReceivingModel receiving) {
    if (socketService.isConnected) {
      socketService.emit('receiving:update', {
        'action': action,
        'receivingId': receiving.id,
        'receiving': receiving.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitReceivingDelete(String receivingId) {
    if (socketService.isConnected) {
      socketService.emit('receiving:update', {
        'action': 'deleted',
        'receivingId': receivingId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
