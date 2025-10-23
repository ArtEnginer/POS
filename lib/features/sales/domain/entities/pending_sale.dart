import 'package:equatable/equatable.dart';
import 'sale.dart';

class PendingSale extends Equatable {
  final String id;
  final String pendingNumber;
  final String? customerId;
  final String? customerName;
  final DateTime savedAt;
  final String savedBy;
  final String? notes;
  final List<SaleItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  const PendingSale({
    required this.id,
    required this.pendingNumber,
    this.customerId,
    this.customerName,
    required this.savedAt,
    required this.savedBy,
    this.notes,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
  });

  PendingSale copyWith({
    String? id,
    String? pendingNumber,
    String? customerId,
    String? customerName,
    DateTime? savedAt,
    String? savedBy,
    String? notes,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
  }) {
    return PendingSale(
      id: id ?? this.id,
      pendingNumber: pendingNumber ?? this.pendingNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      savedAt: savedAt ?? this.savedAt,
      savedBy: savedBy ?? this.savedBy,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pendingNumber,
    customerId,
    customerName,
    savedAt,
    savedBy,
    notes,
    items,
    subtotal,
    tax,
    discount,
    total,
  ];
}
