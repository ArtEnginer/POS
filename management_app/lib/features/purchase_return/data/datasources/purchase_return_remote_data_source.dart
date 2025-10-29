import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/purchase_return_model.dart';

abstract class PurchaseReturnRemoteDataSource {
  Future<List<PurchaseReturnModel>> getAllPurchaseReturns();
  Future<PurchaseReturnModel> getPurchaseReturnById(String id);
  Future<List<PurchaseReturnModel>> getPurchaseReturnsByReceivingId(
    String receivingId,
  );
  Future<List<PurchaseReturnModel>> searchPurchaseReturns(String query);
  Future<PurchaseReturnModel> createPurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  );
  Future<PurchaseReturnModel> updatePurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  );
  Future<PurchaseReturnModel> updatePurchaseReturnStatus(
    String id,
    String status,
  );
  Future<void> deletePurchaseReturn(String id);
  Future<String> generateReturnNumber();
}

class PurchaseReturnRemoteDataSourceImpl
    implements PurchaseReturnRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  PurchaseReturnRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<PurchaseReturnModel>> getAllPurchaseReturns() async {
    try {
      final response = await apiClient.get(
        '/purchase-returns',
        queryParameters: {'limit': 1000},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => PurchaseReturnModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load purchase returns',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseReturnModel> getPurchaseReturnById(String id) async {
    try {
      final response = await apiClient.get('/purchase-returns/$id');

      if (response.statusCode == 200) {
        return PurchaseReturnModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load purchase return',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<PurchaseReturnModel>> getPurchaseReturnsByReceivingId(
    String receivingId,
  ) async {
    try {
      final response = await apiClient.get(
        '/purchase-returns/receiving/$receivingId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => PurchaseReturnModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load purchase returns by receiving',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<PurchaseReturnModel>> searchPurchaseReturns(String query) async {
    try {
      final response = await apiClient.get(
        '/purchase-returns/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => PurchaseReturnModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search purchase returns',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseReturnModel> createPurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  ) async {
    try {
      final jsonData = purchaseReturn.toJson();
      print('=== CREATE PURCHASE RETURN DEBUG ===');
      print('URL: /purchase-returns');
      print('Data being sent:');
      print(jsonData);
      print('Items count: ${(jsonData['items'] as List).length}');
      print('=====================================');

      final response = await apiClient.post(
        '/purchase-returns',
        data: jsonData,
      );

      print('=== RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=====================');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final returnData = PurchaseReturnModel.fromJson(response.data['data']);

        // Emit socket event for real-time update
        final userData = await authService.getUserData();
        socketService.emit('purchase_return:created', {
          'return': returnData.toJson(),
          'user_id': userData?['id'],
        });

        return returnData;
      } else {
        throw app_exceptions.ServerException(
          message:
              response.data['message'] ?? 'Failed to create purchase return',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('=== ERROR DEBUG ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('===================');
      if (e is app_exceptions.ServerException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseReturnModel> updatePurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  ) async {
    try {
      final response = await apiClient.put(
        '/purchase-returns/${purchaseReturn.id}',
        data: purchaseReturn.toJson(),
      );

      if (response.statusCode == 200) {
        final returnData = PurchaseReturnModel.fromJson(response.data['data']);

        // Emit socket event for real-time update
        final userData = await authService.getUserData();
        socketService.emit('purchase_return:updated', {
          'return': returnData.toJson(),
          'user_id': userData?['id'],
        });

        return returnData;
      } else {
        throw app_exceptions.ServerException(
          message:
              response.data['message'] ?? 'Failed to update purchase return',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is app_exceptions.ServerException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<PurchaseReturnModel> updatePurchaseReturnStatus(
    String id,
    String status,
  ) async {
    try {
      final response = await apiClient.patch(
        '/purchase-returns/$id/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final returnData = PurchaseReturnModel.fromJson(response.data['data']);

        // Emit socket event for real-time update
        final userData = await authService.getUserData();
        socketService.emit('purchase_return:status_updated', {
          'return': returnData.toJson(),
          'user_id': userData?['id'],
        });

        return returnData;
      } else {
        throw app_exceptions.ServerException(
          message: response.data['message'] ?? 'Failed to update status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is app_exceptions.ServerException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deletePurchaseReturn(String id) async {
    try {
      final response = await apiClient.delete('/purchase-returns/$id');

      if (response.statusCode == 200) {
        // Emit socket event for real-time update
        final userData = await authService.getUserData();
        socketService.emit('purchase_return:deleted', {
          'return_id': id,
          'user_id': userData?['id'],
        });
      } else {
        throw app_exceptions.ServerException(
          message:
              response.data['message'] ?? 'Failed to delete purchase return',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is app_exceptions.ServerException) rethrow;
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> generateReturnNumber() async {
    try {
      final response = await apiClient.get('/purchase-returns/generate-number');

      if (response.statusCode == 200) {
        return response.data['data']['return_number'] as String;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to generate return number',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }
}
