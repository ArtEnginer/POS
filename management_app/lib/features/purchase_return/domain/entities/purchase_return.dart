import 'package:equatable/equatable.dart';

class PurchaseReturn extends Equatable {
  final String id;
  final String returnNumber;
  final String receivingId;
  final String receivingNumber;
  final String purchaseId;
  final String purchaseNumber;
  final String? supplierId;
  final String? supplierName;
  final DateTime returnDate;
  final double subtotal;
  final double itemDiscount;
  final double itemTax;
  final double totalDiscount;
  final double totalTax;
  final double total;
  final String status; // DRAFT, COMPLETED, CANCELLED
  final String? reason; // Alasan return
  final String? notes;
  final String? processedBy;
  final String syncStatus; // PENDING, SYNCED
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseReturnItem> items;

  const PurchaseReturn({
    required this.id,
    required this.returnNumber,
    required this.receivingId,
    required this.receivingNumber,
    required this.purchaseId,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    required this.returnDate,
    required this.subtotal,
    this.itemDiscount = 0,
    this.itemTax = 0,
    this.totalDiscount = 0,
    this.totalTax = 0,
    required this.total,
    this.status = 'DRAFT',
    this.reason,
    this.notes,
    this.processedBy,
    this.syncStatus = 'PENDING',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  PurchaseReturn copyWith({
    String? id,
    String? returnNumber,
    String? receivingId,
    String? receivingNumber,
    String? purchaseId,
    String? purchaseNumber,
    String? supplierId,
    String? supplierName,
    DateTime? returnDate,
    double? subtotal,
    double? itemDiscount,
    double? itemTax,
    double? totalDiscount,
    double? totalTax,
    double? total,
    String? status,
    String? reason,
    String? notes,
    String? processedBy,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseReturnItem>? items,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      returnNumber: returnNumber ?? this.returnNumber,
      receivingId: receivingId ?? this.receivingId,
      receivingNumber: receivingNumber ?? this.receivingNumber,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      returnDate: returnDate ?? this.returnDate,
      subtotal: subtotal ?? this.subtotal,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      itemTax: itemTax ?? this.itemTax,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalTax: totalTax ?? this.totalTax,
      total: total ?? this.total,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      processedBy: processedBy ?? this.processedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    returnNumber,
    receivingId,
    receivingNumber,
    purchaseId,
    purchaseNumber,
    supplierId,
    supplierName,
    returnDate,
    subtotal,
    itemDiscount,
    itemTax,
    totalDiscount,
    totalTax,
    total,
    status,
    reason,
    notes,
    processedBy,
    syncStatus,
    createdAt,
    updatedAt,
    items,
  ];
}

class PurchaseReturnItem extends Equatable {
  final String id;
  final String returnId;
  final String receivingItemId;
  final String productId;
  final String productName;
  final double receivedQuantity; // Quantity yang diterima sebelumnya
  final double returnQuantity; // Quantity yang dikembalikan
  final double price; // Harga saat receiving
  final double discount;
  final String discountType;
  final double tax;
  final String taxType;
  final double subtotal; // returnQuantity * price
  final double total; // subtotal - discount + tax
  final String? reason; // Alasan return item ini
  final String? notes;
  final DateTime createdAt;

  const PurchaseReturnItem({
    required this.id,
    required this.returnId,
    required this.receivingItemId,
    required this.productId,
    required this.productName,
    required this.receivedQuantity,
    required this.returnQuantity,
    required this.price,
    this.discount = 0,
    this.discountType = 'AMOUNT',
    this.tax = 0,
    this.taxType = 'AMOUNT',
    required this.subtotal,
    required this.total,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  PurchaseReturnItem copyWith({
    String? id,
    String? returnId,
    String? receivingItemId,
    String? productId,
    String? productName,
    double? receivedQuantity,
    double? returnQuantity,
    double? price,
    double? discount,
    String? discountType,
    double? tax,
    String? taxType,
    double? subtotal,
    double? total,
    String? reason,
    String? notes,
    DateTime? createdAt,
  }) {
    return PurchaseReturnItem(
      id: id ?? this.id,
      returnId: returnId ?? this.returnId,
      receivingItemId: receivingItemId ?? this.receivingItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      returnQuantity: returnQuantity ?? this.returnQuantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tax: tax ?? this.tax,
      taxType: taxType ?? this.taxType,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    returnId,
    receivingItemId,
    productId,
    productName,
    receivedQuantity,
    returnQuantity,
    price,
    discount,
    discountType,
    tax,
    taxType,
    subtotal,
    total,
    reason,
    notes,
    createdAt,
  ];
}
