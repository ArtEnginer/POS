import '../../domain/entities/purchase.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.purchaseNumber,
    required super.branchId,
    super.supplierId,
    super.supplierName,
    required super.createdBy,
    required super.purchaseDate,
    super.expectedDate,
    super.status,
    required super.subtotal,
    super.discountAmount,
    super.taxAmount,
    super.shippingCost,
    required super.totalAmount,
    super.paidAmount,
    super.paymentTerms,
    super.paymentMethod,
    super.notes,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.items,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id']?.toString() ?? '',
      purchaseNumber: json['purchase_number'] as String,
      branchId: json['branch_id']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name'] as String?,
      createdBy: json['created_by']?.toString() ?? '',
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      expectedDate:
          json['expected_date'] != null
              ? DateTime.parse(json['expected_date'] as String)
              : null,
      status: json['status'] as String? ?? 'draft',
      subtotal:
          (json['subtotal'] is String)
              ? double.tryParse(json['subtotal']) ?? 0.0
              : (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount:
          (json['discount_amount'] is String)
              ? double.tryParse(json['discount_amount']) ?? 0.0
              : (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount:
          (json['tax_amount'] is String)
              ? double.tryParse(json['tax_amount']) ?? 0.0
              : (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      shippingCost:
          (json['shipping_cost'] is String)
              ? double.tryParse(json['shipping_cost']) ?? 0.0
              : (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      totalAmount:
          (json['total_amount'] is String)
              ? double.tryParse(json['total_amount']) ?? 0.0
              : (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount:
          (json['paid_amount'] is String)
              ? double.tryParse(json['paid_amount']) ?? 0.0
              : (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['payment_terms'] as String?,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map((item) => PurchaseItemModel.fromJson(item))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_number': purchaseNumber,
      'branch_id': int.tryParse(branchId) ?? branchId, // Convert string to int
      'supplier_id':
          supplierId != null ? (int.tryParse(supplierId!) ?? supplierId) : null,
      'supplier_name': supplierName,
      'created_by':
          int.tryParse(createdBy) ?? createdBy, // Convert string to int
      'purchase_date': purchaseDate.toIso8601String(),
      'expected_date': expectedDate?.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'shipping_cost': shippingCost,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_terms': paymentTerms,
      'payment_method': paymentMethod,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'items':
          items
              .map((item) => PurchaseItemModel.fromEntity(item).toJson())
              .toList(),
    };
  }

  factory PurchaseModel.fromEntity(Purchase purchase) {
    return PurchaseModel(
      id: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      branchId: purchase.branchId,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      createdBy: purchase.createdBy,
      purchaseDate: purchase.purchaseDate,
      expectedDate: purchase.expectedDate,
      status: purchase.status,
      subtotal: purchase.subtotal,
      discountAmount: purchase.discountAmount,
      taxAmount: purchase.taxAmount,
      shippingCost: purchase.shippingCost,
      totalAmount: purchase.totalAmount,
      paidAmount: purchase.paidAmount,
      paymentTerms: purchase.paymentTerms,
      paymentMethod: purchase.paymentMethod,
      notes: purchase.notes,
      syncStatus: purchase.syncStatus,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
      deletedAt: purchase.deletedAt,
      items: purchase.items,
    );
  }
}

class PurchaseItemModel extends PurchaseItem {
  const PurchaseItemModel({
    required super.id,
    required super.purchaseId,
    required super.productId,
    required super.productName,
    required super.sku,
    required super.quantityOrdered,
    super.quantityReceived,
    required super.unitPrice,
    super.discountAmount,
    super.taxAmount,
    required super.subtotal,
    required super.total,
    super.notes,
    required super.createdAt,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String,
      sku: json['sku'] as String,
      quantityOrdered: json['quantity_ordered'] as int,
      quantityReceived: json['quantity_received'] as int? ?? 0,
      unitPrice:
          (json['unit_price'] is String)
              ? double.tryParse(json['unit_price']) ?? 0.0
              : (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount:
          (json['discount_amount'] is String)
              ? double.tryParse(json['discount_amount']) ?? 0.0
              : (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount:
          (json['tax_amount'] is String)
              ? double.tryParse(json['tax_amount']) ?? 0.0
              : (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      subtotal:
          (json['subtotal'] is String)
              ? double.tryParse(json['subtotal']) ?? 0.0
              : (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      total:
          (json['total'] is String)
              ? double.tryParse(json['total']) ?? 0.0
              : (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id':
          int.tryParse(productId) ?? productId, // Convert string to int
      'product_name': productName,
      'sku': sku,
      'quantity_ordered': quantityOrdered,
      'quantity_received': quantityReceived,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseItemModel.fromEntity(PurchaseItem item) {
    return PurchaseItemModel(
      id: item.id,
      purchaseId: item.purchaseId,
      productId: item.productId,
      productName: item.productName,
      sku: item.sku,
      quantityOrdered: item.quantityOrdered,
      quantityReceived: item.quantityReceived,
      unitPrice: item.unitPrice,
      discountAmount: item.discountAmount,
      taxAmount: item.taxAmount,
      subtotal: item.subtotal,
      total: item.total,
      notes: item.notes,
      createdAt: item.createdAt,
    );
  }
}
