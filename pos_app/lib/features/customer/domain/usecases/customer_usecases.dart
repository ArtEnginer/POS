import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetAllCustomers {
  final CustomerRepository repository;

  GetAllCustomers(this.repository);

  Future<Either<Failure, List<Customer>>> call() async {
    return await repository.getAllCustomers();
  }
}

class GetCustomerById {
  final CustomerRepository repository;

  GetCustomerById(this.repository);

  Future<Either<Failure, Customer>> call(String id) async {
    return await repository.getCustomerById(id);
  }
}

class SearchCustomers {
  final CustomerRepository repository;

  SearchCustomers(this.repository);

  Future<Either<Failure, List<Customer>>> call(String query) async {
    return await repository.searchCustomers(query);
  }
}

class CreateCustomer {
  final CustomerRepository repository;

  CreateCustomer(this.repository);

  Future<Either<Failure, Customer>> call(Customer customer) async {
    return await repository.createCustomer(customer);
  }
}

class UpdateCustomer {
  final CustomerRepository repository;

  UpdateCustomer(this.repository);

  Future<Either<Failure, Customer>> call(Customer customer) async {
    return await repository.updateCustomer(customer);
  }
}

class DeleteCustomer {
  final CustomerRepository repository;

  DeleteCustomer(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteCustomer(id);
  }
}

class GenerateCustomerCode {
  final CustomerRepository repository;

  GenerateCustomerCode(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateCustomerCode();
  }
}
