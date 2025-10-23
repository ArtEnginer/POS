import 'package:flutter/material.dart';
import '../database/hybrid_sync_manager.dart';
import '../error/exceptions.dart';

/// Guard untuk memastikan fitur manajemen hanya berjalan dalam mode online
class OnlineOnlyGuard {
  final HybridSyncManager syncManager;

  OnlineOnlyGuard({required this.syncManager});

  /// Cek apakah sistem sedang online
  /// Throw OfflineOperationException jika offline
  Future<void> requireOnline(String featureName) async {
    await syncManager.updateSyncMode();

    final isOnline =
        syncManager.currentMode == SyncMode.hybrid ||
        syncManager.currentMode == SyncMode.onlineOnly;

    if (!isOnline) {
      throw OfflineOperationException(
        message: 'Fitur $featureName memerlukan koneksi ke server',
        feature: featureName,
      );
    }
  }

  /// Cek apakah sistem sedang online (tanpa throw exception)
  Future<bool> isOnline() async {
    await syncManager.updateSyncMode();
    return syncManager.currentMode == SyncMode.hybrid ||
        syncManager.currentMode == SyncMode.onlineOnly;
  }

  /// Tampilkan dialog peringatan offline
  static void showOfflineDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
            title: const Text('Koneksi Offline'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur $featureName memerlukan koneksi ke server.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
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
                        '• Fitur manajemen data (Product, Customer, Supplier) harus online',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Fitur Sales/Kasir tetap bisa digunakan offline',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Periksa koneksi internet dan server MySQL',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Tampilkan SnackBar peringatan offline
  static void showOfflineSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Fitur $featureName memerlukan koneksi online'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'INFO',
          textColor: Colors.white,
          onPressed: () {
            showOfflineDialog(context, featureName);
          },
        ),
      ),
    );
  }
}

/// Widget wrapper untuk fitur yang memerlukan online
class OnlineOnlyFeature extends StatelessWidget {
  final HybridSyncManager syncManager;
  final String featureName;
  final Widget child;
  final Widget? offlineWidget;

  const OnlineOnlyFeature({
    super.key,
    required this.syncManager,
    required this.featureName,
    required this.child,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncMode>(
      stream: syncManager.syncModeStream,
      initialData: syncManager.currentMode,
      builder: (context, snapshot) {
        final isOnline =
            snapshot.data == SyncMode.hybrid ||
            snapshot.data == SyncMode.onlineOnly;

        if (isOnline) {
          return child;
        }

        // Tampilkan widget offline atau pesan default
        return offlineWidget ?? _buildOfflineMessage(context);
      },
    );
  }

  Widget _buildOfflineMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Koneksi Offline',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Fitur $featureName memerlukan koneksi ke server.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Yang Harus Dilakukan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Periksa koneksi internet'),
                  const SizedBox(height: 4),
                  const Text('2. Pastikan server MySQL berjalan'),
                  const SizedBox(height: 4),
                  const Text('3. Periksa pengaturan MySQL di Dashboard'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await syncManager.updateSyncMode();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
