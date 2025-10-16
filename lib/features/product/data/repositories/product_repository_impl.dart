import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;
  final SyncManager syncManager;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.syncManager,
  });

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    try {
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
      final productModel = ProductModel.fromEntity(product);
      await localDataSource.insertProduct(productModel);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'products',
        recordId: product.id,
        operation: 'INSERT',
        data: productModel.toJson(),
      );

      return Right(productModel);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      await localDataSource.updateProduct(productModel);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'products',
        recordId: product.id,
        operation: 'UPDATE',
        data: productModel.toJson(),
      );

      return Right(productModel);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await localDataSource.deleteProduct(id);

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'products',
        recordId: id,
        operation: 'DELETE',
        data: {'id': id},
      );

      return const Right(null);
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

      // Add to sync queue
      await syncManager.addToSyncQueue(
        tableName: 'products',
        recordId: id,
        operation: 'UPDATE',
        data: {'id': id, 'stock_change': quantity},
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
