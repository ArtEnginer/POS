import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Hive Service - Fast local database for offline-first operation
class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  bool _isInitialized = false;

  /// Initialize Hive database
  Future<void> init() async {
    if (_isInitialized) return;

    // Get application documents directory for persistent storage
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/hive_db';

    print('📦 Initializing Hive...');
    print('   Hive path: $hivePath');

    // Initialize Hive with explicit path
    await Hive.initFlutter(hivePath);

    // Open all boxes
    print('📂 Opening Hive boxes...');
    await Future.wait([
      Hive.openBox(AppConstants.productsBox),
      Hive.openBox(AppConstants.salesBox),
      Hive.openBox(AppConstants.customersBox),
      Hive.openBox(AppConstants.categoriesBox),
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.authBox),
      Hive.openBox(AppConstants.pendingSalesBox),
    ]);

    _isInitialized = true;

    final authBox = Hive.box(AppConstants.authBox);
    print('✅ Hive initialized successfully');
    print('   Auth box path: ${authBox.path}');
    print('   Auth box is open: ${authBox.isOpen}');
    print('   Auth box current length: ${authBox.length}');

    // DEBUG: Show what's already in auth box
    if (authBox.isNotEmpty) {
      print('   📋 Existing keys in auth box: ${authBox.keys.toList()}');
    }
  }

  /// Get a box by name
  Box getBox(String boxName) {
    if (!_isInitialized) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return Hive.box(boxName);
  }

  /// Products box
  Box get productsBox => getBox(AppConstants.productsBox);

  /// Sales box
  Box get salesBox => getBox(AppConstants.salesBox);

  /// Customers box
  Box get customersBox => getBox(AppConstants.customersBox);

  /// Categories box
  Box get categoriesBox => getBox(AppConstants.categoriesBox);

  /// Settings box
  Box get settingsBox => getBox(AppConstants.settingsBox);

  /// Auth box
  Box get authBox => getBox(AppConstants.authBox);

  /// Pending sales box
  Box get pendingSalesBox => getBox(AppConstants.pendingSalesBox);

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await Future.wait([
      productsBox.clear(),
      salesBox.clear(),
      customersBox.clear(),
      categoriesBox.clear(),
      settingsBox.clear(),
      pendingSalesBox.clear(),
    ]);
  }

  /// Clear auth data only
  Future<void> clearAuthData() async {
    await authBox.clear();
    print('🗑️ Auth data cleared');
  }

  /// Clear everything including auth (complete reset)
  Future<void> clearEverything() async {
    await Future.wait([
      productsBox.clear(),
      salesBox.clear(),
      customersBox.clear(),
      categoriesBox.clear(),
      settingsBox.clear(),
      authBox.clear(),
      pendingSalesBox.clear(),
    ]);
    print('🗑️ All Hive data cleared');
  }

  /// Debug: Show all keys in auth box
  void debugAuthBox() {
    print('📦 Auth Box Debug:');
    print('   Total keys: ${authBox.length}');
    for (var key in authBox.keys) {
      final value = authBox.get(key);
      if (value is String) {
        print(
          '   $key: ${value.length > 50 ? value.substring(0, 50) + '...' : value}',
        );
      } else {
        print('   $key: ${value?.runtimeType ?? 'null'}');
      }
    }
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
