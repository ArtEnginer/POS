import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../database/database_helper.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';

enum SyncStatus { idle, syncing, success, failed }

class SyncManager {
  final ApiClient apiClient;
  final NetworkInfo networkInfo;
  final DatabaseHelper databaseHelper;
  final Logger logger;

  Timer? _syncTimer;
  StreamController<SyncStatus>? _syncStatusController;
  bool _isSyncing = false;

  SyncManager({
    required this.apiClient,
    required this.networkInfo,
    required this.databaseHelper,
    required this.logger,
  });

  Stream<SyncStatus> get syncStatusStream {
    _syncStatusController ??= StreamController<SyncStatus>.broadcast();
    return _syncStatusController!.stream;
  }

  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      AppConstants.syncInterval,
      (_) => performSync(),
    );
    logger.i('Periodic sync started');
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    logger.i('Periodic sync stopped');
  }

  Future<void> performSync() async {
    if (_isSyncing) {
      logger.w('Sync already in progress');
      return;
    }

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      logger.w('No internet connection, skipping sync');
      _syncStatusController?.add(SyncStatus.failed);
      return;
    }

    _isSyncing = true;
    _syncStatusController?.add(SyncStatus.syncing);
    logger.i('Starting sync process...');

    try {
      // 1. Upload pending local changes to server
      await _uploadPendingChanges();

      // 2. Download updates from server
      await _downloadServerUpdates();

      // 3. Update last sync timestamp
      await _updateLastSyncTime();

      _syncStatusController?.add(SyncStatus.success);
      logger.i('Sync completed successfully');
    } catch (e) {
      _syncStatusController?.add(SyncStatus.failed);
      logger.e('Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      _syncStatusController?.add(SyncStatus.idle);
    }
  }

  Future<void> _uploadPendingChanges() async {
    logger.i('Uploading pending changes...');
    final db = await databaseHelper.database;

    // Get pending items from sync queue
    final pendingItems = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC',
      limit: AppConstants.batchSyncSize,
    );

    if (pendingItems.isEmpty) {
      logger.i('No pending changes to upload');
      return;
    }

    for (final item in pendingItems) {
      try {
        await _uploadSingleItem(item);

        // Mark as synced
        await db.update(
          'sync_queue',
          {'status': 'SYNCED', 'synced_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        logger.d('Uploaded: ${item['table_name']} - ${item['record_id']}');
      } catch (e) {
        // Update retry count
        final retryCount = (item['retry_count'] as int?) ?? 0;
        await db.update(
          'sync_queue',
          {
            'status':
                retryCount >= AppConstants.maxRetryAttempts
                    ? 'FAILED'
                    : 'PENDING',
            'retry_count': retryCount + 1,
            'error_message': e.toString(),
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        logger.e('Failed to upload: ${item['table_name']} - ${e.toString()}');
      }
    }
  }

  Future<void> _uploadSingleItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'] as String;
    final recordId = item['record_id'] as String;
    final operation = item['operation'] as String;
    final data = jsonDecode(item['data'] as String);

    final endpoint = _getEndpointForTable(tableName);

    switch (operation) {
      case 'INSERT':
      case 'UPDATE':
        await apiClient.post('$endpoint/sync', data: data);
        break;
      case 'DELETE':
        await apiClient.delete('$endpoint/$recordId');
        break;
    }
  }

  Future<void> _downloadServerUpdates() async {
    logger.i('Downloading server updates...');
    final db = await databaseHelper.database;

    // Get last sync time
    final lastSyncResult = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );

    String? lastSyncTime;
    if (lastSyncResult.isNotEmpty) {
      lastSyncTime = lastSyncResult.first['value'] as String?;
    }

    // Download updates for each table
    await _downloadProducts(lastSyncTime);
    await _downloadCategories(lastSyncTime);
    await _downloadCustomers(lastSyncTime);
    await _downloadUsers(lastSyncTime);
  }

  Future<void> _downloadProducts(String? since) async {
    try {
      final response = await apiClient.get(
        '/products/sync',
        queryParameters: since != null ? {'since': since} : null,
      );

      final products = response.data['data'] as List;
      final db = await databaseHelper.database;

      for (final product in products) {
        await db.insert('products', {
          ...product,
          'sync_status': 'SYNCED',
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      logger.i('Downloaded ${products.length} products');
    } catch (e) {
      logger.e('Failed to download products: $e');
    }
  }

  Future<void> _downloadCategories(String? since) async {
    try {
      final response = await apiClient.get(
        '/categories/sync',
        queryParameters: since != null ? {'since': since} : null,
      );

      final categories = response.data['data'] as List;
      final db = await databaseHelper.database;

      for (final category in categories) {
        await db.insert('categories', {
          ...category,
          'sync_status': 'SYNCED',
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      logger.i('Downloaded ${categories.length} categories');
    } catch (e) {
      logger.e('Failed to download categories: $e');
    }
  }

  Future<void> _downloadCustomers(String? since) async {
    try {
      final response = await apiClient.get(
        '/customers/sync',
        queryParameters: since != null ? {'since': since} : null,
      );

      final customers = response.data['data'] as List;
      final db = await databaseHelper.database;

      for (final customer in customers) {
        await db.insert('customers', {
          ...customer,
          'sync_status': 'SYNCED',
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      logger.i('Downloaded ${customers.length} customers');
    } catch (e) {
      logger.e('Failed to download customers: $e');
    }
  }

  Future<void> _downloadUsers(String? since) async {
    try {
      final response = await apiClient.get(
        '/users/sync',
        queryParameters: since != null ? {'since': since} : null,
      );

      final users = response.data['data'] as List;
      final db = await databaseHelper.database;

      for (final user in users) {
        await db.insert('users', {
          ...user,
          'sync_status': 'SYNCED',
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      logger.i('Downloaded ${users.length} users');
    } catch (e) {
      logger.e('Failed to download users: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'settings',
      {'value': now, 'updated_at': now},
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );
  }

  String _getEndpointForTable(String tableName) {
    switch (tableName) {
      case 'products':
        return '/products';
      case 'categories':
        return '/categories';
      case 'transactions':
        return '/transactions';
      case 'customers':
        return '/customers';
      case 'stock_movements':
        return '/stock-movements';
      default:
        throw SyncException(message: 'Unknown table: $tableName');
    }
  }

  Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': now,
    });

    logger.d('Added to sync queue: $tableName - $recordId - $operation');
  }

  void dispose() {
    stopPeriodicSync();
    _syncStatusController?.close();
  }
}
