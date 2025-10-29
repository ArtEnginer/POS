import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/app_settings.dart';
import 'server_settings_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

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
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _serverAvailable
                          ? Icons.check_circle
                          : _isChecking
                          ? Icons.cloud_sync
                          : Icons.cloud_off,
                      size: 50,
                      color:
                          _serverAvailable
                              ? Colors.green
                              : _isChecking
                              ? const Color(0xFF1E88E5)
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status Title
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Details
                  if (_errorDetails != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _errorDetails!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Loading Indicator
                  if (_isChecking) ...[
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],

                  // Action Buttons
                  if (!_isChecking && !_serverAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openServerSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Konfigurasi Server'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _checkServerConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.8),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Management App memerlukan koneksi ke Backend Server',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Node.js + PostgreSQL + Redis + Socket.IO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
