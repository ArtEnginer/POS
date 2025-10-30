import 'package:uuid/uuid.dart';
import '../../../../core/database/hive_service.dart';
import '../models/pending_sale_model.dart';

class PendingSalesService {
  final HiveService _hiveService;
  final _uuid = const Uuid();

  PendingSalesService(this._hiveService);

  /// Save transaksi sebagai pending
  Future<String> savePending({
    required List<PendingSaleItem> items,
    String? customerId,
    String? customerName,
    required double totalAmount,
    double discount = 0,
    double tax = 0,
    required double grandTotal,
    String? paymentMethod,
    String? notes,
    required String createdBy,
  }) async {
    try {
      // Generate unique ID
      final id = _uuid.v4();

      final pendingSale = PendingSaleModel(
        id: id,
        items: items,
        customerId: customerId,
        customerName: customerName,
        totalAmount: totalAmount,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      // Simpan ke Hive
      final box = _hiveService.pendingSalesBox;
      await box.put(id, pendingSale.toMap());

      print('💾 Pending sale saved: $id');
      print('   Items: ${items.length}');
      print('   Grand Total: $grandTotal');

      return id;
    } catch (e) {
      print('❌ Error saving pending sale: $e');
      rethrow;
    }
  }

  /// Get semua pending sales
  List<PendingSaleModel> getAllPending() {
    try {
      final box = _hiveService.pendingSalesBox;
      final pendingList = <PendingSaleModel>[];

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map) {
          pendingList.add(PendingSaleModel.fromMap(data));
        }
      }

      // Sort by created date (newest first)
      pendingList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('📋 Retrieved ${pendingList.length} pending sales');
      return pendingList;
    } catch (e) {
      print('❌ Error getting pending sales: $e');
      return [];
    }
  }

  /// Get pending sale by ID
  PendingSaleModel? getPendingById(String id) {
    try {
      final box = _hiveService.pendingSalesBox;
      final data = box.get(id);

      if (data != null && data is Map) {
        return PendingSaleModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('❌ Error getting pending sale $id: $e');
      return null;
    }
  }

  /// Delete pending sale
  Future<void> deletePending(String id) async {
    try {
      final box = _hiveService.pendingSalesBox;
      await box.delete(id);

      print('🗑️ Pending sale deleted: $id');
    } catch (e) {
      print('❌ Error deleting pending sale $id: $e');
      rethrow;
    }
  }

  /// Delete all pending sales
  Future<void> deleteAllPending() async {
    try {
      final box = _hiveService.pendingSalesBox;
      await box.clear();

      print('🗑️ All pending sales deleted');
    } catch (e) {
      print('❌ Error deleting all pending sales: $e');
      rethrow;
    }
  }

  /// Get count of pending sales
  int getPendingCount() {
    return _hiveService.pendingSalesBox.length;
  }

  /// Get total amount of all pending sales
  double getTotalPendingAmount() {
    final allPending = getAllPending();
    return allPending.fold<double>(
      0,
      (sum, pending) => sum + pending.grandTotal,
    );
  }

  /// Update pending sale
  Future<void> updatePending(PendingSaleModel pendingSale) async {
    try {
      final box = _hiveService.pendingSalesBox;
      await box.put(pendingSale.id, pendingSale.toMap());

      print('✏️ Pending sale updated: ${pendingSale.id}');
    } catch (e) {
      print('❌ Error updating pending sale: $e');
      rethrow;
    }
  }

  /// Search pending sales by customer name or notes
  List<PendingSaleModel> searchPending(String query) {
    if (query.isEmpty) return getAllPending();

    final allPending = getAllPending();
    final lowercaseQuery = query.toLowerCase();

    return allPending.where((pending) {
      final customerName = pending.customerName?.toLowerCase() ?? '';
      final notes = pending.notes?.toLowerCase() ?? '';
      final createdBy = pending.createdBy.toLowerCase();

      return customerName.contains(lowercaseQuery) ||
          notes.contains(lowercaseQuery) ||
          createdBy.contains(lowercaseQuery);
    }).toList();
  }
}
