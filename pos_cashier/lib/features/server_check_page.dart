import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/utils/app_settings.dart';
import 'server_settings_page.dart';
import 'auth/presentation/pages/login_page.dart';

/// Halaman untuk pengecekan koneksi server saat aplikasi pertama kali dibuka
class ServerCheckPage extends StatefulWidget {
  const ServerCheckPage({super.key});

  @override
  State<ServerCheckPage> createState() => _ServerCheckPageState();
}

class _ServerCheckPageState extends State<ServerCheckPage> {
  bool _isChecking = true;
  bool _serverAvailable = false;
  String _statusMessage = 'Memeriksa koneksi server...';
  String? _errorDetails;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Memeriksa koneksi server...';
      _errorDetails = null;
    });

    try {
      // Ambil konfigurasi server dari settings
      final apiBaseUrl = await AppSettings.getApiBaseUrl();
      final apiVersion = await AppSettings.getApiVersion();

      // Tes koneksi ke server (baik default maupun custom)
      final dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get('/api/$apiVersion/health');

      if (response.statusCode == 200) {
        setState(() {
          _serverAvailable = true;
          _statusMessage = 'Server terhubung!';
          _isChecking = false;
        });

        // Tandai server sudah dikonfigurasi
        await AppSettings.setServerConfigured(true);

        // Auto navigate ke login setelah 1 detik
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() {
          _serverAvailable = false;
          _statusMessage =
              'Server merespons dengan status: ${response.statusCode}';
          _errorDetails = 'Periksa konfigurasi server Anda.';
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _serverAvailable = false;
        _statusMessage = 'Tidak dapat terhubung ke server';
        _errorDetails = _getErrorMessage(e);
        _isChecking = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Pastikan server aktif dan dapat diakses.';
        case DioExceptionType.connectionError:
          return 'Tidak dapat terhubung ke server. Pastikan:\n'
              '• Server backend sudah berjalan\n'
              '• URL server sudah benar\n'
              '• Tidak ada firewall yang memblokir';
        case DioExceptionType.badResponse:
          return 'Server merespons dengan error: ${error.response?.statusCode}';
        default:
          return error.message ?? 'Error tidak diketahui';
      }
    }
    return error.toString();
  }

  void _openServerSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServerSettingsPage(isInitialSetup: true),
      ),
    );

    // Jika kembali dari settings, coba check ulang
    if (result == true) {
      _checkServerConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon/Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.point_of_sale,
                      size: 60,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Title
                  const Text(
                    'POS Kasir',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point of Sale System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Status Icon
                        if (_isChecking)
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2196F3),
                              ),
                            ),
                          )
                        else
                          Icon(
                            _serverAvailable
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 60,
                            color: _serverAvailable ? Colors.green : Colors.red,
                          ),
                        const SizedBox(height: 24),

                        // Status Message
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:
                                _serverAvailable
                                    ? Colors.green
                                    : (_isChecking
                                        ? Colors.grey[700]
                                        : Colors.red),
                          ),
                        ),

                        // Error Details
                        if (_errorDetails != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              _errorDetails!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[900],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        // Action Buttons
                        if (!_isChecking && !_serverAvailable) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _checkServerConnection,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openServerSettings,
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Pengaturan'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2196F3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF2196F3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Text
                  Text(
                    'Memastikan koneksi ke server backend...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
