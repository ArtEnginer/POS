import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:logger/logger.dart';

/// Migration utility to add sync_status column to tables that don't have it
class SyncStatusMigration {
  final DatabaseHelper databaseHelper;
  final Logger logger;

  SyncStatusMigration({required this.databaseHelper, required this.logger});

  /// Tables that need sync_status column
  static const List<String> tablesToMigrate = [
    'purchase_items',
    'receiving_items',
    'purchase_return_items',
  ];

  /// Check if table has sync_status column
  Future<bool> hasSyncStatusColumn(Database db, String tableName) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.any((column) => column['name'] == 'sync_status');
    } catch (e) {
      logger.e('Error checking sync_status column in $tableName: $e');
      return false;
    }
  }

  /// Add sync_status column to table
  Future<void> addSyncStatusColumn(Database db, String tableName) async {
    try {
      logger.i('Adding sync_status column to $tableName');

      await db.execute('''
        ALTER TABLE $tableName 
        ADD COLUMN sync_status TEXT DEFAULT 'SYNCED'
      ''');

      logger.i('✓ Added sync_status column to $tableName');
    } catch (e) {
      logger.e('Failed to add sync_status to $tableName: $e');
      rethrow;
    }
  }

  /// Migrate all tables
  Future<void> migrateAll() async {
    logger.i('Starting sync_status migration...');
    final db = await databaseHelper.database;
    int migratedCount = 0;

    for (final table in tablesToMigrate) {
      try {
        final hasColumn = await hasSyncStatusColumn(db, table);

        if (!hasColumn) {
          await addSyncStatusColumn(db, table);
          migratedCount++;
        } else {
          logger.d('Table $table already has sync_status column');
        }
      } catch (e) {
        logger.e('Error migrating $table: $e');
      }
    }

    logger.i('Migration completed: $migratedCount tables migrated');
  }

  /// Run migration for specific table
  Future<void> migrateTable(String tableName) async {
    logger.i('Migrating table: $tableName');
    final db = await databaseHelper.database;

    final hasColumn = await hasSyncStatusColumn(db, tableName);

    if (!hasColumn) {
      await addSyncStatusColumn(db, tableName);
      logger.i('✓ Table $tableName migrated successfully');
    } else {
      logger.i('Table $tableName already has sync_status column');
    }
  }
}
