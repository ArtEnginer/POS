import 'package:equatable/equatable.dart';
import 'cart_item_model.dart';
import 'sale_return_model.dart';

/// Sale/Transaction model for offline storage
class SaleModel extends Equatable {
  final String id;
  final String invoiceNumber;
  final int? branchId; // Branch ID for multi-branch support
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

  // Returns tracking
  final List<SaleReturnModel> returns;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    this.branchId,
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
    this.returns = const [],
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber:
          json['invoiceNumber']?.toString() ??
          json['invoice_number']?.toString() ??
          '',
      branchId: json['branchId'] ?? json['branch_id'],
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
                    // ✅ FIX: Check if data is from LOCAL storage (nested product) or BACKEND (flat structure)
                    if (item.containsKey('product')) {
                      // LOCAL FORMAT: Data sudah dalam format CartItemModel
                      return CartItemModel.fromJson(item);
                    } else {
                      // BACKEND FORMAT: Transform flat structure to nested CartItemModel
                      final transformedItem = {
                        'product': {
                          'id': item['productId']?.toString() ?? '',
                          'name': item['productName']?.toString() ?? '',
                          'sku': item['sku']?.toString() ?? '',
                          'barcode': item['sku']?.toString() ?? '',
                          'price':
                              (item['unitPrice'] is num)
                                  ? (item['unitPrice'] as num).toDouble()
                                  : double.tryParse(
                                        item['unitPrice']?.toString() ?? '0',
                                      ) ??
                                      0.0,
                          'cost_price':
                              (item['costPrice'] is num)
                                  ? (item['costPrice'] as num).toDouble()
                                  : double.tryParse(
                                        item['costPrice']?.toString() ?? '0',
                                      ) ??
                                      0.0,
                        },
                        'quantity':
                            (item['quantity'] is num)
                                ? (item['quantity'] as num).toDouble()
                                : double.tryParse(
                                      item['quantity']?.toString() ?? '1',
                                    ) ??
                                    1.0,
                        // Support both percentage and amount for discount
                        'discount':
                            (item['discountPercentage'] is num)
                                ? (item['discountPercentage'] as num).toDouble()
                                : double.tryParse(
                                      item['discountPercentage']?.toString() ??
                                          '0',
                                    ) ??
                                    0.0,
                        'discount_amount':
                            (item['discountAmount'] is num)
                                ? (item['discountAmount'] as num).toDouble()
                                : double.tryParse(
                                      item['discountAmount']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        // Support both percentage and amount for tax
                        'tax_percent':
                            (item['taxPercentage'] is num)
                                ? (item['taxPercentage'] as num).toDouble()
                                : (item['taxAmount'] is num &&
                                    item['subtotal'] is num &&
                                    item['subtotal'] > 0)
                                ? ((item['taxAmount'] as num).toDouble() /
                                    (item['subtotal'] as num).toDouble() *
                                    100)
                                : double.tryParse(
                                      item['tax']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'tax_amount':
                            (item['taxAmount'] is num)
                                ? (item['taxAmount'] as num).toDouble()
                                : double.tryParse(
                                      item['taxAmount']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'subtotal':
                            (item['subtotal'] is num)
                                ? (item['subtotal'] as num).toDouble()
                                : double.tryParse(
                                      item['subtotal']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'total':
                            (item['total'] is num)
                                ? (item['total'] as num).toDouble()
                                : double.tryParse(
                                      item['total']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'notes': item['notes']?.toString(),
                      };
                      return CartItemModel.fromJson(transformedItem);
                    }
                  } else if (item is Map) {
                    final itemMap = Map<String, dynamic>.from(item);

                    // ✅ FIX: Check format type
                    if (itemMap.containsKey('product')) {
                      // LOCAL FORMAT
                      return CartItemModel.fromJson(itemMap);
                    } else {
                      // BACKEND FORMAT
                      final transformedItem = {
                        'product': {
                          'id': itemMap['productId']?.toString() ?? '',
                          'name': itemMap['productName']?.toString() ?? '',
                          'sku': itemMap['sku']?.toString() ?? '',
                          'barcode': itemMap['sku']?.toString() ?? '',
                          'price':
                              (itemMap['unitPrice'] is num)
                                  ? (itemMap['unitPrice'] as num).toDouble()
                                  : double.tryParse(
                                        itemMap['unitPrice']?.toString() ?? '0',
                                      ) ??
                                      0.0,
                          'cost_price':
                              (itemMap['costPrice'] is num)
                                  ? (itemMap['costPrice'] as num).toDouble()
                                  : double.tryParse(
                                        itemMap['costPrice']?.toString() ?? '0',
                                      ) ??
                                      0.0,
                        },
                        'quantity':
                            (itemMap['quantity'] is num)
                                ? (itemMap['quantity'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['quantity']?.toString() ?? '1',
                                    ) ??
                                    1.0,
                        'discount':
                            (itemMap['discountPercentage'] is num)
                                ? (itemMap['discountPercentage'] as num)
                                    .toDouble()
                                : double.tryParse(
                                      itemMap['discountPercentage']
                                              ?.toString() ??
                                          '0',
                                    ) ??
                                    0.0,
                        'discount_amount':
                            (itemMap['discountAmount'] is num)
                                ? (itemMap['discountAmount'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['discountAmount']?.toString() ??
                                          '0',
                                    ) ??
                                    0.0,
                        'tax_percent':
                            (itemMap['taxPercentage'] is num)
                                ? (itemMap['taxPercentage'] as num).toDouble()
                                : (itemMap['taxAmount'] is num &&
                                    itemMap['subtotal'] is num &&
                                    itemMap['subtotal'] > 0)
                                ? ((itemMap['taxAmount'] as num).toDouble() /
                                    (itemMap['subtotal'] as num).toDouble() *
                                    100)
                                : double.tryParse(
                                      itemMap['tax']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'tax_amount':
                            (itemMap['taxAmount'] is num)
                                ? (itemMap['taxAmount'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['taxAmount']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'subtotal':
                            (itemMap['subtotal'] is num)
                                ? (itemMap['subtotal'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['subtotal']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'total':
                            (itemMap['total'] is num)
                                ? (itemMap['total'] as num).toDouble()
                                : double.tryParse(
                                      itemMap['total']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                        'notes': itemMap['notes']?.toString(),
                      };
                      return CartItemModel.fromJson(transformedItem);
                    }
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing cart item: $e');
                  print('   Item data: $item');
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
              ? (json['total_cost'] is num
                  ? (json['total_cost'] as num).toDouble()
                  : double.tryParse(json['total_cost']?.toString() ?? '0'))
              : null,
      grossProfit:
          json['gross_profit'] != null
              ? (json['gross_profit'] is num
                  ? (json['gross_profit'] as num).toDouble()
                  : double.tryParse(json['gross_profit']?.toString() ?? '0'))
              : null,
      profitMargin:
          json['profit_margin'] != null
              ? (json['profit_margin'] is num
                  ? (json['profit_margin'] as num).toDouble()
                  : double.tryParse(json['profit_margin']?.toString() ?? '0'))
              : null,
      cashierLocation: json['cashier_location']?.toString(),
      deviceInfo:
          json['device_info'] != null
              ? Map<String, dynamic>.from(json['device_info'] as Map)
              : null,
      returns:
          (json['returns'] as List?)
              ?.map((ret) {
                try {
                  return SaleReturnModel.fromJson(
                    ret is Map<String, dynamic>
                        ? ret
                        : Map<String, dynamic>.from(ret as Map),
                  );
                } catch (e) {
                  print('⚠️ Error parsing return: $e');
                  return null;
                }
              })
              .where((ret) => ret != null)
              .cast<SaleReturnModel>()
              .toList() ??
          [],
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
    int? branchId,
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
    List<SaleReturnModel>? returns,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      branchId: branchId ?? this.branchId,
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
      returns: returns ?? this.returns,
    );
  }

  @override
  List<Object?> get props => [
    id,
    invoiceNumber,
    branchId,
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
    returns,
  ];

  // Helper method to calculate net total after returns
  double get netTotal {
    final totalReturns = returns.fold<double>(
      0.0,
      (sum, ret) => sum + ret.refundAmount,
    );
    return total - totalReturns;
  }

  // Helper method to check if sale has returns
  bool get hasReturns => returns.isNotEmpty;
}
