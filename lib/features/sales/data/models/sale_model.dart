import '../../domain/entities/sale.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    super.branchId,
    required super.saleNumber,
    super.customerId,
    required super.cashierId,
    required super.cashierName,
    required super.saleDate,
    required super.subtotal,
    super.tax,
    super.discount,
    required super.total,
    required super.paymentMethod,
    required super.paymentAmount,
    super.changeAmount,
    super.status,
    super.notes,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString(),
      saleNumber:
          (json['transaction_number'] ?? json['sale_number'] ?? '') as String,
      customerId: json['customer_id']?.toString(),
      cashierId: (json['cashier_id'] ?? json['user_id'] ?? '').toString(),
      cashierName: (json['cashier_name'] ?? 'Kasir') as String,
      saleDate: DateTime.parse(
        (json['transaction_date'] ??
                json['sale_date'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: (json['payment_method'] ?? 'CASH') as String,
      paymentAmount: ((json['payment_amount'] ?? 0) as num).toDouble(),
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'COMPLETED',
      notes: json['notes'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map(
                    (item) =>
                        SaleItemModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'sale_number': saleNumber,
      'customer_id': customerId,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'sale_date': saleDate.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_amount': paymentAmount,
      'change_amount': changeAmount,
      'status': status,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SaleModel.fromEntity(Sale sale) {
    return SaleModel(
      id: sale.id,
      branchId: sale.branchId,
      saleNumber: sale.saleNumber,
      customerId: sale.customerId,
      cashierId: sale.cashierId,
      cashierName: sale.cashierName,
      saleDate: sale.saleDate,
      subtotal: sale.subtotal,
      tax: sale.tax,
      discount: sale.discount,
      total: sale.total,
      paymentMethod: sale.paymentMethod,
      paymentAmount: sale.paymentAmount,
      changeAmount: sale.changeAmount,
      status: sale.status,
      notes: sale.notes,
      syncStatus: sale.syncStatus,
      createdAt: sale.createdAt,
      updatedAt: sale.updatedAt,
      items: sale.items.map((item) => SaleItemModel.fromEntity(item)).toList(),
    );
  }
}

class SaleItemModel extends SaleItem {
  const SaleItemModel({
    required super.id,
    required super.saleId,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.price,
    super.discount,
    required super.subtotal,
    super.syncStatus,
    required super.createdAt,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      saleId: (json['transaction_id'] ?? json['sale_id'] ?? '') as String,
      productId: (json['product_id'] ?? '') as String,
      productName: (json['product_name'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as int,
      price: ((json['price'] ?? 0) as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'subtotal': subtotal,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SaleItemModel.fromEntity(SaleItem item) {
    return SaleItemModel(
      id: item.id,
      saleId: item.saleId,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      price: item.price,
      discount: item.discount,
      subtotal: item.subtotal,
      syncStatus: item.syncStatus,
      createdAt: item.createdAt,
    );
  }
}
