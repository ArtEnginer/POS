import 'package:flutter/material.dart';
import '../../data/datasources/sync_service.dart';

/// Header notification untuk sync yang muncul dengan animasi smooth
class SyncHeaderNotification extends StatefulWidget {
  final Stream<SyncEvent> syncEvents;

  const SyncHeaderNotification({super.key, required this.syncEvents});

  @override
  State<SyncHeaderNotification> createState() => _SyncHeaderNotificationState();
}

class _SyncHeaderNotificationState extends State<SyncHeaderNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  SyncEvent? _currentEvent;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Listen to sync events
    widget.syncEvents.listen((event) {
      if (!mounted) return;

      // Tampilkan untuk progress dan error, auto hide untuk success
      if (event.type == 'progress' || event.type == 'error') {
        _showNotification(event);
      } else if (event.type == 'success') {
        _showNotification(event);
        // Auto hide setelah 3 detik untuk success
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _hideNotification();
        });
      }
    });
  }

  void _showNotification(SyncEvent event) {
    setState(() {
      _currentEvent = event;
      _isVisible = true;
    });
    _controller.forward();
  }

  void _hideNotification() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
          _currentEvent = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentEvent == null) {
      return const SizedBox.shrink();
    }

    final event = _currentEvent!;

    // Warna berdasarkan tipe
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (event.type) {
      case 'progress':
        backgroundColor = Colors.blue[700]!;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.sync;
        break;
      case 'success':
        backgroundColor = Colors.green[600]!;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red[600]!;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = Colors.grey[700]!;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.info;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon dengan animasi rotasi untuk progress
                  if (event.type == 'progress')
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  else
                    Icon(icon, color: iconColor, size: 20),

                  const SizedBox(width: 12),

                  // Message
                  Expanded(
                    child: Text(
                      event.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Progress count jika ada
                  if (event.syncedCount != null && event.syncedCount! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${event.syncedCount}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  // Close button (hanya untuk error atau manual close)
                  if (event.type == 'error') ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _hideNotification,
                      child: Icon(Icons.close, color: iconColor, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
