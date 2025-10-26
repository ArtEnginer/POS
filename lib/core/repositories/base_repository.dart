import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import '../sync/sync_manager.dart';
import '../network/connectivity_manager.dart';

/// Base repository class that provides common functionality for all repositories
/// supporting offline-first operations
abstract class BaseRepository {
  final SyncManager syncManager;
  final ConnectivityManager connectivityManager;

  BaseRepository({
    required this.syncManager,
    required this.connectivityManager,
  });

  /// Safely execute an operation with error handling
  Future<Either<Failure, T>> executeOperation<T>({
    required Future<T> Function() operation,
    required String operationType,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(message: 'Error during $operationType: $e'));
    }
  }

  /// Queue an operation for later sync
  Future<String> queueOperation({
    required String operation, // CREATE, UPDATE, DELETE
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    return await syncManager.addToQueue(
      operation: operation,
      entityType: entityType,
      data: data,
    );
  }

  /// Get data, using local cache if offline
  Future<Either<Failure, T>> getWithFallback<T>({
    required Future<T> Function() remoteOperation,
    required Future<T> Function() localOperation,
    required String operationType,
  }) async {
    try {
      if (connectivityManager.isOnline) {
        try {
          // Try remote first when online
          final result = await remoteOperation();
          return Right(result);
        } catch (e) {
          // Fallback to local if remote fails
          final localResult = await localOperation();
          return Right(localResult);
        }
      } else {
        // Use local when offline
        final result = await localOperation();
        return Right(result);
      }
    } catch (e) {
      return Left(UnknownFailure(message: 'Error during $operationType: $e'));
    }
  }

  /// Create operation with offline support
  Future<Either<Failure, T>> createWithSync<T>({
    required Future<T> Function() localOperation,
    required Future<T> Function() remoteOperation,
    required String entityType,
    required Map<String, dynamic> data,
    required String operationType,
  }) async {
    try {
      // Always save to local first
      final localResult = await localOperation();

      // If online, sync immediately
      if (connectivityManager.isOnline) {
        try {
          await remoteOperation();
        } catch (e) {
          // If remote fails, queue for later sync
          await queueOperation(
            operation: 'CREATE',
            entityType: entityType,
            data: data,
          );
        }
      } else {
        // If offline, queue for sync
        await queueOperation(
          operation: 'CREATE',
          entityType: entityType,
          data: data,
        );
      }

      return Right(localResult);
    } catch (e) {
      return Left(UnknownFailure(message: 'Error during $operationType: $e'));
    }
  }

  /// Update operation with offline support
  Future<Either<Failure, T>> updateWithSync<T>({
    required Future<T> Function() localOperation,
    required Future<T> Function() remoteOperation,
    required String entityType,
    required Map<String, dynamic> data,
    required String operationType,
  }) async {
    try {
      // Always update local first
      final localResult = await localOperation();

      // If online, sync immediately
      if (connectivityManager.isOnline) {
        try {
          await remoteOperation();
        } catch (e) {
          // If remote fails, queue for later sync
          await queueOperation(
            operation: 'UPDATE',
            entityType: entityType,
            data: data,
          );
        }
      } else {
        // If offline, queue for sync
        await queueOperation(
          operation: 'UPDATE',
          entityType: entityType,
          data: data,
        );
      }

      return Right(localResult);
    } catch (e) {
      return Left(UnknownFailure(message: 'Error during $operationType: $e'));
    }
  }

  /// Delete operation with offline support
  Future<Either<Failure, void>> deleteWithSync({
    required Future<void> Function() localOperation,
    required Future<void> Function() remoteOperation,
    required String entityType,
    required Map<String, dynamic> data,
    required String operationType,
  }) async {
    try {
      // Always delete from local first
      await localOperation();

      // If online, sync immediately
      if (connectivityManager.isOnline) {
        try {
          await remoteOperation();
        } catch (e) {
          // If remote fails, queue for later sync
          await queueOperation(
            operation: 'DELETE',
            entityType: entityType,
            data: data,
          );
        }
      } else {
        // If offline, queue for sync
        await queueOperation(
          operation: 'DELETE',
          entityType: entityType,
          data: data,
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Error during $operationType: $e'));
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'hasPendingItems': await syncManager.hasPendingItems(),
      'stats': await syncManager.getSyncStats(),
      'isOnline': connectivityManager.isOnline,
    };
  }
}
