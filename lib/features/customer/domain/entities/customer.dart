import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? postalCode;
  final int points;
  final bool isActive;
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
    this.postalCode,
    this.points = 0,
    this.isActive = true,
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
    String? postalCode,
    int? points,
    bool? isActive,
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
      postalCode: postalCode ?? this.postalCode,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
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
    postalCode,
    points,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
