import 'dart:async';
import 'package:hive/hive.dart';
import '../../../../core/database/hive_service.dart';
import '../models/sales_return_model.dart';
import '../models/sale_model.dart';

/// Service untuk manage return penjualan
class SalesReturnService {
  final HiveService _hiveService;
  static const String _returnBoxName = 'sales_returns';

  // Stream controller untuk update
  final _returnUpdatesController = StreamController<String>.broadcast();
  Stream<String> get returnUpdates => _returnUpdatesController.stream;

  SalesReturnService(this._hiveService);

  /// Initialize return box
  Future<void> init() async {
    try {
      await Hive.openBox(_returnBoxName);
      print('✅ Sales Return Service initialized');
    } catch (e) {
      print('❌ Error initializing Sales Return Service: $e');
    }
  }

  /// Get return box
  dynamic get _returnBox {
    return Hive.box(_returnBoxName);
  }

  /// Create new return
  Future<bool> createReturn(SalesReturnModel returnModel) async {
    try {
      await _returnBox.put(returnModel.id, returnModel.toJson());
      print('✅ Return created: ${returnModel.returnNumber}');
      _returnUpdatesController.add('return_created');
      return true;
    } catch (e) {
      print('❌ Error creating return: $e');
      return false;
    }
  }

  /// Get all returns
  List<SalesReturnModel> getAllReturns() {
    try {
      final returns =
          _returnBox.values
              .map((data) {
                try {
                  if (data is Map<String, dynamic>) {
                    return SalesReturnModel.fromJson(data);
                  } else if (data is Map) {
                    return SalesReturnModel.fromJson(
                      Map<String, dynamic>.from(data),
                    );
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing return: $e');
                  return null;
                }
              })
              .where((ret) => ret != null)
              .cast<SalesReturnModel>()
              .toList();

      // Sort by date descending
      returns.sort(
        (SalesReturnModel a, SalesReturnModel b) =>
            b.returnDate.compareTo(a.returnDate),
      );
      return returns;
    } catch (e) {
      print('❌ Error getting returns: $e');
      return [];
    }
  }

  /// Get return by ID
  SalesReturnModel? getReturnById(String id) {
    try {
      final data = _returnBox.get(id);
      if (data == null) return null;

      if (data is Map<String, dynamic>) {
        return SalesReturnModel.fromJson(data);
      } else if (data is Map) {
        return SalesReturnModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('❌ Error getting return: $e');
      return null;
    }
  }

  /// Get pending returns (not synced)
  List<SalesReturnModel> getPendingReturns() {
    final allReturns = getAllReturns();
    return allReturns.where((ret) => !ret.isSynced).toList();
  }

  /// Get return count
  int getReturnCount() {
    return _returnBox.length;
  }

  /// Get pending return count
  int getPendingReturnCount() {
    return getPendingReturns().length;
  }

  /// Update return status
  Future<bool> updateReturnStatus(String id, String status) async {
    try {
      final returnModel = getReturnById(id);
      if (returnModel == null) return false;

      final updated = returnModel.copyWith(status: status);
      await _returnBox.put(id, updated.toJson());
      print('✅ Return status updated: $status');
      _returnUpdatesController.add('return_updated');
      return true;
    } catch (e) {
      print('❌ Error updating return status: $e');
      return false;
    }
  }

  /// Mark return as synced
  Future<bool> markAsSynced(String id) async {
    try {
      final returnModel = getReturnById(id);
      if (returnModel == null) return false;

      final synced = returnModel.copyWith(
        isSynced: true,
        syncedAt: DateTime.now(),
        status: 'completed',
      );
      await _returnBox.put(id, synced.toJson());
      print('✅ Return marked as synced: ${returnModel.returnNumber}');
      _returnUpdatesController.add('return_synced');
      return true;
    } catch (e) {
      print('❌ Error marking return as synced: $e');
      return false;
    }
  }

  /// Delete return
  Future<bool> deleteReturn(String id) async {
    try {
      await _returnBox.delete(id);
      print('✅ Return deleted: $id');
      _returnUpdatesController.add('return_deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting return: $e');
      return false;
    }
  }

  /// Get returns by original sale ID
  List<SalesReturnModel> getReturnsBySaleId(String saleId) {
    final allReturns = getAllReturns();
    return allReturns.where((ret) => ret.originalSaleId == saleId).toList();
  }

  /// Check if sale has been returned
  bool hasSaleBeenReturned(String saleId) {
    return getReturnsBySaleId(saleId).isNotEmpty;
  }

  /// Get original sale from sales box
  SaleModel? getOriginalSale(String saleId) {
    try {
      final salesBox = _hiveService.salesBox;
      final data = salesBox.get(saleId);
      if (data == null) return null;

      if (data is Map<String, dynamic>) {
        return SaleModel.fromJson(data);
      } else if (data is Map) {
        return SaleModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('❌ Error getting original sale: $e');
      return null;
    }
  }

  /// Get recent sales (last 7 days) untuk di-return
  List<SaleModel> getRecentSales({int days = 7}) {
    try {
      final salesBox = _hiveService.salesBox;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final sales =
          salesBox.values
              .map((data) {
                try {
                  if (data is Map<String, dynamic>) {
                    return SaleModel.fromJson(data);
                  } else if (data is Map) {
                    return SaleModel.fromJson(Map<String, dynamic>.from(data));
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .where(
                (sale) => sale != null && sale.createdAt.isAfter(cutoffDate),
              )
              .cast<SaleModel>()
              .toList();

      // Sort by date descending
      sales.sort(
        (SaleModel a, SaleModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return sales;
    } catch (e) {
      print('❌ Error getting recent sales: $e');
      return [];
    }
  }

  /// Clear all returns (untuk testing)
  Future<void> clearAll() async {
    try {
      await _returnBox.clear();
      print('✅ All returns cleared');
      _returnUpdatesController.add('returns_cleared');
    } catch (e) {
      print('❌ Error clearing returns: $e');
    }
  }

  /// Dispose
  void dispose() {
    _returnUpdatesController.close();
  }
}
