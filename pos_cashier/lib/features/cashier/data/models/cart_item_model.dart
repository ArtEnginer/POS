import 'package:equatable/equatable.dart';
import 'product_model.dart';

/// Cart item model
class CartItemModel extends Equatable {
  final ProductModel product;
  final double quantity;
  final double discount;
  final double taxPercent; // PPN per item
  final String? note;

  const CartItemModel({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.taxPercent = 0,
    this.note,
  });

  /// Calculate subtotal
  double get subtotal => product.price * quantity;

  /// Calculate discount amount
  double get discountAmount => subtotal * (discount / 100);

  /// Calculate after discount
  double get afterDiscount => subtotal - discountAmount;

  /// Calculate tax amount
  double get taxAmount => afterDiscount * (taxPercent / 100);

  /// Calculate total after discount and tax
  double get total => afterDiscount + taxAmount;

  CartItemModel copyWith({
    ProductModel? product,
    double? quantity,
    double? discount,
    double? taxPercent,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      taxPercent: taxPercent ?? this.taxPercent,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'discount': discount,
      'tax_percent': taxPercent,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
      'total': total,
      'note': note,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productData = json['product'];
    final product =
        productData is Map<String, dynamic>
            ? ProductModel.fromJson(productData)
            : ProductModel.fromJson(
              Map<String, dynamic>.from(productData as Map),
            );

    return CartItemModel(
      product: product,
      quantity:
          (json['quantity'] is num)
              ? (json['quantity'] as num).toDouble()
              : double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      discount:
          (json['discount'] is num)
              ? (json['discount'] as num).toDouble()
              : double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      taxPercent:
          (json['tax_percent'] is num)
              ? (json['tax_percent'] as num).toDouble()
              : double.tryParse(json['tax_percent']?.toString() ?? '0') ?? 0.0,
      note: json['note']?.toString(),
    );
    // Note: subtotal, total, discount_amount, tax_amount are calculated properties, not stored
  }

  @override
  List<Object?> get props => [product, quantity, discount, taxPercent, note];
}
