import 'package:equatable/equatable.dart';
import 'cart_item_model.dart';

/// Item yang di-return dari penjualan
class ReturnItemModel extends Equatable {
  final String productId;
  final String productName;
  final double quantity; // Jumlah yang di-return
  final double unitPrice;
  final double subtotal;
  final String? reason; // Alasan return khusus item ini

  const ReturnItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'reason': reason,
    };
  }

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      reason: json['reason']?.toString(),
    );
  }

  /// Create from CartItemModel
  factory ReturnItemModel.fromCartItem(
    CartItemModel cartItem, {
    double? returnQuantity,
    String? reason,
  }) {
    final qty = returnQuantity ?? cartItem.quantity;
    return ReturnItemModel(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      quantity: qty,
      unitPrice: cartItem.product.price,
      subtotal: cartItem.product.price * qty,
      reason: reason,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    quantity,
    unitPrice,
    subtotal,
    reason,
  ];
}

/// Model untuk return penjualan
class SalesReturnModel extends Equatable {
  final String id;
  final String returnNumber; // Return invoice number
  final String originalSaleId; // ID dari penjualan asli
  final String originalInvoiceNumber; // Invoice number dari penjualan asli
  final int branchId; // REQUIRED: Branch tempat return dilakukan
  final DateTime returnDate;
  final List<ReturnItemModel> items;
  final String returnReason; // Alasan umum return
  final double totalRefund; // Total uang yang dikembalikan
  final String refundMethod; // cash, transfer, dll
  final String? customerId;
  final String? customerName;
  final String cashierId;
  final String cashierName;
  final int processedByUserId; // REQUIRED: User yang memproses return
  final String status; // pending, processed, completed
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final String? notes;

  const SalesReturnModel({
    required this.id,
    required this.returnNumber,
    required this.originalSaleId,
    required this.originalInvoiceNumber,
    required this.branchId,
    required this.returnDate,
    required this.items,
    required this.returnReason,
    required this.totalRefund,
    this.refundMethod = 'cash',
    this.customerId,
    this.customerName,
    required this.cashierId,
    required this.cashierName,
    required this.processedByUserId,
    this.status = 'pending',
    this.isSynced = false,
    this.syncedAt,
    required this.createdAt,
    this.notes,
  });

  /// Generate return number
  static String generateReturnNumber() {
    final now = DateTime.now();
    return 'RET-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_number': returnNumber,
      'original_sale_id': originalSaleId,
      'original_invoice_number': originalInvoiceNumber,
      'branch_id': branchId,
      'return_date': returnDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'return_reason': returnReason,
      'total_refund': totalRefund,
      'refund_method': refundMethod,
      'customer_id': customerId,
      'customer_name': customerName,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'processed_by_user_id': processedByUserId,
      'status': status,
      'is_synced': isSynced,
      'synced_at': syncedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) {
    return SalesReturnModel(
      id: json['id']?.toString() ?? '',
      returnNumber: json['return_number']?.toString() ?? '',
      originalSaleId: json['original_sale_id']?.toString() ?? '',
      originalInvoiceNumber: json['original_invoice_number']?.toString() ?? '',
      branchId:
          json['branch_id'] is int
              ? json['branch_id']
              : int.tryParse(json['branch_id']?.toString() ?? '0') ?? 0,
      returnDate:
          json['return_date'] != null
              ? DateTime.parse(json['return_date'])
              : DateTime.now(),
      items:
          (json['items'] as List?)
              ?.map((item) {
                try {
                  if (item is Map<String, dynamic>) {
                    return ReturnItemModel.fromJson(item);
                  } else if (item is Map) {
                    return ReturnItemModel.fromJson(
                      Map<String, dynamic>.from(item),
                    );
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing return item: $e');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<ReturnItemModel>()
              .toList() ??
          [],
      returnReason: json['return_reason']?.toString() ?? '',
      totalRefund: (json['total_refund'] ?? 0).toDouble(),
      refundMethod: json['refund_method']?.toString() ?? 'cash',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      cashierId: json['cashier_id']?.toString() ?? '',
      cashierName: json['cashier_name']?.toString() ?? '',
      processedByUserId:
          json['processed_by_user_id'] is int
              ? json['processed_by_user_id']
              : int.tryParse(json['processed_by_user_id']?.toString() ?? '0') ??
                  0,
      status: json['status']?.toString() ?? 'pending',
      isSynced: json['is_synced'] ?? false,
      syncedAt:
          json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  SalesReturnModel copyWith({
    String? id,
    String? returnNumber,
    String? originalSaleId,
    String? originalInvoiceNumber,
    int? branchId,
    DateTime? returnDate,
    List<ReturnItemModel>? items,
    String? returnReason,
    double? totalRefund,
    String? refundMethod,
    String? customerId,
    String? customerName,
    String? cashierId,
    String? cashierName,
    int? processedByUserId,
    String? status,
    bool? isSynced,
    DateTime? syncedAt,
    DateTime? createdAt,
    String? notes,
  }) {
    return SalesReturnModel(
      id: id ?? this.id,
      returnNumber: returnNumber ?? this.returnNumber,
      originalSaleId: originalSaleId ?? this.originalSaleId,
      originalInvoiceNumber:
          originalInvoiceNumber ?? this.originalInvoiceNumber,
      branchId: branchId ?? this.branchId,
      returnDate: returnDate ?? this.returnDate,
      items: items ?? this.items,
      returnReason: returnReason ?? this.returnReason,
      totalRefund: totalRefund ?? this.totalRefund,
      refundMethod: refundMethod ?? this.refundMethod,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      processedByUserId: processedByUserId ?? this.processedByUserId,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    returnNumber,
    originalSaleId,
    originalInvoiceNumber,
    branchId,
    returnDate,
    items,
    returnReason,
    totalRefund,
    refundMethod,
    customerId,
    customerName,
    cashierId,
    cashierName,
    processedByUserId,
    status,
    isSynced,
    syncedAt,
    createdAt,
    notes,
  ];
}
