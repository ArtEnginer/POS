import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/socket/socket_service.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SocketService socketService;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.socketService,
  }) {
    // Listen for real-time product updates from other users
    _listenToProductUpdates();
  }

  /// Listen to Socket.IO product updates and sync to local cache
  void _listenToProductUpdates() {
    socketService.productUpdates.listen((data) async {
      try {
        print('🔄 Real-time product update received: ${data['action']}');

        // Convert socket data to ProductModel
        final productData = data['product'];
        if (productData != null) {
          final product = ProductModel.fromJson(productData);

          // Update local cache based on action
          switch (data['action']) {
            case 'created':
            case 'updated':
              await localDataSource.upsertProduct(product);
              print('✅ Local cache updated for product: ${product.name}');
              break;
            case 'deleted':
              await localDataSource.deleteProduct(product.id);
              print('🗑️ Local cache deleted for product: ${product.name}');
              break;
          }
        }
      } catch (e) {
        print('❌ Error syncing real-time product update: $e');
      }
    });
  }

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    try {
      // MANAGEMENT: Always fetch from remote when online for data consistency
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Fetch fresh data from PostgreSQL
          final remoteProducts = await remoteDataSource.getAllProducts();

          // CRITICAL: Sync entire dataset to local cache
          // This ensures SQLite always matches PostgreSQL (multi-user consistency)
          await localDataSource.syncAllProducts(remoteProducts);

          return Right(remoteProducts);
        } catch (e) {
          // If remote fails, fallback to local cache (stale data warning)
          print('⚠️ Warning: Using stale local cache due to server error: $e');
          final localProducts = await localDataSource.getAllProducts();
          return Right(localProducts);
        }
      }

      // Offline: use local cache (may be stale)
      print('⚠️ Warning: Offline mode - showing cached data');
      final products = await localDataSource.getAllProducts();
      return Right(products);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final products = await localDataSource.getProductsByCategory(categoryId);
      return Right(products);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final product = await localDataSource.getProductById(id);
      return Right(product);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final product = await localDataSource.getProductByBarcode(barcode);
      return Right(product);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      final products = await localDataSource.searchProducts(query);
      return Right(products);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    try {
      final products = await localDataSource.getLowStockProducts();
      return Right(products);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Product product) async {
    try {
      // MANAGEMENT: Online-only operation
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return Left(
          NetworkFailure(
            message:
                'Tidak dapat menambah produk. Koneksi internet diperlukan untuk management data.',
          ),
        );
      }

      // Send to remote API (PostgreSQL)
      final productModel = ProductModel.fromEntity(product);
      final createdProduct = await remoteDataSource.createProduct(productModel);

      // Update local cache for POS to use (upsert untuk avoid conflicts)
      await localDataSource.upsertProduct(createdProduct);

      return Right(createdProduct);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async {
    try {
      // MANAGEMENT: Online-only operation
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return Left(
          NetworkFailure(
            message:
                'Tidak dapat mengubah produk. Koneksi internet diperlukan untuk management data.',
          ),
        );
      }

      // Send to remote API (PostgreSQL)
      final productModel = ProductModel.fromEntity(product);
      final updatedProduct = await remoteDataSource.updateProduct(productModel);

      // Update local cache for POS to use (upsert untuk consistency)
      await localDataSource.upsertProduct(updatedProduct);

      return Right(updatedProduct);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      // MANAGEMENT: Online-only operation
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return Left(
          NetworkFailure(
            message:
                'Tidak dapat menghapus produk. Koneksi internet diperlukan untuk management data.',
          ),
        );
      }

      // Send to remote API (PostgreSQL)
      await remoteDataSource.deleteProduct(id);

      // Update local cache (soft delete)
      await localDataSource.deleteProduct(id);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(String id, int quantity) async {
    try {
      await localDataSource.updateStock(id, quantity);

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
