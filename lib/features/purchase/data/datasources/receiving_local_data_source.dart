import '../../../../core/database/database_helper.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/receiving_model.dart';

abstract class ReceivingLocalDataSource {
  Future<List<ReceivingModel>> getAllReceivings();
  Future<ReceivingModel> getReceivingById(String id);
  Future<List<ReceivingModel>> getReceivingsByPurchaseId(String purchaseId);
  Future<List<ReceivingModel>> searchReceivings(String query);
  Future<ReceivingModel> createReceiving(ReceivingModel receiving);
  Future<ReceivingModel> updateReceiving(ReceivingModel receiving);
  Future<void> deleteReceiving(String id);
  Future<String> generateReceivingNumber();
}

class ReceivingLocalDataSourceImpl implements ReceivingLocalDataSource {
  final DatabaseHelper databaseHelper;
  final HybridSyncManager hybridSyncManager;

  ReceivingLocalDataSourceImpl({
    required this.databaseHelper,
    required this.hybridSyncManager,
  });

  @override
  Future<List<ReceivingModel>> getAllReceivings() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'receivings',
        orderBy: 'receiving_date DESC, created_at DESC',
      );

      final receivings = <ReceivingModel>[];
      for (var json in results) {
        final receiving = ReceivingModel.fromJson(json);
        final items = await _getReceivingItems(receiving.id);
        receivings.add(
          ReceivingModel.fromEntity(receiving.copyWith(items: items)),
        );
      }

      return receivings;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get receivings: $e',
      );
    }
  }

  @override
  Future<ReceivingModel> getReceivingById(String id) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'receivings',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException(message: 'Receiving not found');
      }

      final receiving = ReceivingModel.fromJson(results.first);
      final items = await _getReceivingItems(id);

      return ReceivingModel.fromEntity(receiving.copyWith(items: items));
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get receiving: $e',
      );
    }
  }

  @override
  Future<List<ReceivingModel>> getReceivingsByPurchaseId(
    String purchaseId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'receivings',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
        orderBy: 'receiving_date DESC',
      );

      final receivings = <ReceivingModel>[];
      for (var json in results) {
        final receiving = ReceivingModel.fromJson(json);
        final items = await _getReceivingItems(receiving.id);
        receivings.add(
          ReceivingModel.fromEntity(receiving.copyWith(items: items)),
        );
      }

      return receivings;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get receivings by purchase: $e',
      );
    }
  }

  @override
  Future<List<ReceivingModel>> searchReceivings(String query) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery(
        '''
        SELECT * FROM receivings
        WHERE receiving_number LIKE ? 
           OR purchase_number LIKE ?
           OR supplier_name LIKE ?
           OR notes LIKE ?
        ORDER BY receiving_date DESC
      ''',
        ['%$query%', '%$query%', '%$query%', '%$query%'],
      );

      final receivings = <ReceivingModel>[];
      for (var json in results) {
        final receiving = ReceivingModel.fromJson(json);
        final items = await _getReceivingItems(receiving.id);
        receivings.add(
          ReceivingModel.fromEntity(receiving.copyWith(items: items)),
        );
      }

      return receivings;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to search receivings: $e',
      );
    }
  }

  @override
  Future<ReceivingModel> createReceiving(ReceivingModel receiving) async {
    try {
      // ✅ AUTO SYNC: Insert receiving header ke local DAN sync ke server
      await hybridSyncManager.insertRecord(
        'receivings',
        receiving.toJson(),
        syncImmediately: true,
      );

      print(
        'DEBUG: Inserting receiving items, count: ${receiving.items.length}',
      );

      // ✅ AUTO SYNC: Insert receiving items ke local DAN sync ke server
      for (var item in receiving.items) {
        final itemJson = (item as ReceivingItemModel).toJson();
        print(
          'DEBUG: Inserting item: ${item.productName}, receiving_id: ${itemJson['receiving_id']}',
        );

        await hybridSyncManager.insertRecord(
          'receiving_items',
          itemJson,
          syncImmediately: true,
        );
      }

      print('DEBUG: All items inserted successfully');

      // 3. Update stock based on received quantity menggunakan HybridSyncManager
      // DIPINDAHKAN KELUAR dari transaction untuk menghindari deadlock
      final db = await databaseHelper.database;
      final now = DateTime.now().toIso8601String();
      for (var item in receiving.items) {
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
          final newStock = currentStock + item.receivedQuantity;

          // Update via HybridSyncManager untuk auto-sync
          await hybridSyncManager.updateRecord(
            'products',
            {'stock': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [item.productId],
            syncImmediately: true,
          );
        }
      }

      // 4. Update purchase status to RECEIVED menggunakan HybridSyncManager untuk auto-sync
      await hybridSyncManager.updateRecord(
        'purchases',
        {'status': 'RECEIVED', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [receiving.purchaseId],
        syncImmediately: true,
      );

      return await getReceivingById(receiving.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to create receiving: $e',
      );
    }
  }

  @override
  Future<ReceivingModel> updateReceiving(ReceivingModel receiving) async {
    try {
      // Get old receiving data untuk stock adjustment
      final oldReceiving = await getReceivingById(receiving.id);

      // ✅ AUTO SYNC: Update receiving header ke local DAN sync ke server
      await hybridSyncManager.updateRecord(
        'receivings',
        receiving.toJson(),
        where: 'id = ?',
        whereArgs: [receiving.id],
        syncImmediately: true,
      );

      final db = await databaseHelper.database;
      final now = DateTime.now().toIso8601String();

      // ✅ AUTO SYNC: Delete old items dari local DAN sync ke server
      final oldItems = await db.query(
        'receiving_items',
        where: 'receiving_id = ?',
        whereArgs: [receiving.id],
      );

      for (var oldItem in oldItems) {
        await hybridSyncManager.deleteRecord(
          'receiving_items',
          where: 'id = ?',
          whereArgs: [oldItem['id']],
          syncImmediately: true,
        );
      }

      // ✅ AUTO SYNC: Insert new items ke local DAN sync ke server
      for (var item in receiving.items) {
        await hybridSyncManager.insertRecord(
          'receiving_items',
          (item as ReceivingItemModel).toJson(),
          syncImmediately: true,
        );
      }

      // 3. Reverse old stock & apply new stock menggunakan HybridSyncManager
      for (var oldItem in oldReceiving.items) {
        // Get current stock
        final db = await databaseHelper.database;
        final productResult = await db.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [oldItem.productId],
          limit: 1,
        );

        if (productResult.isNotEmpty) {
          final currentStock = productResult.first['stock'] as int;
          final newStock = currentStock - oldItem.receivedQuantity;

          // Update via HybridSyncManager
          await hybridSyncManager.updateRecord(
            'products',
            {'stock': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [oldItem.productId],
            syncImmediately: true,
          );
        }
      }

      // Apply new quantities
      for (var item in receiving.items) {
        // Get current stock
        final db = await databaseHelper.database;
        final productResult = await db.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (productResult.isNotEmpty) {
          final currentStock = productResult.first['stock'] as int;
          final newStock = currentStock + item.receivedQuantity;

          // Update via HybridSyncManager
          await hybridSyncManager.updateRecord(
            'products',
            {'stock': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [item.productId],
            syncImmediately: true,
          );
        }
      }

      return await getReceivingById(receiving.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update receiving: $e',
      );
    }
  }

  @override
  Future<void> deleteReceiving(String id) async {
    try {
      // Get receiving data untuk stock reversal
      final receiving = await getReceivingById(id);

      final db = await databaseHelper.database;
      final now = DateTime.now().toIso8601String();

      // 1. Reverse stock (kurangi stock) menggunakan HybridSyncManager
      for (var item in receiving.items) {
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
          final newStock = currentStock - item.receivedQuantity;

          // Update via HybridSyncManager
          await hybridSyncManager.updateRecord(
            'products',
            {'stock': newStock, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [item.productId],
            syncImmediately: true,
          );
        }
      }

      // ✅ AUTO SYNC: Delete receiving items dari local DAN sync ke server
      final items = await db.query(
        'receiving_items',
        where: 'receiving_id = ?',
        whereArgs: [id],
      );

      for (var item in items) {
        await hybridSyncManager.deleteRecord(
          'receiving_items',
          where: 'id = ?',
          whereArgs: [item['id']],
          syncImmediately: true,
        );
      }

      // 3. Delete receiving header menggunakan HybridSyncManager untuk auto-sync
      await hybridSyncManager.deleteRecord(
        'receivings',
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );

      // 4. Check if there are other receivings for this purchase
      final otherReceivings = await db.query(
        'receivings',
        where: 'purchase_id = ?',
        whereArgs: [receiving.purchaseId],
      );

      // 5. If no more receivings, revert purchase status to APPROVED menggunakan HybridSyncManager
      if (otherReceivings.isEmpty) {
        await hybridSyncManager.updateRecord(
          'purchases',
          {
            'status': 'APPROVED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [receiving.purchaseId],
          syncImmediately: true,
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete receiving: $e',
      );
    }
  }

  @override
  Future<String> generateReceivingNumber() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      return 'RCV-$dateStr-$timeStr';
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to generate receiving number: $e',
      );
    }
  }

  Future<List<ReceivingItemModel>> _getReceivingItems(
    String receivingId,
  ) async {
    try {
      final db = await databaseHelper.database;

      // Debug: Check if receiving_items table has data
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM receiving_items WHERE receiving_id = ?',
        [receivingId],
      );
      print(
        'DEBUG: receiving_id=$receivingId, items count in DB: ${countResult.first['count']}',
      );

      final results = await db.query(
        'receiving_items',
        where: 'receiving_id = ?',
        whereArgs: [receivingId],
      );

      print('DEBUG: Query results count: ${results.length}');
      if (results.isNotEmpty) {
        print('DEBUG: First item data: ${results.first}');
      }

      return results.map((json) => ReceivingItemModel.fromJson(json)).toList();
    } catch (e) {
      print('DEBUG ERROR in _getReceivingItems: $e');
      throw app_exceptions.DatabaseException(
        message: 'Failed to get receiving items: $e',
      );
    }
  }
}
