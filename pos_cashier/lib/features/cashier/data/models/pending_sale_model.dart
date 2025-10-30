class PendingSaleModel {
  final String id; // Unique ID untuk pending sale
  final List<PendingSaleItem> items; // Produk yang dijual
  final String? customerId; // ID customer (optional)
  final String? customerName; // Nama customer (optional)
  final double totalAmount; // Total harga
  final double discount; // Diskon
  final double tax; // Pajak
  final double grandTotal; // Total akhir
  final String? paymentMethod; // Metode pembayaran (optional)
  final String? notes; // Catatan transaksi
  final DateTime createdAt; // Waktu pending dibuat
  final String createdBy; // User yang membuat pending

  PendingSaleModel({
    required this.id,
    required this.items,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.grandTotal,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  // Convert to Map untuk disimpan di Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'customerId': customerId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Convert from Map (dari Hive)
  factory PendingSaleModel.fromMap(Map<dynamic, dynamic> map) {
    return PendingSaleModel(
      id: map['id'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => PendingSaleItem.fromMap(item as Map))
              .toList() ??
          [],
      customerId: map['customerId'],
      customerName: map['customerName'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      grandTotal: (map['grandTotal'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Copy with untuk update data
  PendingSaleModel copyWith({
    String? id,
    List<PendingSaleItem>? items,
    String? customerId,
    String? customerName,
    double? totalAmount,
    double? discount,
    double? tax,
    double? grandTotal,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PendingSaleModel(
      id: id ?? this.id,
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class PendingSaleItem {
  final String productId;
  final String productName;
  final String? sku;
  final double quantity;
  final double price; // Harga satuan
  final double subtotal; // Total per item (price * quantity)
  final double discount; // Diskon per item
  final String? notes; // Catatan khusus item

  PendingSaleItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.discount = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'discount': discount,
      'notes': notes,
    };
  }

  factory PendingSaleItem.fromMap(Map<dynamic, dynamic> map) {
    return PendingSaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'],
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      notes: map['notes'],
    );
  }

  PendingSaleItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    double? quantity,
    double? price,
    double? subtotal,
    double? discount,
    String? notes,
  }) {
    return PendingSaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
    );
  }
}
