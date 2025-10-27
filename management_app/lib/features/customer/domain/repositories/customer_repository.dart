import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getAllCustomers();
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, List<Customer>>> searchCustomers(String query);
  Future<Either<Failure, Customer>> createCustomer(Customer customer);
  Future<Either<Failure, Customer>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, String>> generateCustomerCode();
}
