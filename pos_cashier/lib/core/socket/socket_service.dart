import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../database/hive_service.dart';
import '../constants/app_constants.dart';
import '../utils/app_settings.dart';

/// Socket.IO service untuk real-time communication dengan backend
class SocketService {
  final HiveService _hiveService;

  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers untuk event real-time
  final _connectionController = StreamController<bool>.broadcast();
  final _serverStatusController = StreamController<bool>.broadcast();
  final _dataUpdateController = StreamController<String>.broadcast();

  // Public streams
  Stream<bool> get connectionStatus => _connectionController.stream;
  Stream<bool> get serverStatus => _serverStatusController.stream;
  Stream<String> get dataUpdates => _dataUpdateController.stream;

  bool get isConnected => _isConnected;

  SocketService(this._hiveService);

  /// Trigger data update manually (untuk sync events)
  void triggerDataUpdate(String eventType) {
    _dataUpdateController.add(eventType);
  }

  /// Connect ke Socket.IO server
  Future<void> connect() async {
    if (_isConnected && _socket != null) {
      print('🔌 Socket already connected');
      return;
    }

    try {
      // Get auth token
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final token = authBox.get('auth_token');

      if (token == null || token == 'offline_token') {
        print('⚠️ No valid token, skipping socket connection');
        return;
      }

      // Get socket URL from settings
      final socketUrl = await AppSettings.getSocketUrl();
      print('🔌 Connecting to Socket.IO: $socketUrl');

      // Get branch ID and user ID from auth box
      final branchData = authBox.get('branch');
      final branchId =
          branchData != null && branchData is Map
              ? branchData['id']?.toString() ?? '1'
              : '1';
      final userData = authBox.get('user');
      final userId =
          userData != null && userData is Map
              ? userData['id']?.toString()
              : null;

      print('🔌 Socket Auth: branchId=$branchId, userId=$userId');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(999999) // Unlimited reconnection
            .setReconnectionDelay(2000) // 2 seconds
            .setAuth({'token': token, 'branchId': branchId, 'userId': userId})
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      print('❌ Socket connection error: $e');
      _handleDisconnection();
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Socket connected - Server ONLINE');
      _isConnected = true;
      _connectionController.add(true);
      _serverStatusController.add(true);

      // Auto-switch to online mode
      _switchToOnlineMode();
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected - Server OFFLINE');
      _handleDisconnection();
    });

    _socket!.onConnectError((error) {
      print('⚠️ Socket connection error: $error');
      _handleDisconnection();
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
      _handleDisconnection();
    });

    // Custom events from backend
    _socket!.on('server:health', (data) {
      print('💚 Server health check: $data');
      if (data['status'] == 'ok') {
        _serverStatusController.add(true);
      }
    });

    _socket!.on('server:shutdown', (_) {
      print('🔴 Server shutting down');
      _handleDisconnection();
    });

    // 🚀 REAL-TIME DATABASE SYNC EVENTS
    _setupDatabaseEventListeners();

    // Listen for reconnection attempts
    _socket!.onReconnectAttempt((attempt) {
      print('🔄 Reconnection attempt #$attempt');
    });

    _socket!.onReconnect((attempt) {
      print('✅ Reconnected after $attempt attempts');
      _isConnected = true;
      _connectionController.add(true);
      _serverStatusController.add(true);
      _switchToOnlineMode();
    });

