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
  /// Support untuk dataset besar (20k+ products) dengan batch processing
  /// dan incremental sync
  Future<int> syncProductsFromServer({
    bool force = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      print('🔄 Starting product sync...');

      // Cek apakah perlu full sync atau incremental sync
      final lastSyncTime = await _getLastSyncTime();
      final bool needsFullSync = force || lastSyncTime == null;

      if (needsFullSync) {
        print('📥 Performing FULL SYNC...');
        return await _fullSync(onProgress: onProgress);
      } else {
        print(
          '📥 Performing INCREMENTAL SYNC (since ${lastSyncTime.toLocal()})...',
        );
        return await _incrementalSync(
          since: lastSyncTime,
          onProgress: onProgress,
        );
      }
    } catch (e) {
      print('❌ Error syncing products: $e');
      return 0;
    }
  }

  /// Full sync - download semua produk dalam batch
  Future<int> _fullSync({Function(int current, int total)? onProgress}) async {
    try {
      // 1. Dapatkan total count produk
      final totalProducts = await _apiService.getProductsCount(
        branchId: AppConstants.currentBranchId,
      );

      if (totalProducts == 0) {
        print('⚠️ No products found on server');
        return 0;
      }

      print('📊 Total products to sync: $totalProducts');

      // 2. Hitung berapa batch yang dibutuhkan
      const batchSize = 500; // Download 500 products per batch
      final totalBatches = (totalProducts / batchSize).ceil();

      print('📦 Will download in $totalBatches batches ($batchSize per batch)');

      int syncedCount = 0;
      final productsBox = _hiveService.productsBox;

      // 3. Download batch demi batch
      for (int batch = 0; batch < totalBatches; batch++) {
        final page = batch + 1;
        print(
          '📥 Downloading batch ${batch + 1}/$totalBatches (page $page)...',
        );

        final products = await _apiService.getProducts(
          branchId: AppConstants.currentBranchId,
          page: page,
          limit: batchSize,
        );

        if (products.isEmpty) {
          print('⚠️ No products in batch $page');
          break;
        }

        // 4. Simpan ke local database
        for (final productData in products) {
          try {
            final product = ProductModel.fromJson(productData);
            final updatedProduct = product.copyWith(
              lastSynced: DateTime.now(),
              syncVersion: product.syncVersion + 1,
            );

            await productsBox.put(product.id, updatedProduct.toJson());
            syncedCount++;

            // Report progress
            if (onProgress != null) {
              onProgress(syncedCount, totalProducts);
            }
          } catch (e) {
            print('❌ Error saving product ${productData['id']}: $e');
          }
        }

        print(
          '✅ Batch ${batch + 1}/$totalBatches completed ($syncedCount/$totalProducts products)',
        );

        // Small delay untuk tidak overload server
        if (batch < totalBatches - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // 5. Simpan timestamp sync terakhir
      await _saveLastSyncTime(DateTime.now());

      print('✅ Full sync completed: $syncedCount products synced');
      return syncedCount;
    } catch (e) {
      print('❌ Error in full sync: $e');
      return 0;
    }
  }

  /// Incremental sync - hanya download produk yang berubah
  Future<int> _incrementalSync({
    required DateTime since,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      print('📥 Fetching products updated since ${since.toLocal()}...');

      int syncedCount = 0;
      int page = 1;
      const batchSize = 500;
      bool hasMore = true;

      final productsBox = _hiveService.productsBox;

      while (hasMore) {
        final products = await _apiService.getProductsUpdatedSince(
          since: since,
          branchId: AppConstants.currentBranchId,
          page: page,
          limit: batchSize,
        );

        if (products.isEmpty) {
          hasMore = false;
          break;
        }

        for (final productData in products) {
          try {
            final product = ProductModel.fromJson(productData);
            final updatedProduct = product.copyWith(
              lastSynced: DateTime.now(),
              syncVersion: product.syncVersion + 1,
            );

            await productsBox.put(product.id, updatedProduct.toJson());
            syncedCount++;

            if (onProgress != null) {
              onProgress(syncedCount, syncedCount);
            }
          } catch (e) {
            print('❌ Error saving product ${productData['id']}: $e');
          }
        }

        print(
          '✅ Incremental sync page $page: ${products.length} products updated',
        );

        // Jika products kurang dari batch size, berarti sudah habis
        if (products.length < batchSize) {
          hasMore = false;
        } else {
          page++;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Simpan timestamp sync terakhir
      await _saveLastSyncTime(DateTime.now());

      print('✅ Incremental sync completed: $syncedCount products updated');
      return syncedCount;
    } catch (e) {
      print('❌ Error in incremental sync: $e');
      // Jika incremental sync gagal, fallback to minimal sync
      return 0;
    }
  }

  /// Get last sync time dari settings
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final settingsBox = _hiveService.settingsBox;
      final timestamp = settingsBox.get('last_product_sync');
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save last sync time ke settings
  Future<void> _saveLastSyncTime(DateTime time) async {
    try {
      final settingsBox = _hiveService.settingsBox;
      await settingsBox.put('last_product_sync', time.toIso8601String());
    } catch (e) {
      print('❌ Error saving last sync time: $e');
    }
  }

  /// Public method untuk mendapatkan last sync time
  Future<DateTime?> getLastSyncTime() async {
    return _getLastSyncTime();
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
  Future<void> updateProductStock(String productId, double newStock) async {
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
