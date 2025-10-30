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

  // Cost & Profit tracking
  final double? totalCost;
  final double? grossProfit;
  final double? profitMargin;
  final String? cashierLocation;
  final Map<String, dynamic>? deviceInfo;

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
    this.totalCost,
    this.grossProfit,
    this.profitMargin,
    this.cashierLocation,
    this.deviceInfo,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber:
          json['invoiceNumber']?.toString() ??
          json['invoice_number']?.toString() ??
          '',
      transactionDate:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : (json['transaction_date'] != null
                  ? DateTime.parse(json['transaction_date'])
                  : DateTime.now()),
      items:
          (json['items'] as List?)
              ?.map((item) {
                try {
                  if (item is Map<String, dynamic>) {
                    // Transform backend flat structure to nested CartItemModel structure
                    final transformedItem = {
                      'product': {
                        'id': item['productId']?.toString() ?? '',
                        'name': item['productName']?.toString() ?? '',
                        'sku': item['sku']?.toString() ?? '',
                        'price':
                            (item['unitPrice'] is num)
                                ? (item['unitPrice'] as num).toDouble()
                                : double.tryParse(
                                      item['unitPrice']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                      },
                      'quantity':
                          (item['quantity'] is num)
                              ? (item['quantity'] as num).toInt()
                              : int.tryParse(
                                    item['quantity']?.toString() ?? '1',
                                  ) ??
                                  1,
                      'discount':
                          (item['discount'] is num)
                              ? (item['discount'] as num).toDouble()
                              : double.tryParse(
                                    item['discount']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                      'tax_percent':
                          (item['tax'] is num)
                              ? (item['tax'] as num).toDouble()
                              : double.tryParse(
                                    item['tax']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                    };
                    return CartItemModel.fromJson(transformedItem);
                  } else if (item is Map) {
                    final itemMap = Map<String, dynamic>.from(item);
                    final transformedItem = {
                      'product': {
                        'id': itemMap['productId']?.toString() ?? '',
                        'name': itemMap['productName']?.toString() ?? '',
                        'sku': itemMap['sku']?.toString() ?? '',
                        'price':
                            (itemMap['unitPrice'] is num)
                                ? (itemMap['unitPrice'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['unitPrice']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                      },
                      'quantity':
                          (itemMap['quantity'] is num)
                              ? (itemMap['quantity'] as num).toInt()
                              : int.tryParse(
                                    itemMap['quantity']?.toString() ?? '1',
                                  ) ??
                                  1,
                      'discount':
                          (itemMap['discount'] is num)
                              ? (itemMap['discount'] as num).toDouble()
                              : double.tryParse(
                                    itemMap['discount']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                      'tax_percent':
                          (itemMap['tax'] is num)
                              ? (itemMap['tax'] as num).toDouble()
                              : double.tryParse(
                                    itemMap['tax']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                    };
                    return CartItemModel.fromJson(transformedItem);
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
      subtotal:
          (json['subtotal'] is num)
              ? (json['subtotal'] as num).toDouble()
              : double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discount:
          (json['discount'] is num)
              ? (json['discount'] as num).toDouble()
              : double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      tax:
          (json['tax'] is num)
              ? (json['tax'] as num).toDouble()
              : double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      total:
          (json['total'] is num)
              ? (json['total'] as num).toDouble()
              : double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      paid:
          (json['paidAmount'] is num)
              ? (json['paidAmount'] as num).toDouble()
              : (json['paid'] is num)
              ? (json['paid'] as num).toDouble()
              : double.tryParse(
                    json['paidAmount']?.toString() ??
                        json['paid']?.toString() ??
                        '0',
                  ) ??
                  0.0,
      change:
          (json['changeAmount'] is num)
              ? (json['changeAmount'] as num).toDouble()
              : (json['change'] is num)
              ? (json['change'] as num).toDouble()
              : double.tryParse(
                    json['changeAmount']?.toString() ??
                        json['change']?.toString() ??
                        '0',
                  ) ??
                  0.0,
      paymentMethod:
          json['paymentMethod']?.toString() ??
          json['payment_method']?.toString() ??
          'cash',
      customerId:
          json['customerId']?.toString() ?? json['customer_id']?.toString(),
      customerName:
          json['customerName']?.toString() ?? json['customer_name']?.toString(),
      cashierId:
          json['cashierId']?.toString() ?? json['cashier_id']?.toString() ?? '',
      cashierName:
          json['cashierName']?.toString() ??
          json['cashier_name']?.toString() ??
          '',
      note: json['notes']?.toString() ?? json['note']?.toString(),
      isSynced: json['isSynced'] ?? json['is_synced'] ?? true,
      syncedAt:
          json['syncedAt'] != null
              ? DateTime.parse(json['syncedAt'])
              : (json['synced_at'] != null
                  ? DateTime.parse(json['synced_at'])
                  : null),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
      totalCost:
          json['total_cost'] != null
              ? (json['total_cost'] as num).toDouble()
              : null,
      grossProfit:
          json['gross_profit'] != null
              ? (json['gross_profit'] as num).toDouble()
              : null,
      profitMargin:
          json['profit_margin'] != null
              ? (json['profit_margin'] as num).toDouble()
              : null,
      cashierLocation: json['cashier_location']?.toString(),
      deviceInfo:
          json['device_info'] != null
              ? Map<String, dynamic>.from(json['device_info'] as Map)
              : null,
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
      'total_cost': totalCost,
      'gross_profit': grossProfit,
      'profit_margin': profitMargin,
      'cashier_location': cashierLocation,
      'device_info': deviceInfo,
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
    double? totalCost,
    double? grossProfit,
    double? profitMargin,
    String? cashierLocation,
    Map<String, dynamic>? deviceInfo,
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
      totalCost: totalCost ?? this.totalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      cashierLocation: cashierLocation ?? this.cashierLocation,
      deviceInfo: deviceInfo ?? this.deviceInfo,
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
    totalCost,
    grossProfit,
    profitMargin,
    cashierLocation,
    deviceInfo,
  ];
}
