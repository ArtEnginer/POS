import '../database/hive_service.dart';
import '../network/api_service.dart';
import '../constants/app_constants.dart';
import '../../features/cashier/data/models/product_model.dart';

class ProductRepository {
  final HiveService _hiveService;
  final ApiService _apiService;

  ProductRepository({
    required HiveService hiveService,
    required ApiService apiService,
  }) : _hiveService = hiveService,
       _apiService = apiService;

  /// Get products from local database
  List<ProductModel> getLocalProducts({String? search, String? categoryId}) {
    try {
      final productsBox = _hiveService.productsBox;
      final products =
          productsBox.values
              .map((data) {
                try {
                  if (data is Map<String, dynamic>) {
                    return ProductModel.fromJson(data);
                  } else if (data is Map) {
                    return ProductModel.fromJson(
                      Map<String, dynamic>.from(data),
                    );
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing product: $e');
                  return null;
                }
              })
              .where((product) => product != null && product.isActive)
              .cast<ProductModel>()
              .toList();

      // Apply filters
      var filtered = products;

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        filtered =
            filtered.where((p) {
              return p.name.toLowerCase().contains(searchLower) ||
                  p.barcode.contains(searchLower) ||
                  (p.categoryName?.toLowerCase().contains(searchLower) ??
                      false);
            }).toList();
      }

      if (categoryId != null) {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }

      return filtered;
    } catch (e) {
      print('Error getting local products: $e');
      return [];
    }
  }

  /// Sync products from server to local
  Future<int> syncProductsFromServer({bool force = false}) async {
    try {
      print('🔄 Syncing products from server...');

      final products = await _apiService.getProducts(
        branchId: AppConstants.currentBranchId,
        limit: 1000, // Get all products
      );

      if (products.isEmpty) {
        print('⚠️ No products received from server');
        return 0;
      }

      final productsBox = _hiveService.productsBox;
      int syncedCount = 0;

      for (final productData in products) {
        try {
          final product = ProductModel.fromJson(productData);

          // Update last synced time
          final updatedProduct = product.copyWith(lastSynced: DateTime.now());

          await productsBox.put(product.id, updatedProduct.toJson());
          syncedCount++;
        } catch (e) {
          print('Error syncing product ${productData['id']}: $e');
        }
      }

      print('✅ Synced $syncedCount products from server');
      return syncedCount;
    } catch (e) {
      print('❌ Error syncing products: $e');
      return 0;
    }
  }

  /// Get product by ID
  ProductModel? getProductById(String id) {
    try {
      final productsBox = _hiveService.productsBox;
      final data = productsBox.get(id);
      if (data != null) {
        if (data is Map<String, dynamic>) {
          return ProductModel.fromJson(data);
        } else if (data is Map) {
          return ProductModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting product by ID: $e');
      return null;
    }
  }

  /// Get product by barcode
  ProductModel? getProductByBarcode(String barcode) {
    try {
      final productsBox = _hiveService.productsBox;
      final products =
          productsBox.values
              .map((data) {
                try {
                  if (data is Map<String, dynamic>) {
                    return ProductModel.fromJson(data);
                  } else if (data is Map) {
                    return ProductModel.fromJson(
                      Map<String, dynamic>.from(data),
                    );
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .where(
                (product) =>
                    product != null &&
                    product.barcode == barcode &&
                    product.isActive,
              )
              .cast<ProductModel>()
              .toList();

      return products.isNotEmpty ? products.first : null;
    } catch (e) {
      print('❌ Error getting product by barcode: $e');
      return null;
    }
  }

  /// Update product stock locally
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      final product = getProductById(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(stock: newStock);
        await _hiveService.productsBox.put(productId, updatedProduct.toJson());
      }
    } catch (e) {
      print('Error updating product stock: $e');
    }
  }

  /// Check if products need sync (older than 1 hour)
  bool needsSync() {
    try {
      final productsBox = _hiveService.productsBox;
      if (productsBox.isEmpty) return true;

      final firstProduct = ProductModel.fromJson(
        Map<String, dynamic>.from(productsBox.values.first),
      );

      if (firstProduct.lastSynced == null) return true;

      final hoursSinceSync =
          DateTime.now().difference(firstProduct.lastSynced!).inHours;
      return hoursSinceSync >= 1;
    } catch (e) {
      return true;
    }
  }

  /// Get total products count
  int getTotalProductsCount() {
    return _hiveService.productsBox.length;
  }

  /// Clear all local products
  Future<void> clearLocalProducts() async {
    await _hiveService.productsBox.clear();
  }
}
