import 'package:equatable/equatable.dart';

/// Unit konversi untuk produk
/// Contoh: 1 BOX = 10 PCS, 1 DUS = 100 PCS
class ProductUnit extends Equatable {
  final String id;
  final String productId;
  final String unitName; // e.g., 'PCS', 'BOX', 'DUS', 'LUSIN'
  final double conversionValue; // Konversi ke unit dasar
  final bool isBaseUnit; // Unit terkecil/dasar
  final bool isPurchasable; // Bisa dibeli dengan unit ini
  final bool isSellable; // Bisa dijual dengan unit ini
  final String? barcode; // Barcode khusus untuk unit ini
  final int sortOrder; // Urutan tampilan
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ProductUnit({
    required this.id,
    required this.productId,
    required this.unitName,
    required this.conversionValue,
    this.isBaseUnit = false,
    this.isPurchasable = true,
    this.isSellable = true,
    this.barcode,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Display name dengan conversion info
  String get displayName {
    if (isBaseUnit) return unitName;
    if (conversionValue == 1) return unitName;
    return '$unitName (${conversionValue.toInt()}x)';
  }

  /// Konversi dari unit ini ke unit dasar
  double toBaseUnit(double quantity) {
    return quantity * conversionValue;
  }

  /// Konversi dari unit dasar ke unit ini
  double fromBaseUnit(double baseQuantity) {
    return baseQuantity / conversionValue;
  }

  /// Check apakah quantity dapat dijual/dibeli dalam unit ini
  bool canSell(double quantity) {
    return isSellable && quantity > 0;
  }

  bool canPurchase(double quantity) {
    return isPurchasable && quantity > 0;
  }

  ProductUnit copyWith({
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
    return ProductUnit(
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

  @override
  List<Object?> get props => [
    id,
    productId,
    unitName,
    conversionValue,
    isBaseUnit,
    isPurchasable,
    isSellable,
    barcode,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
