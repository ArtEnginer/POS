import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/product_usecases.dart';
import 'product_event.dart' as event;
import 'product_state.dart';

class ProductBloc extends Bloc<event.ProductEvent, ProductState> {
  final GetAllProducts getAllProducts;
  final GetProductById getProductById;
  final GetProductByBarcode getProductByBarcode;
  final SearchProducts searchProducts;
  final GetLowStockProducts getLowStockProducts;
  final CreateProduct createProduct;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;
  final UpdateProductStock updateProductStock;

  ProductBloc({
    required this.getAllProducts,
    required this.getProductById,
    required this.getProductByBarcode,
    required this.searchProducts,
    required this.getLowStockProducts,
    required this.createProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.updateProductStock,
  }) : super(const ProductInitial()) {
    on<event.LoadProducts>(_onLoadProducts);
    on<event.LoadProductById>(_onLoadProductById);
    on<event.LoadProductByBarcode>(_onLoadProductByBarcode);
    on<event.SearchProducts>(_onSearchProducts);
    on<event.LoadLowStockProducts>(_onLoadLowStockProducts);
    on<event.CreateProduct>(_onCreateProduct);
    on<event.UpdateProduct>(_onUpdateProduct);
    on<event.DeleteProduct>(_onDeleteProduct);
    on<event.UpdateProductStock>(_onUpdateProductStock);
  }

  Future<void> _onLoadProducts(
    event.LoadProducts ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await getAllProducts();

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onLoadProductById(
    event.LoadProductById ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await getProductById(ev.id);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  Future<void> _onLoadProductByBarcode(
    event.LoadProductByBarcode ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await getProductByBarcode(ev.barcode);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  Future<void> _onSearchProducts(
    event.SearchProducts ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await searchProducts(ev.query);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onLoadLowStockProducts(
    event.LoadLowStockProducts ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await getLowStockProducts();

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onCreateProduct(
    event.CreateProduct ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await createProduct(ev.product);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(
        ProductOperationSuccess('Product created successfully', product),
      ),
    );
  }

  Future<void> _onUpdateProduct(
    event.UpdateProduct ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await updateProduct(ev.product);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(
        ProductOperationSuccess('Product updated successfully', product),
      ),
    );
  }

  Future<void> _onDeleteProduct(
    event.DeleteProduct ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await deleteProduct(ev.id);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) =>
          emit(const ProductOperationSuccess('Product deleted successfully')),
    );
  }

  Future<void> _onUpdateProductStock(
    event.UpdateProductStock ev,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    final result = await updateProductStock(ev.id, ev.quantity);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(const ProductOperationSuccess('Stock updated successfully')),
    );
  }
}
