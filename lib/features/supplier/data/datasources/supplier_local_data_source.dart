import '../../../../core/database/database_helper.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/supplier_model.dart';

abstract class SupplierLocalDataSource {
  Future<List<SupplierModel>> getSuppliers({
    String? searchQuery,
    bool? isActive,
  });

  Future<SupplierModel> getSupplierById(String id);

  Future<void> insertSupplier(SupplierModel supplier);

  Future<void> updateSupplier(SupplierModel supplier);

  Future<void> deleteSupplier(String id);
}

class SupplierLocalDataSourceImpl implements SupplierLocalDataSource {
  final DatabaseHelper databaseHelper;
  final HybridSyncManager hybridSyncManager;

  SupplierLocalDataSourceImpl({
    required this.databaseHelper,
    required this.hybridSyncManager,
  });

  @override
  Future<List<SupplierModel>> getSuppliers({
    String? searchQuery,
    bool? isActive,
  }) async {
    try {
      final db = await databaseHelper.database;

      String whereClause = 'deleted_at IS NULL';
      List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause += ' AND (name LIKE ? OR code LIKE ? OR phone LIKE ?)';
        whereArgs.addAll([
          '%$searchQuery%',
          '%$searchQuery%',
          '%$searchQuery%',
        ]);
      }

      if (isActive != null) {
        whereClause += ' AND is_active = ?';
        whereArgs.add(isActive ? 1 : 0);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'suppliers',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return SupplierModel.fromJson(maps[i]);
      });
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to get suppliers: $e',
      );
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String id) async {
    try {
      final db = await databaseHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'suppliers',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        throw app_exceptions.CacheException(message: 'Supplier not found');
      }

      return SupplierModel.fromJson(maps.first);
    } catch (e) {
      if (e is app_exceptions.CacheException) {
        rethrow;
      }
      throw app_exceptions.DatabaseException(
        message: 'Failed to get supplier: $e',
      );
    }
  }

  @override
  Future<void> insertSupplier(SupplierModel supplier) async {
    try {
      // ✅ AUTO SYNC: Insert ke local DAN sync ke server jika online
      await hybridSyncManager.insertRecord(
        'suppliers',
        supplier.toJson(),
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to insert supplier: $e',
      );
    }
  }

  @override
  Future<void> updateSupplier(SupplierModel supplier) async {
    try {
      // ✅ AUTO SYNC: Update local DAN sync ke server jika online
      await hybridSyncManager.updateRecord(
        'suppliers',
        supplier.toJson(),
        where: 'id = ?',
        whereArgs: [supplier.id],
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to update supplier: $e',
      );
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      final now = DateTime.now().toIso8601String();

      // ✅ AUTO SYNC: Soft delete ke local DAN sync ke server jika online
      await hybridSyncManager.updateRecord(
        'suppliers',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete supplier: $e',
      );
    }
  }
}
