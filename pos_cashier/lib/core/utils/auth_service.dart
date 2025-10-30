import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/hive_service.dart';
import '../network/api_service.dart';
import '../constants/app_constants.dart';
import '../navigation/navigation_service.dart';

class AuthService {
  final HiveService _hiveService;
  final ApiService _apiService;
  final NavigationService _navigationService = NavigationService();

  AuthService({
    required HiveService hiveService,
    required ApiService apiService,
  }) : _hiveService = hiveService,
       _apiService = apiService;

  /// Hash password for local storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Login user (with auto server detection & offline fallback)
  Future<Map<String, dynamic>?> login(String username, String password) async {
    print('🔐 Login attempt for: $username');

    // Quick server check (non-blocking, timeout 3s)
    bool serverAvailable = false;
    try {
      print('🔍 Checking server availability...');
      serverAvailable = await _apiService.testConnection().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏱️ Server check timeout - will try offline');
          return false;
        },
      );
      print(
        serverAvailable
            ? '✅ Server is ONLINE - Using online login'
            : '⚠️ Server is OFFLINE - Will use offline login',
      );
    } catch (e) {
      print('⚠️ Server check failed: $e - Will use offline login');
      serverAvailable = false;
    }

    // Try online login first if server is available
    if (serverAvailable) {
      try {
        print('🌐 Attempting ONLINE login...');
        final result = await _apiService.login(username, password);

        if (result != null) {
          final token = result['token'];
          final user = result['user'];
          final branch = result['branch'];

          try {
            // Get auth box and verify it's open
            final authBox = _hiveService.getBox(AppConstants.authBox);

            print('📦 Auth box status:');
            print('   Box name: ${AppConstants.authBox}');
            print('   Box is open: ${authBox.isOpen}');
            print('   Box path: ${authBox.path}');
            print('   Current length: ${authBox.length}');

            // Convert to Map<String, dynamic> to ensure proper serialization
            final userMap =
                user is Map ? Map<String, dynamic>.from(user) : user;
            final branchMap =
                branch is Map ? Map<String, dynamic>.from(branch) : branch;

            // Save main auth data
            print('💾 Saving auth data...');
            await authBox.put('auth_token', token.toString());
            print('   ✓ Token saved');

            await authBox.put('user', userMap);
            print('   ✓ User saved');

            await authBox.put('branch', branchMap);
            print('   ✓ Branch saved');

            await authBox.put('login_time', DateTime.now().toIso8601String());
            print('   ✓ Login time saved');

            // Save credentials for offline login (hashed password)
            final passwordHash = _hashPassword(password);
            print('💾 Saving offline credentials...');

            await authBox.put('saved_username', username.toString());
            print('   ✓ Username saved: $username');

            await authBox.put('saved_password_hash', passwordHash);
            print(
              '   ✓ Password hash saved: ${passwordHash.substring(0, 20)}...',
            );

            // SAVE COPY of user and branch for offline login
            await authBox.put('saved_user', userMap);
            print('   ✓ User copy saved for offline login');

            await authBox.put('saved_branch', branchMap);
            print('   ✓ Branch copy saved for offline login');

            await authBox.put(
              'last_online_login',
              DateTime.now().toIso8601String(),
            );
            print('   ✓ Last online login saved');

            // SET FLAG OFFLINE LOGIN = FALSE untuk online login
            await authBox.put('is_offline', false);
            print('   ✓ is_offline flag set to FALSE (online mode)');

            // CRITICAL: Force flush to disk to ensure data is persisted
            print('💾 Flushing to disk...');
            await authBox.flush();
            print('   ✓ Flush complete');

            // Wait a bit to ensure write is complete
            await Future.delayed(const Duration(milliseconds: 100));

            // DEBUG: Re-read from disk to verify persistence
            print('🔍 Verifying saved data...');
            final verifyUsername = authBox.get('saved_username');
            final verifyHash = authBox.get('saved_password_hash');
            final verifyUser = authBox.get('user');
            final verifyBranch = authBox.get('branch');

            print('🔐 Verification results:');
            print('   Username saved: $username');
            print('   Username verified: $verifyUsername');
            print('   Match: ${username == verifyUsername}');
            print('   Password Hash: ${passwordHash.substring(0, 20)}...');
            print(
              '   Hash verified: ${verifyHash?.toString().substring(0, 20)}...',
            );
            print('   Hash match: ${passwordHash == verifyHash}');
            print('   User saved: ${verifyUser != null}');
            print('   Branch saved: ${verifyBranch != null}');
            print('   Box length after save: ${authBox.length}');
            print('   All keys: ${authBox.keys.toList()}');
          } catch (saveError, stackTrace) {
            print('⚠️ Error saving credentials: $saveError');
            print('   Stack trace: $stackTrace');
            // Continue anyway, we still have the login result
          }

          // Set global auth token
          AppConstants.authToken = token;
          _apiService.setAuthToken(token); // Ensure token is set in API service

          // Set current user info
          AppConstants.currentCashierId = user['id']?.toString();
          AppConstants.currentCashierName = user['fullName'];
          AppConstants.currentBranchId = branch['id']?.toString();

          print(
            '✅ Online login successful: userId=${user['id']}, branchId=${branch['id']}',
          );

          return result;
        }

        // Online login returned null (invalid credentials)
        print('❌ Online login failed - Invalid credentials');
        return null;
      } catch (e) {
        print('⚠️ Online login error: $e');
        // Don't fallback to offline here, let user know online failed
        return null;
      }
    } else {
      // Server not available - try offline login
      print('📴 Server not available - Attempting OFFLINE login...');
      return _offlineLogin(username, password);
    }
  }

  /// Offline login using saved credentials
  Future<Map<String, dynamic>?> _offlineLogin(
    String username,
    String password,
  ) async {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);

      // Get saved data with explicit type handling
      final savedUsername = authBox.get('saved_username')?.toString();
      final savedPasswordHash = authBox.get('saved_password_hash')?.toString();
      final user = authBox.get(
        'saved_user',
      ); // ✅ Gunakan saved_user (bukan user)
      final branch = authBox.get(
        'saved_branch',
      ); // ✅ Gunakan saved_branch (bukan branch)

      // DEBUG: Show what's in the box
      print('🔍 Checking offline credentials:');
      print('   Input Username: "$username"');
      print('   Saved Username: "$savedUsername"');
      print('   Saved Hash exists: ${savedPasswordHash != null}');
      if (savedPasswordHash != null) {
        print('   Saved Hash: ${savedPasswordHash.substring(0, 20)}...');
      }
      print('   Saved User data exists: ${user != null}');
      print('   Saved Branch data exists: ${branch != null}');

      // Validate credentials
      if (savedUsername == null ||
          savedPasswordHash == null ||
          user == null ||
          branch == null) {
        print('❌ No saved credentials found for offline login');
        print(
          '   Missing: ${[if (savedUsername == null) 'username', if (savedPasswordHash == null) 'password_hash', if (user == null) 'user_data', if (branch == null) 'branch_data'].join(', ')}',
        );
        return null;
      }

      if (savedUsername != username) {
        print('❌ Username mismatch: "$savedUsername" != "$username"');
        return null;
      }

      final inputPasswordHash = _hashPassword(password);
      print('🔐 Password validation:');
      print('   Input Hash: ${inputPasswordHash.substring(0, 20)}...');
      print('   Saved Hash: ${savedPasswordHash.substring(0, 20)}...');
      print('   Full Input Hash: $inputPasswordHash');
      print('   Full Saved Hash: $savedPasswordHash');

      if (savedPasswordHash != inputPasswordHash) {
        print('❌ Password hash mismatch');
        return null;
      }

      // Offline login successful
      final token = authBox.get('auth_token') ?? 'offline_token';

      // SET FLAG OFFLINE LOGIN - PENTING untuk header status!
      await authBox.put('is_offline', true);
      print('🔶 Set is_offline flag to TRUE');

      // Restore user and branch to current session (untuk restoreSession)
      await authBox.put('auth_token', token);
      await authBox.put('user', user);
      await authBox.put('branch', branch);
      await authBox.put('login_time', DateTime.now().toIso8601String());
      print('✅ Session data restored from saved credentials');

      // Set global auth token
      AppConstants.authToken = token;
      if (token != 'offline_token') {
        _apiService.setAuthToken(token);
      }

      // Set current user info
      AppConstants.currentCashierId = user['id']?.toString();
      AppConstants.currentCashierName = user['fullName'];
      AppConstants.currentBranchId = branch['id']?.toString();

      print('✅ Offline login successful: ${user['username']}');
      print('📊 Current auth box keys: ${authBox.keys.toList()}');

      return {
        'token': token,
        'user': user,
        'branch': branch,
        'offline_mode': true,
      };
    } catch (e) {
      print('❌ Offline login error: $e');
      return null;
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final token = authBox.get('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current auth token
  String? getAuthToken() {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      return authBox.get('auth_token');
    } catch (e) {
      return null;
    }
  }

  /// Get current user
  Map<String, dynamic>? getCurrentUser() {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final user = authBox.get('user');
      if (user is Map) {
        return Map<String, dynamic>.from(user);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);

      print('🔓 Logging out...');
      print('   Current keys before logout: ${authBox.keys.toList()}');

      // DON'T clear the entire box! We need to keep credentials for offline login
      // Only remove session-related data (token, user, branch, login_time)
      await authBox.delete(
        'auth_token',
      ); // ✅ FIX: Gunakan 'auth_token' bukan 'token'
      await authBox.delete('user');
      await authBox.delete('branch');
      await authBox.delete('login_time');

      // Keep these for next login:
      // - saved_username
      // - saved_password_hash
      // - last_online_login
      // - is_offline (akan di-set ulang saat login berikutnya)

      print('🔓 Logged out - Session cleared but credentials preserved');
      print('   Remaining keys: ${authBox.keys.toList()}');

      // Clear app constants
      AppConstants.authToken = null;
      AppConstants.currentCashierId = null;
      AppConstants.currentCashierName = null;
      AppConstants.currentBranchId = null;
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  /// Restore session from storage
  Future<bool> restoreSession() async {
    try {
      final token = getAuthToken();
      if (token != null) {
        AppConstants.authToken = token;
        _apiService.setAuthToken(token);

        // Restore user info
        final authBox = _hiveService.getBox(AppConstants.authBox);
        final user = authBox.get('user');
        final branch = authBox.get('branch');

        if (user != null) {
          AppConstants.currentCashierId = user['id']?.toString();
          AppConstants.currentCashierName = user['fullName'];
        }

        if (branch != null) {
          AppConstants.currentBranchId = branch['id']?.toString();
        }

        print(
          '🔐 Session restored: userId=${AppConstants.currentCashierId}, branchId=${AppConstants.currentBranchId}',
        );

        // DEBUG: Show saved credentials status
        _debugShowSavedCredentials();

        return true;
      }
      return false;
    } catch (e) {
      print('❌ Session restore error: $e');
      return false;
    }
  }

  /// Debug function to show what's saved in auth box
  void _debugShowSavedCredentials() {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final savedUsername = authBox.get('saved_username');
      final savedPasswordHash = authBox.get('saved_password_hash');

      print('📦 Auth Box Contents:');
      print('   Has Token: ${authBox.get('auth_token') != null}');
      print('   Has User: ${authBox.get('user') != null}');
      print('   Has Branch: ${authBox.get('branch') != null}');
      print('   Saved Username: $savedUsername');
      print('   Has Password Hash: ${savedPasswordHash != null}');
      if (savedPasswordHash != null) {
        print(
          '   Hash Preview: ${savedPasswordHash.toString().substring(0, 20)}...',
        );
      }
    } catch (e) {
      print('⚠️ Error showing saved credentials: $e');
    }
  }

  /// Handle session expiration - logout and show dialog
  Future<void> handleSessionExpired() async {
    print('🔴 Session expired - Logging out and redirecting to login');

    // Clear session data
    await logout();

    // Show session expired dialog and redirect
    await _navigationService.showSessionExpiredDialog();
  }
}
