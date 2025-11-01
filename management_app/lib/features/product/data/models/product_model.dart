import 'dart:convert';
import '../../domain/entities/product.dart';
import '../../domain/entities/branch_stock.dart';
import '../../domain/entities/product_unit.dart';
import '../../domain/entities/product_branch_price.dart';
import 'product_unit_model.dart';
import 'product_branch_price_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    super.branchId,
    required super.sku,
    required super.barcode,
    required super.name,
    super.description,
    super.categoryId,
    super.categoryName,
    required super.unit,
    required super.costPrice,
    required super.sellingPrice,
    required super.stock,
    super.minStock,
    super.maxStock,
    super.reorderPoint,
    super.imageUrl,
    super.isActive,
    super.isTrackable,
    super.attributes,
    super.taxRate,
    super.discountPercentage,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.branchStocks,
    super.units,
    super.prices,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse branch stocks if available
    List<BranchStock>? branchStocks;
    if (json['branch_stocks'] != null) {
      final stocksData = json['branch_stocks'];
      if (stocksData is List) {
        branchStocks =
            stocksData
                .map(
                  (stock) =>
                      BranchStock.fromJson(stock as Map<String, dynamic>),
                )
                .toList();
      }
    }

    // Parse product units if available
    List<ProductUnit>? units;
    if (json['units'] != null) {
      final unitsData = json['units'];
      if (unitsData is List) {
        units =
            unitsData
                .map(
                  (unit) =>
                      ProductUnitModel.fromJson(
                        unit as Map<String, dynamic>,
                      ).toEntity(),
                )
                .toList();
      }
    }

    // Parse product prices if available
    List<ProductBranchPrice>? prices;
    if (json['prices'] != null) {
      final pricesData = json['prices'];
      if (pricesData is List) {
        prices =
            pricesData
                .map(
                  (price) =>
                      ProductBranchPriceModel.fromJson(
                        price as Map<String, dynamic>,
                      ).toEntity(),
                )
                .toList();
      }
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branch_id']?.toString(),
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'] as String?,
      unit: json['unit'] as String? ?? 'PCS',
      costPrice: _parseDouble(json['cost_price']) ?? 0.0,
      sellingPrice: _parseDouble(json['selling_price']) ?? 0.0,
      stock: _parseDouble(json['stock_quantity'] ?? json['stock']) ?? 0.0,
      minStock: _parseDouble(json['min_stock']) ?? 0.0,
      maxStock: _parseDouble(json['max_stock']) ?? 0.0,
      reorderPoint: _parseInt(json['reorder_point']) ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isTrackable: json['is_trackable'] == 1 || json['is_trackable'] == true,
      attributes:
          json['attributes'] != null
              ? (json['attributes'] is String
                  ? jsonDecode(json['attributes'] as String)
                  : json['attributes'] as Map<String, dynamic>)
              : null,
      taxRate: _parseDouble(json['tax_rate']) ?? 0.0,
      discountPercentage: _parseDouble(json['discount_percentage']) ?? 0.0,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      branchStocks: branchStocks, // Include branch stocks
      units: units, // Include product units
      prices: prices, // Include product prices
    );
  }

  Map<String, dynamic> toJson() {
    // Don't send ID for new products (let PostgreSQL auto-generate)
    final isNewProduct =
        id.isEmpty || (int.tryParse(id) == null && !id.contains('-'));

    return {
      if (!isNewProduct && int.tryParse(id) != null) 'id': int.parse(id),
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': int.tryParse(categoryId!) ?? categoryId,
      'unit': unit,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'minStock': minStock,
      'maxStock': maxStock,
      'reorderPoint': reorderPoint,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isTrackable': isTrackable,
      if (attributes != null) 'attributes': attributes,
      'taxRate': taxRate,
      'discountPercentage': discountPercentage,
    };
  }

  /// Convert to local SQLite database format
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'reorder_point': reorderPoint,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'is_trackable': isTrackable ? 1 : 0,
      'attributes': attributes != null ? jsonEncode(attributes) : '{}',
      'tax_rate': taxRate,
      'discount_percentage': discountPercentage,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      branchId: product.branchId,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      description: product.description,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      unit: product.unit,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      stock: product.stock,
      minStock: product.minStock,
      maxStock: product.maxStock,
      reorderPoint: product.reorderPoint,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      isTrackable: product.isTrackable,
      attributes: product.attributes,
      taxRate: product.taxRate,
      discountPercentage: product.discountPercentage,
      syncStatus: product.syncStatus,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
      branchStocks: product.branchStocks,
      units: product.units,
      prices: product.prices,
    );
  }

  /// Helper method to safely parse double from dynamic value
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  /// Helper method to safely parse int from dynamic value
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}
