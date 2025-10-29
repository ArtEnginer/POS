import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  const ProductLoaded(
    this.products, {
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.itemsPerPage = 20,
  });

  @override
  List<Object?> get props => [
    products,
    currentPage,
    totalPages,
    totalItems,
    itemsPerPage,
  ];
}

class ProductDetailLoaded extends ProductState {
  final Product product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductOperationSuccess extends ProductState {
  final String message;
  final Product? product;

  const ProductOperationSuccess(this.message, [this.product]);

  @override
  List<Object?> get props => [message, product];
}

class ProductImportSuccess extends ProductState {
  final String message;
  final Map<String, dynamic> details;

  const ProductImportSuccess(this.message, this.details);

  @override
  List<Object?> get props => [message, details];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
