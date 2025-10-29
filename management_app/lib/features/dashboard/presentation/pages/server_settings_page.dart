import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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

    try {
      final prefs = await SharedPreferences.getInstance();

      _apiUrlController.text =
          prefs.getString('api_base_url') ?? 'http://localhost:3001';
      _socketUrlController.text =
          prefs.getString('socket_url') ?? 'ws://localhost:3001';
      _apiVersionController.text = prefs.getString('api_version') ?? 'v2';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('api_base_url', _apiUrlController.text);
      await prefs.setString('socket_url', _socketUrlController.text);
      await prefs.setString('api_version', _apiVersionController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan server berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );

        // Jika initial setup, kembali dengan status berhasil
        if (widget.isInitialSetup) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = 'Menguji koneksi...';
      _statusColor = Colors.orange;
    });

    try {
      // Simple HTTP request to test connection
      final dio = Dio(
        BaseOptions(
          baseUrl: _apiUrlController.text,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get(
        '/api/${_apiVersionController.text}/health',
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectionStatus = 'Koneksi berhasil! Server aktif.';
          _statusColor = Colors.green;
        });
      } else {
        setState(() {
          _connectionStatus =
              'Server merespons dengan status: ${response.statusCode}';
          _statusColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Koneksi gagal: ${e.toString()}';
        _statusColor = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _setDefaultLocal() {
    setState(() {
      _apiUrlController.text = 'http://localhost:3001';
      _socketUrlController.text = 'ws://localhost:3001';
      _apiVersionController.text = 'v2';
    });
  }

  void _setDefaultProduction() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Server Production'),
            content: const Text(
              'Masukkan URL server production Anda.\n\n'
              'Contoh:\n'
              'API: https://api.tokosaya.com\n'
              'Socket: wss://api.tokosaya.com',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // User can manually input the production URL
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Jika initial setup, tidak bisa back tanpa setup
        if (widget.isInitialSetup) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Keluar Setup?'),
                  content: const Text(
                    'Server belum dikonfigurasi. Aplikasi tidak dapat berjalan tanpa koneksi server.\n\n'
                    'Yakin ingin keluar?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isInitialSetup
                ? 'Setup Server - Wajib'
                : 'Pengaturan Server',
          ),
          automaticallyImplyLeading: !widget.isInitialSetup,
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                tooltip: 'Simpan',
              ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Actions
                        _buildSectionHeader('Konfigurasi Cepat'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _setDefaultLocal,
                                icon: const Icon(Icons.computer),
                                label: const Text('Local Server'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _setDefaultProduction,
                                icon: const Icon(Icons.cloud),
                                label: const Text('Production'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // API Settings
                        _buildSectionHeader('Pengaturan Backend API'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _apiUrlController,
                          label: 'Base URL API',
                          icon: Icons.link,
                          helperText:
                              'Contoh: http://localhost:3001 atau https://api.tokosaya.com',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'URL API tidak boleh kosong';
                            }
                            if (!value.startsWith('http://') &&
                                !value.startsWith('https://')) {
                              return 'URL harus dimulai dengan http:// atau https://';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _apiVersionController,
                          label: 'Versi API',
                          icon: Icons.numbers,
                          helperText: 'Contoh: v2',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Versi API tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Socket Settings
                        _buildSectionHeader('Pengaturan WebSocket'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _socketUrlController,
                          label: 'URL WebSocket',
                          icon: Icons.wifi,
                          helperText:
                              'Contoh: ws://localhost:3001 atau wss://api.tokosaya.com',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'URL WebSocket tidak boleh kosong';
                            }
                            if (!value.startsWith('ws://') &&
                                !value.startsWith('wss://')) {
                              return 'URL harus dimulai dengan ws:// atau wss://';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Connection Status
                        if (_connectionStatus != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _statusColor?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _statusColor ?? Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _statusColor == Colors.green
                                      ? Icons.check_circle
                                      : _statusColor == Colors.orange
                                      ? Icons.warning
                                      : Icons.error,
                                  color: _statusColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _connectionStatus!,
                                    style: TextStyle(color: _statusColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Test Connection Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon:
                                _isTesting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.power_settings_new),
                            label: Text(
                              _isTesting ? 'Menguji...' : 'Test Koneksi',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Informasi Backend',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Database', 'PostgreSQL'),
            _buildInfoRow('Cache', 'Redis'),
            _buildInfoRow('Real-time', 'Socket.IO'),
            _buildInfoRow('API Framework', 'Node.js + Express'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
