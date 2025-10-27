import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

enum ConnectivityStatus { online, offline, unknown }

/// Manages connectivity state and provides stream for connectivity changes
class ConnectivityManager {
  final Connectivity _connectivity;
  final Logger _logger;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  ConnectivityStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == ConnectivityStatus.online;
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  ConnectivityManager({
    required Connectivity connectivity,
    required Logger logger,
  }) : _connectivity = connectivity,
       _logger = logger;

  /// Initialize and start monitoring connectivity
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await _checkConnectivity();

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (_) async {
          await _checkConnectivity();
        },
        onError: (error) {
          _logger.e('Connectivity error', error: error);
          _updateStatus(ConnectivityStatus.unknown);
        },
      );

      _logger.i('Connectivity manager initialized');
    } catch (e) {
      _logger.e('Error initializing connectivity manager', error: e);
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.none)) {
        _updateStatus(ConnectivityStatus.offline);
      } else if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet)) {
        _updateStatus(ConnectivityStatus.online);
      } else {
        _updateStatus(ConnectivityStatus.unknown);
      }
    } catch (e) {
      _logger.e('Error checking connectivity', error: e);
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Update status and emit to stream
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);

      switch (newStatus) {
        case ConnectivityStatus.online:
          _logger.i('Device is now ONLINE');
          break;
        case ConnectivityStatus.offline:
          _logger.i('Device is now OFFLINE');
          break;
        case ConnectivityStatus.unknown:
          _logger.i('Device connectivity status is UNKNOWN');
          break;
      }
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
    await _statusController.close();
    _logger.i('Connectivity manager disposed');
  }
}
