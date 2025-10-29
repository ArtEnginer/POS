import 'package:shared_preferences/shared_preferences.dart';

/// Utility class untuk mengelola pengaturan aplikasi
class AppSettings {
  // Keys untuk SharedPreferences
  static const String _keyApiBaseUrl = 'api_base_url';
  static const String _keySocketUrl = 'socket_url';
  static const String _keyApiVersion = 'api_version';
  static const String _keyServerConfigured = 'server_configured';

  // Default values
  static const String _defaultApiBaseUrl = 'http://localhost:3001';
  static const String _defaultSocketUrl = 'http://localhost:3001';
  static const String _defaultApiVersion = 'v2';

  /// Get API Base URL
  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiBaseUrl) ?? _defaultApiBaseUrl;
  }

  /// Set API Base URL
  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiBaseUrl, url);
  }

  /// Get Socket URL
  static Future<String> getSocketUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySocketUrl) ?? _defaultSocketUrl;
  }

  /// Set Socket URL
  static Future<void> setSocketUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySocketUrl, url);
  }

  /// Get API Version
  static Future<String> getApiVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiVersion) ?? _defaultApiVersion;
  }

  /// Set API Version
  static Future<void> setApiVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiVersion, version);
  }

  /// Check if server has been configured
  static Future<bool> isServerConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyServerConfigured) ?? false;
  }

  /// Set server configured status
  static Future<void> setServerConfigured(bool configured) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyServerConfigured, configured);
  }

  /// Get full API Base URL with version
  static Future<String> getFullApiBaseUrl() async {
    final baseUrl = await getApiBaseUrl();
    final version = await getApiVersion();
    return '$baseUrl/api/$version';
  }

  /// Reset all settings to default
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiBaseUrl, _defaultApiBaseUrl);
    await prefs.setString(_keySocketUrl, _defaultSocketUrl);
    await prefs.setString(_keyApiVersion, _defaultApiVersion);
    await prefs.setBool(_keyServerConfigured, false);
  }
}
