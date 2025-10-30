import '../models/cashier_settings_model.dart';
import '../../../../core/database/hive_service.dart';

/// Cashier Settings Service - Local Storage Only
/// Manage konfigurasi kasir di Hive (tidak sync ke backend)
class CashierSettingsService {
  final HiveService _hiveService;
  static const String _settingsKey = 'cashier_settings';

  CashierSettingsService(this._hiveService);

  /// Get current cashier settings
  /// Return default settings if not exists
  CashierSettingsModel getSettings() {
    try {
      final box = _hiveService.settingsBox;
      final data = box.get(_settingsKey);

      if (data == null) {
        // Return default settings if not exists
        final defaultSettings = CashierSettingsModel.defaultSettings();
        saveSettings(defaultSettings); // Save default
        return defaultSettings;
      }

      return CashierSettingsModel.fromHiveMap(
        Map<String, dynamic>.from(data as Map),
      );
    } catch (e) {
      print('❌ Error getting cashier settings: $e');
      return CashierSettingsModel.defaultSettings();
    }
  }

  /// Save cashier settings
  Future<bool> saveSettings(CashierSettingsModel settings) async {
    try {
      final box = _hiveService.settingsBox;
      await box.put(_settingsKey, settings.toHiveMap());
      print('✅ Cashier settings saved: ${settings.deviceName}');
      return true;
    } catch (e) {
      print('❌ Error saving cashier settings: $e');
      return false;
    }
  }

  /// Update specific field
  Future<bool> updateField(String field, dynamic value) async {
    try {
      final currentSettings = getSettings();
      CashierSettingsModel updatedSettings;

      switch (field) {
        case 'deviceName':
          updatedSettings = currentSettings.copyWith(
            deviceName: value as String,
          );
          break;
        case 'cashierLocation':
          updatedSettings = currentSettings.copyWith(
            cashierLocation: value as String?,
          );
          break;
        case 'counterNumber':
          updatedSettings = currentSettings.copyWith(
            counterNumber: value as String?,
          );
          break;
        case 'floorLevel':
          updatedSettings = currentSettings.copyWith(
            floorLevel: value as String?,
          );
          break;
        case 'receiptPrinter':
          updatedSettings = currentSettings.copyWith(
            receiptPrinter: value as String?,
          );
          break;
        case 'cashDrawerPort':
          updatedSettings = currentSettings.copyWith(
            cashDrawerPort: value as String?,
          );
          break;
        case 'autoPrintReceipt':
          updatedSettings = currentSettings.copyWith(
            autoPrintReceipt: value as bool,
          );
          break;
        case 'themePreference':
          updatedSettings = currentSettings.copyWith(
            themePreference: value as String,
          );
          break;
        default:
          print('⚠️  Unknown field: $field');
          return false;
      }

      return await saveSettings(updatedSettings);
    } catch (e) {
      print('❌ Error updating field $field: $e');
      return false;
    }
  }

  /// Reset to default settings
  Future<bool> resetToDefault() async {
    try {
      final defaultSettings = CashierSettingsModel.defaultSettings();
      return await saveSettings(defaultSettings);
    } catch (e) {
      print('❌ Error resetting settings: $e');
      return false;
    }
  }

  /// Delete settings (clear)
  Future<bool> deleteSettings() async {
    try {
      final box = _hiveService.settingsBox;
      await box.delete(_settingsKey);
      print('✅ Cashier settings deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting settings: $e');
      return false;
    }
  }

  /// Check if settings exists
  bool hasSettings() {
    final box = _hiveService.settingsBox;
    return box.containsKey(_settingsKey);
  }

  /// Get device info untuk transaksi (formatted untuk API)
  Map<String, dynamic> getDeviceInfoForTransaction() {
    final settings = getSettings();
    return settings.getDeviceInfo();
  }

  /// Get cashier location untuk transaksi
  String? getCashierLocation() {
    final settings = getSettings();
    return settings.cashierLocation;
  }

  /// Export settings as JSON (for backup)
  Map<String, dynamic> exportSettings() {
    final settings = getSettings();
    return settings.toHiveMap();
  }

  /// Import settings from JSON (from backup)
  Future<bool> importSettings(Map<String, dynamic> data) async {
    try {
      final settings = CashierSettingsModel.fromHiveMap(data);
      return await saveSettings(settings);
    } catch (e) {
      print('❌ Error importing settings: $e');
      return false;
    }
  }
}
