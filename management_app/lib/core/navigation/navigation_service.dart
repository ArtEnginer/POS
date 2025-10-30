import 'package:flutter/material.dart';

/// Global navigation service to handle navigation from anywhere in the app
/// Used for session expiration handling
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Flag to prevent multiple session expired dialogs
  bool _isShowingSessionExpiredDialog = false;
  DateTime? _lastSessionExpiredTime;

  /// Navigate to login page and clear all navigation stack
  void navigateToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  /// Show session expired dialog (with debounce to prevent multiple dialogs)
  Future<void> showSessionExpiredDialog() async {
    // Prevent showing dialog if already showing
    if (_isShowingSessionExpiredDialog) {
      print('⚠️ Session expired dialog already showing, skipping...');
      return;
    }

    // Prevent showing dialog again within 5 seconds
    if (_lastSessionExpiredTime != null) {
      final diff = DateTime.now().difference(_lastSessionExpiredTime!);
      if (diff.inSeconds < 5) {
        print('⚠️ Session expired dialog shown recently, skipping...');
        return;
      }
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ No context available for session expired dialog');
      return;
    }

    _isShowingSessionExpiredDialog = true;
    _lastSessionExpiredTime = DateTime.now();

    print('🔴 Showing session expired dialog');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Sesi Berakhir'),
            ],
          ),
          content: const Text(
            'Sesi Anda telah berakhir. Silakan login kembali untuk melanjutkan.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isShowingSessionExpiredDialog = false;
                navigateToLogin();
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    _isShowingSessionExpiredDialog = false;
  }
}
