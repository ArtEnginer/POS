import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String plu;
  final String barcode;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int minStock;
  final String? imageUrl;
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.plu,
    required this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    this.minStock = 0,
    this.imageUrl,
    this.isActive = true,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;
  double get profit => sellingPrice - purchasePrice;
  double get profitMargin => ((profit / purchasePrice) * 100);

  Product copyWith({
    String? id,
    String? plu,
    String? barcode,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? minStock,
    String? imageUrl,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id ?? this.id,
      plu: plu ?? this.plu,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    plu,
    barcode,
    name,
    description,
    categoryId,
    categoryName,
    unit,
    purchasePrice,
    sellingPrice,
    stock,
    minStock,
    imageUrl,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
