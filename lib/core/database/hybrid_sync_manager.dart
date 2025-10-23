import 'dart:async';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'mysql_connector.dart';
import '../network/network_info.dart';

enum SyncMode { localOnly, onlineOnly, hybrid }

enum SyncDirection { upload, download, bidirectional }

/// Hybrid Sync Manager for local-online synchronization
/// Automatically syncs between SQLite (local) and MySQL (server)
class HybridSyncManager {
  final DatabaseHelper databaseHelper;
  final MySQLConnector mysqlConnector;
  final NetworkInfo networkInfo;
  final Logger logger;

  Timer? _autoSyncTimer;
  Timer? _fastSyncTimer;
  bool _isSyncing = false;
  SyncMode _currentMode = SyncMode.localOnly;
  final StreamController<SyncMode> _syncModeController =
      StreamController<SyncMode>.broadcast();
  final StreamController<SyncProgress> _syncProgressController =
      StreamController<SyncProgress>.broadcast();

  // Sync intervals
  static const Duration autoSyncInterval = Duration(
    minutes: 5,
  ); // Backup slow sync
  static const Duration fastSyncInterval = Duration(
    seconds: 30,
  ); // Fast sync when online
  static const int batchSize = 100;

  // Tables to sync
  static const List<String> syncTables = [
    'products',
    'categories',
    'suppliers',
    'customers',
    'purchases',
    'purchase_items',
    'receivings',
    'receiving_items',
    'purchase_returns',
    'purchase_return_items',
    'transactions',
    'transaction_items',
    'stock_movements',
  ];

  // Tables that don't have updated_at column (use created_at instead)
  static const List<String> tablesWithoutUpdatedAt = [
    'purchase_items',
    'transaction_items',
    'stock_movements',
    'receiving_items',
    'purchase_return_items',
  ];

  HybridSyncManager({
    required this.databaseHelper,
    required this.mysqlConnector,
    required this.networkInfo,
    required this.logger,
  });

  /// Stream of current sync mode
  Stream<SyncMode> get syncModeStream => _syncModeController.stream;

  /// Stream of sync progress
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;

  /// Get current sync mode
  SyncMode get currentMode => _currentMode;

  /// Check and update sync mode based on MySQL availability
  Future<SyncMode> updateSyncMode() async {
    final hasNetwork = await networkInfo.isConnected;
    final mysqlAvailable = mysqlConnector.isAvailable;

    SyncMode newMode;

    if (!hasNetwork) {
      newMode = SyncMode.localOnly;
      logger.i('No network connection - using local mode');
    } else if (mysqlAvailable) {
      newMode = SyncMode.hybrid;
      logger.i('MySQL server available - using hybrid mode');
    } else {
      newMode = SyncMode.localOnly;
      logger.i('MySQL server not available - using local mode');
    }

    if (_currentMode != newMode) {
      _currentMode = newMode;
      _syncModeController.add(newMode);

      // If switching to hybrid mode, trigger immediate sync
      if (newMode == SyncMode.hybrid) {
        unawaited(performSync(SyncDirection.bidirectional));
      }
    }

    return newMode;
  }

  /// Start connection-aware sync (no timer, checks on-demand)
  void startAutoSync() {
    _autoSyncTimer?.cancel();
    _fastSyncTimer?.cancel();

    // Only use a slow background sync for occasional checks
    // Real sync happens on-demand when data operations occur
    _autoSyncTimer = Timer.periodic(autoSyncInterval, (_) async {
      await updateSyncMode();
      if (_currentMode != SyncMode.localOnly && !_isSyncing) {
        logger.d('🔄 Background sync check');
        await performSync(SyncDirection.bidirectional);
      }
    });

    logger.i('✅ Connection-aware sync started (on-demand mode)');
    logger.i('   📡 Server availability checked before each operation');
    logger.i('   🔄 Background sync: every $autoSyncInterval (5min) as backup');
  }

