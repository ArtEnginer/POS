import 'package:equatable/equatable.dart';

/// Sale Return Item model
class SaleReturnItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? sku;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double discountPercentage;
  final double taxAmount;
  final double taxPercentage;
  final double subtotal;
  final double total;

  const SaleReturnItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.discountPercentage,
    required this.taxAmount,
    required this.taxPercentage,
    required this.subtotal,
    required this.total,
  });

  factory SaleReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']),
      discountAmount: _parseDouble(json['discountAmount']),
      discountPercentage: _parseDouble(json['discountPercentage']),
      taxAmount: _parseDouble(json['taxAmount']),
      taxPercentage: _parseDouble(json['taxPercentage']),
      subtotal: _parseDouble(json['subtotal']),
      total: _parseDouble(json['total']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    sku,
    quantity,
    unitPrice,
    discountAmount,
    discountPercentage,
    taxAmount,
    taxPercentage,
    subtotal,
    total,
  ];
}

/// Sale Return model
class SaleReturnModel extends Equatable {
  final String id;
  final String returnNumber;
  final DateTime returnDate;
  final String reason;
  final double refundAmount;
  final String status;
  final String? processedBy;
  final String? processedByName;
  final List<SaleReturnItemModel> items;

  const SaleReturnModel({
    required this.id,
    required this.returnNumber,
    required this.returnDate,
    required this.reason,
    required this.refundAmount,
    required this.status,
    this.processedBy,
    this.processedByName,
    required this.items,
  });

  factory SaleReturnModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnModel(
      id: json['id']?.toString() ?? '',
      returnNumber: json['returnNumber']?.toString() ?? '',
      returnDate:
          json['returnDate'] != null
              ? DateTime.parse(json['returnDate'])
              : DateTime.now(),
      reason: json['reason']?.toString() ?? '',
      refundAmount: _parseDouble(json['refundAmount']),
      status: json['status']?.toString() ?? 'pending',
      processedBy: json['processedBy']?.toString(),
      processedByName: json['processedByName']?.toString(),
      items:
          (json['items'] as List?)
              ?.map(
                (item) => SaleReturnItemModel.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [
    id,
    returnNumber,
    returnDate,
    reason,
    refundAmount,
    status,
    processedBy,
    processedByName,
    items,
  ];
}
