import 'package:equatable/equatable.dart';
import 'cart_item_model.dart';

/// Sale/Transaction model for offline storage
class SaleModel extends Equatable {
  final String id;
  final String invoiceNumber;
  final DateTime transactionDate;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final String paymentMethod; // cash, card, qris, etc
  final String? customerId;
  final String? customerName;
  final String cashierId;
  final String cashierName;
  final String? note;
  final bool isSynced;
  final DateTime? syncedAt;
  final DateTime createdAt;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.transactionDate,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    required this.cashierId,
    required this.cashierName,
    this.note,
    this.isSynced = false,
    this.syncedAt,
    required this.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      transactionDate: DateTime.parse(json['transaction_date']),
      items:
          (json['items'] as List?)
              ?.map((item) {
                try {
                  if (item is Map<String, dynamic>) {
                    return CartItemModel.fromJson(item);
                  } else if (item is Map) {
                    return CartItemModel.fromJson(
                      Map<String, dynamic>.from(item),
                    );
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing cart item: $e');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<CartItemModel>()
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      cashierId: json['cashier_id']?.toString() ?? '',
      cashierName: json['cashier_name']?.toString() ?? '',
      note: json['note']?.toString(),
      isSynced: json['is_synced'] ?? false,
      syncedAt:
          json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paid': paid,
      'change': change,
      'payment_method': paymentMethod,
      'customer_id': customerId,
      'customer_name': customerName,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'note': note,
      'is_synced': isSynced,
      'synced_at': syncedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? transactionDate,
    List<CartItemModel>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paid,
    double? change,
    String? paymentMethod,
    String? customerId,
    String? customerName,
    String? cashierId,
    String? cashierName,
    String? note,
    bool? isSynced,
    DateTime? syncedAt,
    DateTime? createdAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      change: change ?? this.change,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    transactionDate,
    items,
    subtotal,
    discount,
    tax,
    total,
    paid,
    change,
    paymentMethod,
    customerId,
    customerName,
    cashierId,
    cashierName,
    note,
    isSynced,
    syncedAt,
    createdAt,
  ];
}
