import 'package:flutter/material.dart';
import '../../../../core/database/mysql_connector.dart';
import '../../../../core/database/mysql_config_manager.dart';
import '../../../../core/database/hybrid_sync_manager.dart';
import '../../../../injection_container.dart' as di;

class MySQLSettingsPage extends StatefulWidget {
  const MySQLSettingsPage({Key? key}) : super(key: key);

  @override
  State<MySQLSettingsPage> createState() => _MySQLSettingsPageState();
}

class _MySQLSettingsPageState extends State<MySQLSettingsPage> {
  final _configManager = di.sl<MySQLConfigManager>();
  final _mysqlConnector = di.sl<MySQLConnector>();
  final _hybridSyncManager = di.sl<HybridSyncManager>();

  bool _isEnabled = false;
  MySQLConfig? _currentConfig;
  SyncMode _currentMode = SyncMode.localOnly;
  SyncStatistics? _syncStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    _listenToSyncMode();
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);

    try {
      _isEnabled = _configManager.isEnabled;
      _currentConfig = await _configManager.getConfig();
      _currentMode = _hybridSyncManager.currentMode;
      _syncStats = await _hybridSyncManager.getSyncStatistics();

      // Initialize MySQL if enabled
      if (_isEnabled && _currentConfig != null) {
        await _mysqlConnector.initialize(_currentConfig!);
        await _hybridSyncManager.updateSyncMode();
      }
    } catch (e) {
      _showError('Error loading configuration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listenToSyncMode() {
    _hybridSyncManager.syncModeStream.listen((mode) {
      if (mounted) {
        setState(() => _currentMode = mode);
      }
    });
  }

  Future<void> _showConfigDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => MySQLConfigDialog(
            initialConfig: _currentConfig,
            onSave: (config) async {
              await _saveConfiguration(config);
            },
          ),
    );
  }

  Future<void> _saveConfiguration(MySQLConfig config) async {
    try {
      // Save configuration
      await _configManager.saveConfig(config);

      // Initialize MySQL connector
      final success = await _mysqlConnector.initialize(config);

      if (success) {
        setState(() {
          _isEnabled = true;
          _currentConfig = config;
        });

        // Update sync mode
        await _hybridSyncManager.updateSyncMode();

        // Start auto-sync
        _hybridSyncManager.startAutoSync();

        _showSuccess('Konfigurasi MySQL berhasil disimpan!');

        // Trigger initial sync
        _performSync();
      } else {
        _showError('Tidak dapat terhubung ke MySQL server');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    try {
      if (value) {
        // Enable - show configuration dialog if no config exists
        if (_currentConfig == null) {
          await _showConfigDialog();
        } else {
          await _configManager.setEnabled(true);
          await _mysqlConnector.initialize(_currentConfig!);
          await _hybridSyncManager.updateSyncMode();
          _hybridSyncManager.startAutoSync();

          setState(() => _isEnabled = true);
          _showSuccess('MySQL sync diaktifkan');
        }
      } else {
        // Disable
        await _configManager.setEnabled(false);
        _hybridSyncManager.stopAutoSync();
        _mysqlConnector.stopHeartbeat();

        setState(() => _isEnabled = false);
        _showSuccess('MySQL sync dinonaktifkan');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _performSync() async {
    try {
      _showInfo('Memulai sinkronisasi...');

      final result = await _hybridSyncManager.performSync(
        SyncDirection.bidirectional,
      );

      if (result.success) {
        _showSuccess(
          'Sync berhasil!\n'
          'Upload: ${result.uploadedRecords} records\n'
          'Download: ${result.downloadedRecords} records',
        );

        // Reload statistics
        final stats = await _hybridSyncManager.getSyncStatistics();
        setState(() => _syncStats = stats);
      } else {
        _showError('Sync gagal: ${result.message}');
      }
    } catch (e) {
      _showError('Error saat sync: $e');
    }
  }

  Future<void> _testConnection() async {
    if (_currentConfig == null) {
      _showError('Konfigurasi MySQL belum diatur');
      return;
    }

    try {
      final success = await _mysqlConnector.checkConnection();

      if (success) {
        _showSuccess('Koneksi ke MySQL server berhasil!');
      } else {
        _showError('Tidak dapat terhubung ke MySQL server');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan MySQL')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan MySQL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfiguration,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentMode == SyncMode.hybrid
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color:
                            _currentMode == SyncMode.hybrid
                                ? Colors.green
                                : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getModeTitle(_currentMode),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _getModeDescription(_currentMode),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Aktifkan MySQL Sync'),
                    subtitle: const Text(
                      'Sinkronisasi otomatis dengan MySQL server',
                    ),
                    value: _isEnabled,
                    onChanged: _toggleEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Configuration Card
          if (_isEnabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi Server',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_currentConfig != null) ...[
                      _buildInfoRow('Host', _currentConfig!.host, Icons.dns),
                      _buildInfoRow(
                        'Port',
                        _currentConfig!.port.toString(),
                        Icons.settings_ethernet,
                      ),
                      _buildInfoRow(
                        'Database',
                        _currentConfig!.database,
                        Icons.storage,
                      ),
                      _buildInfoRow(
                        'Username',
                        _currentConfig!.username,
                        Icons.person,
                      ),
                      _buildInfoRow(
                        'SSL',
                        _currentConfig!.useSSL ? 'Aktif' : 'Nonaktif',
                        Icons.security,
                      ),
                    ] else
                      const Text('Konfigurasi belum diatur'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showConfigDialog,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Konfigurasi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.wifi_find),
                            label: const Text('Test Koneksi'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync Statistics Card
            if (_syncStats != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Sinkronisasi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Pending',
                              _syncStats!.totalPending.toString(),
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Synced',
                              _syncStats!.totalSynced.toString(),
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_syncStats!.lastSyncTime != null)
                        Text(
                          'Terakhir sync: ${_formatDateTime(_syncStats!.lastSyncTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _currentMode == SyncMode.hybrid
                                  ? _performSync
                                  : null,
                          icon: const Icon(Icons.sync),
                          label: const Text('Sinkronisasi Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          // Information Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Aplikasi akan otomatis menggunakan database lokal ketika server MySQL tidak tersedia\n'
                    '• Data akan otomatis tersinkronisasi ketika koneksi ke MySQL tersedia\n'
                    '• Sinkronisasi otomatis berjalan setiap 5 menit\n'
                    '• Pastikan MySQL server memiliki endpoint REST API yang sesuai',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  String _getModeTitle(SyncMode mode) {
    switch (mode) {
      case SyncMode.localOnly:
        return 'Mode Lokal';
      case SyncMode.hybrid:
        return 'Mode Hybrid (Online)';
      case SyncMode.onlineOnly:
        return 'Mode Online';
    }
  }

  String _getModeDescription(SyncMode mode) {
    switch (mode) {
      case SyncMode.localOnly:
        return 'Menggunakan database lokal (SQLite)';
      case SyncMode.hybrid:
        return 'Lokal + MySQL Server (Tersinkronisasi)';
      case SyncMode.onlineOnly:
        return 'Hanya menggunakan MySQL Server';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Don't dispose global singletons
    super.dispose();
  }
}
