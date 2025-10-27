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
    super.customerType,
    super.taxId,
    super.creditLimit,
    super.currentBalance,
    super.totalPurchases,
    super.totalPoints,
    super.isActive,
    super.notes,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      customerType: json['customer_type'] as String? ?? 'regular',
      taxId: json['tax_id'] as String?,
      creditLimit:
          (json['credit_limit'] is String)
              ? double.tryParse(json['credit_limit']) ?? 0.0
              : (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentBalance:
          (json['current_balance'] is String)
              ? double.tryParse(json['current_balance']) ?? 0.0
              : (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      totalPurchases:
          (json['total_purchases'] is String)
              ? double.tryParse(json['total_purchases']) ?? 0.0
              : (json['total_purchases'] as num?)?.toDouble() ?? 0.0,
      totalPoints: json['total_points'] as int? ?? 0,
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
      'customer_type': customerType,
      'tax_id': taxId,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'total_purchases': totalPurchases,
      'total_points': totalPoints,
      'is_active': isActive,
      'notes': notes,
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
      customerType: customer.customerType,
      taxId: customer.taxId,
      creditLimit: customer.creditLimit,
      currentBalance: customer.currentBalance,
      totalPurchases: customer.totalPurchases,
      totalPoints: customer.totalPoints,
      isActive: customer.isActive,
      notes: customer.notes,
      syncStatus: customer.syncStatus,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      deletedAt: customer.deletedAt,
    );
  }
}
