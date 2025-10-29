import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, Map<String, dynamic>>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    bool ascending = true,
  });
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  );
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, Product>> getProductByBarcode(String barcode);
  Future<Either<Failure, List<Product>>> searchProducts(String query);
  Future<Either<Failure, List<Product>>> getLowStockProducts();
  Future<Either<Failure, Map<String, dynamic>>> getLowStockProductsPaginated({
    int page = 1,
    int limit = 20,
    String search = '',
  });
  Future<Either<Failure, Product>> createProduct(Product product);
  Future<Either<Failure, Product>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, void>> updateStock(
    String id,
    double quantity, {
    String? branchId,
    String operation = 'set',
  });
  Future<Either<Failure, Map<String, dynamic>>> importProducts(String filePath);
  Future<Either<Failure, String>> downloadImportTemplate();
}
