import 'package:flutter/material.dart';
import '../../core/database/hive_service.dart';
import '../../core/utils/app_settings.dart';

/// Development tools page untuk debugging dan reset data
class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  String _output = '';

  void _addOutput(String message) {
    setState(() {
      _output += '$message\n';
    });
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }

  Future<void> _clearAuthData() async {
    _clearOutput();
    _addOutput('🗑️ Clearing auth data...');
    try {
      await HiveService.instance.clearAuthData();
      _addOutput('✅ Auth data cleared successfully');
      _addOutput('📝 You need to login again');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _clearAllData() async {
    _clearOutput();
    _addOutput('🗑️ Clearing ALL Hive data...');
    try {
      await HiveService.instance.clearEverything();
      _addOutput('✅ All data cleared successfully');
      _addOutput('📝 App state reset to initial');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _resetServerSettings() async {
    _clearOutput();
    _addOutput('🗑️ Resetting server settings...');
    try {
      await AppSettings.resetToDefaults();
      _addOutput('✅ Server settings reset to defaults');
      _addOutput('📝 Default: http://localhost:3001');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _debugAuthBox() {
    _clearOutput();
    _addOutput('🔍 Debugging auth box...\n');
    try {
      final authBox = HiveService.instance.authBox;
      _addOutput('📦 Auth Box Contents:');
      _addOutput('   Total keys: ${authBox.length}\n');

      if (authBox.isEmpty) {
        _addOutput('   (Empty - no data saved)');
      } else {
        for (var key in authBox.keys) {
          final value = authBox.get(key);
          if (value is String) {
            final preview =
                value.length > 50 ? '${value.substring(0, 50)}...' : value;
            _addOutput('   [$key] = "$preview"');
          } else if (value is Map) {
            _addOutput('   [$key] = Map with ${value.length} entries');
          } else {
            _addOutput('   [$key] = ${value?.runtimeType ?? 'null'}');
          }
        }
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _showAllBoxStats() {
    _clearOutput();
    _addOutput('📊 All Hive Boxes Statistics:\n');
    try {
      _addOutput('Products: ${HiveService.instance.productsBox.length} items');
      _addOutput('Sales: ${HiveService.instance.salesBox.length} items');
      _addOutput(
        'Customers: ${HiveService.instance.customersBox.length} items',
      );
      _addOutput(
        'Categories: ${HiveService.instance.categoriesBox.length} items',
      );
      _addOutput('Settings: ${HiveService.instance.settingsBox.length} items');
      _addOutput('Auth: ${HiveService.instance.authBox.length} items');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  Future<void> _testHiveWrite() async {
    _clearOutput();
    _addOutput('🧪 Testing Hive Write/Read...\n');
    try {
      final authBox = HiveService.instance.authBox;

      // Test write
      _addOutput('Writing test data...');
      await authBox.put('test_string', 'Hello Hive');
      await authBox.put('test_number', 12345);
      await authBox.put('test_map', {
        'key': 'value',
        'nested': {'data': 'test'},
      });
      await authBox.flush();

      _addOutput('Flushing to disk...');
      await Future.delayed(const Duration(milliseconds: 100));

      // Test read
      _addOutput('\nReading test data...');
      final readString = authBox.get('test_string');
      final readNumber = authBox.get('test_number');
      final readMap = authBox.get('test_map');

      _addOutput('test_string: $readString');
      _addOutput('test_number: $readNumber');
      _addOutput('test_map: $readMap');

      // Verify
      if (readString == 'Hello Hive' &&
          readNumber == 12345 &&
          readMap != null) {
        _addOutput('\n✅ Hive is working correctly!');
      } else {
        _addOutput('\n❌ Hive read/write mismatch!');
      }

      // Cleanup
      await authBox.delete('test_string');
      await authBox.delete('test_number');
      await authBox.delete('test_map');
      _addOutput('\nTest data cleaned up');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Dev Tools'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade900),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Development Tools - Use with caution!',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tools Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Debug Tools
                  const Text(
                    'Debug Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _debugAuthBox,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Debug Auth Box'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAllBoxStats,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Show Stats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _testHiveWrite,
                    icon: const Icon(Icons.science),
                    label: const Text('Test Hive Write/Read'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Clear Tools
                  const Text(
                    'Clear Data Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Clear Auth Data?'),
                              content: const Text(
                                'This will clear login credentials and auth token.\n'
                                'You will need to login again.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) _clearAuthData();
                    },
                    icon: const Icon(Icons.person_remove),
                    label: const Text('Clear Auth Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Clear ALL Data?'),
                              content: const Text(
                                'This will clear ALL Hive data including:\n'
                                '• Auth & credentials\n'
                                '• Products\n'
                                '• Sales\n'
                                '• Customers\n'
                                '• Categories\n'
                                '• Settings\n\n'
                                'This action cannot be undone!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) _clearAllData();
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear ALL Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _resetServerSettings,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Reset Server Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Output Console
                  const Text(
                    'Output Console',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _output.isEmpty ? '> Ready...' : _output,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
