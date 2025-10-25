import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/sale_model.dart';
import '../models/pending_sale_model.dart';

abstract class SaleLocalDataSource {
  Future<List<SaleModel>> getAllSales();
  Future<SaleModel> getSaleById(String id);
  Future<List<SaleModel>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<SaleModel>> searchSales(String query);
  Future<SaleModel> createSale(SaleModel sale);
  Future<SaleModel> updateSale(SaleModel sale);
  Future<void> deleteSale(String id);
  Future<String> generateSaleNumber();
  Future<Map<String, dynamic>> getDailySummary(DateTime date);

  // Pending transaction methods
  Future<PendingSaleModel> savePendingSale(PendingSaleModel pendingSale);
  Future<List<PendingSaleModel>> getPendingSales();
  Future<PendingSaleModel> getPendingSaleById(String id);
  Future<void> deletePendingSale(String id);
  Future<String> generatePendingNumber();
}

class SaleLocalDataSourceImpl implements SaleLocalDataSource {
  final DatabaseHelper databaseHelper;

  SaleLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<SaleModel>> getAllSales() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query('transactions', orderBy: 'created_at DESC');

      final sales = <SaleModel>[];
      for (var saleData in result) {
        final items = await _getSaleItems(db, saleData['id'] as String);
        sales.add(
          SaleModel.fromJson({
            ...saleData,
            'items': items.map((item) => item.toJson()).toList(),
          }),
        );
      }

      return sales;
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<SaleModel> getSaleById(String id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        throw app_exceptions.CacheException(
          message: 'Transaksi tidak ditemukan',
        );
      }

      final items = await _getSaleItems(db, id);
      return SaleModel.fromJson({
        ...result.first,
        'items': items.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<List<SaleModel>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final result = await db.query(
        'transactions',
        where: 'DATE(transaction_date) BETWEEN ? AND ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'created_at DESC',
      );

      final sales = <SaleModel>[];
      for (var saleData in result) {
        final items = await _getSaleItems(db, saleData['id'] as String);
        sales.add(
          SaleModel.fromJson({
            ...saleData,
            'items': items.map((item) => item.toJson()).toList(),
          }),
        );
      }

      return sales;
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<List<SaleModel>> searchSales(String query) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'transactions',
        where: '''
          transaction_number LIKE ? OR 
          cashier_name LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      final sales = <SaleModel>[];
      for (var saleData in result) {
        final items = await _getSaleItems(db, saleData['id'] as String);
        sales.add(
          SaleModel.fromJson({
            ...saleData,
            'items': items.map((item) => item.toJson()).toList(),
          }),
        );
      }

      return sales;
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<SaleModel> createSale(SaleModel sale) async {
    try {
      final db = await databaseHelper.database;
      await db.transaction((txn) async {
        for (var item in sale.items) {
          // Insert transaction items
          await txn.insert('transaction_items', {
            'id': item.id,
            'transaction_id': sale.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'discount': item.discount,
            'subtotal': item.subtotal,
            'sync_status': 'PENDING',
            'created_at': item.createdAt.toIso8601String(),
          });

          // Update product stock (reduce stock)
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ?, sync_status = ? WHERE id = ?',
            [item.quantity, 'PENDING', item.productId],
          );
        }
      });

      // Return the sale directly instead of calling getSaleById
      // This avoids the circular dependency issue
      return sale;
    } catch (e) {
      throw app_exceptions.DatabaseException(message: e.toString());
    }
  }

  @override
  Future<SaleModel> updateSale(SaleModel sale) async {
    try {
      // ✅ HYBRID MODE: Update local DAN sync ke server jika online
      // TODO: Replace with direct database operations
      // await hybridSyncManager.updateRecord(
      //   'transactions',
      //   {
      //     'customer_id': sale.customerId,
      //     'subtotal': sale.subtotal,
      //     'tax': sale.tax,
      //     'discount': sale.discount,
      //     'total': sale.total,
      //     'payment_method': sale.paymentMethod,
      //     'payment_amount': sale.paymentAmount,
      //     'change_amount': sale.changeAmount,
      //     'status': sale.status,
      //     'notes': sale.notes,
      //     'sync_status': 'PENDING',
      //     'updated_at': DateTime.now().toIso8601String(),
      //   },
      //   where: 'id = ?',
      //   whereArgs: [sale.id],
      //   syncImmediately: true,
      // );

      return await getSaleById(sale.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Get sale items to restore stock
        final items = await _getSaleItems(txn, id);

        // Restore product stock
        for (var item in items) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ?, sync_status = ? WHERE id = ?',
            [item.quantity, 'PENDING', item.productId],
          );
        }

        // Delete sale items
        await txn.delete(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [id],
        );
      });

      // ✅ HYBRID MODE: Delete dari local DAN sync ke server jika online
      // TODO: Replace with direct database operations
      // await hybridSyncManager.deleteRecord(
      //   'transactions',
      //   where: 'id = ?',
      //   whereArgs: [id],
      //   syncImmediately: true,
      // );
    } catch (e) {
      throw app_exceptions.DatabaseException(message: e.toString());
    }
  }

  @override
  Future<String> generateSaleNumber() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd').format(now);
      final prefix = 'TRX-$dateFormat';

      final result = await db.rawQuery(
        '''
        SELECT transaction_number 
        FROM transactions 
        WHERE transaction_number LIKE ?
        ORDER BY transaction_number DESC 
        LIMIT 1
        ''',
        ['$prefix%'],
      );

      if (result.isEmpty) {
        return '$prefix-0001';
      }

      final lastNumber = result.first['transaction_number'] as String;
      final lastSequence = int.parse(lastNumber.split('-').last);
      final newSequence = (lastSequence + 1).toString().padLeft(4, '0');

      return '$prefix-$newSequence';
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      final dateStr = date.toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_transactions,
          COALESCE(SUM(total), 0) as total_sales,
          COALESCE(SUM(tax), 0) as total_tax,
          COALESCE(SUM(discount), 0) as total_discount,
          COALESCE(SUM(CASE WHEN payment_method = 'CASH' THEN total ELSE 0 END), 0) as cash_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'CARD' THEN total ELSE 0 END), 0) as card_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'QRIS' THEN total ELSE 0 END), 0) as qris_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'E_WALLET' THEN total ELSE 0 END), 0) as ewallet_sales
        FROM transactions
        WHERE DATE(transaction_date) = ? AND status = 'COMPLETED'
        ''',
        [dateStr],
      );

      return result.first;
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  Future<List<SaleItemModel>> _getSaleItems(
    DatabaseExecutor db,
    String saleId,
  ) async {
    final result = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [saleId],
    );

    return result.map((item) => SaleItemModel.fromJson(item)).toList();
  }

