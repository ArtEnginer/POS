import '../../domain/entities/receiving.dart';

class ReceivingModel extends Receiving {
  const ReceivingModel({
    required super.id,
    required super.receivingNumber,
    required super.purchaseId,
    required super.purchaseNumber,
    super.supplierId,
    super.supplierName,
    required super.receivingDate,
    super.invoiceNumber,
    super.deliveryOrderNumber,
    super.vehicleNumber,
    super.driverName,
    required super.subtotal,
    super.itemDiscount,
    super.itemTax,
    super.totalDiscount,
    super.totalTax,
    required super.total,
    super.status,
    super.notes,
    super.receivedBy,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.items,
  });

  factory ReceivingModel.fromJson(Map<String, dynamic> json) {
    return ReceivingModel(
      id: json['id'] as String,
      receivingNumber: json['receiving_number'] as String,
      purchaseId: json['purchase_id'] as String,
      purchaseNumber: json['purchase_number'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      receivingDate: DateTime.parse(json['receiving_date'] as String),
      invoiceNumber: json['invoice_number'] as String?,
      deliveryOrderNumber: json['delivery_order_number'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      driverName: json['driver_name'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0,
      itemTax: (json['item_tax'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0,
      totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'COMPLETED',
      notes: json['notes'] as String?,
      receivedBy: json['received_by'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiving_number': receivingNumber,
      'purchase_id': purchaseId,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'receiving_date': receivingDate.toIso8601String(),
      'invoice_number': invoiceNumber,
      'delivery_order_number': deliveryOrderNumber,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'subtotal': subtotal,
      'item_discount': itemDiscount,
      'item_tax': itemTax,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'total': total,
      'status': status,
      'notes': notes,
      'received_by': receivedBy,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReceivingModel.fromEntity(Receiving receiving) {
    return ReceivingModel(
      id: receiving.id,
      receivingNumber: receiving.receivingNumber,
      purchaseId: receiving.purchaseId,
      purchaseNumber: receiving.purchaseNumber,
      supplierId: receiving.supplierId,
      supplierName: receiving.supplierName,
      receivingDate: receiving.receivingDate,
      invoiceNumber: receiving.invoiceNumber,
      deliveryOrderNumber: receiving.deliveryOrderNumber,
      vehicleNumber: receiving.vehicleNumber,
      driverName: receiving.driverName,
      subtotal: receiving.subtotal,
      itemDiscount: receiving.itemDiscount,
      itemTax: receiving.itemTax,
      totalDiscount: receiving.totalDiscount,
      totalTax: receiving.totalTax,
      total: receiving.total,
      status: receiving.status,
      notes: receiving.notes,
      receivedBy: receiving.receivedBy,
      syncStatus: receiving.syncStatus,
      createdAt: receiving.createdAt,
      updatedAt: receiving.updatedAt,
      items:
          receiving.items
              .map((item) => ReceivingItemModel.fromEntity(item))
              .toList(),
    );
  }
}

class ReceivingItemModel extends ReceivingItem {
  const ReceivingItemModel({
    required super.id,
    required super.receivingId,
    super.purchaseItemId,
    required super.productId,
    required super.productName,
    required super.poQuantity,
    required super.poPrice,
    required super.receivedQuantity,
    required super.receivedPrice,
    super.discount,
    super.discountType,
    super.tax,
    super.taxType,
    required super.subtotal,
    required super.total,
    super.notes,
    required super.createdAt,
  });

  factory ReceivingItemModel.fromJson(Map<String, dynamic> json) {
    return ReceivingItemModel(
      id: json['id'] as String,
      receivingId: json['receiving_id'] as String,
      purchaseItemId: json['purchase_item_id'] as String?,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      poQuantity: json['po_quantity'] as int,
      poPrice: (json['po_price'] as num).toDouble(),
      receivedQuantity: json['received_quantity'] as int,
      receivedPrice: (json['received_price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      discountType: json['discount_type'] as String? ?? 'AMOUNT',
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      taxType: json['tax_type'] as String? ?? 'AMOUNT',
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiving_id': receivingId,
      'purchase_item_id': purchaseItemId,
      'product_id': productId,
      'product_name': productName,
      'po_quantity': poQuantity,
      'po_price': poPrice,
      'received_quantity': receivedQuantity,
      'received_price': receivedPrice,
      'discount': discount,
      'discount_type': discountType,
      'tax': tax,
      'tax_type': taxType,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReceivingItemModel.fromEntity(ReceivingItem item) {
    return ReceivingItemModel(
      id: item.id,
      receivingId: item.receivingId,
      purchaseItemId: item.purchaseItemId,
      productId: item.productId,
      productName: item.productName,
      poQuantity: item.poQuantity,
      poPrice: item.poPrice,
      receivedQuantity: item.receivedQuantity,
      receivedPrice: item.receivedPrice,
      discount: item.discount,
      discountType: item.discountType,
      tax: item.tax,
      taxType: item.taxType,
      subtotal: item.subtotal,
      total: item.total,
      notes: item.notes,
      createdAt: item.createdAt,
    );
  }
}
