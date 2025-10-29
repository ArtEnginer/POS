import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/socket/socket_service.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

/// Management App Product Repository - ONLINE-ONLY
/// No local database, all operations require internet connection
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SocketService socketService;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.socketService,
  }) {
    // Listen for real-time product updates from other users
    _listenToProductUpdates();
  }

  /// Listen to Socket.IO product updates (real-time sync for multi-user)
  void _listenToProductUpdates() {
    socketService.productUpdates.listen((data) async {
      try {
        print(
          '🔄 [Management App] Real-time product update: ${data['action']}',
        );

        final productData = data['product'];
        if (productData != null) {
          final product = ProductModel.fromJson(productData);
          print('✅ Product ${product.name} ${data['action']} by another user');
          // Note: In Management App, we don't cache locally
          // UI will automatically refresh via BLoC state management
        }
      } catch (e) {
        print('❌ Error processing real-time product update: $e');
      }
    });
  }

  /// Check if online (required for all operations in Management App)
  Future<void> _ensureOnline() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw NetworkException(
        message: 'Management App memerlukan koneksi internet untuk beroperasi',
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      await _ensureOnline();

      // Always fetch from remote (PostgreSQL) with server-side pagination
      final result = await remoteDataSource.getAllProducts(
        page: page,
        limit: limit,
        search: search,
        sortBy: sortBy,
        ascending: ascending,
      );

      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      await _ensureOnline();

      // Fetch from remote with category filter
      // For category filter, we can still get all products from first page
      // or better, add category filter to backend
      final result = await remoteDataSource.getAllProducts(limit: 1000);
      final products = result['products'] as List<Product>;
      final filteredProducts =
          products.where((p) => p.categoryId == categoryId).toList();

      return Right(filteredProducts);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      await _ensureOnline();

      // Fetch single product from remote
      final product = await remoteDataSource.getProductById(id);
      return Right(product);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      await _ensureOnline();

      // Fetch by barcode from remote
      final product = await remoteDataSource.getProductByBarcode(barcode);
      return Right(product);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      await _ensureOnline();

      // Search from remote
      final products = await remoteDataSource.searchProducts(query);
      return Right(products);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    try {
      await _ensureOnline();

      // Get low stock products from remote
      final products = await remoteDataSource.getLowStockProducts();
      return Right(products);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLowStockProductsPaginated({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      await _ensureOnline();

      // Get paginated low stock products from remote
      final result = await remoteDataSource.getLowStockProductsPaginated(
        page: page,
        limit: limit,
        search: search,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Product product) async {
    try {
      await _ensureOnline();

      // Create product on remote (PostgreSQL)
      final productModel = ProductModel.fromEntity(product);
      final createdProduct = await remoteDataSource.createProduct(productModel);

      print('✅ Product created: ${createdProduct.name}');
      return Right(createdProduct);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async {
    try {
      await _ensureOnline();

      // Update product on remote (PostgreSQL)
      final productModel = ProductModel.fromEntity(product);
      final updatedProduct = await remoteDataSource.updateProduct(productModel);

      print('✅ Product updated: ${updatedProduct.name}');
      return Right(updatedProduct);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _ensureOnline();

      // Delete product on remote (PostgreSQL)
      await remoteDataSource.deleteProduct(id);

      print('🗑️ Product deleted: $id');
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(
    String id,
    double quantity, {
    String? branchId,
    String operation = 'set',
  }) async {
    try {
      await _ensureOnline();

      // Update stock on remote (PostgreSQL) with branch and operation
      await remoteDataSource.updateStock(
        id,
        quantity,
        branchId: branchId,
        operation: operation,
      );

      print('✅ Stock updated for product $id: $quantity ($operation)');
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> importProducts(
    String filePath,
  ) async {
    try {
      await _ensureOnline();

      // Import products from file
      final result = await remoteDataSource.importProducts(filePath);

      print('✅ Products imported: ${result['imported']} products');
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadImportTemplate() async {
    try {
      await _ensureOnline();

      // Download template file
      final filePath = await remoteDataSource.downloadImportTemplate();

      print('✅ Template downloaded: $filePath');
      return Right(filePath);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
