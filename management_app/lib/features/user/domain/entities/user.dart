import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final String? phone;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int>? branchIds;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.phone,
    this.avatarUrl,
    this.lastLoginAt,
    this.lastLoginIp,
    required this.createdAt,
    required this.updatedAt,
    this.branchIds,
  });

  // Helper getters
  bool get isActive => status == 'active';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';
  bool get isStaff => role == 'staff';

  // Role display name
  String get roleDisplayName {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Kasir';
      case 'staff':
        return 'Staff';
      default:
        return role;
    }
  }

  // Status display name
  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      case 'suspended':
        return 'Ditangguhkan';
      default:
        return status;
    }
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? status,
    String? phone,
    String? avatarUrl,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? branchIds,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      branchIds: branchIds ?? this.branchIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    fullName,
    role,
    status,
    phone,
    avatarUrl,
    lastLoginAt,
    lastLoginIp,
    createdAt,
    updatedAt,
    branchIds,
  ];
}

// User list result with pagination info
class UserListResult extends Equatable {
  final List<User> users;
  final int total;

  const UserListResult({required this.users, required this.total});

  @override
  List<Object> get props => [users, total];
}

// User statistics
class UserStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int suspendedUsers;
  final int superAdmins;
  final int admins;
  final int managers;
  final int cashiers;
  final int staff;

  const UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.suspendedUsers,
    required this.superAdmins,
    required this.admins,
    required this.managers,
    required this.cashiers,
    required this.staff,
  });

  @override
  List<Object> get props => [
    totalUsers,
    activeUsers,
    inactiveUsers,
    suspendedUsers,
    superAdmins,
    admins,
    managers,
    cashiers,
    staff,
  ];
}
