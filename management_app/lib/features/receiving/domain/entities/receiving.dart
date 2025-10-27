import 'package:equatable/equatable.dart';

class Receiving extends Equatable {
  final String id;
  final String receivingNumber;
  final String purchaseId;
  final String purchaseNumber;
  final String? supplierId;
  final String? supplierName;
  final DateTime receivingDate;
  final String? invoiceNumber; // Nomor Faktur dari supplier
  final String? deliveryOrderNumber; // Nomor Surat Jalan
  final String? vehicleNumber; // Nomor Kendaraan pengiriman
  final String? driverName; // Nama Sopir
  final double subtotal;
  final double itemDiscount; // Total discount dari semua item
  final double itemTax; // Total tax dari semua item
  final double totalDiscount; // Discount untuk total keseluruhan
  final double totalTax; // Tax untuk total keseluruhan
  final double total;
  final String status;
  final String? notes;
  final String? receivedBy;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReceivingItem> items;

  const Receiving({
    required this.id,
    required this.receivingNumber,
    required this.purchaseId,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    required this.receivingDate,
    this.invoiceNumber,
    this.deliveryOrderNumber,
    this.vehicleNumber,
    this.driverName,
    required this.subtotal,
    this.itemDiscount = 0,
    this.itemTax = 0,
    this.totalDiscount = 0,
    this.totalTax = 0,
    required this.total,
    this.status = 'completed',
    this.notes,
    this.receivedBy,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Receiving copyWith({
    String? id,
    String? receivingNumber,
    String? purchaseId,
    String? purchaseNumber,
    String? supplierId,
    String? supplierName,
    DateTime? receivingDate,
    String? invoiceNumber,
    String? deliveryOrderNumber,
    String? vehicleNumber,
    String? driverName,
    double? subtotal,
    double? itemDiscount,
    double? itemTax,
    double? totalDiscount,
    double? totalTax,
    double? total,
    String? status,
    String? notes,
    String? receivedBy,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReceivingItem>? items,
  }) {
    return Receiving(
      id: id ?? this.id,
      receivingNumber: receivingNumber ?? this.receivingNumber,
      purchaseId: purchaseId ?? this.purchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      receivingDate: receivingDate ?? this.receivingDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      deliveryOrderNumber: deliveryOrderNumber ?? this.deliveryOrderNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      subtotal: subtotal ?? this.subtotal,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      itemTax: itemTax ?? this.itemTax,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalTax: totalTax ?? this.totalTax,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      receivedBy: receivedBy ?? this.receivedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    id,
    receivingNumber,
    purchaseId,
    purchaseNumber,
    supplierId,
    supplierName,
    receivingDate,
    invoiceNumber,
    deliveryOrderNumber,
    vehicleNumber,
    driverName,
    subtotal,
    itemDiscount,
    itemTax,
    totalDiscount,
    totalTax,
    total,
    status,
    notes,
    receivedBy,
    syncStatus,
    createdAt,
    updatedAt,
    items,
  ];
}

class ReceivingItem extends Equatable {
  final String id;
  final String receivingId;
  final String? purchaseItemId;
  final String productId;
  final String productName;
  final double poQuantity; // Quantity dari PO original
  final double poPrice; // Price dari PO original
  final double receivedQuantity; // Quantity yang diterima
  final double receivedPrice; // Price saat diterima
  final double discount; // Diskon untuk item ini
  final String discountType; // amount atau percentage
  final double tax; // Tax untuk item ini
  final String taxType; // amount atau percentage
  final double subtotal; // receivedQuantity * receivedPrice
  final double total; // subtotal - discount + tax
  final String? notes;
  final DateTime createdAt;

  const ReceivingItem({
    required this.id,
    required this.receivingId,
    this.purchaseItemId,
    required this.productId,
    required this.productName,
    required this.poQuantity,
    required this.poPrice,
    required this.receivedQuantity,
    required this.receivedPrice,
    this.discount = 0,
    this.discountType = 'amount',
    this.tax = 0,
    this.taxType = 'amount',
    required this.subtotal,
    required this.total,
    this.notes,
    required this.createdAt,
  });

  ReceivingItem copyWith({
    String? id,
    String? receivingId,
    String? purchaseItemId,
    String? productId,
    String? productName,
    double? poQuantity,
    double? poPrice,
    double? receivedQuantity,
    double? receivedPrice,
    double? discount,
    String? discountType,
    double? tax,
    String? taxType,
    double? subtotal,
    double? total,
    String? notes,
    DateTime? createdAt,
  }) {
    return ReceivingItem(
      id: id ?? this.id,
      receivingId: receivingId ?? this.receivingId,
      purchaseItemId: purchaseItemId ?? this.purchaseItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      poQuantity: poQuantity ?? this.poQuantity,
      poPrice: poPrice ?? this.poPrice,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      receivedPrice: receivedPrice ?? this.receivedPrice,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tax: tax ?? this.tax,
      taxType: taxType ?? this.taxType,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    receivingId,
    purchaseItemId,
    productId,
    productName,
    poQuantity,
    poPrice,
    receivedQuantity,
    receivedPrice,
    discount,
    discountType,
    tax,
    taxType,
    subtotal,
    total,
    notes,
    createdAt,
  ];
}
