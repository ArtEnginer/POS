import 'dart:async';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';
import '../sync/sync_manager.dart';
import '../network/connectivity_manager.dart';
import '../network/api_client.dart';

/// Handles background synchronization tasks
class BackgroundSyncService {
  static const String syncTaskId = 'pos_background_sync';
  static const String syncTaskName = 'Background Sync Task';
  static const Duration syncInterval = Duration(minutes: 5);

  final SyncManager _syncManager;
  final ConnectivityManager _connectivityManager;
  final ApiClient _apiClient;
  final Logger _logger;

  Timer? _syncTimer;
  bool _isSyncing = false;

  BackgroundSyncService({
    required SyncManager syncManager,
    required ConnectivityManager connectivityManager,
    required ApiClient apiClient,
    required Logger logger,
  }) : _syncManager = syncManager,
       _connectivityManager = connectivityManager,
       _apiClient = apiClient,
       _logger = logger;

  /// Initialize background sync service
  Future<void> initialize() async {
    try {
      // Initialize Workmanager for periodic background tasks
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      _logger.i('Background sync service initialized');

      // Start listening to connectivity changes
      _connectivityManager.statusStream.listen((status) {
        if (status.name == 'online') {
          _logger.i('Device came online, triggering sync...');
          performSync();
        }
      });

      // Initial sync when service starts
      if (_connectivityManager.isOnline) {
        performSync();
      }
    } catch (e) {
      _logger.e('Error initializing background sync service', error: e);
    }
  }

  /// Start periodic background sync
  Future<void> startPeriodicSync() async {
    try {
      // Register periodic task (only when online)
      if (_connectivityManager.isOnline) {
        await Workmanager().registerPeriodicTask(
          syncTaskId,
          syncTaskName,
          frequency: syncInterval,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresDeviceIdle: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
          ),
          initialDelay: syncInterval,
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 1),
        );
        _logger.i('Periodic sync task registered');
      }
    } catch (e) {
      _logger.e('Error starting periodic sync', error: e);
    }
  }

  /// Stop periodic background sync
  Future<void> stopPeriodicSync() async {
    try {
      await Workmanager().cancelByTag(syncTaskId);
      _logger.i('Periodic sync task cancelled');
    } catch (e) {
      _logger.e('Error stopping periodic sync', error: e);
    }
  }

  /// Perform manual synchronization
  Future<void> performSync({bool fullSync = false}) async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      _logger.i('Sync already in progress, skipping...');
      return;
    }

    // Only sync if online
    if (!_connectivityManager.isOnline) {
      _logger.i('Device is offline, skipping sync');
      return;
    }

    _isSyncing = true;

    try {
      _logger.i('Starting sync operation (fullSync: $fullSync)');

      // Get all pending items
      final pendingItems = await _syncManager.getPendingItems();

      if (pendingItems.isEmpty) {
        _logger.i('No pending items to sync');
        _isSyncing = false;
        return;
      }

      _logger.i('Found ${pendingItems.length} pending items to sync');

      // Sync items by priority
      // Priority 1: Sales (most critical)
      await _syncItemsByType(pendingItems, 'sales', 'Priority 1: Sales');

      // Priority 2: Payments & Returns
      await _syncItemsByType(pendingItems, 'payments', 'Priority 2: Payments');

      // Priority 3: Inventory & Products
      await _syncItemsByType(pendingItems, 'products', 'Priority 3: Products');

      // Priority 4: Others
      final syncedCount =
          pendingItems.where((item) => item.syncedAt != null).length;

      if (syncedCount < pendingItems.length) {
        await _syncRemainingItems(pendingItems);
      }

      // Get sync stats
      final stats = await _syncManager.getSyncStats();
      _logger.i('Sync completed - Stats: $stats');

      // If full sync and there are conflicts, log them
      if (fullSync) {
        final conflicts = await _syncManager.getConflictedItems();
        if (conflicts.isNotEmpty) {
          _logger.w(
            'Found ${conflicts.length} items with conflicts after sync',
          );
        }
      }
    } catch (e) {
      _logger.e('Error during sync operation', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync items by entity type
  Future<void> _syncItemsByType(
    List<SyncQueueItem> items,
    String entityType,
    String label,
  ) async {
    try {
      final itemsToSync =
          items
              .where(
                (item) =>
                    item.entityType == entityType && item.syncedAt == null,
              )
              .toList();

      if (itemsToSync.isEmpty) return;

      _logger.i('$label: Syncing ${itemsToSync.length} items');

      for (final item in itemsToSync) {
        try {
          await _syncItem(item);
          await _syncManager.markAsSynced(item.id);
          _logger.i('Successfully synced: ${item.id}');
        } catch (e) {
          _logger.w('Error syncing item ${item.id}: $e');
          await _syncManager.incrementRetryCount(item.id);
        }
      }
    } catch (e) {
      _logger.e('Error syncing $entityType items', error: e);
    }
  }

  /// Sync remaining items that weren't categorized
  Future<void> _syncRemainingItems(List<SyncQueueItem> items) async {
    try {
      final remainingItems =
          items.where((item) => item.syncedAt == null).toList();

      if (remainingItems.isEmpty) return;

      _logger.i(
        'Priority 4+: Syncing ${remainingItems.length} remaining items',
      );

      for (final item in remainingItems) {
        try {
          await _syncItem(item);
          await _syncManager.markAsSynced(item.id);
          _logger.i('Successfully synced: ${item.id}');
        } catch (e) {
          _logger.w('Error syncing item ${item.id}: $e');
          await _syncManager.incrementRetryCount(item.id);
        }
      }
    } catch (e) {
      _logger.e('Error syncing remaining items', error: e);
    }
  }

  /// Sync a single item to the server
  Future<void> _syncItem(SyncQueueItem item) async {
    try {
      final endpoint = '/api/v1/sync/${item.entityType}';

      switch (item.operation) {
        case 'CREATE':
          await _apiClient.post(endpoint, data: item.data);
          break;
        case 'UPDATE':
          await _apiClient.put('$endpoint/${item.data['id']}', data: item.data);
          break;
        case 'DELETE':
          await _apiClient.delete('$endpoint/${item.data['id']}');
          break;
        default:
          throw Exception('Unknown operation: ${item.operation}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopPeriodicSync();
    _syncTimer?.cancel();
    _logger.i('Background sync service disposed');
  }

  /// Get current sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'isSyncing': _isSyncing,
      'isOnline': _connectivityManager.isOnline,
      'stats': await _syncManager.getSyncStats(),
    };
  }
}

/// Callback dispatcher for background sync tasks
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // This runs in a background isolate
      // You would need to reinitialize services here
      // For now, just log the task execution
      print('Background sync task executed: $taskName');
      return true;
    } catch (e) {
      print('Error in background sync task: $e');
      return false;
    }
  });
}
