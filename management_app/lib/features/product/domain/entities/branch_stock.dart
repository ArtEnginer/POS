import 'package:equatable/equatable.dart';

/// Represents stock information for a product in a specific branch
class BranchStock extends Equatable {
  final String branchId;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;

  const BranchStock({
    required this.branchId,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
  });

  bool get hasStock => quantity > 0;
  bool get isAvailable => availableQuantity > 0;
  bool get hasReserved => reservedQuantity > 0;

  factory BranchStock.fromJson(Map<String, dynamic> json) {
    return BranchStock(
      branchId: json['branchId']?.toString() ?? '',
      quantity: _parseInt(json['quantity']) ?? 0,
      reservedQuantity: _parseInt(json['reservedQuantity']) ?? 0,
      availableQuantity: _parseInt(json['availableQuantity']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'availableQuantity': availableQuantity,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  @override
  List<Object?> get props => [
    branchId,
    quantity,
    reservedQuantity,
    availableQuantity,
  ];
}
