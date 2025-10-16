import '../../domain/entities/purchase.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.purchaseNumber,
    super.supplierId,
    super.supplierName,
    required super.purchaseDate,
    required super.subtotal,
    super.tax,
    super.discount,
    required super.total,
    required super.paymentMethod,
    required super.paidAmount,
    super.status,
    super.notes,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.items,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      purchaseNumber: json['purchase_number'] as String,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paidAmount: (json['paid_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'purchase_date': purchaseDate.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'status': status,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromEntity(Purchase purchase) {
    return PurchaseModel(
      id: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      purchaseDate: purchase.purchaseDate,
      subtotal: purchase.subtotal,
      tax: purchase.tax,
      discount: purchase.discount,
      total: purchase.total,
      paymentMethod: purchase.paymentMethod,
      paidAmount: purchase.paidAmount,
      status: purchase.status,
      notes: purchase.notes,
      syncStatus: purchase.syncStatus,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
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
    required super.quantity,
    required super.price,
    required super.subtotal,
    required super.createdAt,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
