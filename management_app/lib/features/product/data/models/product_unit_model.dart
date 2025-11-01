import '../../domain/entities/product_unit.dart';

class ProductUnitModel extends ProductUnit {
  const ProductUnitModel({
    required super.id,
    required super.productId,
    required super.unitName,
    required super.conversionValue,
    super.isBaseUnit,
    super.isPurchasable,
    super.isSellable,
    super.barcode,
    super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitModel(
      id: json['id'].toString(),
      productId:
          json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      unitName:
          json['unit_name']?.toString() ?? json['unitName']?.toString() ?? '',
      conversionValue: _parseDouble(
        json['conversion_value'] ?? json['conversionValue'] ?? 1,
      ),
      isBaseUnit: json['is_base_unit'] ?? json['isBaseUnit'] ?? false,
      isPurchasable: json['is_purchasable'] ?? json['isPurchasable'] ?? true,
      isSellable: json['is_sellable'] ?? json['isSellable'] ?? true,
      barcode: json['barcode']?.toString(),
      sortOrder: json['sort_order'] ?? json['sortOrder'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ??
            json['updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      deletedAt:
          json['deleted_at'] != null || json['deletedAt'] != null
              ? DateTime.parse(json['deleted_at'] ?? json['deletedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'conversion_value': conversionValue,
      'is_base_unit': isBaseUnit,
      'is_purchasable': isPurchasable,
      'is_sellable': isSellable,
      'barcode': barcode,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  ProductUnit toEntity() => ProductUnit(
    id: id,
    productId: productId,
    unitName: unitName,
    conversionValue: conversionValue,
    isBaseUnit: isBaseUnit,
    isPurchasable: isPurchasable,
    isSellable: isSellable,
    barcode: barcode,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  ProductUnitModel copyWith({
    String? id,
    String? productId,
    String? unitName,
    double? conversionValue,
    bool? isBaseUnit,
    bool? isPurchasable,
    bool? isSellable,
    String? barcode,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductUnitModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      conversionValue: conversionValue ?? this.conversionValue,
      isBaseUnit: isBaseUnit ?? this.isBaseUnit,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      isSellable: isSellable ?? this.isSellable,
      barcode: barcode ?? this.barcode,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
