import 'package:equatable/equatable.dart';

class Sale extends Equatable {
  final String id;
  final String? branchId;
  final String saleNumber;
  final String? customerId;
  final String cashierId;
  final String cashierName;
  final DateTime saleDate;
  final double subtotal;
  final double? tax;
  final double? discount;
  final double total;
  final String paymentMethod; // CASH, CARD, QRIS, E_WALLET
  final double paymentAmount;
  final double changeAmount;
  final String status; // COMPLETED, CANCELLED, REFUNDED
  final String? notes;
  final String? syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem>? items;

  const Sale({
    required this.id,
    this.branchId,
    required this.saleNumber,
    this.customerId,
    required this.cashierId,
    required this.cashierName,
    required this.saleDate,
    required this.subtotal,
    this.tax,
    this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.changeAmount,
    required this.status,
    this.notes,
    this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  Sale copyWith({
    String? id,
    String? branchId,
    String? saleNumber,
    String? customerId,
    String? cashierId,
    String? cashierName,
    DateTime? saleDate,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentMethod,
    double? paymentAmount,
    double? changeAmount,
    String? status,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      saleNumber: saleNumber ?? this.saleNumber,
      customerId: customerId ?? this.customerId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      saleDate: saleDate ?? this.saleDate,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      changeAmount: changeAmount ?? this.changeAmount,
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
    branchId,
    saleNumber,
    customerId,
    cashierId,
    cashierName,
    saleDate,
    subtotal,
    tax,
    discount,
    total,
    paymentMethod,
    paymentAmount,
    changeAmount,
    status,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    items,
  ];
}

class SaleItem extends Equatable {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final double discount;
  final double subtotal;
  final String? syncStatus;
  final DateTime createdAt;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.subtotal,
    this.syncStatus,
    required this.createdAt,
  });

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? discount,
    double? subtotal,
    String? syncStatus,
    DateTime? createdAt,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    saleId,
    productId,
    productName,
    quantity,
    price,
    discount,
    subtotal,
    syncStatus,
    createdAt,
  ];
}
