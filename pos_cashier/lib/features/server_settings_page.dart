import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/utils/app_settings.dart';

class ServerSettingsPage extends StatefulWidget {
  final bool isInitialSetup;

  const ServerSettingsPage({super.key, this.isInitialSetup = false});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrlController = TextEditingController();
  final _socketUrlController = TextEditingController();
  final _apiVersionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _connectionStatus;
  Color? _statusColor;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _socketUrlController.dispose();
    _apiVersionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final apiBaseUrl = await AppSettings.getApiBaseUrl();
    final socketUrl = await AppSettings.getSocketUrl();
    final apiVersion = await AppSettings.getApiVersion();

    _apiUrlController.text = apiBaseUrl;
    _socketUrlController.text = socketUrl;
    _apiVersionController.text = apiVersion;

    setState(() => _isLoading = false);
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _connectionStatus = null;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _apiUrlController.text.trim(),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get(
        '/api/${_apiVersionController.text.trim()}/health',
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectionStatus = '✓ Koneksi berhasil!';
          _statusColor = Colors.green;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Koneksi ke server berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _connectionStatus =
              '✗ Server merespons dengan status: ${response.statusCode}';
          _statusColor = Colors.orange;
        });
      }
    } on DioException catch (e) {
      String errorMsg = 'Error tidak diketahui';
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMsg = '✗ Koneksi timeout';
          break;
        case DioExceptionType.connectionError:
          errorMsg = '✗ Tidak dapat terhubung ke server';
          break;
        case DioExceptionType.badResponse:
          errorMsg = '✗ Server error: ${e.response?.statusCode}';
          break;
        default:
          errorMsg = '✗ ${e.message}';
      }

      setState(() {
        _connectionStatus = errorMsg;
        _statusColor = Colors.red;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() {
        _connectionStatus = '✗ Error: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await AppSettings.setApiBaseUrl(_apiUrlController.text.trim());
      await AppSettings.setSocketUrl(_socketUrlController.text.trim());
      await AppSettings.setApiVersion(_apiVersionController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Pengaturan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya dengan result true
      if (widget.isInitialSetup) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset ke Default'),
            content: const Text(
              'Apakah Anda yakin ingin mereset pengaturan ke nilai default?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await AppSettings.resetToDefaults();
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pengaturan direset ke default'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Server'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset ke Default',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isInitialSetup
                            ? 'Konfigurasi server untuk terhubung dengan backend POS'
                            : 'Ubah pengaturan koneksi server backend',
                        style: TextStyle(color: Colors.blue[900], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // API Base URL
              TextFormField(
                controller: _apiUrlController,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://localhost:3001',
                  prefixIcon: const Icon(Icons.cloud),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'URL dasar untuk API backend (tanpa /api/v2)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL tidak boleh kosong';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'URL harus dimulai dengan http:// atau https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Socket URL
              TextFormField(
                controller: _socketUrlController,
                decoration: InputDecoration(
                  labelText: 'Socket URL',
                  hintText: 'http://localhost:3001',
                  prefixIcon: const Icon(Icons.power),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'URL untuk koneksi Socket.IO real-time',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL tidak boleh kosong';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'URL harus dimulai dengan http:// atau https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // API Version
              TextFormField(
                controller: _apiVersionController,
                decoration: InputDecoration(
                  labelText: 'API Version',
                  hintText: 'v2',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Versi API backend',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Versi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Connection Status
              if (_connectionStatus != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor ?? Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusColor == Colors.green
                            ? Icons.check_circle
                            : Icons.error,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _connectionStatus!,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_connectionStatus != null) const SizedBox(height: 24),

              // Test Connection Button
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon:
                    _isTesting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.wifi_find),
                label: Text(_isTesting ? 'Mengetes...' : 'Tes Koneksi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFF2196F3),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengaturan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Default Values Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nilai Default:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API Base URL: http://localhost:3001',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Socket URL: http://localhost:3001',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'API Version: v2',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
