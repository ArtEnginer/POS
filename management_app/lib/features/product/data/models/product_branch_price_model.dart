import '../../domain/entities/product_branch_price.dart';

class ProductBranchPriceModel extends ProductBranchPrice {
  const ProductBranchPriceModel({
    required super.id,
    required super.productId,
    required super.branchId,
    super.productUnitId,
    required super.costPrice,
    required super.sellingPrice,
    super.wholesalePrice,
    super.memberPrice,
    super.marginPercentage,
    super.validFrom,
    super.validUntil,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.branchCode,
    super.branchName,
    super.unitName,
    super.conversionValue,
  });

  factory ProductBranchPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductBranchPriceModel(
      id: json['id'].toString(),
      productId:
          json['product_id']?.toString() ?? json['productId']?.toString() ?? '',
      branchId:
          json['branch_id']?.toString() ?? json['branchId']?.toString() ?? '',
      productUnitId:
          json['product_unit_id']?.toString() ??
          json['productUnitId']?.toString(),
      costPrice: _parseDouble(json['cost_price'] ?? json['costPrice'] ?? 0),
      sellingPrice: _parseDouble(
        json['selling_price'] ?? json['sellingPrice'] ?? 0,
      ),
      wholesalePrice:
          json['wholesale_price'] != null || json['wholesalePrice'] != null
              ? _parseDouble(json['wholesale_price'] ?? json['wholesalePrice'])
              : null,
      memberPrice:
          json['member_price'] != null || json['memberPrice'] != null
              ? _parseDouble(json['member_price'] ?? json['memberPrice'])
              : null,
      marginPercentage: _parseDouble(
        json['margin_percentage'] ?? json['marginPercentage'] ?? 0,
      ),
      validFrom:
          json['valid_from'] != null || json['validFrom'] != null
              ? DateTime.parse(json['valid_from'] ?? json['validFrom'])
              : null,
      validUntil:
          json['valid_until'] != null || json['validUntil'] != null
              ? DateTime.parse(json['valid_until'] ?? json['validUntil'])
              : null,
      isActive:
          json['is_active'] ??
          json['isActive'] ??
          json['price_is_active'] ??
          true,
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
      branchCode:
          json['branch_code']?.toString() ?? json['branchCode']?.toString(),
      branchName:
          json['branch_name']?.toString() ?? json['branchName']?.toString(),
      unitName: json['unit_name']?.toString() ?? json['unitName']?.toString(),
      conversionValue:
          json['conversion_value'] != null || json['conversionValue'] != null
              ? _parseDouble(
                json['conversion_value'] ?? json['conversionValue'],
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'branch_id': branchId,
      'product_unit_id': productUnitId,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'member_price': memberPrice,
      'margin_percentage': marginPercentage,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'branch_code': branchCode,
      'branch_name': branchName,
      'unit_name': unitName,
      'conversion_value': conversionValue,
    };
  }

  ProductBranchPrice toEntity() => ProductBranchPrice(
    id: id,
    productId: productId,
    branchId: branchId,
    productUnitId: productUnitId,
    costPrice: costPrice,
    sellingPrice: sellingPrice,
    wholesalePrice: wholesalePrice,
    memberPrice: memberPrice,
    marginPercentage: marginPercentage,
    validFrom: validFrom,
    validUntil: validUntil,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    branchCode: branchCode,
    branchName: branchName,
    unitName: unitName,
    conversionValue: conversionValue,
  );

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory ProductBranchPriceModel.fromEntity(ProductBranchPrice entity) {
    return ProductBranchPriceModel(
      id: entity.id,
      productId: entity.productId,
      branchId: entity.branchId,
      productUnitId: entity.productUnitId,
      costPrice: entity.costPrice,
      sellingPrice: entity.sellingPrice,
      wholesalePrice: entity.wholesalePrice,
      memberPrice: entity.memberPrice,
      marginPercentage: entity.marginPercentage,
      validFrom: entity.validFrom,
      validUntil: entity.validUntil,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      branchCode: entity.branchCode,
      branchName: entity.branchName,
      unitName: entity.unitName,
      conversionValue: entity.conversionValue,
    );
  }
}
