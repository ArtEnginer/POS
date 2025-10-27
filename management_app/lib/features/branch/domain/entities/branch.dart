import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String id;
  final String code;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final String type; // HQ, BRANCH
  final bool isActive;
  final String? parentBranchId;
  final String? apiKey;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Branch({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    required this.type,
    required this.isActive,
    this.parentBranchId,
    this.apiKey,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'].toString(),
      code: json['code'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      type: json['type'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      parentBranchId:
          json['parent_branch_id']?.toString() ??
          json['parentBranchId']?.toString(),
      apiKey: json['api_key'] ?? json['apiKey'],
      settings: json['settings'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'type': type,
      'is_active': isActive,
      'parent_branch_id': parentBranchId,
      'api_key': apiKey,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Branch copyWith({
    String? id,
    String? code,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? type,
    bool? isActive,
    String? parentBranchId,
    String? apiKey,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      parentBranchId: parentBranchId ?? this.parentBranchId,
      apiKey: apiKey ?? this.apiKey,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isHQ => type == 'HQ';
  bool get isBranch => type == 'BRANCH';

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    address,
    phone,
    email,
    type,
    isActive,
    parentBranchId,
    apiKey,
    settings,
    createdAt,
    updatedAt,
  ];
}
