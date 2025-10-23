import '../../domain/entities/pending_sale.dart';
import 'sale_model.dart';

class PendingSaleModel extends PendingSale {
  const PendingSaleModel({
    required super.id,
    required super.pendingNumber,
    super.customerId,
    super.customerName,
    required super.savedAt,
    required super.savedBy,
    super.notes,
    required super.items,
    required super.subtotal,
    required super.tax,
    required super.discount,
    required super.total,
  });

  factory PendingSaleModel.fromJson(Map<String, dynamic> json) {
    return PendingSaleModel(
      id: json['id'] as String,
      pendingNumber: json['pending_number'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      savedAt: DateTime.parse(json['saved_at'] as String),
      savedBy: json['saved_by'] as String,
      notes: json['notes'] as String?,
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map(
                    (item) =>
                        SaleItemModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : [],
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pending_number': pendingNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'saved_at': savedAt.toIso8601String(),
      'saved_by': savedBy,
      'notes': notes,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
    };
  }

  factory PendingSaleModel.fromEntity(PendingSale pendingSale) {
    return PendingSaleModel(
      id: pendingSale.id,
      pendingNumber: pendingSale.pendingNumber,
      customerId: pendingSale.customerId,
      customerName: pendingSale.customerName,
      savedAt: pendingSale.savedAt,
      savedBy: pendingSale.savedBy,
      notes: pendingSale.notes,
      items: pendingSale.items,
      subtotal: pendingSale.subtotal,
      tax: pendingSale.tax,
      discount: pendingSale.discount,
      total: pendingSale.total,
    );
  }
}
