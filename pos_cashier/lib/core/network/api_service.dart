import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/app_settings.dart';
import '../navigation/navigation_service.dart';

class ApiService {
  late Dio _dio;
  final NavigationService _navigationService = NavigationService();
  bool _sessionExpiredShown = false;

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add error interceptor for session expiration
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Handle 401 Unauthorized - Session expired
          if (error.response?.statusCode == 401) {
            print('🔴 Session expired (401) - Redirecting to login...');

            // Show session expired dialog and redirect to login
            if (!_sessionExpiredShown) {
              _sessionExpiredShown = true;
              await _navigationService.showSessionExpiredDialog();
              // Reset flag after dialog is shown
              _sessionExpiredShown = false;
            }
          }

          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print(obj), // Debug log
      ),
    );
  }

  /// Update base URL from settings
  Future<void> updateBaseUrlFromSettings() async {
    final apiBaseUrl = await AppSettings.getFullApiBaseUrl();
    _dio.options.baseUrl = apiBaseUrl;
    print('✅ API Base URL updated to: $apiBaseUrl');
  }

  /// Set authentication token
  void setAuthToken(String token) {
    AppConstants.authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Login
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Backend V2 response structure: { success, user, branch, tokens: { accessToken, refreshToken } }
        final token = response.data['tokens']['accessToken'];
        final user = response.data['user'];
        final branch = response.data['branch'];

        // Set token for subsequent requests
        setAuthToken(token);

        print('✅ Login success: ${user['username']}, token set');

        return {'token': token, 'user': user, 'branch': branch};
      }
      return null;
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  /// Get products from server (with branch filter)
  Future<List<Map<String, dynamic>>> getProducts({
    String? branchId,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'isActive': 'true',
      };

      if (branchId != null) {
        queryParams['branchId'] = branchId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  /// Get products count untuk mengetahui berapa batch yang perlu di-download
  Future<int> getProductsCount({String? branchId, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 1,
        'isActive': 'true',
      };

      if (branchId != null) {
        queryParams['branchId'] = branchId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final pagination = response.data['pagination'];
        return pagination?['total'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting products count: $e');
      return 0;
    }
  }

  /// Get products yang berubah setelah timestamp tertentu (incremental sync)
  Future<List<Map<String, dynamic>>> getProductsUpdatedSince({
    required DateTime since,
    String? branchId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'isActive': 'true',
        'updatedSince': since.toIso8601String(),
      };

      if (branchId != null) {
        queryParams['branchId'] = branchId;
      }

      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error getting updated products: $e');
      // Fallback ke getProducts biasa jika server belum support
      return getProducts(branchId: branchId, page: page, limit: limit);
    }
  }

  /// Get categories from server
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get(AppConstants.categoriesEndpoint);

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Sync sale to server (Backend V2 format)
  Future<bool> syncSale(Map<String, dynamic> saleData) async {
    try {
      // Transform sale data to match backend format
      final items =
          (saleData['items'] as List).map((item) {
            // Calculate item values
            final product = item['product'];
            final quantity = item['quantity'] ?? 1;
            final unitPrice = (product['price'] ?? 0).toDouble();
            final costPrice = (product['cost_price'] ?? 0).toDouble();
            final discountPercentage = (item['discount'] ?? 0).toDouble();

            final itemSubtotal = unitPrice * quantity;
            final itemDiscountAmount =
                itemSubtotal * (discountPercentage / 100);
            final itemTotal = itemSubtotal - itemDiscountAmount;

            return {
              'productId': product['id'],
              'productName': product['name'],
              'sku': product['barcode'] ?? product['sku'] ?? '',
              'quantity': quantity,
              'unitPrice': unitPrice,
              'costPrice': costPrice, // ← ADDED
              'discountAmount': itemDiscountAmount,
              'discountPercentage': discountPercentage,
              'taxAmount': 0,
              'subtotal': itemSubtotal,
              'total': itemTotal,
              'notes': item['note'],
            };
          }).toList();

      final transformedData = {
        'saleNumber': saleData['invoice_number'],
        'branchId': AppConstants.currentBranchId,
        'customerId': saleData['customer_id'],
        'items': items,
        'subtotal': saleData['subtotal'],
        'discountAmount': saleData['discount'],
        'discountPercentage': 0,
        'taxAmount': saleData['tax'] ?? 0,
        'totalAmount': saleData['total'],
        'paidAmount': saleData['paid'],
        'changeAmount': saleData['change'],
        'paymentMethod': saleData['payment_method'] ?? 'cash',
        'paymentReference': null,
        'notes': saleData['note'],
        'cashierLocation': saleData['cashier_location'], // ← ADDED
        'deviceInfo': saleData['device_info'], // ← ADDED
      };

      print('📤 Sending sale to server: ${transformedData['saleNumber']}');
      print(
        '   Items: ${items.length}, Total: ${transformedData['totalAmount']}',
      );

      final response = await _dio.post(
        AppConstants.salesEndpoint,
        data: transformedData,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error syncing sale: $e');
      return false;
    }
  }

  /// Get customers from server
  Future<List<Map<String, dynamic>>> getCustomers({
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.customersEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
