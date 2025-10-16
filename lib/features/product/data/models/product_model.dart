import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.plu,
    required super.barcode,
    required super.name,
    super.description,
    super.categoryId,
    super.categoryName,
    required super.unit,
    required super.purchasePrice,
    required super.sellingPrice,
    required super.stock,
    super.minStock,
    super.imageUrl,
    super.isActive,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      plu: json['plu'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      unit: json['unit'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      stock: json['stock'] as int,
      minStock: json['min_stock'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plu': plu,
      'barcode': barcode,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_stock': minStock,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      plu: product.plu,
      barcode: product.barcode,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      unit: product.unit,
      purchasePrice: product.purchasePrice,
      sellingPrice: product.sellingPrice,
      stock: product.stock,
      minStock: product.minStock,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      syncStatus: product.syncStatus,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );
  }
}
