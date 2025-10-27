import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/socket/socket_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getAllCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<List<CustomerModel>> searchCustomers(String query);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<String> generateCustomerCode();
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final dynamic apiClient;
  final SocketService socketService;
  final AuthService authService;

  CustomerRemoteDataSourceImpl({
    required this.apiClient,
    required this.socketService,
    required this.authService,
  });

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final response = await apiClient.get(
        '/customers',
        queryParameters: {
          'limit': 1000, // Get all customers
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => CustomerModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load customers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await apiClient.get('/customers/$id');

      if (response.statusCode == 200) {
        return CustomerModel.fromJson(response.data['data']);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to load customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final response = await apiClient.get(
        '/customers/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => CustomerModel.fromJson(json)).toList();
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to search customers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final response = await apiClient.post(
        '/customers',
        data: customer.toJson(),
      );

      if (response.statusCode == 201) {
        final newCustomer = CustomerModel.fromJson(response.data['data']);

        // Emit customer created event via Socket.IO
        _emitCustomerUpdate('created', newCustomer);

        return newCustomer;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to create customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final response = await apiClient.put(
        '/customers/${customer.id}',
        data: customer.toJson(),
      );

      if (response.statusCode == 200) {
        final updatedCustomer = CustomerModel.fromJson(response.data['data']);

        // Emit customer updated event via Socket.IO
        _emitCustomerUpdate('updated', updatedCustomer);

        return updatedCustomer;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to update customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final response = await apiClient.delete('/customers/$id');

      if (response.statusCode == 200) {
        // Emit customer deleted event via Socket.IO
        _emitCustomerDelete(id);
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to delete customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<String> generateCustomerCode() async {
    try {
      final response = await apiClient.get('/customers/generate-code');

      if (response.statusCode == 200) {
        return response.data['data']['code'] as String;
      } else {
        throw app_exceptions.ServerException(
          message: 'Failed to generate customer code',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  // Helper methods for Socket.IO events
  void _emitCustomerUpdate(String action, CustomerModel customer) {
    if (socketService.isConnected) {
      socketService.emit('customer:update', {
        'action': action,
        'customerId': customer.id,
        'customer': customer.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _emitCustomerDelete(String customerId) {
    if (socketService.isConnected) {
      socketService.emit('customer:update', {
        'action': 'deleted',
        'customerId': customerId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
}
