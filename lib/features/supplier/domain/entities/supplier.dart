import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? taxNumber;
  final int paymentTerms; // Days
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.postalCode,
    this.taxNumber,
    this.paymentTerms = 0,
    this.isActive = true,
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
    contactPerson,
    phone,
    email,
    address,
    city,
    postalCode,
    taxNumber,
    paymentTerms,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  Supplier copyWith({
    String? id,
    String? code,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? postalCode,
    String? taxNumber,
    int? paymentTerms,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      taxNumber: taxNumber ?? this.taxNumber,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
