import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String customerType; // 'regular', 'vip', 'wholesale', 'retail'
  final String? taxId;
  final double creditLimit;
  final double currentBalance;
  final double totalPurchases;
  final int totalPoints;
  final bool isActive;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.customerType = 'regular',
    this.taxId,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.totalPurchases = 0,
    this.totalPoints = 0,
    this.isActive = true,
    this.notes,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Customer copyWith({
    String? id,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? customerType,
    String? taxId,
    double? creditLimit,
    double? currentBalance,
    double? totalPurchases,
    int? totalPoints,
    bool? isActive,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      customerType: customerType ?? this.customerType,
      taxId: taxId ?? this.taxId,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPoints: totalPoints ?? this.totalPoints,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    phone,
    email,
    address,
    city,
    customerType,
    taxId,
    creditLimit,
    currentBalance,
    totalPurchases,
    totalPoints,
    isActive,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
