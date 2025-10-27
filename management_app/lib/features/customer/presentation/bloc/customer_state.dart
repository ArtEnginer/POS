import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;

  const CustomerLoaded(this.customers);

  @override
  List<Object> get props => [customers];
}

class CustomerDetailLoaded extends CustomerState {
  final Customer customer;

  const CustomerDetailLoaded(this.customer);

  @override
  List<Object> get props => [customer];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;

  const CustomerOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CustomerCodeGenerated extends CustomerState {
  final String code;

  const CustomerCodeGenerated(this.code);

  @override
  List<Object> get props => [code];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}
