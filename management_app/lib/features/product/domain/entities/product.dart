import 'package:equatable/equatable.dart';
import 'branch_stock.dart';
import 'product_unit.dart';
import 'product_branch_price.dart';

class Product extends Equatable {
  final String id;
  final String? branchId;
  final String sku;
  final String barcode;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double stock; // Total stock across all branches
  final double minStock;
  final double maxStock;
  final int reorderPoint;
  final String? imageUrl;
  final bool isActive;
  final bool isTrackable;
  final Map<String, dynamic>? attributes;
  final double taxRate;
  final double discountPercentage;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<BranchStock>? branchStocks; // Stock per branch (from backend)

  // Multi-unit & Pricing
  final List<ProductUnit>? units; // Available units for this product
  final List<ProductBranchPrice>? prices; // Prices per branch per unit

  const Product({
    required this.id,
    this.branchId,
    required this.sku,
    required this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    this.minStock = 0,
    this.maxStock = 0,
    this.reorderPoint = 0,
    this.imageUrl,
    this.isActive = true,
    this.isTrackable = true,
    this.attributes,
    this.taxRate = 0,
    this.discountPercentage = 0,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.branchStocks,
    this.units,
    this.prices,
  });

  // Computed properties
  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;
  bool get needsReorder => stock <= reorderPoint;
  double get profit => sellingPrice - costPrice;
  double get profitMargin => costPrice > 0 ? ((profit / costPrice) * 100) : 0;
  double get finalPrice =>
      sellingPrice - (sellingPrice * discountPercentage / 100);
  double get priceWithTax => finalPrice + (finalPrice * taxRate / 100);

  // Multi-branch helpers
  bool get hasMultipleBranches =>
      branchStocks != null && branchStocks!.length > 1;
  int get totalBranches => branchStocks?.length ?? 0;
  int get branchesWithStock =>
      branchStocks?.where((s) => s.hasStock).length ?? 0;

  // Multi-unit helpers
  bool get hasMultipleUnits => units != null && units!.length > 1;
  int get totalUnits => units?.length ?? 0;
  ProductUnit? get baseUnit =>
      units?.firstWhere((u) => u.isBaseUnit, orElse: () => units!.first);

  // Pricing helpers
  int get totalPrices => prices?.length ?? 0;
  bool get hasBranchSpecificPricing => prices != null && prices!.isNotEmpty;

  // Get price for specific branch and unit
  ProductBranchPrice? getPriceFor({required String branchId, String? unitId}) {
    if (prices == null) return null;
    return prices!.firstWhere(
      (p) =>
          p.branchId == branchId &&
          (unitId == null || p.productUnitId == unitId),
      orElse: () => prices!.first,
    );
  }

  // Backward compatibility getters (TEMPORARY - will be removed after UI update)
  @Deprecated('Use sku instead')
  String get plu => sku;

  @Deprecated('Use costPrice instead')
  double get purchasePrice => costPrice;

  Product copyWith({
    String? id,
    String? branchId,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    double? stock,
    double? minStock,
    double? maxStock,
    int? reorderPoint,
    String? imageUrl,
    bool? isActive,
    bool? isTrackable,
    Map<String, dynamic>? attributes,
    double? taxRate,
    double? discountPercentage,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<BranchStock>? branchStocks,
    List<ProductUnit>? units,
    List<ProductBranchPrice>? prices,
  }) {
    return Product(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isTrackable: isTrackable ?? this.isTrackable,
      attributes: attributes ?? this.attributes,
      taxRate: taxRate ?? this.taxRate,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      branchStocks: branchStocks ?? this.branchStocks,
      units: units ?? this.units,
      prices: prices ?? this.prices,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    sku,
    barcode,
    name,
    description,
    categoryId,
    categoryName,
    unit,
    costPrice,
    sellingPrice,
    stock,
    minStock,
    maxStock,
    reorderPoint,
    imageUrl,
    isActive,
    isTrackable,
    attributes,
    taxRate,
    discountPercentage,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    branchStocks,
    units,
    prices,
  ];
}
