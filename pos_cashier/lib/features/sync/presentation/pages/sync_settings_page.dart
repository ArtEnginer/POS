import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../widgets/sync_header_notification.dart';

/// Halaman untuk mengelola sinkronisasi data
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  bool _isSyncing = false;
  String _syncMessage = '';
  int _currentProgress = 0;
  int _totalProgress = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
    _listenToSyncEvents();
  }

  void _loadLastSyncTime() async {
    // Load dari settings box
    final settingsBox = await productRepository.getLastSyncTime();
    if (settingsBox != null && mounted) {
      setState(() {
        _lastSyncTime = settingsBox;
      });
    }
  }

  void _listenToSyncEvents() {
    syncService.syncEvents.listen((event) {
      if (!mounted) return;

      setState(() {
        _syncMessage = event.message;

        if (event.type == 'progress') {
          _isSyncing = true;
          _currentProgress = event.syncedCount ?? 0;
          // Total akan di-update saat ada progress
        } else if (event.type == 'success') {
          _isSyncing = false;
          _currentProgress = 0;
          _totalProgress = 0;
          _lastSyncTime = DateTime.now();
        } else if (event.type == 'error') {
          _isSyncing = false;
          _currentProgress = 0;
          _totalProgress = 0;
        }
      });
    });
  }

  Future<void> _performIncrementalSync() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Memulai sinkronisasi...';
    });

    await syncService.manualSync();
  }

  Future<void> _performFullSync() async {
    // Konfirmasi dulu
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sinkronisasi Penuh'),
            content: const Text(
              'Sinkronisasi penuh akan mengunduh ulang semua produk dari server. '
              'Proses ini mungkin memakan waktu beberapa menit.\n\n'
              'Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncMessage = 'Memulai sinkronisasi penuh...';
      _currentProgress = 0;
      _totalProgress = 0;
    });

    await syncService.forceFullSync(
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _currentProgress = current;
            _totalProgress = total;
          });
        }
      },
    );
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return 'Belum pernah';

    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return '${diff.inDays} hari yang lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = syncService.getSyncStatus();
    final totalProducts = syncStatus['total_products'] ?? 0;
    final pendingSales = syncStatus['pending_sales'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sinkronisasi'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // Sync Header Notification - animated
          SyncHeaderNotification(syncEvents: syncService.syncEvents),

          // Main Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Status Sinkronisasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildStatusRow(
                          'Total Produk Lokal',
                          '$totalProducts produk',
                          Icons.inventory_2,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          'Transaksi Pending',
                          '$pendingSales transaksi',
                          Icons.pending_actions,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          'Sinkronisasi Terakhir',
                          _formatLastSync(),
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Progress Card (hanya tampil saat syncing)
                if (_isSyncing) ...[
                  Card(
                    elevation: 4,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[700]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _syncMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_totalProgress > 0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _currentProgress / _totalProgress,
                              backgroundColor: Colors.blue[100],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[700]!,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_currentProgress / $_totalProgress produk',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sync, color: Colors.blue[700], size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Aksi Sinkronisasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Incremental Sync Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSyncing ? null : _performIncrementalSync,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sinkronisasi Cepat'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hanya mengunduh data yang berubah sejak sinkronisasi terakhir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Full Sync Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _performFullSync,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Sinkronisasi Penuh'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mengunduh ulang semua produk dari server (untuk 20,000+ produk)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Card
                Card(
                  elevation: 4,
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber[800],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Gunakan Sinkronisasi Cepat untuk pembaruan harian\n'
                          '• Gunakan Sinkronisasi Penuh jika ada data yang hilang\n'
                          '• Sinkronisasi otomatis berjalan setiap 5 menit saat online\n'
                          '• Semua transaksi akan tersinkron otomatis saat kembali online',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
