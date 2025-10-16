import '../../domain/entities/purchase_return.dart';

class PurchaseReturnModel extends PurchaseReturn {
  const PurchaseReturnModel({
    required super.id,
    required super.returnNumber,
    required super.receivingId,
    required super.receivingNumber,
    required super.purchaseId,
    required super.purchaseNumber,
    super.supplierId,
    super.supplierName,
    required super.returnDate,
    required super.subtotal,
    super.itemDiscount,
    super.itemTax,
    super.totalDiscount,
    super.totalTax,
    required super.total,
    super.status,
    super.reason,
    super.notes,
    super.processedBy,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.items,
  });

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnModel(
      id: json['id'] as String,
      returnNumber: json['return_number'] as String,
      receivingId: json['receiving_id'] as String,
      receivingNumber: json['receiving_number'] as String,
      purchaseId: json['purchase_id'] as String,
      purchaseNumber: json['purchase_number'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      returnDate: DateTime.parse(json['return_date'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0,
      itemTax: (json['item_tax'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'DRAFT',
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      processedBy: json['processed_by'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => PurchaseReturnItemModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_number': returnNumber,
      'receiving_id': receivingId,
      'receiving_number': receivingNumber,
      'purchase_id': purchaseId,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'return_date': returnDate.toIso8601String(),
      'subtotal': subtotal,
      'item_discount': itemDiscount,
      'item_tax': itemTax,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'total': total,
      'status': status,
      'reason': reason,
      'notes': notes,
      'processed_by': processedBy,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items':
          items
              .map((item) => PurchaseReturnItemModel.fromEntity(item).toJson())
              .toList(),
    };
  }

  /// toJson for database insert (without items field)
  Map<String, dynamic> toJsonForDb() {
    return {
      'id': id,
      'return_number': returnNumber,
      'receiving_id': receivingId,
      'receiving_number': receivingNumber,
      'purchase_id': purchaseId,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'return_date': returnDate.toIso8601String(),
      'subtotal': subtotal,
      'item_discount': itemDiscount,
      'item_tax': itemTax,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'total': total,
      'status': status,
      'reason': reason,
      'notes': notes,
      'processed_by': processedBy,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // items excluded - inserted separately in purchase_return_items table
    };
  }

  factory PurchaseReturnModel.fromEntity(PurchaseReturn purchaseReturn) {
    return PurchaseReturnModel(
      id: purchaseReturn.id,
      returnNumber: purchaseReturn.returnNumber,
      receivingId: purchaseReturn.receivingId,
      receivingNumber: purchaseReturn.receivingNumber,
      purchaseId: purchaseReturn.purchaseId,
      purchaseNumber: purchaseReturn.purchaseNumber,
      supplierId: purchaseReturn.supplierId,
      supplierName: purchaseReturn.supplierName,
      returnDate: purchaseReturn.returnDate,
      subtotal: purchaseReturn.subtotal,
      itemDiscount: purchaseReturn.itemDiscount,
      itemTax: purchaseReturn.itemTax,
      totalDiscount: purchaseReturn.totalDiscount,
      totalTax: purchaseReturn.totalTax,
      total: purchaseReturn.total,
      status: purchaseReturn.status,
      reason: purchaseReturn.reason,
      notes: purchaseReturn.notes,
      processedBy: purchaseReturn.processedBy,
      syncStatus: purchaseReturn.syncStatus,
      createdAt: purchaseReturn.createdAt,
      updatedAt: purchaseReturn.updatedAt,
      items: purchaseReturn.items,
    );
  }
}

class PurchaseReturnItemModel extends PurchaseReturnItem {
  const PurchaseReturnItemModel({
    required super.id,
    required super.returnId,
    required super.receivingItemId,
    required super.productId,
    required super.productName,
    required super.receivedQuantity,
    required super.returnQuantity,
    required super.price,
    super.discount,
    super.discountType,
    super.tax,
    super.taxType,
    required super.subtotal,
    required super.total,
    super.reason,
    super.notes,
    required super.createdAt,
  });

  factory PurchaseReturnItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItemModel(
      id: json['id'] as String,
      returnId: json['return_id'] as String,
      receivingItemId: json['receiving_item_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      receivedQuantity: json['received_quantity'] as int,
      returnQuantity: json['return_quantity'] as int,
      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      discountType: json['discount_type'] as String? ?? 'AMOUNT',
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      taxType: json['tax_type'] as String? ?? 'AMOUNT',
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_id': returnId,
      'receiving_item_id': receivingItemId,
      'product_id': productId,
      'product_name': productName,
      'received_quantity': receivedQuantity,
      'return_quantity': returnQuantity,
      'price': price,
      'discount': discount,
      'discount_type': discountType,
      'tax': tax,
      'tax_type': taxType,
      'subtotal': subtotal,
      'total': total,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseReturnItemModel.fromEntity(PurchaseReturnItem item) {
    return PurchaseReturnItemModel(
      id: item.id,
      returnId: item.returnId,
      receivingItemId: item.receivingItemId,
      productId: item.productId,
      productName: item.productName,
      receivedQuantity: item.receivedQuantity,
      returnQuantity: item.returnQuantity,
      price: item.price,
      discount: item.discount,
      discountType: item.discountType,
      tax: item.tax,
      taxType: item.taxType,
      subtotal: item.subtotal,
      total: item.total,
      reason: item.reason,
      notes: item.notes,
      createdAt: item.createdAt,
    );
  }
}
