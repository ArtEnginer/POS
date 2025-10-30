import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/product_repository.dart';
import '../../../cashier/data/models/sale_model.dart';

/// Sync event untuk broadcast ke UI
class SyncEvent {
  final String type; // 'success', 'error', 'progress'
  final String message;
  final int? syncedCount;
  final int? failedCount;

  SyncEvent({
    required this.type,
    required this.message,
    this.syncedCount,
    this.failedCount,
  });
}

/// Background sync service untuk sync data offline/online
class SyncService {
  final HiveService _hiveService;
  final ApiService _apiService;
  final ProductRepository _productRepository;
  final SocketService _socketService;
  final Connectivity _connectivity;

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isOnline = false;
  StreamSubscription? _socketStatusSubscription;

  // Stream untuk broadcast sync events ke UI
  final _syncEventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  SyncService({
    required HiveService hiveService,
    required ApiService apiService,
    required ProductRepository productRepository,
    required SocketService socketService,
  }) : _hiveService = hiveService,
       _apiService = apiService,
       _productRepository = productRepository,
       _socketService = socketService,
       _connectivity = Connectivity() {
    _initConnectivityListener();
    _initSocketListener(); // Listen to WebSocket status
  }

  /// Initialize WebSocket listener untuk real-time mode switching
  void _initSocketListener() {
    _socketStatusSubscription = _socketService.serverStatus.listen((isOnline) {
      print('🔌 WebSocket status changed: ${isOnline ? "ONLINE" : "OFFLINE"}');
      _isOnline = isOnline;

      if (isOnline) {
        print('🟢 Server is ONLINE - Checking for pending sales...');

        // Check pending sales count
        final pendingCount = _getPendingSalesCount();

        if (pendingCount > 0) {
          print('📦 Found $pendingCount pending sales - AUTO-SYNCING...');

          // Broadcast event: Sync starting
          _syncEventController.add(
            SyncEvent(
              type: 'progress',
              message: 'Menyinkronkan $pendingCount transaksi...',
              syncedCount: 0,
              failedCount: 0,
            ),
          );

          // AUTO-SYNC saat WebSocket connect!
          syncAll().then((success) {
            if (success) {
              final newPendingCount = _getPendingSalesCount();
              final synced = pendingCount - newPendingCount;

              print(
                '✅ AUTO-SYNC COMPLETED: $synced/$pendingCount sales synced',
              );

              // Broadcast success event
              _syncEventController.add(
                SyncEvent(
                  type: 'success',
                  message: '✅ Berhasil menyinkronkan $synced transaksi!',
                  syncedCount: synced,
                  failedCount: pendingCount - synced,
                ),
              );
            }
          });
        } else {
          print('✅ No pending sales to sync');
        }
      }
    });
  }

  /// Get pending sales count
  int _getPendingSalesCount() {
    try {
      final salesBox = _hiveService.salesBox;
      return salesBox.values.where((data) {
        try {
          final sale =
              data is Map<String, dynamic>
                  ? SaleModel.fromJson(data)
                  : SaleModel.fromJson(Map<String, dynamic>.from(data as Map));
          return !sale.isSynced;
        } catch (e) {
          return false;
        }
      }).length;
    } catch (e) {
      print('❌ Error counting pending sales: $e');
      return 0;
    }
  }

  /// REAL-TIME: Sync single sale immediately (called after payment)
  Future<bool> syncSaleImmediately(String saleId) async {
    if (!_isOnline) {
      print('⚠️ Cannot sync sale $saleId - Server OFFLINE');
      return false;
    }

    try {
      final salesBox = _hiveService.salesBox;
      final saleData = salesBox.get(saleId);

      if (saleData == null) {
        print('❌ Sale $saleId not found in local database');
        return false;
      }

      final sale =
          saleData is Map<String, dynamic>
              ? SaleModel.fromJson(saleData)
              : SaleModel.fromJson(Map<String, dynamic>.from(saleData as Map));

      if (sale.isSynced) {
        print('✅ Sale ${sale.invoiceNumber} already synced');
        return true;
      }

      print('📤 IMMEDIATE SYNC: Uploading sale ${sale.invoiceNumber}...');

      final saleJson = Map<String, dynamic>.from(sale.toJson());
      final success = await _apiService.syncSale(saleJson);

      if (success) {
        // Mark as synced
        final updatedSale = sale.copyWith(
          isSynced: true,
          syncedAt: DateTime.now(),
        );
        await salesBox.put(sale.id, updatedSale.toJson());

        print('✅ REAL-TIME SYNC SUCCESS: ${sale.invoiceNumber}');
        return true;
      } else {
        print('❌ REAL-TIME SYNC FAILED: ${sale.invoiceNumber}');
        return false;
      }
    } catch (e) {
      print('❌ Error in immediate sync: $e');
      return false;
    }
  }

