import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final String? icon;
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.icon,
    this.isActive = true,
    this.syncStatus = 'SYNCED',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    String? icon,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
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
    name,
    description,
    parentId,
    icon,
    isActive,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
