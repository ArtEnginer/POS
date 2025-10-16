import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
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

  SupplierLocalDataSourceImpl({required this.databaseHelper});

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
      final db = await databaseHelper.database;

      await db.insert(
        'suppliers',
        supplier.toJson(),
        conflictAlgorithm: ConflictAlgorithm.abort,
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
      final db = await databaseHelper.database;

      await db.update(
        'suppliers',
        supplier.toJson(),
        where: 'id = ?',
        whereArgs: [supplier.id],
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
      final db = await databaseHelper.database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        'suppliers',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        message: 'Failed to delete supplier: $e',
      );
    }
  }
}
