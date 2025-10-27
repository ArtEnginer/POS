import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllCustomers extends CustomerEvent {}

class LoadCustomerById extends CustomerEvent {
  final String id;

  const LoadCustomerById(this.id);

  @override
  List<Object> get props => [id];
}

class SearchCustomersEvent extends CustomerEvent {
  final String query;

  const SearchCustomersEvent(this.query);

  @override
  List<Object> get props => [query];
}

class CreateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const CreateCustomerEvent(this.customer);

  @override
  List<Object> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;

  const DeleteCustomerEvent(this.id);

  @override
  List<Object> get props => [id];
}

class GenerateCustomerCodeEvent extends CustomerEvent {}
