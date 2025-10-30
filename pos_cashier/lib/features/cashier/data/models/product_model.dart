import 'package:equatable/equatable.dart';

/// Product model for offline storage with incremental sync support
class ProductModel extends Equatable {
  final String id;
  final String barcode;
  final String name;
  final String? description;
  final double price;
  final double costPrice; // ✅ ADDED: Cost price untuk profit calculation
  final double stock;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final bool isActive;
  final DateTime? lastSynced; // Local sync timestamp
  final DateTime? updatedAt; // Server update timestamp (untuk incremental sync)
  final int syncVersion; // Versi sync untuk conflict resolution

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    this.description,
    required this.price,
    this.costPrice = 0, // ✅ Default to 0 if not provided
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.isActive = true,
    this.lastSynced,
    this.updatedAt,
    this.syncVersion = 1,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _parsePrice(json['selling_price'] ?? json['price']),
      costPrice: _parsePrice(
        json['cost_price'] ?? json['costPrice'],
      ), // ✅ ADDED
      stock: _parseStock(
        json['stock_quantity'] ?? json['available_quantity'] ?? json['stock'],
      ),
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] ?? true,
      lastSynced:
          json['last_synced'] != null
              ? DateTime.parse(json['last_synced'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      syncVersion: json['sync_version'] ?? 1,
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double _parseStock(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'description': description,
      'price': price,
      'cost_price': costPrice, // ✅ ADDED
      'stock': stock,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'is_active': isActive,
      'last_synced': lastSynced?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_version': syncVersion,
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    String? description,
    double? price,
    double? costPrice, // ✅ ADDED
    double? stock,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isActive,
    DateTime? lastSynced,
    DateTime? updatedAt,
    int? syncVersion,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice, // ✅ ADDED
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      lastSynced: lastSynced ?? this.lastSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  @override
  List<Object?> get props => [
    id,
    barcode,
    name,
    description,
    price,
    costPrice, // ✅ ADDED
    stock,
    categoryId,
    categoryName,
    imageUrl,
    isActive,
    lastSynced,
    updatedAt,
    syncVersion,
  ];
}
