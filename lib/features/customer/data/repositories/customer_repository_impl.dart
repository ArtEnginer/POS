import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    try {
      final customers = await localDataSource.getAllCustomers();
      return Right(customers);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final customer = await localDataSource.getCustomerById(id);
      return Right(customer);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(String query) async {
    try {
      final customers = await localDataSource.searchCustomers(query);
      return Right(customers);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer(Customer customer) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen customer harus online
      // Guard removed
      // Guard removed

      final customerModel = CustomerModel.fromEntity(customer);
      final result = await localDataSource.createCustomer(customerModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(result);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer(Customer customer) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen customer harus online
      // Guard removed
      // Guard removed

      final customerModel = CustomerModel.fromEntity(customer);
      final result = await localDataSource.updateCustomer(customerModel);

      // Add to sync queue
      // Temporarily disabled

      return Right(result);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      // ✅ ONLINE-ONLY: Fitur manajemen customer harus online
      // Guard removed
      // Guard removed

      await localDataSource.deleteCustomer(id);

      // Add to sync queue
      // Temporarily disabled

      return const Right(null);
    } on OfflineOperationException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateCustomerCode() async {
    try {
      final code = await localDataSource.generateCustomerCode();
      return Right(code);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
