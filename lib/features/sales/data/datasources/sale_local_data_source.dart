import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/sale_model.dart';

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
      throw CacheException(message: e.toString());
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
        throw CacheException(message: 'Transaksi tidak ditemukan');
      }

      final items = await _getSaleItems(db, id);
      return SaleModel.fromJson({
        ...result.first,
        'items': items.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      throw CacheException(message: e.toString());
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
      throw CacheException(message: e.toString());
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
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<SaleModel> createSale(SaleModel sale) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Insert sale
        await txn.insert('transactions', {
          'id': sale.id,
          'transaction_number': sale.saleNumber,
          'customer_id': sale.customerId,
          'cashier_id': sale.cashierId,
          'cashier_name': sale.cashierName,
          'subtotal': sale.subtotal,
          'tax': sale.tax,
          'discount': sale.discount,
          'total': sale.total,
          'payment_method': sale.paymentMethod,
          'payment_amount': sale.paymentAmount,
          'change_amount': sale.changeAmount,
          'status': sale.status,
          'notes': sale.notes,
          'sync_status': sale.syncStatus,
          'transaction_date': sale.saleDate.toIso8601String(),
          'created_at': sale.createdAt.toIso8601String(),
          'updated_at': sale.updatedAt.toIso8601String(),
        });

        // Insert sale items and update stock
        for (var item in sale.items) {
          await txn.insert('transaction_items', {
            'id': item.id,
            'transaction_id': sale.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'price': item.price,
            'discount': item.discount,
            'subtotal': item.subtotal,
            'sync_status': item.syncStatus,
            'created_at': item.createdAt.toIso8601String(),
          });

          // Update product stock
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      });

      return await getSaleById(sale.id);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<SaleModel> updateSale(SaleModel sale) async {
    try {
      final db = await databaseHelper.database;

      await db.update(
        'transactions',
        {
          'customer_id': sale.customerId,
          'subtotal': sale.subtotal,
          'tax': sale.tax,
          'discount': sale.discount,
          'total': sale.total,
          'payment_method': sale.paymentMethod,
          'payment_amount': sale.paymentAmount,
          'change_amount': sale.changeAmount,
          'status': sale.status,
          'notes': sale.notes,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sale.id],
      );

      return await getSaleById(sale.id);
    } catch (e) {
      throw CacheException(message: e.toString());
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
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }

        // Delete sale items
        await txn.delete(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [id],
        );

        // Delete sale
        await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      throw CacheException(message: e.toString());
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
      throw CacheException(message: e.toString());
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
      throw CacheException(message: e.toString());
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
}
