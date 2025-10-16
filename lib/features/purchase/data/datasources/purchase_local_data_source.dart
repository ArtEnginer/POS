import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
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

  PurchaseLocalDataSourceImpl({required this.databaseHelper});

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
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Insert purchase header
        await txn.insert(
          'purchases',
          purchase.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // Insert purchase items
        for (var item in purchase.items) {
          await txn.insert(
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
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // NOTE: Stock update removed - will be handled by Receiving process
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to insert purchase: $e',
      );
    }
  }

  @override
  Future<void> updatePurchase(PurchaseModel purchase) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Update purchase header
        await txn.update(
          'purchases',
          purchase.toJson(),
          where: 'id = ?',
          whereArgs: [purchase.id],
        );

        // Delete old items
        await txn.delete(
          'purchase_items',
          where: 'purchase_id = ?',
          whereArgs: [purchase.id],
        );

        // Insert new items
        for (var item in purchase.items) {
          await txn.insert(
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
          );
        }
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update purchase: $e',
      );
    }
  }

  @override
  Future<void> deletePurchase(String id) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Delete purchase items
        await txn.delete(
          'purchase_items',
          where: 'purchase_id = ?',
          whereArgs: [id],
        );

        // Delete purchase
        await txn.delete('purchases', where: 'id = ?', whereArgs: [id]);
      });
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

      await db.transaction((txn) async {
        // Get purchase items INSIDE transaction using txn
        final itemResults = await txn.query(
          'purchase_items',
          where: 'purchase_id = ?',
          whereArgs: [id],
        );

        final items =
            itemResults
                .map((json) => PurchaseItemModel.fromJson(json))
                .toList();

        // Update stock for each item
        for (var item in items) {
          await txn.rawUpdate(
            '''
            UPDATE products 
            SET stock = stock + ?, 
                updated_at = ?,
                sync_status = 'PENDING'
            WHERE id = ?
          ''',
            [item.quantity, DateTime.now().toIso8601String(), item.productId],
          );
        }

        // Update purchase status to RECEIVED
        await txn.update(
          'purchases',
          {
            'status': 'RECEIVED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
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
