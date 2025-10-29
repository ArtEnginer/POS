import 'package:equatable/equatable.dart';

/// Product model for offline storage
class ProductModel extends Equatable {
  final String id;
  final String barcode;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final bool isActive;
  final DateTime? lastSynced;

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.isActive = true,
    this.lastSynced,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _parsePrice(json['selling_price'] ?? json['price']),
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
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseStock(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'is_active': isActive,
      'last_synced': lastSynced?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isActive,
    DateTime? lastSynced,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    barcode,
    name,
    description,
    price,
    stock,
    categoryId,
    categoryName,
    imageUrl,
    isActive,
    lastSynced,
  ];
}
