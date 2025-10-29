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
      id: json['id'].toString(),
      returnNumber: json['return_number'] as String,
      receivingId: json['receiving_id'].toString(),
      receivingNumber: json['receiving_number'] as String? ?? '',
      purchaseId: json['purchase_id'].toString(),
      purchaseNumber: json['purchase_number'] as String? ?? '',
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name'] as String?,
      returnDate: DateTime.parse(json['return_date'] as String),
      subtotal: double.parse(json['subtotal'].toString()),
      itemDiscount:
          json['item_discount'] != null
              ? double.parse(json['item_discount'].toString())
              : 0,
      itemTax:
          json['item_tax'] != null
              ? double.parse(json['item_tax'].toString())
              : 0,
      totalDiscount:
          json['total_discount'] != null
              ? double.parse(json['total_discount'].toString())
              : 0,
      totalTax:
          json['total_tax'] != null
              ? double.parse(json['total_tax'].toString())
              : 0,
      total: double.parse(json['total'].toString()),
      status: json['status'] as String? ?? 'DRAFT',
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      processedBy: json['processed_by']?.toString(),
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
      'purchase_id': purchaseId,
      'supplier_id': supplierId,
      'return_date': returnDate.toIso8601String(),
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'total': total,
      'reason': reason,
      'notes': notes,
      'returned_by':
          processedBy, // Backend expects 'returned_by' not 'processed_by'
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
      id: json['id'].toString(),
      returnId: json['return_id'].toString(),
      receivingItemId: json['receiving_item_id'].toString(),
      productId: json['product_id'].toString(),
      productName: json['product_name'] as String,
      receivedQuantity: double.parse(json['received_quantity'].toString()),
      returnQuantity: double.parse(json['return_quantity'].toString()),
      price: double.parse(json['price'].toString()),
      discount:
          json['discount'] != null
              ? double.parse(json['discount'].toString())
              : 0,
      discountType: json['discount_type'] as String? ?? 'AMOUNT',
      tax: json['tax'] != null ? double.parse(json['tax'].toString()) : 0,
      taxType: json['tax_type'] as String? ?? 'AMOUNT',
      subtotal: double.parse(json['subtotal'].toString()),
      total: double.parse(json['total'].toString()),
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
