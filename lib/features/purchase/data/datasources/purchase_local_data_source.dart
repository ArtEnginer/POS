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
  Future<void> receivePurchase(String id);
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
    // TODO: Implement with Backend V2 - Direct database operations
    throw UnimplementedError(
      'Purchase insert temporarily disabled during migration',
    );
  }

  @override
  Future<void> updatePurchase(PurchaseModel purchase) async {
    // TODO: Implement with Backend V2 - Direct database operations
    throw UnimplementedError(
      'Purchase update temporarily disabled during migration',
    );
  }

  @override
  Future<void> deletePurchase(String id) async {
    // TODO: Implement with Backend V2 - Direct database operations
    throw UnimplementedError(
      'Purchase delete temporarily disabled during migration',
    );
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
    // TODO: Implement with Backend V2 - Direct database operations
    throw UnimplementedError(
      'Purchase receive temporarily disabled during migration',
    );
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