  /// Initialize connectivity listener
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      final hasNetwork = result != ConnectivityResult.none;

      if (hasNetwork && wasOffline) {
        print('🟢 Network connection restored');
        // WebSocket akan auto-reconnect dan trigger sync
      } else if (!hasNetwork && !wasOffline) {
        print('🔴 Network connection lost');
      }
    });
  }

  /// Start background sync
  void startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      if (_isOnline) {
        syncAll();
      }
    });

    print(
      '⏰ Background sync started (every ${AppConstants.syncInterval.inMinutes} minutes)',
    );
    print('🔌 Real-time mode switching via WebSocket enabled');
  }

  /// Force set online status (dipanggil saat online login berhasil)
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    print('📡 Online status manually set to: $isOnline');
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _socketStatusSubscription?.cancel();
    print('⏰ Background sync stopped');
    print('🔌 WebSocket listener stopped');
  }

  /// Sync all data
  Future<bool> syncAll() async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress, skipping...');
      return false;
    }

    _isSyncing = true;
    try {
      print('🔄 Starting full sync...');

      // Download products from server
      await _downloadProducts();

      // Download categories
      await _downloadCategories();

      // Upload pending sales
      await _uploadPendingSales();

      print('✅ Full sync completed successfully');
      return true;
    } catch (e) {
      print('❌ Sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Download products from server
  Future<void> _downloadProducts() async {
    try {
      // Broadcast: Starting download
      _syncEventController.add(
        SyncEvent(
          type: 'progress',
          message: 'Memulai sinkronisasi produk...',
          syncedCount: 0,
        ),
      );

      final count = await _productRepository.syncProductsFromServer(
        onProgress: (current, total) {
          // Broadcast progress
          _syncEventController.add(
            SyncEvent(
              type: 'progress',
              message: 'Mengunduh produk: $current dari $total',
              syncedCount: current,
            ),
          );
        },
      );

      if (count > 0) {
        print('✅ Downloaded $count products from server');

        // Broadcast: Success
        _syncEventController.add(
          SyncEvent(
            type: 'success',
            message: '✅ Berhasil menyinkronkan $count produk',
            syncedCount: count,
          ),
        );

        // ✅ NOTIFY UI: Produk sudah di-download, refresh UI!
        _socketService.triggerDataUpdate('product:synced');
      } else {
        print('⚠️ No products downloaded');

        // Broadcast: Warning
        _syncEventController.add(
          SyncEvent(
            type: 'progress',
            message: 'Tidak ada produk baru untuk disinkronkan',
            syncedCount: 0,
          ),
        );
      }
    } catch (e) {
      print('❌ Error downloading products: $e');

      // Broadcast: Error
      _syncEventController.add(
        SyncEvent(
          type: 'error',
          message: 'Gagal mengunduh produk: $e',
          syncedCount: 0,
        ),
      );
    }
  }

  /// Download categories from server
  Future<void> _downloadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      final categoriesBox = _hiveService.categoriesBox;

      for (final categoryData in categories) {
        await categoriesBox.put(categoryData['id'].toString(), categoryData);
      }

      print('✅ Synced ${categories.length} categories from server');
    } catch (e) {
      print('❌ Error downloading categories: $e');
    }
  }

  /// Upload pending sales to server
  Future<void> _uploadPendingSales() async {
    try {
      final salesBox = _hiveService.salesBox;
      final pendingSales =
          salesBox.values
              .map((data) {
                // Ensure data is Map<String, dynamic>
                if (data is Map<String, dynamic>) {
                  return SaleModel.fromJson(data);
                } else if (data is Map) {
                  return SaleModel.fromJson(Map<String, dynamic>.from(data));
                } else {
                  print('⚠️ Invalid sale data type: ${data.runtimeType}');
                  return null;
                }
              })
              .where((sale) => sale != null && !sale.isSynced)
              .cast<SaleModel>()
              .toList();

      if (pendingSales.isEmpty) {
        print('📦 No pending sales to upload');
        return;
      }

      print('📤 Uploading ${pendingSales.length} pending sales...');

      int syncedCount = 0;
      int failedCount = 0;

      for (final sale in pendingSales) {
        try {
          // Convert to JSON with proper type
          final saleJson = Map<String, dynamic>.from(sale.toJson());
          final success = await _apiService.syncSale(saleJson);

          if (success) {
            // Mark as synced
            final updatedSale = sale.copyWith(
              isSynced: true,
              syncedAt: DateTime.now(),
            );
            await salesBox.put(sale.id, updatedSale.toJson());
            syncedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          print('❌ Failed to sync sale ${sale.invoiceNumber}: $e');
          failedCount++;
        }
      }

      print('✅ Uploaded $syncedCount sales (Failed: $failedCount)');
    } catch (e) {
      print('❌ Error uploading sales: $e');
    }
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    try {
      final salesBox = _hiveService.salesBox;
      final pendingSales =
          salesBox.values
              .map((data) {
                try {
                  if (data is Map<String, dynamic>) {
                    return SaleModel.fromJson(data);
                  } else if (data is Map) {
                    return SaleModel.fromJson(Map<String, dynamic>.from(data));
                  }
                  return null;
                } catch (e) {
                  print('⚠️ Error parsing sale in getSyncStatus: $e');
                  return null;
                }
              })
              .where((sale) => sale != null && !sale.isSynced)
              .length;

      // Check if user logged in via offline mode
      final authBox = _hiveService.getBox(AppConstants.authBox);
      final isOfflineLogin = authBox.get('is_offline', defaultValue: false);

      // Status online jika: ada network connection DAN user login secara online (bukan offline)
      final isOnline = _isOnline && !isOfflineLogin;

      // DEBUG: Show status calculation
      print('📊 getSyncStatus():');
      print('   _isOnline (network): $_isOnline');
      print('   isOfflineLogin (flag): $isOfflineLogin');
      print('   Result isOnline: $isOnline');

      return {
        'is_online': isOnline,
        'is_syncing': _isSyncing,
        'pending_sales': pendingSales,
        'total_products': _productRepository.getTotalProductsCount(),
        'last_sync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error in getSyncStatus: $e');
      return {
        'is_online': false, // Default to offline on error
        'is_syncing': _isSyncing,
        'pending_sales': 0,
        'total_products': 0,
        'last_sync': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Manual sync trigger
  Future<bool> manualSync() async {
    print('🔄 Manual sync triggered');
    return await syncAll();
  }

  /// Force full sync - download ulang semua produk
  Future<bool> forceFullSync({
    Function(int current, int total)? onProgress,
  }) async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress, skipping...');
      return false;
    }

    _isSyncing = true;
    try {
      print('🔄 Starting FORCE FULL SYNC...');

      // Broadcast: Starting
      _syncEventController.add(
        SyncEvent(
          type: 'progress',
          message: 'Memulai sinkronisasi penuh...',
          syncedCount: 0,
        ),
      );

      // Force full sync
      final count = await _productRepository.syncProductsFromServer(
        force: true,
        onProgress:
            onProgress ??
            (current, total) {
              // Broadcast progress
              _syncEventController.add(
                SyncEvent(
                  type: 'progress',
                  message: 'Mengunduh produk: $current dari $total',
                  syncedCount: current,
                ),
              );
            },
      );

      if (count > 0) {
        print('✅ Force full sync completed: $count products');

        // Broadcast: Success
        _syncEventController.add(
          SyncEvent(
            type: 'success',
            message: '✅ Sinkronisasi penuh selesai: $count produk',
            syncedCount: count,
          ),
        );

        // ✅ NOTIFY UI: Produk sudah di-download, refresh UI!
        _socketService.triggerDataUpdate('product:synced');

        return true;
      } else {
        // Broadcast: No updates
        _syncEventController.add(
          SyncEvent(
            type: 'progress',
            message: 'Tidak ada produk untuk disinkronkan',
            syncedCount: 0,
          ),
        );

        return false;
      }
    } catch (e) {
      print('❌ Force full sync error: $e');

      // Broadcast: Error
      _syncEventController.add(
        SyncEvent(
          type: 'error',
          message: 'Gagal melakukan sinkronisasi: $e',
          syncedCount: 0,
        ),
      );

      return false;
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    stopBackgroundSync();
    _syncEventController.close();
  }
}
