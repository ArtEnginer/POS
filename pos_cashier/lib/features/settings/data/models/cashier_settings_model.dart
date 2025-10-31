import 'package:equatable/equatable.dart';

/// Cashier Settings Model - Local-Only Storage
/// Menyimpan konfigurasi per kasir di Hive (tidak sync ke backend)
class CashierSettingsModel extends Equatable {
  // Device Information
  final String deviceName;
  final String deviceType;
  final String? deviceIdentifier;

  // Location Information
  final String? cashierLocation;
  final String? counterNumber;
  final String? floorLevel;

  // Hardware Settings
  final String? receiptPrinter;
  final String? cashDrawerPort;

  // Display & UI Settings
  final String displayType;
  final String themePreference;

  // Operational Settings
  final bool isActive;
  final bool allowOfflineMode;
  final bool autoPrintReceipt;
  final bool requireCustomerDisplay;

  // Print Settings
  final String defaultPrintFormat; // 'receipt', 'invoice', 'delivery_note'

  // Additional Settings (flexible JSON)
  final Map<String, dynamic> additionalSettings;

  final DateTime? updatedAt;

  const CashierSettingsModel({
    required this.deviceName,
    this.deviceType = 'windows',
    this.deviceIdentifier,
    this.cashierLocation,
    this.counterNumber,
    this.floorLevel,
    this.receiptPrinter,
    this.cashDrawerPort,
    this.displayType = 'standard',
    this.themePreference = 'light',
    this.isActive = true,
    this.allowOfflineMode = true,
    this.autoPrintReceipt = true,
    this.requireCustomerDisplay = false,
    this.defaultPrintFormat = 'receipt',
    this.additionalSettings = const {},
    this.updatedAt,
  });

  /// Default settings untuk pertama kali install
  factory CashierSettingsModel.defaultSettings() {
    return CashierSettingsModel(
      deviceName: 'Kasir-1',
      deviceType: 'windows',
      cashierLocation: 'Default Location',
      counterNumber: '1',
      displayType: 'standard',
      themePreference: 'light',
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to Hive map for storage
  Map<String, dynamic> toHiveMap() {
    return {
      'device_name': deviceName,
      'device_type': deviceType,
      'device_identifier': deviceIdentifier,
      'cashier_location': cashierLocation,
      'counter_number': counterNumber,
      'floor_level': floorLevel,
      'receipt_printer': receiptPrinter,
      'cash_drawer_port': cashDrawerPort,
      'display_type': displayType,
      'theme_preference': themePreference,
      'is_active': isActive,
      'allow_offline_mode': allowOfflineMode,
      'auto_print_receipt': autoPrintReceipt,
      'require_customer_display': requireCustomerDisplay,
      'default_print_format': defaultPrintFormat,
      'additional_settings': additionalSettings,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create from Hive map
  factory CashierSettingsModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return CashierSettingsModel(
      deviceName: map['device_name']?.toString() ?? 'Kasir-1',
      deviceType: map['device_type']?.toString() ?? 'windows',
      deviceIdentifier: map['device_identifier']?.toString(),
      cashierLocation: map['cashier_location']?.toString(),
      counterNumber: map['counter_number']?.toString(),
      floorLevel: map['floor_level']?.toString(),
      receiptPrinter: map['receipt_printer']?.toString(),
      cashDrawerPort: map['cash_drawer_port']?.toString(),
      displayType: map['display_type']?.toString() ?? 'standard',
      themePreference: map['theme_preference']?.toString() ?? 'light',
      isActive: map['is_active'] as bool? ?? true,
      allowOfflineMode: map['allow_offline_mode'] as bool? ?? true,
      autoPrintReceipt: map['auto_print_receipt'] as bool? ?? true,
      requireCustomerDisplay: map['require_customer_display'] as bool? ?? false,
      defaultPrintFormat: map['default_print_format']?.toString() ?? 'receipt',
      additionalSettings: Map<String, dynamic>.from(
        map['additional_settings'] as Map? ?? {},
      ),
      updatedAt:
          map['updated_at'] != null
              ? DateTime.parse(map['updated_at'] as String)
              : null,
    );
  }

  /// Get device info untuk dikirim ke backend saat transaksi
  Map<String, dynamic> getDeviceInfo() {
    return {
      'platform': deviceType,
      'device_name': deviceName,
      'device_identifier': deviceIdentifier ?? 'unknown',
      'app_version': '1.0.0',
    };
  }

  /// Copy with new values
  CashierSettingsModel copyWith({
    String? deviceName,
    String? deviceType,
    String? deviceIdentifier,
    String? cashierLocation,
    String? counterNumber,
    String? floorLevel,
    String? receiptPrinter,
    String? cashDrawerPort,
    String? displayType,
    String? themePreference,
    bool? isActive,
    bool? allowOfflineMode,
    bool? autoPrintReceipt,
    bool? requireCustomerDisplay,
    String? defaultPrintFormat,
    Map<String, dynamic>? additionalSettings,
  }) {
    return CashierSettingsModel(
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      deviceIdentifier: deviceIdentifier ?? this.deviceIdentifier,
      cashierLocation: cashierLocation ?? this.cashierLocation,
      counterNumber: counterNumber ?? this.counterNumber,
      floorLevel: floorLevel ?? this.floorLevel,
      receiptPrinter: receiptPrinter ?? this.receiptPrinter,
      cashDrawerPort: cashDrawerPort ?? this.cashDrawerPort,
      displayType: displayType ?? this.displayType,
      themePreference: themePreference ?? this.themePreference,
      isActive: isActive ?? this.isActive,
      allowOfflineMode: allowOfflineMode ?? this.allowOfflineMode,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      requireCustomerDisplay:
          requireCustomerDisplay ?? this.requireCustomerDisplay,
      defaultPrintFormat: defaultPrintFormat ?? this.defaultPrintFormat,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    deviceName,
    deviceType,
    deviceIdentifier,
    cashierLocation,
    counterNumber,
    floorLevel,
    receiptPrinter,
    cashDrawerPort,
    displayType,
    themePreference,
    isActive,
    allowOfflineMode,
    autoPrintReceipt,
    requireCustomerDisplay,
    defaultPrintFormat,
    additionalSettings,
    updatedAt,
  ];

  @override
  String toString() {
    return 'CashierSettings(device: $deviceName, location: $cashierLocation, counter: $counterNumber)';
  }
}
