import 'package:equatable/equatable.dart';

/// Harga produk per branch dan per unit
class ProductBranchPrice extends Equatable {
  final String id;
  final String productId;
  final String branchId;
  final String? productUnitId; // null = harga untuk unit dasar
  final double costPrice; // Harga beli
  final double sellingPrice; // Harga jual
  final double? wholesalePrice; // Harga grosir (optional)
  final double? memberPrice; // Harga member (optional)
  final double marginPercentage; // Auto-calculated dari backend
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Additional info dari join query
  final String? branchCode;
  final String? branchName;
  final String? unitName;
  final double? conversionValue;

  const ProductBranchPrice({
    required this.id,
    required this.productId,
    required this.branchId,
    this.productUnitId,
    required this.costPrice,
    required this.sellingPrice,
    this.wholesalePrice,
    this.memberPrice,
    this.marginPercentage = 0,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.branchCode,
    this.branchName,
    this.unitName,
    this.conversionValue,
  });

  /// Profit per unit
  double get profit => sellingPrice - costPrice;

  /// Check apakah harga masih valid
  bool get isValidNow {
    if (!isActive) return false;

    final now = DateTime.now();

    if (validFrom != null && now.isBefore(validFrom!)) {
      return false;
    }

    if (validUntil != null && now.isAfter(validUntil!)) {
      return false;
    }

    return true;
  }

  /// Get harga terbaik untuk customer type
  double getPriceForCustomerType(String customerType) {
    switch (customerType.toLowerCase()) {
      case 'wholesale':
        return wholesalePrice ?? sellingPrice;
      case 'member':
      case 'vip':
        return memberPrice ?? sellingPrice;
      default:
        return sellingPrice;
    }
  }

  /// Display name untuk UI
  String get displayName {
    final unit = unitName ?? 'BASE';
    final branch = branchCode ?? branchName ?? 'Unknown';
    return '$branch - $unit';
  }

  ProductBranchPrice copyWith({
    String? id,
    String? productId,
    String? branchId,
    String? productUnitId,
    double? costPrice,
    double? sellingPrice,
    double? wholesalePrice,
    double? memberPrice,
    double? marginPercentage,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? branchCode,
    String? branchName,
    String? unitName,
    double? conversionValue,
  }) {
    return ProductBranchPrice(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      branchId: branchId ?? this.branchId,
      productUnitId: productUnitId ?? this.productUnitId,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      memberPrice: memberPrice ?? this.memberPrice,
      marginPercentage: marginPercentage ?? this.marginPercentage,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      unitName: unitName ?? this.unitName,
      conversionValue: conversionValue ?? this.conversionValue,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    branchId,
    productUnitId,
    costPrice,
    sellingPrice,
    wholesalePrice,
    memberPrice,
    marginPercentage,
    validFrom,
    validUntil,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
    branchCode,
    branchName,
    unitName,
    conversionValue,
  ];
}
