import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/product_model.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

abstract class ProductRemoteDataSource {
  Future<Map<String, dynamic>> getAllProducts({
    String? branchId,
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    bool ascending = true,
  });
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> getProductByBarcode(String barcode);
  Future<List<ProductModel>> searchProducts(String query, {String? branchId});
  Future<List<ProductModel>> getLowStockProducts({String? branchId});
  Future<Map<String, dynamic>> getLowStockProductsPaginated({
    String? branchId,
    int page = 1,
    int limit = 20,
    String search = '',
  });
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(
    String id,
    double quantity, {
    String? branchId,
    String operation = 'set',
  });
  Future<Map<String, dynamic>> importProducts(String filePath);
  Future<String> downloadImportTemplate();
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
  Future<Map<String, dynamic>> getAllProducts({
    String? branchId,
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      // Build query parameters for server-side pagination
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
        queryParams['sortOrder'] = ascending ? 'asc' : 'desc';
      }

      // Don't send branchId for management - we want all products
      // if (branchId != null) {
      //   queryParams['branchId'] = branchId;
      // }

      final response = await apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final products =
            data.map((json) => ProductModel.fromJson(json)).toList();

        final pagination = response.data['pagination'];

        return {
          'products': products,
          'pagination': {
            'currentPage': pagination['page'] ?? page,
            'totalPages': pagination['totalPages'] ?? 1,
            'totalItems': pagination['total'] ?? products.length,
            'itemsPerPage': pagination['limit'] ?? limit,
          },
        };
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
      // Use /complete endpoint to get units and prices
      final response = await apiClient.get('/products/$id/complete');

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
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final response = await apiClient.get('/products/barcode/$barcode');

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Product not found',
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
  Future<Map<String, dynamic>> getLowStockProductsPaginated({
    String? branchId,
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final currentBranchId =
          branchId ?? await authService.getCurrentBranchId();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (currentBranchId != null) 'branchId': currentBranchId,
      };

      final response = await apiClient.get(
        '/products/low-stock',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final products =
            data.map((json) => ProductModel.fromJson(json)).toList();

        final pagination = response.data['pagination'];

        return {
          'products': products,
          'currentPage': pagination['page'] ?? 1,
          'totalPages': pagination['totalPages'] ?? 1,
          'totalItems': pagination['total'] ?? 0,
          'itemsPerPage': pagination['limit'] ?? limit,
        };
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
  Future<void> updateStock(
    String id,
    double quantity, {
    String? branchId,
    String operation = 'set',
  }) async {
    try {
      // Get current branch if not specified
      final currentBranchId =
          branchId ?? await authService.getCurrentBranchId();

      if (currentBranchId == null) {
        throw app_exceptions.ValidationException(
          message: 'Branch ID is required for stock update',
        );
      }

      // FIX: Use PUT method and send all required parameters
      final response = await apiClient.put(
        '/products/$id/stock',
        data: {
          'branchId': int.parse(currentBranchId),
          'quantity': quantity,
          'operation': operation, // 'set', 'add', or 'subtract'
        },
      );

      if (response.statusCode == 200) {
        // Emit stock updated event via Socket.IO
        _emitStockUpdate(id, quantity, currentBranchId, operation);
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

  void _emitStockUpdate(
    String productId,
    double quantity,
    String branchId,
    String operation,
  ) {
    if (socketService.isConnected) {
      socketService.emit('stock:update', {
        'productId': productId,
        'branchId': branchId,
        'quantity': quantity,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<Map<String, dynamic>> importProducts(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      // Use longer timeout for import (5 minutes for large files)
      final response = await apiClient.post(
        '/products/import',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'total': response.data['data']['total'],
          'imported': response.data['data']['imported'],
          'errors': response.data['data']['errors'],
          'skipped': response.data['data']['skipped'],
          'details': response.data['details'],
        };
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to import products',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> downloadImportTemplate() async {
    try {
      final response = await apiClient.get(
        '/products/import/template',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Get downloads directory
        final directory = await getDownloadsDirectory();
        final filePath = '${directory?.path ?? ''}/template_import_produk.xlsx';

        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        return filePath;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to download template',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }
}
