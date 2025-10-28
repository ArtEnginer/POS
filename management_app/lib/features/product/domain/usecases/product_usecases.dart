import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetAllProducts {
  final ProductRepository repository;

  GetAllProducts(this.repository);

  Future<Either<Failure, List<Product>>> call() async {
    return await repository.getAllProducts();
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
