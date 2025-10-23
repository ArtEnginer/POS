import '../../../../core/database/database_helper.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> getProductByBarcode(String barcode);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getLowStockProducts();
  Future<void> insertProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, int quantity);
  Future<String> generatePLU();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;
  final HybridSyncManager hybridSyncManager;

  ProductLocalDataSourceImpl({
    required this.databaseHelper,
    required this.hybridSyncManager,
  });

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT p.*, c.name as category_name 
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.deleted_at IS NULL AND p.is_active = 1
        ORDER BY p.name ASC
      ''');

      return results.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get products: $e',
      );
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'products',
        where: 'category_id = ? AND deleted_at IS NULL AND is_active = 1',
        whereArgs: [categoryId],
        orderBy: 'name ASC',
      );

      return results.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get products by category: $e',
      );
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery(
        '''
        SELECT p.*, c.name as category_name 
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.id = ? AND p.deleted_at IS NULL
        LIMIT 1
      ''',
        [id],
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }

      return ProductModel.fromJson(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get product: $e',
      );
    }
  }

  @override
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'products',
        where: 'barcode = ? AND deleted_at IS NULL AND is_active = 1',
        whereArgs: [barcode],
        limit: 1,
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }

      return ProductModel.fromJson(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get product by barcode: $e',
      );
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final db = await databaseHelper.database;
      final searchQuery = '%$query%';

      final results = await db.query(
        'products',
        where:
            '(name LIKE ? OR barcode LIKE ?) AND deleted_at IS NULL AND is_active = 1',
        whereArgs: [searchQuery, searchQuery],
        orderBy: 'name ASC',
      );

      return results.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to search products: $e',
      );
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT * FROM products 
        WHERE stock <= min_stock 
        AND deleted_at IS NULL 
        AND is_active = 1
        ORDER BY stock ASC
      ''');

      return results.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get low stock products: $e',
      );
    }
  }

  @override
  Future<void> insertProduct(ProductModel product) async {
    try {
      // ✅ AUTO SYNC: Insert ke local DAN sync ke server jika online
      await hybridSyncManager.insertRecord(
        'products',
        product.toJson(),
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to insert product: $e',
      );
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      // ✅ AUTO SYNC: Update local DAN sync ke server jika online
      final result = await hybridSyncManager.updateRecord(
        'products',
        product.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );

      if (result == 0) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update product: $e',
      );
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final now = DateTime.now().toIso8601String();

      // ✅ AUTO SYNC: Soft delete ke local DAN sync ke server jika online
      final result = await hybridSyncManager.updateRecord(
        'products',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );

      if (result == 0) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete product: $e',
      );
    }
  }

  @override
  Future<void> updateStock(String id, int quantity) async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now().toIso8601String();

      // Get current stock first
      final current = await db.query(
        'products',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (current.isEmpty) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }

      final currentStock = current.first['stock'] as int;
      final newStock = currentStock + quantity;

      // ✅ AUTO SYNC: Update stock ke local DAN sync ke server jika online
      final result = await hybridSyncManager.updateRecord(
        'products',
        {'stock': newStock, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );

      if (result == 0) {
        throw app_exceptions.DatabaseException(message: 'Product not found');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update stock: $e',
      );
    }
  }

  @override
  Future<String> generatePLU() async {
    try {
      final db = await databaseHelper.database;

      // Get the last PLU number
      final results = await db.rawQuery('''
        SELECT plu FROM products 
        WHERE plu IS NOT NULL 
        ORDER BY plu DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (results.isNotEmpty && results.first['plu'] != null) {
        final lastPLU = results.first['plu'] as String;
        // Extract number from PLU (assuming format: PLU00001)
        final numberPart = lastPLU.replaceAll(RegExp(r'[^0-9]'), '');
        if (numberPart.isNotEmpty) {
          nextNumber = int.parse(numberPart) + 1;
        }
      }

      // Format: PLU00001, PLU00002, etc.
      return 'PLU${nextNumber.toString().padLeft(5, '0')}';
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to generate PLU: $e',
      );
    }
  }
}
