import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
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

  ReceivingLocalDataSourceImpl({required this.databaseHelper});

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
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // 1. Insert receiving header
        await txn.insert(
          'receivings',
          receiving.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // 2. Insert receiving items
        for (var item in receiving.items) {
          await txn.insert(
            'receiving_items',
            (item as ReceivingItemModel).toJson(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          // 3. Update stock based on received quantity
          await txn.rawUpdate(
            '''
            UPDATE products 
            SET stock = stock + ?, 
                updated_at = ?,
                sync_status = 'PENDING'
            WHERE id = ?
          ''',
            [
              item.receivedQuantity,
              DateTime.now().toIso8601String(),
              item.productId,
            ],
          );
        }

        // 4. Update purchase status to RECEIVED (tidak ubah data lain)
        await txn.update(
          'purchases',
          {
            'status': 'RECEIVED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [receiving.purchaseId],
        );
      });

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
      final db = await databaseHelper.database;

      // Get old receiving data untuk stock adjustment
      final oldReceiving = await getReceivingById(receiving.id);

      await db.transaction((txn) async {
        // 1. Update receiving header
        await txn.update(
          'receivings',
          receiving.toJson(),
          where: 'id = ?',
          whereArgs: [receiving.id],
        );

        // 2. Delete old items
        await txn.delete(
          'receiving_items',
          where: 'receiving_id = ?',
          whereArgs: [receiving.id],
        );

        // 3. Reverse old stock (kurangi stock berdasarkan old quantity)
        for (var oldItem in oldReceiving.items) {
          await txn.rawUpdate(
            '''
            UPDATE products 
            SET stock = stock - ?, 
                updated_at = ?,
                sync_status = 'PENDING'
            WHERE id = ?
          ''',
            [
              oldItem.receivedQuantity,
              DateTime.now().toIso8601String(),
              oldItem.productId,
            ],
          );
        }

        // 4. Insert new items & update stock with new quantity
        for (var item in receiving.items) {
          await txn.insert(
            'receiving_items',
            (item as ReceivingItemModel).toJson(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          await txn.rawUpdate(
            '''
            UPDATE products 
            SET stock = stock + ?, 
                updated_at = ?,
                sync_status = 'PENDING'
            WHERE id = ?
          ''',
            [
              item.receivedQuantity,
              DateTime.now().toIso8601String(),
              item.productId,
            ],
          );
        }
      });

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
      final db = await databaseHelper.database;

      // Get receiving data untuk stock reversal
      final receiving = await getReceivingById(id);

      await db.transaction((txn) async {
        // 1. Reverse stock (kurangi stock)
        for (var item in receiving.items) {
          await txn.rawUpdate(
            '''
            UPDATE products 
            SET stock = stock - ?, 
                updated_at = ?,
                sync_status = 'PENDING'
            WHERE id = ?
          ''',
            [
              item.receivedQuantity,
              DateTime.now().toIso8601String(),
              item.productId,
            ],
          );
        }

        // 2. Delete receiving items
        await txn.delete(
          'receiving_items',
          where: 'receiving_id = ?',
          whereArgs: [id],
        );

        // 3. Delete receiving header
        await txn.delete('receivings', where: 'id = ?', whereArgs: [id]);

        // 4. Check if there are other receivings for this purchase
        final otherReceivings = await txn.query(
          'receivings',
          where: 'purchase_id = ?',
          whereArgs: [receiving.purchaseId],
        );

        // 5. If no more receivings, revert purchase status to APPROVED
        if (otherReceivings.isEmpty) {
          await txn.update(
            'purchases',
            {
              'status': 'APPROVED',
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [receiving.purchaseId],
          );
        }
      });
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
      final results = await db.query(
        'receiving_items',
        where: 'receiving_id = ?',
        whereArgs: [receivingId],
      );

      return results.map((json) => ReceivingItemModel.fromJson(json)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get receiving items: $e',
      );
    }
  }
}
