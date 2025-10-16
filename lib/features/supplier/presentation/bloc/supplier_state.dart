import 'package:equatable/equatable.dart';
import '../../domain/entities/supplier.dart';

abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<Supplier> suppliers;

  const SuppliersLoaded(this.suppliers);

  @override
  List<Object> get props => [suppliers];
}

class SupplierLoaded extends SupplierState {
  final Supplier supplier;

  const SupplierLoaded(this.supplier);

  @override
  List<Object> get props => [supplier];
}

class SupplierOperationSuccess extends SupplierState {
  final String message;

  const SupplierOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError(this.message);

  @override
  List<Object> get props => [message];
}
