import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../auth/auth_service.dart';
import '../error/exceptions.dart';
import '../navigation/navigation_service.dart';

class ApiClient {
  late final Dio _dio;
  final AuthService _authService;
  final NavigationService _navigationService = NavigationService();
  bool _isRefreshing = false;
  bool _isLoggingOut = false; // Prevent multiple logout attempts
  List<RequestOptions> _pendingRequests = [];

  ApiClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          'Accept': ApiConstants.contentTypeJson,
        },
      ),
    );

    // Add JWT interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach access token to every request
          final token = await _authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] =
                '${ApiConstants.bearerPrefix} $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - Token expired
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              // Try to refresh token
              await _authService.refreshAccessToken();

              // Retry the original request with new token
              final options = error.requestOptions;
              final token = await _authService.getAccessToken();
              options.headers['Authorization'] =
                  '${ApiConstants.bearerPrefix} $token';

              final response = await _dio.fetch(options);
              _isRefreshing = false;

              // Retry all pending requests
              _retryPendingRequests();

              return handler.resolve(response);
            } catch (e) {
              _isRefreshing = false;
              _pendingRequests.clear();

              // Prevent multiple logout/dialog attempts
              if (_isLoggingOut) {
                print('⚠️ Already logging out, skipping...');
                return handler.reject(error);
              }

              _isLoggingOut = true;

              // Refresh failed, session expired - logout and redirect
              print('🔴 Token refresh failed: $e');
              await _authService.logout();

              // Show session expired dialog ONCE
              await _navigationService.showSessionExpiredDialog();

              return handler.reject(error);
            }
          }

          // If token is being refreshed, queue this request
          if (_isRefreshing && error.response?.statusCode == 401) {
            _pendingRequests.add(error.requestOptions);
            return handler.reject(error);
          }

          _handleError(error);
          return handler.next(error);
        },
      ),
    );

    // Add logger in debug mode
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }

  // Retry all pending requests after token refresh
  Future<void> _retryPendingRequests() async {
    final requests = List<RequestOptions>.from(_pendingRequests);
    _pendingRequests.clear();

    final token = await _authService.getAccessToken();
    for (final options in requests) {
      options.headers['Authorization'] = '${ApiConstants.bearerPrefix} $token';
      try {
        await _dio.fetch(options);
      } catch (e) {
        // Ignore errors for now
      }
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException(message: 'Connection timeout');

        case DioExceptionType.connectionError:
          return NetworkException(message: 'No internet connection');

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          String message;
          if (responseData is Map<String, dynamic>) {
            message =
                responseData['message'] ??
                error.response?.statusMessage ??
                'Server error';
          } else if (responseData is String) {
            message = responseData;
          } else {
            message = error.response?.statusMessage ?? 'Server error';
          }

          if (statusCode == 401) {
            return UnauthorizedException(message: message);
          }

          return ServerException(
            message: message,
            statusCode: statusCode,
            data: error.response?.data,
          );

        case DioExceptionType.cancel:
          return ServerException(message: 'Request cancelled');

        default:
          return ServerException(message: error.message ?? 'Unknown error');
      }
    }

    return ServerException(message: error.toString());
  }
}
