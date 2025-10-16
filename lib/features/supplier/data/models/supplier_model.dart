import '../../domain/entities/supplier.dart';

class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.code,
    required super.name,
    super.contactPerson,
    super.phone,
    super.email,
    super.address,
    super.city,
    super.postalCode,
    super.taxNumber,
    super.paymentTerms,
    super.isActive,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      taxNumber: json['tax_number'] as String?,
      paymentTerms: json['payment_terms'] as int? ?? 0,
      isActive: (json['is_active'] as int? ?? 1) == 1,
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
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'tax_number': taxNumber,
      'payment_terms': paymentTerms,
      'is_active': isActive ? 1 : 0,
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
      contactPerson: supplier.contactPerson,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      city: supplier.city,
      postalCode: supplier.postalCode,
      taxNumber: supplier.taxNumber,
      paymentTerms: supplier.paymentTerms,
      isActive: supplier.isActive,
      syncStatus: supplier.syncStatus,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
      deletedAt: supplier.deletedAt,
    );
  }
}
