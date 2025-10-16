import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final String id;
  final String purchaseNumber;
  final String? supplierId;
  final String? supplierName;
  final DateTime purchaseDate;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final double paidAmount;
  final String status; // PENDING, COMPLETED, CANCELLED
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    required this.paidAmount,
    this.status = 'PENDING',
    this.notes,
    this.syncStatus = 'PENDING',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Purchase copyWith({
    String? id,
    String? purchaseNumber,
    String? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    double? paidAmount,
    String? status,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    purchaseNumber,
    supplierId,
    supplierName,
    purchaseDate,
    subtotal,
    tax,
    discount,
    total,
    paymentMethod,
    paidAmount,
    status,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    items,
  ];
}

class PurchaseItem extends Equatable {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final DateTime createdAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    purchaseId,
    productId,
    productName,
    quantity,
    price,
    subtotal,
    createdAt,
  ];
}
