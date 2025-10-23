import '../../../../core/database/database_helper.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../models/customer_model.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getAllCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<List<CustomerModel>> searchCustomers(String query);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<String> generateCustomerCode();
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper databaseHelper;
  final HybridSyncManager hybridSyncManager;

  CustomerLocalDataSourceImpl({
    required this.databaseHelper,
    required this.hybridSyncManager,
  });

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'deleted_at IS NULL AND is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );

      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get customers: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw CacheException(message: 'Customer not found');
      }

      return CustomerModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException(message: 'Failed to get customer: $e');
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where:
            '(name LIKE ? OR code LIKE ? OR phone LIKE ?) AND deleted_at IS NULL',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to search customers: $e');
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      // ✅ AUTO SYNC: Insert ke local DAN sync ke server jika online
      await hybridSyncManager.insertRecord(
        'customers',
        customer.toJson(),
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );
      return customer;
    } catch (e) {
      throw CacheException(message: 'Failed to create customer: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      // ✅ AUTO SYNC: Update local DAN sync ke server jika online
      final result = await hybridSyncManager.updateRecord(
        'customers',
        customer.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
        syncImmediately: true, // Langsung sync ke server jika tersedia
      );

      if (result == 0) {
        throw CacheException(message: 'Customer not found');
      }

      return customer;
    } catch (e) {
      throw CacheException(message: 'Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final now = DateTime.now().toIso8601String();

      // ✅ AUTO SYNC: Soft delete ke local DAN sync ke server jika online
      final result = await hybridSyncManager.updateRecord(
        'customers',
        {'deleted_at': now, 'is_active': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
        syncImmediately: true,
      );

      if (result == 0) {
        throw CacheException(message: 'Customer not found');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to delete customer: $e');
    }
  }

  @override
  Future<String> generateCustomerCode() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT code FROM customers WHERE code LIKE ? ORDER BY code DESC LIMIT 1',
        ['CUST%'],
      );

      if (result.isEmpty) {
        return 'CUST001';
      }

      final lastCode = result.first['code'] as String;
      final number = int.parse(lastCode.replaceAll('CUST', ''));
      final newNumber = number + 1;
      return 'CUST${newNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      throw CacheException(message: 'Failed to generate customer code: $e');
    }
  }
}
