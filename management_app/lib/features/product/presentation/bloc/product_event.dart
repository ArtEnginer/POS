import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class LoadProductById extends ProductEvent {
  final String id;

  const LoadProductById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadProductsByCategory extends ProductEvent {
  final String categoryId;

  const LoadProductsByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadProductByBarcode extends ProductEvent {
  final String barcode;

  const LoadProductByBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class LoadLowStockProducts extends ProductEvent {
  const LoadLowStockProducts();
}

class CreateProduct extends ProductEvent {
  final Product product;

  const CreateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String id;

  const DeleteProduct(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateProductStock extends ProductEvent {
  final String id;
  final double quantity;

  const UpdateProductStock(this.id, this.quantity);

  @override
  List<Object?> get props => [id, quantity];
}
