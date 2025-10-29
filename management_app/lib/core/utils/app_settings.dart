import 'package:shared_preferences/shared_preferences.dart';

/// Utility class untuk mengakses pengaturan aplikasi
class AppSettings {
  // Private constructor
  AppSettings._();

  // ==================== Company/Store Settings ====================

  static Future<String> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_company_name') ?? 'Toko Saya';
  }

  static Future<void> setCompanyName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_company_name', value);
  }

  static Future<String> getCompanyAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_company_address') ?? '';
  }

  static Future<void> setCompanyAddress(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_company_address', value);
  }

  static Future<String> getCompanyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_company_phone') ?? '';
  }

  static Future<void> setCompanyPhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_company_phone', value);
  }

  static Future<String> getCompanyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_company_email') ?? '';
  }

  static Future<void> setCompanyEmail(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_company_email', value);
  }

  static Future<String> getTaxId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_tax_id') ?? '';
  }

  static Future<void> setTaxId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_tax_id', value);
  }

  static Future<String> getFooterText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_footer_text') ??
        'Terima kasih atas kunjungan Anda';
  }

  static Future<void> setFooterText(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_footer_text', value);
  }

  // ==================== Server Settings ====================

  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? 'http://localhost:3001';
  }

  static Future<void> setApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', value);
  }

  static Future<String> getSocketUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('socket_url') ?? 'ws://localhost:3001';
  }

  static Future<void> setSocketUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('socket_url', value);
  }

  static Future<String> getApiVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_version') ?? 'v2';
  }

  static Future<void> setApiVersion(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_version', value);
  }

  // ==================== Helper Methods ====================

  /// Get complete API URL (base + version)
  static Future<String> getFullApiUrl() async {
    final baseUrl = await getApiBaseUrl();
    final version = await getApiVersion();
    return '$baseUrl/api/$version';
  }

  /// Clear all settings
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Reset to default settings
  static Future<void> resetToDefaults() async {
    await setCompanyName('Toko Saya');
    await setCompanyAddress('');
    await setCompanyPhone('');
    await setCompanyEmail('');
    await setTaxId('');
    await setFooterText('Terima kasih atas kunjungan Anda');
    await setApiBaseUrl('http://localhost:3001');
    await setSocketUrl('ws://localhost:3001');
    await setApiVersion('v2');
  }

  /// Export all settings as Map
  static Future<Map<String, String>> exportSettings() async {
    return {
      'company_name': await getCompanyName(),
      'company_address': await getCompanyAddress(),
      'company_phone': await getCompanyPhone(),
      'company_email': await getCompanyEmail(),
      'tax_id': await getTaxId(),
      'footer_text': await getFooterText(),
      'api_base_url': await getApiBaseUrl(),
      'socket_url': await getSocketUrl(),
      'api_version': await getApiVersion(),
    };
  }

  /// Import settings from Map
  static Future<void> importSettings(Map<String, String> settings) async {
    if (settings.containsKey('company_name')) {
      await setCompanyName(settings['company_name']!);
    }
    if (settings.containsKey('company_address')) {
      await setCompanyAddress(settings['company_address']!);
    }
    if (settings.containsKey('company_phone')) {
      await setCompanyPhone(settings['company_phone']!);
    }
    if (settings.containsKey('company_email')) {
      await setCompanyEmail(settings['company_email']!);
    }
    if (settings.containsKey('tax_id')) {
      await setTaxId(settings['tax_id']!);
    }
    if (settings.containsKey('footer_text')) {
      await setFooterText(settings['footer_text']!);
    }
    if (settings.containsKey('api_base_url')) {
      await setApiBaseUrl(settings['api_base_url']!);
    }
    if (settings.containsKey('socket_url')) {
      await setSocketUrl(settings['socket_url']!);
    }
    if (settings.containsKey('api_version')) {
      await setApiVersion(settings['api_version']!);
    }
  }
}
