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
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    try {
      await _ensureOnline();

      // Always fetch from remote (PostgreSQL)
      final products = await remoteDataSource.getAllProducts();
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
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      await _ensureOnline();

      // Fetch from remote with category filter
      final allProducts = await remoteDataSource.getAllProducts();
      final filteredProducts =
          allProducts.where((p) => p.categoryId == categoryId).toList();

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
}
