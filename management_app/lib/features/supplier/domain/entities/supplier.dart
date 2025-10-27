import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? taxId;
  final String? paymentTerms;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.taxId,
    this.paymentTerms,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.isActive = true,
    this.notes,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    phone,
    email,
    address,
    city,
    taxId,
    paymentTerms,
    creditLimit,
    currentBalance,
    isActive,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  Supplier copyWith({
    String? id,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? taxId,
    String? paymentTerms,
    double? creditLimit,
    double? currentBalance,
    bool? isActive,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      taxId: taxId ?? this.taxId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
