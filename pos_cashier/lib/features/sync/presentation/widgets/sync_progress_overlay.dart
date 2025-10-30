import 'package:flutter/material.dart';
import '../../data/datasources/sync_service.dart';

/// Overlay untuk menampilkan progress sinkronisasi
class SyncProgressOverlay extends StatelessWidget {
  final Stream<SyncEvent> syncEvents;

  const SyncProgressOverlay({super.key, required this.syncEvents});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncEvent>(
      stream: syncEvents,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final event = snapshot.data!;

        // Hanya tampilkan untuk progress dan error
        if (event.type != 'progress' && event.type != 'error') {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: event.type == 'error' ? Colors.red[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      event.type == 'error'
                          ? Colors.red[300]!
                          : Colors.blue[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  if (event.type == 'error')
                    const Icon(Icons.error_outline, color: Colors.red, size: 28)
                  else
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[700]!,
                        ),
                      ),
                    ),

                  const SizedBox(width: 16),

                  // Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.type == 'error'
                              ? 'Sinkronisasi Gagal'
                              : 'Sinkronisasi Berjalan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                                event.type == 'error'
                                    ? Colors.red[800]
                                    : Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.message,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                event.type == 'error'
                                    ? Colors.red[700]
                                    : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Snackbar helper untuk menampilkan notifikasi sync
class SyncNotification {
  static void show(BuildContext context, SyncEvent event) {
    final color =
        event.type == 'success'
            ? Colors.green
            : event.type == 'error'
            ? Colors.red
            : Colors.blue;

    final icon =
        event.type == 'success'
            ? Icons.check_circle
            : event.type == 'error'
            ? Icons.error
            : Icons.info;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(event.message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        duration:
            event.type == 'success'
                ? const Duration(seconds: 2)
                : const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
