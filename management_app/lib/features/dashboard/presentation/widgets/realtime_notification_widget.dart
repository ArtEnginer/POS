import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/socket/socket_service.dart';
import '../../../../injection_container.dart' as di;

class RealtimeNotificationWidget extends StatefulWidget {
  const RealtimeNotificationWidget({super.key});

  @override
  State<RealtimeNotificationWidget> createState() =>
      _RealtimeNotificationWidgetState();
}

class _RealtimeNotificationWidgetState
    extends State<RealtimeNotificationWidget> {
  final List<NotificationItem> _notifications = [];
  StreamSubscription? _productSubscription;
  StreamSubscription? _stockSubscription;
  StreamSubscription? _saleSubscription;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _stockSubscription?.cancel();
    _saleSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _initListeners() {
    final socketService = di.sl<SocketService>();

    // Listen to product updates
    _productSubscription = socketService.productUpdates.listen((data) {
      _addNotification(
        'Product Update',
        'Product ${data['productId']} was ${data['action']}',
        Icons.inventory,
        Colors.blue,
      );
    });

    // Listen to stock updates
    _stockSubscription = socketService.stockUpdates.listen((data) {
      _addNotification(
        'Stock Update',
        'Stock updated for product ${data['productId']}',
        Icons.warehouse,
        Colors.orange,
      );
    });

    // Listen to sale completed
    _saleSubscription = socketService.saleCompleted.listen((data) {
      _addNotification(
        'New Sale',
        'Sale ${data['saleNumber']} completed',
        Icons.shopping_cart,
        Colors.green,
      );
    });

    // Listen to custom notifications
    _notificationSubscription = socketService.notifications.listen((data) {
      _addNotification(
        data['title'] ?? 'Notification',
        data['message'] ?? '',
        Icons.notifications,
        Colors.purple,
      );
    });
  }

  void _addNotification(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    if (mounted) {
      setState(() {
        _notifications.insert(
          0,
          NotificationItem(
            title: title,
            message: message,
            icon: icon,
            color: color,
            timestamp: DateTime.now(),
          ),
        );

        // Keep only last 10 notifications
        if (_notifications.length > 10) {
          _notifications.removeLast();
        }
      });

      // Auto dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _notifications.isNotEmpty) {
          setState(() {
            _notifications.removeAt(_notifications.length - 1);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 70,
      right: 16,
      child: SizedBox(
        width: 300,
        child: Column(
          children:
              _notifications.map((notification) {
                return _NotificationCard(
                  notification: notification,
                  onDismiss: () {
                    setState(() {
                      _notifications.remove(notification);
                    });
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: notification.color, width: 4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