  // Pending Sale Methods Implementation
  @override
  Future<PendingSaleModel> savePendingSale(PendingSaleModel pendingSale) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Insert pending transaction
        await txn.insert('pending_transactions', {
          'id': pendingSale.id,
          'pending_number': pendingSale.pendingNumber,
          'customer_id': pendingSale.customerId,
          'customer_name': pendingSale.customerName,
          'saved_at': pendingSale.savedAt.toIso8601String(),
          'saved_by': pendingSale.savedBy,
          'notes': pendingSale.notes,
          'subtotal': pendingSale.subtotal,
          'tax': pendingSale.tax,
          'discount': pendingSale.discount,
          'total': pendingSale.total,
        });

        // Insert pending transaction items
        for (var item in pendingSale.items) {
          await txn.insert('pending_transaction_items', {
            'id': item.id,
            'pending_id': pendingSale.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'discount': item.discount,
            'subtotal': item.subtotal,
            'created_at': item.createdAt.toIso8601String(),
          });
        }
      });

      return await getPendingSaleById(pendingSale.id);
    } catch (e) {
      throw app_exceptions.DatabaseException(message: e.toString());
    }
  }

  @override
  Future<List<PendingSaleModel>> getPendingSales() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'pending_transactions',
        orderBy: 'saved_at DESC',
      );

      final pendingSales = <PendingSaleModel>[];
      for (var pendingData in result) {
        final items = await _getPendingSaleItems(
          db,
          pendingData['id'] as String,
        );
        pendingSales.add(
          PendingSaleModel.fromJson({
            ...pendingData,
            'items': items.map((item) => item.toJson()).toList(),
          }),
        );
      }

      return pendingSales;
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<PendingSaleModel> getPendingSaleById(String id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'pending_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        throw app_exceptions.CacheException(
          message: 'Pending transaksi tidak ditemukan',
        );
      }

      final items = await _getPendingSaleItems(db, id);
      return PendingSaleModel.fromJson({
        ...result.first,
        'items': items.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deletePendingSale(String id) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Delete pending sale items
        await txn.delete(
          'pending_transaction_items',
          where: 'pending_id = ?',
          whereArgs: [id],
        );

        // Delete pending sale
        await txn.delete(
          'pending_transactions',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(message: e.toString());
    }
  }

  @override
  Future<String> generatePendingNumber() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd').format(now);
      final prefix = 'PEND-$dateFormat';

      final result = await db.rawQuery(
        '''
        SELECT pending_number 
        FROM pending_transactions 
        WHERE pending_number LIKE ?
        ORDER BY pending_number DESC 
        LIMIT 1
        ''',
        ['$prefix%'],
      );

      if (result.isEmpty) {
        return '$prefix-0001';
      }

      final lastNumber = result.first['pending_number'] as String;
      final lastSequence = int.parse(lastNumber.split('-').last);
      final newSequence = (lastSequence + 1).toString().padLeft(4, '0');

      return '$prefix-$newSequence';
    } catch (e) {
      throw app_exceptions.CacheException(message: e.toString());
    }
  }

  Future<List<SaleItemModel>> _getPendingSaleItems(
    DatabaseExecutor db,
    String pendingId,
  ) async {
    final result = await db.query(
      'pending_transaction_items',
      where: 'pending_id = ?',
      whereArgs: [pendingId],
    );

    return result
        .map(
          (item) => SaleItemModel.fromJson({
            ...item,
            'sale_id': item['pending_id'],
            'transaction_id': item['pending_id'],
          }),
        )
        .toList();
  }
}
