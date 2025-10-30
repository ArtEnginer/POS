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
      print('\n🔍 ═══════════════════════════════════════════════════════════');
      print('🔍 ORIGINAL SALE DATA (BEFORE TRANSFORM):');
      print('🔍 ═══════════════════════════════════════════════════════════');
      print('Invoice Number: ${saleData['invoice_number']}');
      print(
        'Customer ID: ${saleData['customer_id']} (type: ${saleData['customer_id'].runtimeType})',
      );
      print('Payment Method: ${saleData['payment_method']}');
      print('Subtotal: ${saleData['subtotal']}');
      print('Discount: ${saleData['discount']}');
      print('Tax: ${saleData['tax']}');
      print('Total: ${saleData['total']}');
      print('Paid: ${saleData['paid']}');
      print('Change: ${saleData['change']}');
      print('Note: ${saleData['note']}');
      print('Cashier Location: ${saleData['cashier_location']}');
      print('Device Info: ${saleData['device_info']}');

      print('\n📦 ORIGINAL ITEMS:');
      final originalItems = saleData['items'] as List;
      for (var i = 0; i < originalItems.length; i++) {
        final item = originalItems[i];
        final product = item['product'];
        print('  Item ${i + 1}:');
        print(
          '    Product ID: ${product['id']} (type: ${product['id'].runtimeType})',
        );
        print('    Product Name: ${product['name']}');
        print('    Product Barcode: ${product['barcode']}');
        print('    Product Price: ${product['price']}');
        print('    Product Cost Price: ${product['cost_price']}');
        print('    Quantity: ${item['quantity']}');
        print('    Discount: ${item['discount']}%');
        print('    Tax Percent: ${item['tax_percent']}%'); // ← ADDED
        print('    Tax Amount: ${item['tax_amount']}'); // ← ADDED
        print('    Note: ${item['note']}');
      }
      print('🔍 ═══════════════════════════════════════════════════════════\n');

      // Transform sale data to match backend format
      final items =
          (saleData['items'] as List).map((item) {
            // Calculate item values
            final product = item['product'];
            final quantity = item['quantity'] ?? 1;
            final unitPrice = (product['price'] ?? 0).toDouble();
            final costPrice = (product['cost_price'] ?? 0).toDouble();
            final discountPercentage = (item['discount'] ?? 0).toDouble();
            final taxPercentage =
                (item['tax_percent'] ?? 0).toDouble(); // ← ADDED

            final itemSubtotal = unitPrice * quantity;
            final itemDiscountAmount =
                itemSubtotal * (discountPercentage / 100);
            final afterDiscount = itemSubtotal - itemDiscountAmount;
            final itemTaxAmount =
                afterDiscount * (taxPercentage / 100); // ← ADDED
            final itemTotal = afterDiscount + itemTaxAmount; // ← UPDATED

            // ✅ FIX: Ensure productId is valid integer
            final productIdRaw = product['id'];
            int? productIdValue;

            if (productIdRaw != null && productIdRaw.toString().isNotEmpty) {
              productIdValue = int.tryParse(productIdRaw.toString());
              if (productIdValue == null) {
                print('⚠️ Invalid productId: $productIdRaw');
                throw Exception('Invalid productId: $productIdRaw');
              }
            } else {
              print('❌ Product ID is missing!');
              throw Exception('Product ID is required but missing');
            }

            return {
              'productId': productIdValue, // ✅ Validated integer (required)
              'productName': product['name'] ?? '',
              'sku': product['barcode'] ?? product['sku'] ?? '',
              'quantity': quantity,
              'unitPrice': unitPrice,
              'costPrice': costPrice,
              'discountAmount': itemDiscountAmount,
              'discountPercentage': discountPercentage,
              'taxAmount': itemTaxAmount, // ← FIXED: Use calculated value
              'taxPercentage': taxPercentage, // ← ADDED
              'subtotal': itemSubtotal,
              'total': itemTotal,
              'notes': item['note'] ?? '',
            };
          }).toList();

      // ✅ FIX: Convert customerId - optional field, null is valid
      final customerIdRaw = saleData['customer_id'];
      int? customerIdValue;

      if (customerIdRaw != null &&
          customerIdRaw.toString().isNotEmpty &&
          customerIdRaw.toString() != 'null') {
        customerIdValue = int.tryParse(customerIdRaw.toString());
        // If parsing fails, log warning but continue (customer is optional)
        if (customerIdValue == null) {
          print('⚠️ Invalid customerId: $customerIdRaw, setting to null');
        }
      }

      // ✅ FIX: Ensure branchId is valid integer (required!)
      final branchIdRaw = AppConstants.currentBranchId;
      int? branchIdValue;

      if (branchIdRaw != null && branchIdRaw.isNotEmpty) {
        branchIdValue = int.tryParse(branchIdRaw);
        if (branchIdValue == null) {
          print('❌ Invalid branchId: $branchIdRaw');
          throw Exception('Invalid branchId: $branchIdRaw');
        }
      } else {
        print('❌ Branch ID is missing!');
        throw Exception('Branch ID is required but missing');
      }

      final transformedData = {
        'saleNumber': saleData['invoice_number'],
        'branchId': branchIdValue, // ✅ Validated integer (required)
        'customerId': customerIdValue, // ✅ Validated integer or null (optional)
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
        '   Branch ID: ${transformedData['branchId']} (type: ${transformedData['branchId'].runtimeType})',
      );
      print(
        '   Customer ID: ${transformedData['customerId']} (type: ${transformedData['customerId'].runtimeType})',
      );
      print('   Payment Method: ${transformedData['paymentMethod']}');
      print('   Items Count: ${items.length}');
      print('   Subtotal: ${transformedData['subtotal']}');
      print('   Discount: ${transformedData['discountAmount']}');
      print('   Tax: ${transformedData['taxAmount']}');
      print('   Total: ${transformedData['totalAmount']}');
      print('   Paid: ${transformedData['paidAmount']}');
      print('   Change: ${transformedData['changeAmount']}');

      // Debug: Print ALL items details
      print('\n📦 Items Details (AFTER TRANSFORM):');
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        print('   Item ${i + 1}:');
        print(
          '     - ProductID: ${item['productId']} (type: ${item['productId'].runtimeType})',
        );
        print('     - Name: ${item['productName']}');
        print('     - SKU: ${item['sku']}');
        print('     - Quantity: ${item['quantity']}');
        print('     - Unit Price: ${item['unitPrice']}');
        print('     - Cost Price: ${item['costPrice']}');
        print('     - Discount %: ${item['discountPercentage']}');
        print('     - Discount Amount: ${item['discountAmount']}');
        print('     - Tax %: ${item['taxPercentage']}'); // ← ADDED
        print('     - Tax Amount: ${item['taxAmount']}'); // ← ADDED
        print('     - Subtotal: ${item['subtotal']}');
        print('     - Total: ${item['total']}');
      }

      print('\n📋 FULL REQUEST DATA:');
      print('═══════════════════════════════════════════════════════════');
      print(transformedData);
      print('═══════════════════════════════════════════════════════════\n');

      final response = await _dio.post(
        AppConstants.salesEndpoint,
        data: transformedData,
      );

      print('\n✅ ═══════════════════════════════════════════════════════════');
      print('✅ SERVER RESPONSE:');
      print('✅ ═══════════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Response Data:');
      print(response.data);
      print('✅ ═══════════════════════════════════════════════════════════\n');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('\n❌ ═══════════════════════════════════════════════════════════');
      print('❌ ERROR SYNCING SALE:');
      print('❌ ═══════════════════════════════════════════════════════════');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('❌ ═══════════════════════════════════════════════════════════\n');
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
