import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetAllProducts {
  final ProductRepository repository;

  GetAllProducts(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    bool ascending = true,
  }) async {
    return await repository.getAllProducts(
      page: page,
      limit: limit,
      search: search,
      sortBy: sortBy,
      ascending: ascending,
    );
  }
}

class GetProductById {
  final ProductRepository repository;

  GetProductById(this.repository);

  Future<Either<Failure, Product>> call(String id) async {
    return await repository.getProductById(id);
  }
}

class GetProductByBarcode {
  final ProductRepository repository;

  GetProductByBarcode(this.repository);

  Future<Either<Failure, Product>> call(String barcode) async {
    return await repository.getProductByBarcode(barcode);
  }
}

class SearchProducts {
  final ProductRepository repository;

  SearchProducts(this.repository);

  Future<Either<Failure, List<Product>>> call(String query) async {
    return await repository.searchProducts(query);
  }
}

class GetLowStockProducts {
  final ProductRepository repository;

  GetLowStockProducts(this.repository);

  Future<Either<Failure, List<Product>>> call() async {
    return await repository.getLowStockProducts();
  }
}

class GetLowStockProductsPaginated {
  final ProductRepository repository;

  GetLowStockProductsPaginated(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    return await repository.getLowStockProductsPaginated(
      page: page,
      limit: limit,
      search: search,
    );
  }
}

class CreateProduct {
  final ProductRepository repository;

  CreateProduct(this.repository);

  Future<Either<Failure, Product>> call(Product product) async {
    return await repository.createProduct(product);
  }
}

class UpdateProduct {
  final ProductRepository repository;

  UpdateProduct(this.repository);

  Future<Either<Failure, Product>> call(Product product) async {
    return await repository.updateProduct(product);
  }
}

class DeleteProduct {
  final ProductRepository repository;

  DeleteProduct(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteProduct(id);
  }
}

class UpdateProductStock {
  final ProductRepository repository;

  UpdateProductStock(this.repository);

  Future<Either<Failure, void>> call(String id, double quantity) async {
    return await repository.updateStock(id, quantity);
  }
}

class ImportProducts {
  final ProductRepository repository;

  ImportProducts(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String filePath) async {
    return await repository.importProducts(filePath);
  }
}

class DownloadImportTemplate {
  final ProductRepository repository;

  DownloadImportTemplate(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.downloadImportTemplate();
  }
}
