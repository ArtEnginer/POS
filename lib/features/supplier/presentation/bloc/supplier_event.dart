import 'package:equatable/equatable.dart';
import '../../domain/entities/supplier.dart';

abstract class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuppliersEvent extends SupplierEvent {
  final String? searchQuery;
  final bool? isActive;

  const LoadSuppliersEvent({this.searchQuery, this.isActive});

  @override
  List<Object?> get props => [searchQuery, isActive];
}

class LoadSupplierByIdEvent extends SupplierEvent {
  final String id;

  const LoadSupplierByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CreateSupplierEvent extends SupplierEvent {
  final Supplier supplier;

  const CreateSupplierEvent(this.supplier);

  @override
  List<Object> get props => [supplier];
}

class UpdateSupplierEvent extends SupplierEvent {
  final Supplier supplier;

  const UpdateSupplierEvent(this.supplier);

  @override
  List<Object> get props => [supplier];
}

class DeleteSupplierEvent extends SupplierEvent {
  final String id;

  const DeleteSupplierEvent(this.id);

  @override
  List<Object> get props => [id];
}
