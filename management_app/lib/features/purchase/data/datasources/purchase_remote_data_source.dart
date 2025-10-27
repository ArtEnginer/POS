import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/purchase_model.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseModel>> getAllPurchases();
  Future<PurchaseModel> getPurchaseById(String id);
  Future<List<PurchaseModel>> searchPurchases(String query);
  Future<PurchaseModel> createPurchase(PurchaseModel purchase);
  Future<PurchaseModel> updatePurchase(PurchaseModel purchase);
  Future<void> deletePurchase(String id);
  Future<String> generatePurchaseNumber();
  Future<PurchaseModel> updatePurchaseStatus(String id, String status);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  PurchaseRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<PurchaseModel>> getAllPurchases() async {
    try {
      final response = await apiClient.get(
        '/purchases',
        queryParameters: {'limit': 1000},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => PurchaseModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load purchases',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseModel> getPurchaseById(String id) async {
    try {
      final response = await apiClient.get('/purchases/$id');

      if (response.statusCode == 200) {
        return PurchaseModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load purchase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<PurchaseModel>> searchPurchases(String query) async {
    try {
      final response = await apiClient.get(
        '/purchases/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => PurchaseModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search purchases',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseModel> createPurchase(PurchaseModel purchase) async {
    try {
      final response = await apiClient.post(
        '/purchases',
        data: purchase.toJson(),
      );

      if (response.statusCode == 201) {
        final newPurchase = PurchaseModel.fromJson(response.data['data']);

        // Emit purchase created event via Socket.IO
        _emitPurchaseUpdate('created', newPurchase);

        return newPurchase;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to create purchase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseModel> updatePurchase(PurchaseModel purchase) async {
    try {
      final response = await apiClient.put(
        '/purchases/${purchase.id}',
        data: purchase.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedPurchase = PurchaseModel.fromJson(response.data['data']);

        // Emit purchase updated event via Socket.IO
        _emitPurchaseUpdate('updated', updatedPurchase);

        return updatedPurchase;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update purchase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deletePurchase(String id) async {
    try {
      final response = await apiClient.delete('/purchases/$id');

      if (response.statusCode == 200) {
        // Emit purchase deleted event via Socket.IO
        _emitPurchaseDelete(id);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to delete purchase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> generatePurchaseNumber() async {
    try {
      final response = await apiClient.get('/purchases/generate-number');

      if (response.statusCode == 200) {
        return response.data['data']['purchase_number'] as String;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to generate purchase number',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseModel> updatePurchaseStatus(String id, String status) async {
    try {
      final response = await apiClient.patch(
        '/purchases/$id/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final updatedPurchase = PurchaseModel.fromJson(response.data['data']);

        // Emit purchase status updated event via Socket.IO
        _emitPurchaseUpdate('status_updated', updatedPurchase);

        return updatedPurchase;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update purchase status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  // Helper methods for Socket.IO events
  void _emitPurchaseUpdate(String action, PurchaseModel purchase) {
    if (socketService.isConnected) {
      socketService.emit('purchase:update', {
        'action': action,
        'purchaseId': purchase.id,
        'purchase': purchase.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitPurchaseDelete(String purchaseId) {
    if (socketService.isConnected) {
      socketService.emit('purchase:update', {
        'action': 'deleted',
        'purchaseId': purchaseId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
