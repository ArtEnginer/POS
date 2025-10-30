import 'package:flutter/material.dart';
import '../../../../main.dart';

/// Widget untuk menampilkan status real-time sync
/// Menunjukkan:
/// - Online/Offline status
/// - WebSocket connection status
/// - Pending sync count
/// - Last sync time
class RealtimeSyncIndicator extends StatefulWidget {
  const RealtimeSyncIndicator({super.key});

  @override
  State<RealtimeSyncIndicator> createState() => _RealtimeSyncIndicatorState();
}

class _RealtimeSyncIndicatorState extends State<RealtimeSyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for online indicator pulse
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen to real-time updates - NO TIMER!
    return StreamBuilder<bool>(
      stream: socketService.serverStatus,
      initialData: false,
      builder: (context, serverSnapshot) {
        final isOnline = serverSnapshot.data ?? false;

        return StreamBuilder<bool>(
          stream: socketService.connectionStatus,
          initialData: false,
          builder: (context, connectionSnapshot) {
            final isWebSocketConnected = connectionSnapshot.data ?? false;
            final status = syncService.getSyncStatus();
            final pendingSales = status['pending_sales'] ?? 0;

            // Parse last sync time
            DateTime? lastSync;
            final lastSyncStr = status['last_sync'];
            if (lastSyncStr != null) {
              try {
                lastSync = DateTime.parse(lastSyncStr);
              } catch (e) {
                lastSync = null;
              }
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                border: Border.all(
                  color: isOnline ? Colors.green : Colors.orange,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Icon dengan pulse animation saat online
                  isOnline
                      ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: const Icon(
                          Icons.cloud_done,
                          color: Colors.green,
                          size: 20,
                        ),
                      )
                      : const Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 20,
                      ),

                  const SizedBox(width: 8),

                  // Status Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Online/Offline status
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color:
                              isOnline
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                        ),
                      ),

                      // WebSocket & Pending info
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // WebSocket status
                          Icon(
                            isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
                            size: 10,
                            color:
                                isWebSocketConnected
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 4),

                          // Pending sales
                          if (pendingSales > 0) ...[
                            const Icon(
                              Icons.pending_actions,
                              size: 10,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$pendingSales pending',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Semua sync',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Last sync time
                      Text(
                        'Sync: ${_getLastSyncText(lastSync)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // Manual sync button
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.sync, size: 18, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Manual Sync',
                    onPressed: () async {
                      // Show loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Memulai sinkronisasi...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Trigger manual sync
                      final success = await syncService.manualSync();

                      // Show result
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✅ Sinkronisasi berhasil!'
                                  : '❌ Sinkronisasi gagal!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getLastSyncText(DateTime? lastSync) {
    if (lastSync == null) return 'Belum pernah';

    final diff = DateTime.now().difference(lastSync);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }
}

/// Compact version - hanya icon
class RealtimeSyncIndicatorCompact extends StatelessWidget {
  const RealtimeSyncIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder - NO TIMER, NO setState!
    return StreamBuilder<bool>(
      stream: socketService.serverStatus,
      initialData: false,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        final status = syncService.getSyncStatus();
        final pendingSales = status['pending_sales'] ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: Colors.white,
              ),
              if (pendingSales > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pendingSales',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
