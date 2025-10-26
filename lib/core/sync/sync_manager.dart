import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';

/// Represents a sync queue item for offline-first operations
class SyncQueueItem {
  final String id;
  final String operation; // CREATE, UPDATE, DELETE
  final String entityType; // sales, products, customers, etc
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final bool isResolved;
  final String? conflictResolution; // KEEP_LOCAL, KEEP_REMOTE, MERGE
  final String? conflictDetails;

  SyncQueueItem({
    String? id,
    required this.operation,
    required this.entityType,
    required this.data,
    DateTime? createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.isResolved = false,
    this.conflictResolution,
    this.conflictDetails,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'entityType': entityType,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'retryCount': retryCount,
      'isResolved': isResolved ? 1 : 0,
      'conflictResolution': conflictResolution,
      'conflictDetails': conflictDetails,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      operation: map['operation'] as String,
      entityType: map['entityType'] as String,
      data: map['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncedAt:
          map['syncedAt'] != null
              ? DateTime.parse(map['syncedAt'] as String)
              : null,
      retryCount: map['retryCount'] as int? ?? 0,
      isResolved: (map['isResolved'] as int? ?? 0) == 1,
      conflictResolution: map['conflictResolution'] as String?,
      conflictDetails: map['conflictDetails'] as String?,
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? operation,
    String? entityType,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? syncedAt,
    int? retryCount,
    bool? isResolved,
    String? conflictResolution,
    String? conflictDetails,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      isResolved: isResolved ?? this.isResolved,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      conflictDetails: conflictDetails ?? this.conflictDetails,
    );
  }
}

/// Manages the sync queue and offline-first operations
class SyncManager {
  static const String _tableName = 'sync_queue';
  static const int _maxRetries = 5;
  static const int _maxQueueAge = 7; // days

  final DatabaseHelper _dbHelper;
  final Logger _logger;

  SyncManager({required DatabaseHelper dbHelper, required Logger logger})
    : _dbHelper = dbHelper,
      _logger = logger;

  /// Add an item to the sync queue
  Future<String> addToQueue({
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = SyncQueueItem(
        operation: operation,
        entityType: entityType,
        data: data,
      );

      final db = await _dbHelper.database;
      await db.insert(
        _tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.i('Added to sync queue: ${item.id} - $operation:$entityType');
      return item.id;
    } catch (e) {
      _logger.e('Error adding to sync queue', error: e);
      rethrow;
    }
  }

  /// Get all pending sync items
  Future<List<SyncQueueItem>> getPendingItems({String? entityType}) async {
    try {
      final db = await _dbHelper.database;

      String where = 'syncedAt IS NULL AND isResolved = 0';
      List<dynamic> whereArgs = [];

      if (entityType != null) {
        where += ' AND entityType = ?';
        whereArgs.add(entityType);
      }

      where += ' ORDER BY createdAt ASC';

      final maps = await db.query(
        _tableName,
        where: where,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );

      return List<SyncQueueItem>.from(
        maps.map((map) => SyncQueueItem.fromMap(map as Map<String, dynamic>)),
      );
    } catch (e) {
      _logger.e('Error getting pending items', error: e);
      rethrow;
    }
  }

  /// Mark an item as synced
  Future<void> markAsSynced(String itemId) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        _tableName,
        {'syncedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      _logger.i('Marked as synced: $itemId');
    } catch (e) {
      _logger.e('Error marking as synced', error: e);
      rethrow;
    }
  }

  /// Increment retry count for an item
  Future<void> incrementRetryCount(String itemId) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (result.isNotEmpty) {
        final item = SyncQueueItem.fromMap(
          result.first as Map<String, dynamic>,
        );
        final newRetryCount = item.retryCount + 1;

        if (newRetryCount > _maxRetries) {
          // Mark as resolved but not synced - needs manual intervention
          await db.update(
            _tableName,
            {
              'retryCount': newRetryCount,
              'isResolved': 1,
              'conflictDetails': 'Max retries exceeded',
            },
            where: 'id = ?',
            whereArgs: [itemId],
          );
          _logger.w('Max retries exceeded for: $itemId');
        } else {
          await db.update(
            _tableName,
            {'retryCount': newRetryCount},
            where: 'id = ?',
            whereArgs: [itemId],
          );
          _logger.i('Incremented retry count for $itemId: $newRetryCount');
        }
      }
    } catch (e) {
      _logger.e('Error incrementing retry count', error: e);
      rethrow;
    }
  }

  /// Resolve a conflict for a sync item
  Future<void> resolveConflict({
    required String itemId,
    required String resolution, // KEEP_LOCAL, KEEP_REMOTE, MERGE
    required Map<String, dynamic> resolvedData,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        _tableName,
        {
          'conflictResolution': resolution,
          'data': resolvedData,
          'isResolved': 1,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
      _logger.i('Resolved conflict for $itemId with strategy: $resolution');
    } catch (e) {
      _logger.e('Error resolving conflict', error: e);
      rethrow;
    }
  }

  /// Get items with conflicts (needs manual resolution)
  Future<List<SyncQueueItem>> getConflictedItems() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        _tableName,
        where: 'conflictResolution IS NOT NULL AND syncedAt IS NULL',
        orderBy: 'createdAt DESC',
      );

      return List<SyncQueueItem>.from(
        maps.map((map) => SyncQueueItem.fromMap(map as Map<String, dynamic>)),
      );
    } catch (e) {
      _logger.e('Error getting conflicted items', error: e);
      rethrow;
    }
  }

  /// Delete a sync queue item
  Future<void> deleteItem(String itemId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [itemId]);
      _logger.i('Deleted sync queue item: $itemId');
    } catch (e) {
      _logger.e('Error deleting sync queue item', error: e);
      rethrow;
    }
  }

  /// Clean up old synced items (older than _maxQueueAge days)
  Future<void> cleanupOldItems() async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: _maxQueueAge));

      final result = await db.delete(
        _tableName,
        where: 'syncedAt IS NOT NULL AND syncedAt < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      _logger.i('Cleaned up $result old sync items');
    } catch (e) {
      _logger.e('Error cleaning up old items', error: e);
      rethrow;
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final db = await _dbHelper.database;

      final pendingResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE syncedAt IS NULL AND isResolved = 0',
      );

      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE syncedAt IS NOT NULL',
      );

      final conflictResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE conflictResolution IS NOT NULL',
      );

      return {
        'pending': (pendingResult.first['count'] as int?) ?? 0,
        'synced': (syncedResult.first['count'] as int?) ?? 0,
        'conflicts': (conflictResult.first['count'] as int?) ?? 0,
      };
    } catch (e) {
      _logger.e('Error getting sync stats', error: e);
      rethrow;
    }
  }

  /// Check if there are pending items to sync
  Future<bool> hasPendingItems({String? entityType}) async {
    try {
      final pendingItems = await getPendingItems(entityType: entityType);
      return pendingItems.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking pending items', error: e);
      return false;
    }
  }

  /// Get the oldest pending item
  Future<SyncQueueItem?> getOldestPendingItem() async {
    try {
      final items = await getPendingItems();
      return items.isNotEmpty ? items.first : null;
    } catch (e) {
      _logger.e('Error getting oldest pending item', error: e);
      return null;
    }
  }
}
