import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'mysql_connector.dart';
import '../utils/encryption_helper.dart';

/// MySQL Configuration Manager
/// Handles storing and retrieving MySQL server configuration
class MySQLConfigManager {
  static const String _keyHost = 'mysql_host';
  static const String _keyPort = 'mysql_port';
  static const String _keyDatabase = 'mysql_database';
  static const String _keyUsername = 'mysql_username';
  static const String _keyPassword = 'mysql_password';
  static const String _keyUseSSL = 'mysql_use_ssl';
  static const String _keyEnabled = 'mysql_enabled';

  final SharedPreferences prefs;

  MySQLConfigManager(this.prefs);

  /// Check if MySQL sync is enabled
  bool get isEnabled => prefs.getBool(_keyEnabled) ?? false;

  /// Enable/disable MySQL sync
  Future<void> setEnabled(bool enabled) async {
    await prefs.setBool(_keyEnabled, enabled);
  }

  /// Get saved MySQL configuration
  Future<MySQLConfig?> getConfig() async {
    if (!isEnabled) return null;

    final host = prefs.getString(_keyHost);
    final port = prefs.getInt(_keyPort);
    final database = prefs.getString(_keyDatabase);
    final username = prefs.getString(_keyUsername);
    final encryptedPassword = prefs.getString(_keyPassword);
    final useSSL = prefs.getBool(_keyUseSSL) ?? false;

    if (host == null ||
        port == null ||
        database == null ||
        username == null ||
        encryptedPassword == null) {
      return null;
    }

    // Decrypt password
    final password = EncryptionHelper.decrypt(encryptedPassword);

    return MySQLConfig(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      useSSL: useSSL,
    );
  }

  /// Save MySQL configuration
  Future<void> saveConfig(MySQLConfig config) async {
    // Encrypt password
    final encryptedPassword = EncryptionHelper.encrypt(config.password);

    await prefs.setString(_keyHost, config.host);
    await prefs.setInt(_keyPort, config.port);
    await prefs.setString(_keyDatabase, config.database);
    await prefs.setString(_keyUsername, config.username);
    await prefs.setString(_keyPassword, encryptedPassword);
    await prefs.setBool(_keyUseSSL, config.useSSL);
    await prefs.setBool(_keyEnabled, true);
  }

  /// Clear MySQL configuration
  Future<void> clearConfig() async {
    await prefs.remove(_keyHost);
    await prefs.remove(_keyPort);
    await prefs.remove(_keyDatabase);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyUseSSL);
    await prefs.setBool(_keyEnabled, false);
  }

  /// Test connection with provided configuration
  static Future<bool> testConnection(
    MySQLConfig config,
    MySQLConnector connector,
  ) async {
    try {
      return await connector.initialize(config);
    } catch (e) {
      return false;
    }
  }
}

/// MySQL Configuration Dialog
class MySQLConfigDialog extends StatefulWidget {
  final MySQLConfig? initialConfig;
  final Function(MySQLConfig config) onSave;

  const MySQLConfigDialog({Key? key, this.initialConfig, required this.onSave})
    : super(key: key);

  @override
  State<MySQLConfigDialog> createState() => _MySQLConfigDialogState();
}

class _MySQLConfigDialogState extends State<MySQLConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _databaseController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _useSSL = false;
  bool _isTestingConnection = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(
      text: widget.initialConfig?.host ?? 'localhost',
    );
    _portController = TextEditingController(
      text: widget.initialConfig?.port.toString() ?? '3306',
    );
    _databaseController = TextEditingController(
      text: widget.initialConfig?.database ?? 'pos_db',
    );
    _usernameController = TextEditingController(
      text: widget.initialConfig?.username ?? 'root',
    );
    _passwordController = TextEditingController(
      text: widget.initialConfig?.password ?? '',
    );
    _useSSL = widget.initialConfig?.useSSL ?? false;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    try {
      final config = MySQLConfig(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        useSSL: _useSSL,
      );

      // Test connection via health check
      final connector = MySQLConnector(
        logger: Logger(printer: PrettyPrinter()),
      );

      final success = await connector.initialize(config);
      connector.dispose();

      setState(() {
        _testResult =
            success
                ? '✓ Koneksi berhasil!'
                : '✗ Koneksi gagal. Periksa konfigurasi.';
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) return;

    final config = MySQLConfig(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      database: _databaseController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useSSL: _useSSL,
    );

    widget.onSave(config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi MySQL Server'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host/IP Address',
                  hintText: 'localhost atau 192.168.1.100',
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Host tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '3306',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Port tidak boleh kosong';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Port harus antara 1-65535';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _databaseController,
                decoration: const InputDecoration(
                  labelText: 'Database',
                  hintText: 'pos_db',
                  prefixIcon: Icon(Icons.storage),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Database tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'root',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Gunakan SSL'),
                subtitle: const Text('Koneksi aman (HTTPS)'),
                value: _useSSL,
                onChanged: (value) {
                  setState(() {
                    _useSSL = value;
                  });
                },
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _testResult!.startsWith('✓')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _testResult!.startsWith('✓')
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color:
                          _testResult!.startsWith('✓')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _isTestingConnection ? null : _testConnection,
          child:
              _isTestingConnection
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Test Koneksi'),
        ),
        ElevatedButton(onPressed: _saveConfig, child: const Text('Simpan')),
      ],
    );
  }
}
