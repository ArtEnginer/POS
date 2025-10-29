import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../dev_tools_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (result != null && mounted) {
        final isOfflineMode = result['offline_mode'] == true;

        // Show appropriate message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOfflineMode
                  ? '✓ Login berhasil (Mode Offline)'
                  : '✓ Login berhasil! Memuat data produk...',
            ),
            backgroundColor: isOfflineMode ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Only sync if online
        if (!isOfflineMode) {
          // Set online status immediately (before WebSocket connects)
          syncService.setOnlineStatus(true);
          print('🟢 Online mode - Set status to ONLINE');

          // Connect to WebSocket for real-time updates
          try {
            socketService
                .connect()
                .then((_) {
                  print('🔌 WebSocket connection initiated');
                })
                .catchError((e) {
                  print('⚠️ WebSocket connection failed: $e');
                });
          } catch (e) {
            print('⚠️ Socket service error: $e');
          }

          // Trigger initial sync
          syncService.syncAll().then((success) {
            if (success) {
              print('✅ Initial data sync successful');
            }
          });

          // Start background sync
          syncService.startBackgroundSync();
        } else {
          // Set offline status
          syncService.setOnlineStatus(false);
          print('📴 Offline mode - Set status to OFFLINE');

          print('📴 Offline mode - skipping sync and WebSocket');
          // Try to connect WebSocket anyway (will auto-switch if server available)
          try {
            socketService
                .connect()
                .then((_) {
                  print('🔌 WebSocket connection attempted from offline mode');
                })
                .catchError((e) {
                  print('⚠️ WebSocket connection failed from offline: $e');
                });
          } catch (e) {
            print('⚠️ Socket service error: $e');
          }

          // Start background sync (for periodic sync when online)
          syncService.startBackgroundSync();
        }

        // Navigate to cashier page
        Navigator.of(context).pushReplacementNamed('/cashier');
      } else {
        setState(() {
          _errorMessage = 'Username atau password salah';
        });
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage =
            'Login gagal. Pastikan Anda pernah login online sebelumnya\natau periksa koneksi ke server';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Dev Tools button (top right)
          IconButton(
            icon: const Icon(Icons.build, color: Colors.white),
            tooltip: 'Dev Tools',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DevToolsPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      const Icon(
                        Icons.point_of_sale,
                        size: 60,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'POS Kasir',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Login untuk memulai',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 20),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info text
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Offline Mode Available',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Login online pertama kali untuk mengaktifkan mode offline',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
