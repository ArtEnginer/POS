import '../../domain/entities/supplier.dart';

class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.code,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.city,
    super.taxId,
    super.paymentTerms,
    super.creditLimit,
    super.currentBalance,
    super.isActive,
    super.notes,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      taxId: json['tax_id'] as String?,
      paymentTerms: json['payment_terms'] as String?,
      creditLimit:
          (json['credit_limit'] is String)
              ? double.tryParse(json['credit_limit']) ?? 0.0
              : (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentBalance:
          (json['current_balance'] is String)
              ? double.tryParse(json['current_balance']) ?? 0.0
              : (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'tax_id': taxId,
      'payment_terms': paymentTerms,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'is_active': isActive,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory SupplierModel.fromEntity(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      code: supplier.code,
      name: supplier.name,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      city: supplier.city,
      taxId: supplier.taxId,
      paymentTerms: supplier.paymentTerms,
      creditLimit: supplier.creditLimit,
      currentBalance: supplier.currentBalance,
      isActive: supplier.isActive,
      notes: supplier.notes,
      syncStatus: supplier.syncStatus,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
      deletedAt: supplier.deletedAt,
    );
  }
}
