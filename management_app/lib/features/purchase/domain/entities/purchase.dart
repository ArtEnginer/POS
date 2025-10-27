import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final String id;
  final String purchaseNumber;
  final String branchId;
  final String? supplierId;
  final String? supplierName;
  final String createdBy;
  final DateTime purchaseDate;
  final DateTime? expectedDate;
  final String status; // draft, ordered, approved, partial, received, cancelled

  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingCost;
  final double totalAmount;
  final double paidAmount;

  final String? paymentTerms;
  final String? paymentMethod;
  final String? notes;

  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.branchId,
    this.supplierId,
    this.supplierName,
    required this.createdBy,
    required this.purchaseDate,
    this.expectedDate,
    this.status = 'draft',
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.shippingCost = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    this.paymentTerms,
    this.paymentMethod,
    this.notes,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.items = const [],
  });

  Purchase copyWith({
    String? id,
    String? purchaseNumber,
    String? branchId,
    String? supplierId,
    String? supplierName,
    String? createdBy,
    DateTime? purchaseDate,
    DateTime? expectedDate,
    String? status,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? shippingCost,
    double? totalAmount,
    double? paidAmount,
    String? paymentTerms,
    String? paymentMethod,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      branchId: branchId ?? this.branchId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      createdBy: createdBy ?? this.createdBy,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedDate: expectedDate ?? this.expectedDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    purchaseNumber,
    branchId,
    supplierId,
    supplierName,
    createdBy,
    purchaseDate,
    expectedDate,
    status,
    subtotal,
    discountAmount,
    taxAmount,
    shippingCost,
    totalAmount,
    paidAmount,
    paymentTerms,
    paymentMethod,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    items,
  ];
}

class PurchaseItem extends Equatable {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String sku;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;
  final double subtotal;
  final double total;
  final String? notes;
  final DateTime createdAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantityOrdered,
    this.quantityReceived = 0,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.subtotal,
    required this.total,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    purchaseId,
    productId,
    productName,
    sku,
    quantityOrdered,
    quantityReceived,
    unitPrice,
    discountAmount,
    taxAmount,
    subtotal,
    total,
    notes,
    createdAt,
  ];
}
