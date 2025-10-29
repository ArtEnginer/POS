import 'package:equatable/equatable.dart';
import 'product_model.dart';

/// Cart item model
class CartItemModel extends Equatable {
  final ProductModel product;
  final int quantity;
  final double discount;
  final String? note;

  const CartItemModel({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.note,
  });

  /// Calculate subtotal
  double get subtotal => product.price * quantity;

  /// Calculate discount amount
  double get discountAmount => subtotal * (discount / 100);

  /// Calculate total after discount
  double get total => subtotal - discountAmount;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? discount,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'discount': discount,
      'discount_amount': discountAmount,
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
      quantity: json['quantity'] ?? 1,
      discount: (json['discount'] ?? 0).toDouble(),
      note: json['note']?.toString(),
    );
    // Note: subtotal, total, discount_amount are calculated properties, not stored
  }

  @override
  List<Object?> get props => [product, quantity, discount, note];
}