  /// Stop auto-sync timer
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    logger.i('❌ Auto-sync stopped');
  }

  /// Perform synchronization
  Future<SyncResult> performSync(SyncDirection direction) async {
    if (_isSyncing) {
      logger.w('Sync already in progress');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (_currentMode == SyncMode.localOnly) {
      logger.w('Cannot sync in local-only mode');
      return SyncResult(success: false, message: 'MySQL server not available');
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    int uploadedRecords = 0;
    int downloadedRecords = 0;
    final List<String> errors = [];

    try {
      logger.i('Starting sync in ${direction.name} mode');

      for (var i = 0; i < syncTables.length; i++) {
        final table = syncTables[i];
        _syncProgressController.add(
          SyncProgress(
            currentTable: table,
            tableIndex: i,
            totalTables: syncTables.length,
            recordsSynced: 0,
          ),
        );

        try {
          // Upload (Local to MySQL)
          if (direction == SyncDirection.upload ||
              direction == SyncDirection.bidirectional) {
            final uploaded = await _uploadTable(table);
            uploadedRecords += uploaded;
            logger.d('Uploaded $uploaded records from $table');
          }

          // Download (MySQL to Local)
          if (direction == SyncDirection.download ||
              direction == SyncDirection.bidirectional) {
            final downloaded = await _downloadTable(table);
            downloadedRecords += downloaded;
            logger.d('Downloaded $downloaded records to $table');
          }
        } catch (e) {
          final error = 'Error syncing $table: $e';
          errors.add(error);
          logger.e(error);
        }
      }

      // Update last sync timestamp
      await _updateLastSyncTime();

      final duration = DateTime.now().difference(startTime);
      final result = SyncResult(
        success: errors.isEmpty,
        message:
            errors.isEmpty
                ? 'Sync completed successfully'
                : 'Sync completed with errors',
        uploadedRecords: uploadedRecords,
        downloadedRecords: downloadedRecords,
        duration: duration,
        errors: errors,
      );

      logger.i(
        'Sync completed: ${result.uploadedRecords} uploaded, '
        '${result.downloadedRecords} downloaded in ${duration.inSeconds}s',
      );

      return result;
    } finally {
      _isSyncing = false;
      _syncProgressController.add(
        SyncProgress(
          currentTable: '',
          tableIndex: syncTables.length,
          totalTables: syncTables.length,
          recordsSynced: uploadedRecords + downloadedRecords,
        ),
      );
    }
  }

  /// Upload local changes to MySQL
  Future<int> _uploadTable(String table) async {
    final db = await databaseHelper.database;
    int totalUploaded = 0;

    // Get pending records (sync_status = PENDING)
    final pendingRecords = await db.query(
      table,
      where: 'sync_status = ?',
      whereArgs: ['PENDING'],
      limit: batchSize,
    );

    if (pendingRecords.isEmpty) {
      return 0;
    }

    try {
      // Upload in batches
      await mysqlConnector.batchInsert(table, pendingRecords);

      // Update sync status to SYNCED
      final batch = db.batch();
      for (final record in pendingRecords) {
        batch.update(
          table,
          {'sync_status': 'SYNCED'},
          where: 'id = ?',
          whereArgs: [record['id']],
        );
      }
      await batch.commit(noResult: true);

      totalUploaded = pendingRecords.length;
    } catch (e) {
      logger.e('Failed to upload $table: $e');
      rethrow;
    }

    return totalUploaded;
  }

  /// Download changes from MySQL to local
  Future<int> _downloadTable(String table) async {
    try {
      // Always do full sync to ensure local mirrors server (detects deletes)
      // This is important to keep data consistent with server
      return await _fullSyncTable(table);
    } catch (e) {
      logger.e('Failed to download $table: $e');
      rethrow;
    }
  }

  /// Full sync table - mirror server data (for online mode)
  Future<int> _fullSyncTable(String table) async {
    final db = await databaseHelper.database;
    int totalSynced = 0;

    try {
      // Use debug level for routine syncs to reduce noise
      logger.d('🔄 Syncing $table...');

      // Get all records from server
      final serverRecords = await mysqlConnector.query(table, limit: 10000);

      // Get all local record IDs
      final localRecords = await db.query(table, columns: ['id']);
      final localIds =
          localRecords
              .map((r) => r['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();

      // Get server record IDs
      final serverIds =
          serverRecords
              .map((r) => r['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();

      logger.d(
        '📊 $table - Local IDs: ${localIds.length}, Server IDs: ${serverIds.length}',
      );

      // Find records to delete (exist locally but not on server)
      final idsToDelete = localIds.difference(serverIds);

      if (idsToDelete.isNotEmpty) {
        logger.w(
          '🗑️ Deleting ${idsToDelete.length} records from $table (removed from server)',
        );
        logger.d(
          '   IDs to delete: ${idsToDelete.take(5).join(", ")}${idsToDelete.length > 5 ? "..." : ""}',
        );

        final batch = db.batch();
        for (final id in idsToDelete) {
          batch.delete(table, where: 'id = ?', whereArgs: [id]);
        }
        await batch.commit(noResult: true);
      } else {
        logger.d('✓ No records to delete from $table');
      }

      // Insert or update server records to local
      if (serverRecords.isNotEmpty) {
        logger.i('⬇️ Syncing ${serverRecords.length} records to $table');
        final batch = db.batch();
        for (final record in serverRecords) {
          batch.insert(table, {
            ...record,
            'sync_status': 'SYNCED',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        totalSynced = serverRecords.length;
      }

      // Update last sync time
      final now = DateTime.now().toIso8601String();
      await db.insert('settings', {
        'key': 'last_sync_$table',
        'value': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Only log completion if there were actual changes
      if (totalSynced > 0 || idsToDelete.isNotEmpty) {
        logger.i(
          '✅ $table synced: $totalSynced updated, ${idsToDelete.length} deleted',
        );
      } else {
        logger.d('✓ $table up to date');
      }
    } catch (e) {
      logger.e('❌ Failed to full sync $table: $e');
      rethrow;
    }

    return totalSynced;
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('settings', {
      'key': 'last_sync',
      'value': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Queue record for sync
  Future<void> queueForSync(
    String table,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final db = await databaseHelper.database;

    // Update sync_status to PENDING
    await db.update(
      table,
      {'sync_status': 'PENDING'},
      where: 'id = ?',
      whereArgs: [recordId],
    );

    logger.d('Queued $table record $recordId for sync');

    // If in hybrid mode, trigger immediate sync
    if (_currentMode == SyncMode.hybrid && !_isSyncing) {
      unawaited(performSync(SyncDirection.upload));
    }
  }

  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics() async {
    final db = await databaseHelper.database;
    final Map<String, int> pendingCounts = {};
    final Map<String, int> syncedCounts = {};

    for (final table in syncTables) {
      // Count pending records
      final pendingResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $table WHERE sync_status = ?',
        ['PENDING'],
      );
      pendingCounts[table] = Sqflite.firstIntValue(pendingResult) ?? 0;

      // Count synced records
      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $table WHERE sync_status = ?',
        ['SYNCED'],
      );
      syncedCounts[table] = Sqflite.firstIntValue(syncedResult) ?? 0;
    }

    // Get last sync time
    final lastSyncResult = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );

    DateTime? lastSyncTime;
    if (lastSyncResult.isNotEmpty) {
      final value = lastSyncResult.first['value'] as String?;
      if (value != null) {
        lastSyncTime = DateTime.tryParse(value);
      }
    }

    return SyncStatistics(
      pendingCounts: pendingCounts,
      syncedCounts: syncedCounts,
      lastSyncTime: lastSyncTime,
      currentMode: _currentMode,
    );
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _syncModeController.close();
    _syncProgressController.close();
  }
}

/// Sync progress information
class SyncProgress {
  final String currentTable;
  final int tableIndex;
  final int totalTables;
  final int recordsSynced;

  SyncProgress({
    required this.currentTable,
    required this.tableIndex,
    required this.totalTables,
    required this.recordsSynced,
  });

  double get progress => totalTables > 0 ? tableIndex / totalTables : 0.0;

  @override
  String toString() =>
      'Syncing $currentTable ($tableIndex/$totalTables) - $recordsSynced records';
}

/// Sync result information
class SyncResult {
  final bool success;
  final String message;
  final int uploadedRecords;
  final int downloadedRecords;
  final Duration? duration;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.uploadedRecords = 0,
    this.downloadedRecords = 0,
    this.duration,
    this.errors = const [],
  });

  @override
  String toString() =>
      'SyncResult(success: $success, '
      'uploaded: $uploadedRecords, downloaded: $downloadedRecords, '
      'duration: ${duration?.inSeconds}s, errors: ${errors.length})';
}

/// Sync statistics
class SyncStatistics {
  final Map<String, int> pendingCounts;
  final Map<String, int> syncedCounts;
  final DateTime? lastSyncTime;
  final SyncMode currentMode;

  SyncStatistics({
    required this.pendingCounts,
    required this.syncedCounts,
    required this.lastSyncTime,
    required this.currentMode,
  });

  int get totalPending =>
      pendingCounts.values.fold(0, (sum, count) => sum + count);

  int get totalSynced =>
      syncedCounts.values.fold(0, (sum, count) => sum + count);

  @override
  String toString() =>
      'SyncStatistics(pending: $totalPending, '
      'synced: $totalSynced, mode: ${currentMode.name}, '
      'lastSync: $lastSyncTime)';
}

/// Extension for HybridSyncManager to support on-demand data fetching
extension HybridDataFetcher on HybridSyncManager {
  /// Query data with automatic server check and fallback
  /// 1. Check if server is available
  /// 2. If available, fetch from server (online data)
  /// 3. If not available, fetch from local SQLite
  /// 4. Sync in background if switching from offline to online
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    // Update sync mode to check server availability
    await updateSyncMode();

    try {
      // If server is available, fetch from server (real-time data)
      if (_currentMode == SyncMode.hybrid ||
          _currentMode == SyncMode.onlineOnly) {
        logger.d('📡 Fetching $table from server (online mode)');

        final records = await mysqlConnector.query(
          table,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );

        // Update local cache in background (non-blocking)
        if (records.isNotEmpty) {
          unawaited(_updateLocalCache(table, records));
        }

        logger.d('✅ Retrieved ${records.length} records from server');
        return records;
      }
    } catch (e) {
      logger.w('⚠️ Server query failed, falling back to local: $e');
      // Fall through to local query
    }

    // Fallback: Fetch from local SQLite
    logger.d('💾 Fetching $table from local database (offline mode)');
    final db = await databaseHelper.database;

    final records = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    logger.d('✅ Retrieved ${records.length} records from local');
    return records;
  }

  /// Insert data with automatic online/offline handling
  Future<int> insertRecord(
    String table,
    Map<String, dynamic> data, {
    bool syncImmediately = true,
  }) async {
    await updateSyncMode();

    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    // Add metadata
    data['sync_status'] = 'PENDING';
    data['updated_at'] = now;
    if (!data.containsKey('created_at')) {
      data['created_at'] = now;
    }

    // Insert to local first (for offline support)
    final localId = await db.insert(table, data);
    logger.d('💾 Inserted record to local $table (id: $localId)');

    // If online, sync immediately
    if ((_currentMode == SyncMode.hybrid ||
            _currentMode == SyncMode.onlineOnly) &&
        syncImmediately) {
      try {
        await mysqlConnector.insert(table, data);

        // Update sync status
        await db.update(
          table,
          {'sync_status': 'SYNCED'},
          where: 'id = ?',
          whereArgs: [localId],
        );

        logger.d('📡 Synced record to server immediately');
      } catch (e) {
        logger.w('⚠️ Failed to sync to server, will retry later: $e');
      }
    }

    return localId;
  }

  /// Update data with automatic online/offline handling
  Future<int> updateRecord(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
    bool syncImmediately = true,
  }) async {
    await updateSyncMode();

    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    // Add metadata
    data['sync_status'] = 'PENDING';
    data['updated_at'] = now;

    // Update local first
    final count = await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
    logger.d('💾 Updated $count records in local $table');

    // If online, sync immediately
    if ((_currentMode == SyncMode.hybrid ||
            _currentMode == SyncMode.onlineOnly) &&
        syncImmediately &&
        where != null) {
      try {
        await mysqlConnector.update(table, data, where, whereArgs);

        // Update sync status
        await db.update(
          table,
          {'sync_status': 'SYNCED'},
          where: where,
          whereArgs: whereArgs,
        );

        logger.d('📡 Synced updates to server immediately');
      } catch (e) {
        logger.w('⚠️ Failed to sync to server, will retry later: $e');
      }
    }

    return count;
  }

  /// Delete data with automatic online/offline handling
  Future<int> deleteRecord(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    bool syncImmediately = true,
  }) async {
    await updateSyncMode();

    final db = await databaseHelper.database;

    // Delete from local
    final count = await db.delete(table, where: where, whereArgs: whereArgs);
    logger.d('💾 Deleted $count records from local $table');

    // If online, sync immediately
    if ((_currentMode == SyncMode.hybrid ||
            _currentMode == SyncMode.onlineOnly) &&
        syncImmediately &&
        where != null) {
      try {
        await mysqlConnector.delete(table, where, whereArgs);

        logger.d('📡 Synced deletion to server immediately');
      } catch (e) {
        logger.w('⚠️ Failed to sync deletion to server, will retry later: $e');
      }
    }

    return count;
  }

  /// Update local cache in background (non-blocking)
  Future<void> _updateLocalCache(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final db = await databaseHelper.database;
      final batch = db.batch();

      for (final record in records) {
        batch.insert(table, {
          ...record,
          'sync_status': 'SYNCED',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      logger.d(
        '💾 Updated local cache for $table with ${records.length} records',
      );
    } catch (e) {
      logger.e('❌ Failed to update local cache: $e');
    }
  }
}

// Helper to avoid unawaited_futures lint
void unawaited(Future<void> future) {}
