import 'package:flutter/material.dart';
import '../database/hybrid_sync_manager.dart';

/// Widget untuk menampilkan status koneksi online/offline dengan desain modern
class ConnectionStatusIndicator extends StatelessWidget {
  final SyncMode syncMode;
  final bool showLabel;
  final double iconSize;
  final double fontSize;
  final bool compact;

  const ConnectionStatusIndicator({
    super.key,
    required this.syncMode,
    this.showLabel = true,
    this.iconSize = 20,
    this.fontSize = 12,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline =
        syncMode == SyncMode.hybrid || syncMode == SyncMode.onlineOnly;

    return Container(
      padding:
          compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isOnline
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
          color: isOnline ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot dengan animasi
          _StatusDot(isOnline: isOnline, size: iconSize - 6),
          const SizedBox(width: 6),
          if (showLabel) ...[
            Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color:
                    isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dot status dengan animasi yang smooth
class _StatusDot extends StatefulWidget {
  final bool isOnline;
  final double size;

  const _StatusDot({required this.isOnline, required this.size});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      // Offline: static dot dengan icon
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.orange.shade400,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.signal_wifi_off,
          color: Colors.white,
          size: widget.size * 0.6,
        ),
      );
    }

    // Online: animated dot
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse effect
            if (widget.isOnline)
              Container(
                width: widget.size * _scaleAnimation.value,
                height: widget.size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(
                    _opacityAnimation.value * 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            // Main dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.cloud_done,
                color: Colors.white,
                size: widget.size * 0.6,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Modern banner untuk status koneksi
class ConnectionStatusBanner extends StatelessWidget {
  final SyncMode syncMode;
  final VoidCallback? onTap;
  final bool showSyncProgress;

  const ConnectionStatusBanner({
    super.key,
    required this.syncMode,
    this.onTap,
    this.showSyncProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline =
        syncMode == SyncMode.hybrid || syncMode == SyncMode.onlineOnly;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isOnline
                    ? [
                      Colors.green.shade50,
                      Colors.green.shade100,
                      Colors.green.shade50,
                    ]
                    : [
                      Colors.orange.shade50,
                      Colors.orange.shade100,
                      Colors.orange.shade50,
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: isOnline ? Colors.green.shade300 : Colors.orange.shade300,
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated icon dengan background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isOnline ? Colors.green.shade100 : Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: _AnimatedConnectionIcon(isOnline: isOnline, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Sistem Online' : 'Mode Offline',
                    style: TextStyle(
                      color:
                          isOnline
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline
                        ? 'Koneksi stabil • Data tersinkronisasi real-time'
                        : 'Koneksi terputus • Data tersimpan secara lokal',
                    style: TextStyle(
                      color:
                          isOnline
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                  if (showSyncProgress && !isOnline) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.orange.shade400,
                      ),
                      backgroundColor: Colors.orange.shade200,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isOnline ? Colors.green.shade100 : Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color:
                      isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Icon dengan animasi yang lebih smooth
class _AnimatedConnectionIcon extends StatefulWidget {
  final bool isOnline;
  final double size;

  const _AnimatedConnectionIcon({required this.isOnline, required this.size});

  @override
  State<_AnimatedConnectionIcon> createState() =>
      _AnimatedConnectionIconState();
}

class _AnimatedConnectionIconState extends State<_AnimatedConnectionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) {
      return Icon(
        Icons.cloud_off_rounded,
        color: Colors.orange.shade700,
        size: widget.size,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.cloud_done_rounded,
            color: Colors.green.shade700,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Mini indicator untuk corner screen
class ConnectionStatusMini extends StatelessWidget {
  final SyncMode syncMode;
  final VoidCallback? onTap;

  const ConnectionStatusMini({super.key, required this.syncMode, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOnline =
        syncMode == SyncMode.hybrid || syncMode == SyncMode.onlineOnly;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade400 : Colors.orange.shade400,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child:
            isOnline ? null : Icon(Icons.close, color: Colors.white, size: 8),
      ),
    );
  }
}

/// Stream builder dengan auto update
class StreamConnectionStatusIndicator extends StatelessWidget {
  final HybridSyncManager syncManager;
  final bool showLabel;
  final double iconSize;
  final double fontSize;
  final bool compact;

  const StreamConnectionStatusIndicator({
    super.key,
    required this.syncManager,
    this.showLabel = true,
    this.iconSize = 20,
    this.fontSize = 12,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncMode>(
      stream: syncManager.syncModeStream,
      initialData: syncManager.currentMode,
      builder: (context, snapshot) {
        return ConnectionStatusIndicator(
          syncMode: snapshot.data ?? SyncMode.localOnly,
          showLabel: showLabel,
          iconSize: iconSize,
          fontSize: fontSize,
          compact: compact,
        );
      },
    );
  }
}
