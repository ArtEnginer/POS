import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../auth/auth_service.dart';

class SocketService {
  final AuthService _authService;
  final Logger _logger;

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentBranchId;

  // Stream controllers for real-time events
  final _productUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _stockUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _saleCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get productUpdates =>
      _productUpdateController.stream;
  Stream<Map<String, dynamic>> get stockUpdates =>
      _stockUpdateController.stream;
  Stream<Map<String, dynamic>> get saleCompleted =>
      _saleCompletedController.stream;
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool get isConnected => _isConnected;

  SocketService(this._authService, this._logger);

  /// Initialize and connect to Socket.IO server
  Future<void> connect() async {
    if (_isConnected) {
      _logger.i('Socket already connected');
      return;
    }

    try {
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        _logger.w('No access token available, skipping socket connection');
        return; // Changed from throw to return
      }

      _currentBranchId = await _authService.getCurrentBranchId();
      if (_currentBranchId == null) {
        _logger.w('No branch ID available, skipping socket connection');
        return; // Changed from throw to return
      }

      _logger.i('Connecting to Socket.IO server: ${ApiConstants.socketUrl}');

      _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setAuth({'token': accessToken, 'branchId': _currentBranchId})
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      _logger.e('Socket connection error: $e');
      // Don't rethrow - just log the error
    }
  }

  /// Setup event listeners for Socket.IO
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _logger.i('✅ Socket connected');
      _isConnected = true;
      _connectionController.add(true);

      // Join branch room if branch ID is available
      if (_currentBranchId != null) {
        joinBranchRoom(_currentBranchId!);
      }
    });

    _socket!.onDisconnect((_) {
      _logger.w('❌ Socket disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      _logger.e('Socket connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      _logger.e('Socket error: $error');
    });

    _socket!.on('authenticated', (data) {
      _logger.i('Socket authenticated: $data');
    });

    // Business events
    _socket!.on(ApiConstants.productUpdate, (data) {
      _logger.d('Product update received: $data');
      _productUpdateController.add(data);
    });

    _socket!.on(ApiConstants.stockUpdate, (data) {
      _logger.d('Stock update received: $data');
      _stockUpdateController.add(data);
    });

    _socket!.on(ApiConstants.saleCompleted, (data) {
      _logger.d('Sale completed received: $data');
      _saleCompletedController.add(data);
    });

    _socket!.on(ApiConstants.notificationSend, (data) {
      _logger.d('Notification received: $data');
      _notificationController.add(data);
    });

    // Sync events
    _socket!.on('sync:response', (data) {
      _logger.d('Sync response received: $data');
    });

    _socket!.on('sync:complete', (data) {
      _logger.i('Sync complete: $data');
    });

    // Ping/Pong for connection health
    _socket!.on('pong', (data) {
      _logger.v('Pong received: $data');
    });
  }

  /// Join a branch room
  void joinBranchRoom(String branchId) {
    if (_socket == null || !_isConnected) {
      _logger.w('Cannot join branch room: Socket not connected');
      return;
    }

    _logger.i('Joining branch room: $branchId');
    _socket!.emit('join:branch', {'branchId': branchId});
    _currentBranchId = branchId;
  }

  /// Leave a branch room
  void leaveBranchRoom(String branchId) {
    if (_socket == null || !_isConnected) return;

    _logger.i('Leaving branch room: $branchId');
    _socket!.emit('leave:branch', {'branchId': branchId});
  }

  /// Switch to a different branch room
  Future<void> switchBranch(String newBranchId) async {
    if (_currentBranchId != null) {
      leaveBranchRoom(_currentBranchId!);
    }
    joinBranchRoom(newBranchId);
  }

  /// Request data synchronization
  void requestSync({
    required String entity,
    String? lastSyncTime,
    Map<String, dynamic>? filters,
  }) {
    if (_socket == null || !_isConnected) {
      _logger.w('Cannot request sync: Socket not connected');
      return;
    }

    _logger.i('Requesting sync for entity: $entity');
    _socket!.emit(ApiConstants.syncRequest, {
      'entity': entity,
      'branchId': _currentBranchId,
      'lastSyncTime': lastSyncTime,
      if (filters != null) 'filters': filters,
    });
  }

  /// Emit custom event
  void emit(String event, dynamic data) {
    if (_socket == null || !_isConnected) {
      _logger.w('Cannot emit event: Socket not connected');
      return;
    }

    _socket!.emit(event, data);
  }

  /// Listen to custom event
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      _logger.w('Cannot listen to event: Socket not initialized');
      return;
    }

    _socket!.on(event, callback);
  }

  /// Remove event listener
  void off(String event) {
    if (_socket == null) return;
    _socket!.off(event);
  }

  /// Disconnect from Socket.IO server
  Future<void> disconnect() async {
    if (_socket == null) return;

    _logger.i('Disconnecting from Socket.IO server');

    if (_currentBranchId != null) {
      leaveBranchRoom(_currentBranchId!);
    }

    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    _isConnected = false;
    _currentBranchId = null;
    _connectionController.add(false);
  }

  /// Reconnect to Socket.IO server
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }

  /// Send ping to check connection
  void ping() {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _productUpdateController.close();
    _stockUpdateController.close();
    _saleCompletedController.close();
    _notificationController.close();
    _connectionController.close();
  }
}
