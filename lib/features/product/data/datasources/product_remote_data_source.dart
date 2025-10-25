import '../../../../core/database/database_helper.dart';
// import hybrid_sync_manager; // DELETED
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getAllProducts({String? branchId});
  Future<ProductModel> getProductById(String id);
  Future<List<ProductModel>> searchProducts(String query, {String? branchId});
  Future<List<ProductModel>> getLowStockProducts({String? branchId});
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, int quantity);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  ProductRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<ProductModel>> getAllProducts({String? branchId}) async {
    try {
      final currentBranchId =
          branchId ?? await authService.getCurrentBranchId();

      final response = await apiClient.get(
        '/products',
        queryParameters: {
          if (currentBranchId != null) 'branchId': currentBranchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load products',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await apiClient.get('/products/$id');

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load product',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    String? branchId,
  }) async {
    try {
      final currentBranchId =
          branchId ?? await authService.getCurrentBranchId();

      final response = await apiClient.get(
        '/products/search',
        queryParameters: {
          'q': query,
          if (currentBranchId != null) 'branchId': currentBranchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search products',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts({String? branchId}) async {
    try {
      final currentBranchId =
          branchId ?? await authService.getCurrentBranchId();

      final response = await apiClient.get(
        '/products/low-stock',
        queryParameters: {
          if (currentBranchId != null) 'branchId': currentBranchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load low stock products',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await apiClient.post(
        '/products',
        data: product.toJson(),
      );

      if (response.statusCode == 201) {
        final newProduct = ProductModel.fromJson(response.data['data']);

        // Emit product created event via Socket.IO
        _emitProductUpdate('created', newProduct);

        return newProduct;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to create product',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await apiClient.put(
        '/products/${product.id}',
        data: product.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedProduct = ProductModel.fromJson(response.data['data']);

        // Emit product updated event via Socket.IO
        _emitProductUpdate('updated', updatedProduct);

        return updatedProduct;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update product',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final response = await apiClient.delete('/products/$id');

      if (response.statusCode == 200) {
        // Emit product deleted event via Socket.IO
        _emitProductDelete(id);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to delete product',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateStock(String id, int quantity) async {
    try {
      final response = await apiClient.patch(
        '/products/$id/stock',
        data: {'quantity': quantity},
      );

      if (response.statusCode == 200) {
        // Emit stock updated event via Socket.IO
        _emitStockUpdate(id, quantity);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update stock',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  // Helper methods for Socket.IO events
  void _emitProductUpdate(String action, ProductModel product) {
    if (socketService.isConnected) {
      socketService.emit('product:update', {
        'action': action,
        'productId': product.id,
        'branchId': product.branchId,
        'product': product.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitProductDelete(String productId) {
    if (socketService.isConnected) {
      socketService.emit('product:update', {
        'action': 'deleted',
        'productId': productId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitStockUpdate(String productId, int quantity) {
    if (socketService.isConnected) {
      socketService.emit('stock:update', {
        'productId': productId,
        'quantity': quantity,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
