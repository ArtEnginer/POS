import '../../../../core/database/database_helper.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../domain/entities/purchase.dart';
import '../models/purchase_model.dart';

abstract class PurchaseLocalDataSource {
  Future<List<PurchaseModel>> getAllPurchases();
  Future<PurchaseModel> getPurchaseById(String id);
  Future<List<PurchaseModel>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<PurchaseModel>> searchPurchases(String query);
  Future<void> insertPurchase(PurchaseModel purchase);
  Future<void> updatePurchase(PurchaseModel purchase);
  Future<void> deletePurchase(String id);
  Future<String> generatePurchaseNumber();
  Future<void> receivePurchase(String id); // New method for receiving
}

class PurchaseLocalDataSourceImpl implements PurchaseLocalDataSource {
  final DatabaseHelper databaseHelper;
  final HybridSyncManager hybridSyncManager;

  PurchaseLocalDataSourceImpl({
    required this.databaseHelper,
    required this.hybridSyncManager,
  });

  @override
  Future<List<PurchaseModel>> getAllPurchases() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchases',
        orderBy: 'purchase_date DESC, created_at DESC',
      );

      final purchases = <PurchaseModel>[];
      for (var json in results) {
        final purchase = PurchaseModel.fromJson(json);
        final items = await _getPurchaseItems(purchase.id);
        purchases.add(
          PurchaseModel.fromEntity(purchase.copyWith(items: items)),
        );
      }

      return purchases;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchases: $e',
      );
    }
  }

  @override
  Future<PurchaseModel> getPurchaseById(String id) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException(message: 'Purchase not found');
      }

      final purchase = PurchaseModel.fromJson(results.first);
      final items = await _getPurchaseItems(id);

      return PurchaseModel.fromEntity(purchase.copyWith(items: items));
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchase: $e',
      );
    }
  }

  @override
  Future<List<PurchaseModel>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchases',
        where: 'purchase_date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'purchase_date DESC',
      );

      final purchases = <PurchaseModel>[];
      for (var json in results) {
        final purchase = PurchaseModel.fromJson(json);
        final items = await _getPurchaseItems(purchase.id);
        purchases.add(
          PurchaseModel.fromEntity(purchase.copyWith(items: items)),
        );
      }

      return purchases;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchases by date: $e',
      );
    }
  }

  @override
  Future<List<PurchaseModel>> searchPurchases(String query) async {
    try {
      final db = await databaseHelper.database;
      final searchQuery = '%$query%';

      final results = await db.query(
        'purchases',
        where: 'purchase_number LIKE ? OR supplier_name LIKE ?',
        whereArgs: [searchQuery, searchQuery],
        orderBy: 'purchase_date DESC',
      );

      final purchases = <PurchaseModel>[];
      for (var json in results) {
        final purchase = PurchaseModel.fromJson(json);
        final items = await _getPurchaseItems(purchase.id);
        purchases.add(
          PurchaseModel.fromEntity(purchase.copyWith(items: items)),
        );
      }

      return purchases;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to search purchases: $e',
      );
    }
  }

  @override
  Future<void> insertPurchase(PurchaseModel purchase) async {
    try {
      // ✅ AUTO SYNC: Insert ke local DAN sync ke server jika online
      await hybridSyncManager.insertRecord(
        'purchases',
        purchase.toJson(),
        syncImmediately: true,
      );

      // ✅ AUTO SYNC: Insert purchase items ke local DAN sync ke server
      for (var item in purchase.items) {
        await hybridSyncManager.insertRecord(
          'purchase_items',
          PurchaseItemModel.fromJson({
            'id': item.id,
            'purchase_id': item.purchaseId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'subtotal': item.subtotal,
            'created_at': item.createdAt.toIso8601String(),
          }).toJson(),
          syncImmediately: true,
        );
      }

      // NOTE: Stock update removed - will be handled by Receiving process
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to insert purchase: $e',
      );
    }
  }

  @override
  Future<void> updatePurchase(PurchaseModel purchase) async {
    try {
      // ✅ AUTO SYNC: Update local DAN sync ke server jika online
      await hybridSyncManager.updateRecord(
        'purchases',
        purchase.toJson(),
        where: 'id = ?',
        whereArgs: [purchase.id],
        syncImmediately: true,
      );

      // ✅ AUTO SYNC: Delete old items dari local DAN sync ke server
      final db = await databaseHelper.database;
      final oldItems = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchase.id],
      );

      for (var oldItem in oldItems) {
        await hybridSyncManager.deleteRecord(
          'purchase_items',
          where: 'id = ?',
          whereArgs: [oldItem['id']],
          syncImmediately: true,
        );
      }

      // ✅ AUTO SYNC: Insert new items ke local DAN sync ke server
      for (var item in purchase.items) {
        await hybridSyncManager.insertRecord(
          'purchase_items',
          PurchaseItemModel.fromJson({
            'id': item.id,
            'purchase_id': item.purchaseId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'subtotal': item.subtotal,
            'created_at': item.createdAt.toIso8601String(),
          }).toJson(),
          syncImmediately: true,
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update purchase: $e',
      );
    }
  }

  @override
  Future<void> deletePurchase(String id) async {
    try {
      // ✅ AUTO SYNC: Delete purchase items dari local DAN sync ke server
      final db = await databaseHelper.database;
      final items = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
      );

      for (var item in items) {
        await hybridSyncManager.deleteRecord(
          'purchase_items',
          where: 'id = ?',
          whereArgs: [item['id']],
          syncImmediately: true,
        );
      }

      // ✅ AUTO SYNC: Delete purchase header dari local DAN sync ke server
      await hybridSyncManager.deleteRecord(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete purchase: $e',
      );
    }
  }

  @override
  Future<String> generatePurchaseNumber() async {
    try {
      final db = await databaseHelper.database;
      final today = DateTime.now();
      final dateStr =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // Get count of purchases today
      final results = await db.rawQuery('''
        SELECT COUNT(*) as count FROM purchases 
        WHERE purchase_number LIKE 'PO-$dateStr-%'
      ''');

      final count = results.first['count'] as int;
      final nextNumber = (count + 1).toString().padLeft(4, '0');

      return 'PO-$dateStr-$nextNumber';
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to generate purchase number: $e',
      );
    }
  }

  @override
  Future<void> receivePurchase(String id) async {
    try {
      final db = await databaseHelper.database;

      // Get purchase items first
      final itemResults = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
      );

      final items =
          itemResults.map((json) => PurchaseItemModel.fromJson(json)).toList();

      // Update stock for each item using HybridSyncManager
      final now = DateTime.now().toIso8601String();
      for (var item in items) {
        // Get current stock
        final productResult = await db.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (productResult.isNotEmpty) {
          final currentStock = productResult.first['stock'] as int;
          final newStock = currentStock + item.quantity;

          // ✅ AUTO SYNC: Update stock menggunakan HybridSyncManager
          await hybridSyncManager.updateRecord(
            'products',
            {'stock': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [item.productId],
            syncImmediately: true,
          );
        }
      }

      // ✅ AUTO SYNC: Update purchase status ke local DAN sync ke server
      await hybridSyncManager.updateRecord(
        'purchases',
        {'status': 'RECEIVED'},
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to receive purchase: $e',
      );
    }
  }

  Future<List<PurchaseItem>> _getPurchaseItems(String purchaseId) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      return results.map((json) => PurchaseItemModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
