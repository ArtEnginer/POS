import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    super.code,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.city,
    super.postalCode,
    super.points,
    super.isActive,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      points: json['points'] as int? ?? 0,
      isActive: json['is_active'] == 1,
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
      'postal_code': postalCode,
      'points': points,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      code: customer.code,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      city: customer.city,
      postalCode: customer.postalCode,
      points: customer.points,
      isActive: customer.isActive,
      syncStatus: customer.syncStatus,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      deletedAt: customer.deletedAt,
    );
  }
}
