import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/purchase_return_model.dart';

abstract class PurchaseReturnLocalDataSource {
  Future<List<PurchaseReturnModel>> getAllPurchaseReturns();
  Future<PurchaseReturnModel> getPurchaseReturnById(String id);
  Future<List<PurchaseReturnModel>> getPurchaseReturnsByReceivingId(
    String receivingId,
  );
  Future<List<PurchaseReturnModel>> searchPurchaseReturns(String query);
  Future<PurchaseReturnModel> createPurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  );
  Future<PurchaseReturnModel> updatePurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  );
  Future<void> deletePurchaseReturn(String id);
  Future<String> generateReturnNumber();
}

class PurchaseReturnLocalDataSourceImpl
    implements PurchaseReturnLocalDataSource {
  final DatabaseHelper databaseHelper;

  PurchaseReturnLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<PurchaseReturnModel>> getAllPurchaseReturns() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchase_returns',
        orderBy: 'return_date DESC, created_at DESC',
      );

      final returns = <PurchaseReturnModel>[];
      for (var json in results) {
        final purchaseReturn = PurchaseReturnModel.fromJson(json);
        final items = await _getPurchaseReturnItems(purchaseReturn.id);
        returns.add(
          PurchaseReturnModel.fromEntity(purchaseReturn.copyWith(items: items)),
        );
      }

      return returns;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchase returns: $e',
      );
    }
  }

  @override
  Future<PurchaseReturnModel> getPurchaseReturnById(String id) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchase_returns',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException(
          message: 'Purchase return not found',
        );
      }

      final purchaseReturn = PurchaseReturnModel.fromJson(results.first);
      final items = await _getPurchaseReturnItems(id);

      return PurchaseReturnModel.fromEntity(
        purchaseReturn.copyWith(items: items),
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchase return: $e',
      );
    }
  }

  @override
  Future<List<PurchaseReturnModel>> getPurchaseReturnsByReceivingId(
    String receivingId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchase_returns',
        where: 'receiving_id = ?',
        whereArgs: [receivingId],
        orderBy: 'return_date DESC',
      );

      final returns = <PurchaseReturnModel>[];
      for (var json in results) {
        final purchaseReturn = PurchaseReturnModel.fromJson(json);
        final items = await _getPurchaseReturnItems(purchaseReturn.id);
        returns.add(
          PurchaseReturnModel.fromEntity(purchaseReturn.copyWith(items: items)),
        );
      }

      return returns;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchase returns by receiving: $e',
      );
    }
  }

  @override
  Future<List<PurchaseReturnModel>> searchPurchaseReturns(String query) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery(
        '''
        SELECT * FROM purchase_returns
        WHERE return_number LIKE ? 
           OR receiving_number LIKE ?
           OR purchase_number LIKE ?
           OR supplier_name LIKE ?
           OR notes LIKE ?
        ORDER BY return_date DESC
      ''',
        ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      );

      final returns = <PurchaseReturnModel>[];
      for (var json in results) {
        final purchaseReturn = PurchaseReturnModel.fromJson(json);
        final items = await _getPurchaseReturnItems(purchaseReturn.id);
        returns.add(
          PurchaseReturnModel.fromEntity(purchaseReturn.copyWith(items: items)),
        );
      }

      return returns;
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to search purchase returns: $e',
      );
    }
  }

  @override
  Future<PurchaseReturnModel> createPurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  ) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // 1. Insert purchase return header (without items)
        await txn.insert(
          'purchase_returns',
          purchaseReturn.toJsonForDb(), // ✅ Use toJsonForDb to exclude items
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // 2. Insert purchase return items
        for (var item in purchaseReturn.items) {
          final itemModel = PurchaseReturnItemModel.fromEntity(item);
          await txn.insert(
            'purchase_return_items',
            itemModel.toJson(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // 3. Update stock if status is COMPLETED
        if (purchaseReturn.status == 'COMPLETED') {
          for (var item in purchaseReturn.items) {
            await _updateProductStock(
              txn,
              item.productId,
              -item.returnQuantity,
            );
          }
        }
      });

      return await getPurchaseReturnById(purchaseReturn.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to create purchase return: $e',
      );
    }
  }

  @override
  Future<PurchaseReturnModel> updatePurchaseReturn(
    PurchaseReturnModel purchaseReturn,
  ) async {
    try {
      final db = await databaseHelper.database;

      // Get old data for stock adjustment
      final oldReturn = await getPurchaseReturnById(purchaseReturn.id);

      await db.transaction((txn) async {
        // 1. Update purchase return header (without items)
        await txn.update(
          'purchase_returns',
          purchaseReturn.toJsonForDb(), // ✅ Use toJsonForDb to exclude items
          where: 'id = ?',
          whereArgs: [purchaseReturn.id],
        );

        // 2. Delete old items
        await txn.delete(
          'purchase_return_items',
          where: 'return_id = ?',
          whereArgs: [purchaseReturn.id],
        );

        // 3. Insert new items
        for (var item in purchaseReturn.items) {
          final itemModel = PurchaseReturnItemModel.fromEntity(item);
          await txn.insert(
            'purchase_return_items',
            itemModel.toJson(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        // 4. Adjust stock if needed
        // Reverse old stock adjustment if it was COMPLETED
        if (oldReturn.status == 'COMPLETED') {
          for (var item in oldReturn.items) {
            await _updateProductStock(txn, item.productId, item.returnQuantity);
          }
        }

        // Apply new stock adjustment if status is COMPLETED
        if (purchaseReturn.status == 'COMPLETED') {
          for (var item in purchaseReturn.items) {
            await _updateProductStock(
              txn,
              item.productId,
              -item.returnQuantity,
            );
          }
        }
      });

      return await getPurchaseReturnById(purchaseReturn.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update purchase return: $e',
      );
    }
  }

  @override
  Future<void> deletePurchaseReturn(String id) async {
    try {
      final db = await databaseHelper.database;

      // Get return data for stock adjustment
      final purchaseReturn = await getPurchaseReturnById(id);

      await db.transaction((txn) async {
        // 1. Reverse stock if status was COMPLETED
        if (purchaseReturn.status == 'COMPLETED') {
          for (var item in purchaseReturn.items) {
            await _updateProductStock(txn, item.productId, item.returnQuantity);
          }
        }

        // 2. Delete items
        await txn.delete(
          'purchase_return_items',
          where: 'return_id = ?',
          whereArgs: [id],
        );

        // 3. Delete header
        await txn.delete('purchase_returns', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete purchase return: $e',
      );
    }
  }

  @override
  Future<String> generateReturnNumber() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();
      final prefix = 'RTN-${DateFormat('yyyyMM').format(now)}-';

      final result = await db.rawQuery(
        '''
        SELECT return_number FROM purchase_returns
        WHERE return_number LIKE ?
        ORDER BY return_number DESC
        LIMIT 1
      ''',
        ['$prefix%'],
      );

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastNumber = result.first['return_number'] as String;
        final numberPart = lastNumber.split('-').last;
        nextNumber = int.tryParse(numberPart) ?? 0;
        nextNumber++;
      }

      return '$prefix${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to generate return number: $e',
      );
    }
  }

  // Helper methods
  Future<List<PurchaseReturnItemModel>> _getPurchaseReturnItems(
    String returnId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'purchase_return_items',
        where: 'return_id = ?',
        whereArgs: [returnId],
        orderBy: 'product_name ASC',
      );

      return results
          .map((json) => PurchaseReturnItemModel.fromJson(json))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get purchase return items: $e',
      );
    }
  }

  Future<void> _updateProductStock(
    Transaction txn,
    String productId,
    int quantityChange,
  ) async {
    try {
      await txn.rawUpdate(
        '''
        UPDATE products 
        SET stock = stock + ?,
            updated_at = ?
        WHERE id = ?
      ''',
        [quantityChange, DateTime.now().toIso8601String(), productId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update product stock: $e',
      );
    }
  }
}