    _socket!.onReconnectError((error) {
      print('⚠️ Reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Reconnection failed - giving up');
      _handleDisconnection();
    });
  }

  /// 🚀 Setup listeners for real-time database events
  void _setupDatabaseEventListeners() {
    if (_socket == null) return;

    // Product Events
    _socket!.on('product:created', (data) async {
      print('📦 Real-time event: Product CREATED');
      print('   Data: $data');
      await _handleProductCreated(data);
    });

    _socket!.on('product:updated', (data) async {
      print('📦 Real-time event: Product UPDATED');
      print('   Data: $data');
      await _handleProductUpdated(data);
    });

    _socket!.on('product:deleted', (data) async {
      print('📦 Real-time event: Product DELETED');
      print('   Data: $data');
      await _handleProductDeleted(data);
    });

    // Category Events
    _socket!.on('category:created', (data) async {
      print('🏷️ Real-time event: Category CREATED');
      print('   Data: $data');
      await _handleCategoryCreated(data);
    });

    _socket!.on('category:updated', (data) async {
      print('🏷️ Real-time event: Category UPDATED');
      print('   Data: $data');
      await _handleCategoryUpdated(data);
    });

    _socket!.on('category:deleted', (data) async {
      print('🏷️ Real-time event: Category DELETED');
      print('   Data: $data');
      await _handleCategoryDeleted(data);
    });
  }

  /// Handle product created event
  Future<void> _handleProductCreated(dynamic data) async {
    try {
      final product = data['product'];
      if (product == null) return;

      final productsBox = _hiveService.productsBox;
      final productId = product['id'].toString();

      // Transform backend data to match frontend format
      final productData = {
        'id': productId,
        'sku': product['sku'],
        'barcode': product['barcode'],
        'name': product['name'],
        'description': product['description'],
        'category_id':
            product['categoryId']?.toString() ??
            product['category_id']?.toString(),
        'unit': product['unit'] ?? 'PCS',
        'cost_price':
            (product['costPrice'] ?? product['cost_price'] ?? 0).toDouble(),
        'selling_price':
            (product['sellingPrice'] ?? product['selling_price'] ?? 0)
                .toDouble(),
        'stock': 0, // Initial stock
        'min_stock': product['minStock'] ?? product['min_stock'] ?? 0,
        'max_stock': product['maxStock'] ?? product['max_stock'] ?? 0,
        'image_url': product['imageUrl'] ?? product['image_url'],
        'is_active': product['isActive'] ?? product['is_active'] ?? true,
        'created_at':
            product['createdAt'] ??
            product['created_at'] ??
            DateTime.now().toIso8601String(),
        'updated_at':
            product['updatedAt'] ??
            product['updated_at'] ??
            DateTime.now().toIso8601String(),
      };

      await productsBox.put(productId, productData);
      print('✅ Product added to local DB: ${product['name']} (ID: $productId)');

      // Notify listeners that product data changed
      _dataUpdateController.add('product:created');
    } catch (e) {
      print('❌ Error handling product created: $e');
    }
  }

  /// Handle product updated event
  Future<void> _handleProductUpdated(dynamic data) async {
    try {
      final product = data['product'];
      if (product == null) return;

      final productsBox = _hiveService.productsBox;
      final productId = product['id'].toString();

      // Get existing product to preserve stock
      final existingData = productsBox.get(productId);
      final existingStock =
          existingData != null
              ? (existingData is Map ? existingData['stock'] ?? 0 : 0)
              : 0;

      // Transform and merge with existing data
      final productData = {
        'id': productId,
        'sku': product['sku'],
        'barcode': product['barcode'],
        'name': product['name'],
        'description': product['description'],
        'category_id':
            product['categoryId']?.toString() ??
            product['category_id']?.toString(),
        'unit': product['unit'] ?? 'PCS',
        'cost_price':
            (product['costPrice'] ?? product['cost_price'] ?? 0).toDouble(),
        'selling_price':
            (product['sellingPrice'] ?? product['selling_price'] ?? 0)
                .toDouble(),
        'stock': existingStock, // Preserve existing stock
        'min_stock': product['minStock'] ?? product['min_stock'] ?? 0,
        'max_stock': product['maxStock'] ?? product['max_stock'] ?? 0,
        'image_url': product['imageUrl'] ?? product['image_url'],
        'is_active': product['isActive'] ?? product['is_active'] ?? true,
        'created_at':
            product['createdAt'] ??
            product['created_at'] ??
            DateTime.now().toIso8601String(),
        'updated_at':
            product['updatedAt'] ??
            product['updated_at'] ??
            DateTime.now().toIso8601String(),
      };

      await productsBox.put(productId, productData);
      print(
        '✅ Product updated in local DB: ${product['name']} (ID: $productId)',
      );

      // Notify listeners that product data changed
      _dataUpdateController.add('product:updated');
    } catch (e) {
      print('❌ Error handling product updated: $e');
    }
  }

  /// Handle product deleted event
  Future<void> _handleProductDeleted(dynamic data) async {
    try {
      final productId = data['productId']?.toString();
      if (productId == null) return;

      final productsBox = _hiveService.productsBox;
      await productsBox.delete(productId);

      print('✅ Product deleted from local DB: $productId');

      // Notify listeners that product data changed
      _dataUpdateController.add('product:deleted');
    } catch (e) {
      print('❌ Error handling product deleted: $e');
    }
  }

  /// Handle category created event
  Future<void> _handleCategoryCreated(dynamic data) async {
    try {
      final category = data['category'];
      if (category == null) return;

      final categoriesBox = _hiveService.categoriesBox;
      final categoryId = category['id'].toString();

      final categoryData = {
        'id': categoryId,
        'name': category['name'],
        'description': category['description'],
        'parent_id': category['parent_id']?.toString(),
        'icon': category['icon'],
        'is_active': category['is_active'] ?? true,
        'created_at':
            category['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at':
            category['updated_at'] ?? DateTime.now().toIso8601String(),
      };

      await categoriesBox.put(categoryId, categoryData);
      print(
        '✅ Category added to local DB: ${category['name']} (ID: $categoryId)',
      );
    } catch (e) {
      print('❌ Error handling category created: $e');
    }
  }

  /// Handle category updated event
  Future<void> _handleCategoryUpdated(dynamic data) async {
    try {
      final category = data['category'];
      if (category == null) return;

      final categoriesBox = _hiveService.categoriesBox;
      final categoryId = category['id'].toString();

      final categoryData = {
        'id': categoryId,
        'name': category['name'],
        'description': category['description'],
        'parent_id': category['parent_id']?.toString(),
        'icon': category['icon'],
        'is_active': category['is_active'] ?? true,
        'created_at':
            category['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at':
            category['updated_at'] ?? DateTime.now().toIso8601String(),
      };

      await categoriesBox.put(categoryId, categoryData);
      print(
        '✅ Category updated in local DB: ${category['name']} (ID: $categoryId)',
      );
    } catch (e) {
      print('❌ Error handling category updated: $e');
    }
  }

  /// Handle category deleted event
  Future<void> _handleCategoryDeleted(dynamic data) async {
    try {
      final categoryId = data['categoryId']?.toString();
      if (categoryId == null) return;

      final categoriesBox = _hiveService.categoriesBox;
      await categoriesBox.delete(categoryId);

      print('✅ Category deleted from local DB: $categoryId');
    } catch (e) {
      print('❌ Error handling category deleted: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectionController.add(false);
    _serverStatusController.add(false);
    _switchToOfflineMode();
  }

  /// Auto-switch to online mode
  Future<void> _switchToOnlineMode() async {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final token = authBox.get('auth_token');

      // Only switch if user is logged in
      if (token != null && token != 'offline_token') {
        final currentOfflineFlag = authBox.get(
          'is_offline',
          defaultValue: false,
        );

        if (currentOfflineFlag) {
          await authBox.put('is_offline', false);
          print('🟢 Auto-switched to ONLINE mode (WebSocket connected)');
        }
      }
    } catch (e) {
      print('❌ Error switching to online mode: $e');
    }
  }

  /// Auto-switch to offline mode
  Future<void> _switchToOfflineMode() async {
    try {
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final token = authBox.get('auth_token');

      // Only switch if user is logged in
      if (token != null) {
        final currentOfflineFlag = authBox.get(
          'is_offline',
          defaultValue: false,
        );

        if (!currentOfflineFlag) {
          await authBox.put('is_offline', true);
          print('🟠 Auto-switched to OFFLINE mode (WebSocket disconnected)');
        }
      }
    } catch (e) {
      print('❌ Error switching to offline mode: $e');
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      print('🔌 Disconnecting socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _serverStatusController.close();
  }
}
