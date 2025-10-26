import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AuthService {
  final SharedPreferences _prefs;
  final Dio _dio;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _branchDataKey = 'branch_data';

  AuthService(this._prefs, this._dio);

  // ==================== Token Management ====================

  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> deleteTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_branchDataKey);
  }

  bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  Map<String, dynamic> decodeToken(String token) {
    return JwtDecoder.decode(token);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  // ==================== User Data Management ====================

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = _prefs.getString(_userDataKey);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> saveBranchData(Map<String, dynamic> branchData) async {
    await _prefs.setString(_branchDataKey, jsonEncode(branchData));
  }

  Future<Map<String, dynamic>?> getBranchData() async {
    final data = _prefs.getString(_branchDataKey);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // ==================== API Calls ====================

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? branchId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/login',
        data: {
          'username': username,
          'password': password,
          if (branchId != null) 'branchId': branchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract tokens from nested structure
        final tokens = data['tokens'] ?? data;
        final accessToken = tokens['accessToken'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw Exception('Invalid token response');
        }

        // Save tokens
        await saveTokens(accessToken, refreshToken);

        // Save user data
        if (data['user'] != null) {
          await saveUserData(data['user']);
        }

        // Save branch data if exists
        if (data['branch'] != null) {
          await saveBranchData(data['branch']);
        }

        return data;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract tokens from nested structure
        final tokens = data['tokens'] ?? data;
        final accessToken = tokens['accessToken'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw Exception('Invalid token response');
        }

        // Save new tokens
        await saveTokens(accessToken, refreshToken);

        return data;
      } else {
        throw Exception('Token refresh failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Token refresh failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final accessToken = await getAccessToken();

      if (accessToken != null) {
        await _dio.post(
          '${ApiConstants.baseUrl}/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      // Always delete tokens locally
      await deleteTokens();
    }
  }

  /// Get user profile from token
  Future<Map<String, dynamic>?> getUserProfile() async {
    final userData = await getUserData();
    if (userData != null) return userData;

    // Try to decode from token
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final decoded = decodeToken(token);
      return {
        'id': decoded['userId'],
        'username': decoded['username'],
        'fullName': decoded['fullName'],
        'role': decoded['role'],
        'branchId': decoded['branchId'],
      };
    } catch (e) {
      return null;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(String role) async {
    final userData = await getUserProfile();
    if (userData == null) return false;
    return userData['role'] == role;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    return await hasRole('admin') || await hasRole('super_admin');
  }

  /// Get current branch ID
  Future<String?> getCurrentBranchId() async {
    final branchData = await getBranchData();
    if (branchData != null && branchData['id'] != null) {
      return branchData['id'].toString();
    }

    final userData = await getUserProfile();
    if (userData != null && userData['branchId'] != null) {
      return userData['branchId'].toString();
    }

    return null;
  }

  /// Switch branch (for multi-branch users)
  Future<void> switchBranch(String branchId) async {
    try {
      final accessToken = await getAccessToken();

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/switch-branch',
        data: {'branchId': branchId},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract tokens from nested structure
        final tokens = data['tokens'] ?? data;
        final accessToken = tokens['accessToken'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;

        if (accessToken != null && refreshToken != null) {
          // Save new tokens and branch data
          await saveTokens(accessToken, refreshToken);
        }

        if (data['branch'] != null) {
          await saveBranchData(data['branch']);
        }
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Switch branch failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
