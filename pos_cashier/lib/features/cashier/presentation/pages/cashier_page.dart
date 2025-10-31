import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/pending_sale_model.dart';
import '../bloc/cashier_bloc.dart';
import '../widgets/pending_sales_dialog.dart';
import '../widgets/print_options_dialog.dart';
import 'sales_history_page.dart'; // Sales History Page
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../main.dart';
import '../../../sync/presentation/widgets/sync_header_notification.dart';
import '../../../sync/presentation/widgets/realtime_sync_indicator.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _customerCodeController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isSearchingCustomer = false;
  StreamSubscription? _socketStatusListener; // Listener untuk WebSocket status
  StreamSubscription? _dataUpdateListener; // Listener untuk product updates

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);

    // Listen to WebSocket status changes for REAL-TIME update (NO TIMER!)
    _socketStatusListener = socketService.serverStatus.listen((isOnline) {
      print(
        '🔔 WebSocket status changed in UI: ${isOnline ? "ONLINE" : "OFFLINE"}',
      );
      // Widget RealtimeSyncIndicator will auto-update via StreamBuilder
    });

    // Listen to product updates via WebSocket - OPTIMIZED!
    // Hanya reload jika event dari SYNC, bukan dari WebSocket real-time update
    _dataUpdateListener = socketService.dataUpdates.listen((eventType) {
      print('🔔 Data update detected: $eventType');

      // WebSocket real-time events (product:created, product:updated, product:deleted)
      // sudah langsung update Hive database oleh SocketService
      // Jadi kita HANYA perlu refresh UI jika produk yang berubah sedang ditampilkan
      if (eventType.startsWith('product:') && !eventType.contains('synced')) {
        // Hanya refresh filtered products dari database lokal
        // TIDAK download dari server karena WebSocket sudah update Hive
        print('   → Refreshing UI from local DB (no download)');
        _refreshProductsFromLocalDB();
      }
      // Untuk sync events (product:synced dari manual sync), reload full
      else if (eventType.contains('synced') || eventType.contains('sync')) {
        print('   → Full reload after manual sync');
        _loadProducts();
      }
      // Category events juga hanya refresh local
      else if (eventType.startsWith('category:')) {
        print('   → Category updated, refreshing UI');
        _refreshProductsFromLocalDB();
      }
    });

    // Hapus SnackBar listener - sekarang menggunakan header notification
    // sync events akan di-handle oleh SyncHeaderNotification widget
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _customerCodeController.dispose();
    _socketStatusListener?.cancel(); // Cancel WebSocket listener
    _dataUpdateListener?.cancel(); // Cancel data update listener
    super.dispose();
  }

  /// Load products from ProductRepository
  void _loadProducts() async {
    try {
      // Get products from local database
      final products = productRepository.getLocalProducts();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });

      // Check if need to sync
      if (productRepository.needsSync()) {
        print('🔄 Products need sync, triggering background sync...');
        syncService.syncAll().then((success) {
          if (success) {
            // Reload products after sync
            _loadProducts();
          }
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  /// Refresh products from LOCAL database only (NO server download)
  /// Digunakan saat WebSocket event untuk update UI tanpa download ulang
  void _refreshProductsFromLocalDB() {
    try {
      print('🔄 Refreshing products from LOCAL database (no download)...');

      // Get products from local database (sudah di-update oleh SocketService)
      final products = productRepository.getLocalProducts();

      setState(() {
        _allProducts = products;
        // Re-apply search filter jika ada
        _filterProducts();
      });

      print('✅ UI refreshed with ${products.length} products from local DB');
    } catch (e) {
      print('❌ Error refreshing products from local DB: $e');
    }
  }

  /// Filter products based on search query
  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts =
            _allProducts.where((product) {
              return product.name.toLowerCase().contains(query) ||
                  product.barcode.contains(query) ||
                  (product.categoryName?.toLowerCase().contains(query) ??
                      false);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.point_of_sale, size: 24),
            const SizedBox(width: 8),
            const Text('POS Kasir'),
            const SizedBox(width: 16),
            // Real-time Sync Indicator - pindah ke title area
            const RealtimeSyncIndicatorCompact(),
          ],
        ),
        actions: [
          // ===== TRANSACTION ACTIONS =====
          // Pending Sales
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.schedule, color: Colors.white),
                if (pendingSalesService.getPendingCount() > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${pendingSalesService.getPendingCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showPendingSales,
            tooltip: 'Transaksi Pending',
          ),

          // Riwayat Penjualan - NEW FEATURE
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showSalesHistory,
            tooltip: 'Riwayat Penjualan',
          ),

          // Visual Divider
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white24,
          ),

          // ===== SETTINGS & CONFIGURATIONS =====
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Pengaturan',
            onSelected: (value) {
              switch (value) {
                case 'cashier_settings':
                  Navigator.pushNamed(context, '/cashier-settings');
                  break;
                case 'sync_settings':
                  Navigator.pushNamed(context, '/sync-settings');
                  break;
                case 'server_settings':
                  Navigator.pushNamed(context, '/server-settings');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'cashier_settings',
                    child: Row(
                      children: [
                        Icon(Icons.store, size: 20),
                        SizedBox(width: 12),
                        Text('Pengaturan Kasir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sync_settings',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 20),
                        SizedBox(width: 12),
                        Text('Pengaturan Sinkronisasi'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'server_settings',
                    child: Row(
                      children: [
                        Icon(Icons.dns, size: 20),
                        SizedBox(width: 12),
                        Text('Pengaturan Server'),
                      ],
                    ),
                  ),
                ],
          ),

          // Visual Divider
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white24,
          ),

          // ===== SYSTEM ACTIONS =====
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sync Header Notification - animated, tidak mengganggu
          SyncHeaderNotification(syncEvents: syncService.syncEvents),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left: Cart & Transaction Details (Main Section) - LEBIH LEBAR
                Expanded(flex: 6, child: _buildCartSection()),

                // Right: Detail Nominal Only - LEBIH KECIL
                Expanded(flex: 2, child: _buildDetailNominalSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Detail Nominal Section - Right Side (tanpa input barcode)
  Widget _buildDetailNominalSection() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue[700],
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Detail Nominal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Icon untuk membuka pencarian customer
                IconButton(
                  icon: Icon(
                    _selectedCustomer != null
                        ? Icons.person
                        : Icons.person_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _showCustomerSearchDialog(),
                  tooltip: 'Pilih Customer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Customer info banner (jika sudah dipilih)
          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(
                  bottom: BorderSide(color: Colors.green[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _selectedCustomer!['code'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null;
                        _customerCodeController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Detail Nominal Content
          Expanded(
            child: BlocBuilder<CashierBloc, CashierState>(
              builder: (context, state) {
                if (state is CashierLoaded) {
                  return Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtotal
                                _buildNominalRow(
                                  'Subtotal',
                                  state.subtotal,
                                  Icons.shopping_basket,
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),

                                // Diskon per item (jika ada)
                                if (state.itemDiscountAmount > 0)
                                  _buildNominalRow(
                                    'Diskon Item',
                                    state.itemDiscountAmount,
                                    Icons.discount,
                                    Colors.red,
                                    isDiscount: true,
                                  ),
                                if (state.itemDiscountAmount > 0)
                                  const SizedBox(height: 12),

                                // PPN per item (jika ada)
                                if (state.itemTaxAmount > 0)
                                  _buildNominalRow(
                                    'PPN Item',
                                    state.itemTaxAmount,
                                    Icons.receipt_long,
                                    Colors.purple,
                                  ),
                                if (state.itemTaxAmount > 0)
                                  const SizedBox(height: 12),

                                // Show Diskon & PPN Global (jika ada)
                                if (state.globalDiscountAmount > 0)
                                  _buildNominalRow(
                                    'Diskon Total',
                                    state.globalDiscountAmount,
                                    Icons.discount,
                                    Colors.red,
                                    isDiscount: true,
                                  ),
                                if (state.globalDiscountAmount > 0)
                                  const SizedBox(height: 12),

                                if (state.globalTaxAmount > 0)
                                  _buildNominalRow(
                                    'PPN Total',
                                    state.globalTaxAmount,
                                    Icons.receipt_long,
                                    Colors.purple,
                                  ),
                                if (state.globalTaxAmount > 0)
                                  const SizedBox(height: 12),

                                const Divider(),
                                const SizedBox(height: 12),

                                // Total Sebelum Pembulatan
                                _buildNominalRow(
                                  'Total',
                                  state.total,
                                  Icons.calculate,
                                  Colors.grey[700]!,
                                ),
                                const SizedBox(height: 12),

                                // Pembulatan (jika ada)
                                if (state.rounding != 0)
                                  _buildNominalRow(
                                    'Pembulatan',
                                    state.rounding,
                                    Icons.trending_flat,
                                    state.rounding > 0
                                        ? Colors.green
                                        : Colors.orange,
                                    isRounding: true,
                                  ),
                                if (state.rounding != 0)
                                  const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // GRAND TOTAL BAYAR - FIXED POSITION
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GRAND TOTAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(
                                        state.grandTotal,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Menu Titik 3 untuk Diskon & PPN
                              PopupMenuButton<String>(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.more_vert,
                                    color: Colors.green[700],
                                  ),
                                ),
                                tooltip: 'Diskon & PPN',
                                onSelected: (value) {
                                  if (value == 'discount') {
                                    _showDiscountDialog(context, state);
                                  } else if (value == 'tax') {
                                    _showTaxDialog(context, state);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'discount',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.percent,
                                              color: Colors.orange[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Diskon Total'),
                                            if (state.globalDiscount > 0) ...[
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${state.globalDiscount.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'tax',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.receipt,
                                              color: Colors.purple[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('PPN Total'),
                                            if (state.globalTax > 0) ...[
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${state.globalTax.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),

                        // Tombol Aksi di bawah - BAYAR + MENU
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Menu Titik 3 untuk BATAL & PENDING
                              PopupMenuButton<String>(
                                icon: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey[700],
                                    size: 28,
                                  ),
                                ),
                                tooltip: 'Opsi Lainnya',
                                enabled: state.cartItems.isNotEmpty,
                                onSelected: (value) {
                                  if (value == 'batal') {
                                    context.read<CashierBloc>().add(
                                      ClearCart(),
                                    );
                                  } else if (value == 'pending') {
                                    _savePending(state);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'batal',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.clear,
                                              color: Colors.red[400],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Batal Transaksi',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'pending',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Colors.orange[400],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Simpan Pending',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                              const SizedBox(width: 12),

                              // Tombol BAYAR - FULL WIDTH
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      state.cartItems.isEmpty
                                          ? null
                                          : () => _showPaymentDialog(
                                            state.grandTotal,
                                          ),
                                  icon: const Icon(Icons.payment, size: 28),
                                  label: const Text(
                                    'BAYAR',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    elevation: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominalRow(
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool isDiscount = false,
    bool isRounding = false,
  }) {
    String prefix = '';
    if (isDiscount) {
      prefix = '-';
    } else if (isRounding && amount != 0) {
      prefix = amount > 0 ? '+' : '';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$prefix${CurrencyFormatter.format(amount.abs())}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                isDiscount
                    ? Colors.red
                    : isRounding && amount > 0
                    ? Colors.green
                    : isRounding && amount < 0
                    ? Colors.orange
                    : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Handle barcode input (scan or manual)
  void _handleBarcodeInput(String barcode) {
    if (barcode.trim().isEmpty) return;

    // Search product by barcode
    final product = productRepository.getProductByBarcode(barcode.trim());

    if (product != null) {
      // Add to cart
      context.read<CashierBloc>().add(AddToCart(product: product));

      // Clear input
      _barcodeController.clear();

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('${product.name} ditambahkan ke keranjang')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Product not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Produk dengan barcode "$barcode" tidak ditemukan'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _barcodeController.clear();
    }
  }

  /// Scan barcode using camera
  Future<void> _scanBarcode() async {
    // TODO: Implement barcode scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur scanner akan segera tersedia'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Search customer by code (ONLINE ONLY)
  Future<void> _searchCustomer(String customerCode) async {
    if (customerCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode customer'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if online
    final isOnline = socketService.isConnected;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pencarian customer memerlukan koneksi internet. Silakan hubungkan ke server terlebih dahulu.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isSearchingCustomer = true;
    });

    try {
      // Search customer via API using apiService from main.dart
      final response = await apiService.getCustomerByCode(customerCode.trim());

      if (response != null) {
        setState(() {
          _selectedCustomer = response;
          _isSearchingCustomer = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Customer ditemukan: ${response['name']}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isSearchingCustomer = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Customer dengan kode "$customerCode" tidak ditemukan',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching customer: $e');
      setState(() {
        _isSearchingCustomer = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Gagal mencari customer: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show customer search dialog
  void _showCustomerSearchDialog() {
    final dialogCustomerCodeController = TextEditingController(
      text: _customerCodeController.text,
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.person_search, size: 24),
                    const SizedBox(width: 12),
                    const Text('Cari Customer'),
                    const Spacer(),

                    // Online/Offline indicator
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masukkan kode customer untuk mencari:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dialogCustomerCodeController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: CUST-001',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _searchCustomer(value.trim());
                            Navigator.pop(dialogContext);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pencarian customer hanya bisa dilakukan saat ONLINE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('BATAL'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isSearchingCustomer
                            ? null
                            : () {
                              final code =
                                  dialogCustomerCodeController.text.trim();
                              if (code.isNotEmpty) {
                                _customerCodeController.text = code;
                                _searchCustomer(code);
                                Navigator.pop(dialogContext);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Masukkan kode customer'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                    icon:
                        _isSearchingCustomer
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.search),
                    label: const Text('CARI'),
                  ),
                ],
              );
            },
          ),
    );
  }

  /// Show product search dialog
  void _showProductSearchDialog() {
    // Reset search
    _searchController.clear();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                child: Container(
                  width: 600,
                  height: 700,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(Icons.search, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Cari Produk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Search field
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Ketik nama produk...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setDialogState(() {
                                        _filterProducts();
                                      });
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            _filterProducts();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Product list
                      Expanded(
                        child:
                            _filteredProducts.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isEmpty
                                            ? 'Ketik untuk mencari produk'
                                            : 'Produk tidak ditemukan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${product.barcode} • Stok: ${product.stock}',
                                      ),
                                      trailing: Text(
                                        CurrencyFormatter.format(product.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      onTap: () {
                                        // Add to cart
                                        context.read<CashierBloc>().add(
                                          AddToCart(product: product),
                                        );

                                        // Close dialog
                                        Navigator.pop(context);

                                        // Clear search
                                        _searchController.clear();
                                        _filterProducts();

                                        // Show feedback
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.name} ditambahkan',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  /// Cart Section - Transaction Details (Left Side)
  Widget _buildCartSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Input Barcode Section - 1 Baris di atas keranjang (SELALU MUNCUL)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 2),
              ),
            ),
            child: Row(
              children: [
                // Barcode Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _barcodeController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Scan atau ketik barcode...',
                      prefixIcon: const Icon(Icons.qr_code, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: _handleBarcodeInput,
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Cari
                ElevatedButton.icon(
                  onPressed: _showProductSearchDialog,
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('CARI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Scan
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: const Text('SCAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cart Content
          Expanded(
            child: BlocConsumer<CashierBloc, CashierState>(
              listener: (context, state) {
                if (state is PaymentSuccess) {
                  _showPaymentSuccessDialog(state);
                } else if (state is CashierError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CashierLoaded) {
                  return _buildCartContent(state);
                } else if (state is PaymentProcessing) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildEmptyCart();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Kosong',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CashierLoaded state) {
    return Column(
      children: [
        // Header - Simple (tanpa tombol)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Keranjang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.cartItems.length} item',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cart items - Table format (compact)
        Expanded(
          child:
              state.cartItems.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Keranjang Kosong',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildCartTable(state.cartItems),
                    ),
                  ),
        ),
      ],
    );
  }

  /// Build cart table - compact format
  Widget _buildCartTable(List<CartItemModel> items) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      columnWidths: const {
        0: FixedColumnWidth(40), // No
        1: FlexColumnWidth(3), // Produk
        2: FixedColumnWidth(120), // Harga (lebih lebar)
        3: FixedColumnWidth(140), // Qty (lebih lebar)
        4: FixedColumnWidth(60), // Disc%
        5: FixedColumnWidth(60), // PPN%
        6: FixedColumnWidth(100), // Total
        7: FixedColumnWidth(40), // Del
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Produk'),
            _buildTableHeader('Harga'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Disc'),
            _buildTableHeader('PPN'),
            _buildTableHeader('Total'),
            _buildTableHeader(''),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildTableRow(item, index + 1);
        }),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(CartItemModel item, double number) {
    // Create controllers for this specific item
    final discountController = TextEditingController(
      text: item.discount > 0 ? item.discount.toStringAsFixed(0) : '',
    );
    final taxController = TextEditingController(
      text: item.taxPercent > 0 ? item.taxPercent.toStringAsFixed(0) : '',
    );

    return TableRow(
      children: [
        // Number
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '$number',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Product name & barcode
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.product.barcode,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Price
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            CurrencyFormatter.format(item.product.price),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Quantity controls
        Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  context.read<CashierBloc>().add(
                    UpdateCartItemQuantity(
                      productId: item.product.id,
                      quantity: item.quantity - 1,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Colors.red),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  context.read<CashierBloc>().add(
                    UpdateCartItemQuantity(
                      productId: item.product.id,
                      quantity: item.quantity + 1,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.green),
                ),
              ),
            ],
          ),
        ),

        // Discount input
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 50,
            child: TextField(
              controller: discountController,
              decoration: const InputDecoration(
                hintText: '0',
                suffix: Text('%', style: TextStyle(fontSize: 10)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final discount = double.tryParse(value) ?? 0;
                context.read<CashierBloc>().add(
                  UpdateCartItemDiscount(
                    productId: item.product.id,
                    discount: discount,
                  ),
                );
              },
            ),
          ),
        ),

        // Tax input (PPN)
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 50,
            child: TextField(
              controller: taxController,
              decoration: const InputDecoration(
                hintText: '0',
                suffix: Text('%', style: TextStyle(fontSize: 10)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 11),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final taxPercent = double.tryParse(value) ?? 0;
                context.read<CashierBloc>().add(
                  UpdateCartItemTax(
                    productId: item.product.id,
                    taxPercent: taxPercent,
                  ),
                );
              },
            ),
          ),
        ),

        // Total
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.discount > 0 || item.taxPercent > 0) ...[
                Text(
                  CurrencyFormatter.format(item.subtotal),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                CurrencyFormatter.format(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        // Delete button
        Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<CashierBloc>().add(
                UpdateCartItemQuantity(productId: item.product.id, quantity: 0),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Save current transaction as pending
  void _savePending(CashierLoaded state) async {
    try {
      // Get current user info
      final authBox = HiveService.instance.authBox;
      final userData = authBox.get('user');
      final userName =
          userData != null && userData is Map
              ? userData['name']?.toString() ?? 'Unknown'
              : 'Unknown';

      // Convert cart items to pending sale items
      final items =
          state.cartItems.map((cartItem) {
            return PendingSaleItem(
              productId: cartItem.product.id.toString(),
              productName: cartItem.product.name,
              sku: cartItem.product.barcode, // Use barcode as SKU
              quantity: cartItem.quantity,
              price: cartItem.product.price,
              subtotal: cartItem.subtotal,
              discount: cartItem.discountAmount,
              notes: cartItem.note,
            );
          }).toList();

      // Save pending sale
      final pendingId = await pendingSalesService.savePending(
        items: items,
        totalAmount: state.subtotal,
        discount: state.totalDiscountAmount,
        tax: state.totalTaxAmount,
        grandTotal: state.total,
        notes: 'Pending - ${DateTime.now().toString().substring(0, 16)}',
        createdBy: userName,
      );

      // Clear cart after saving
      if (mounted) {
        context.read<CashierBloc>().add(ClearCart());

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaksi disimpan sebagai pending (${items.length} item)',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Lihat',
              textColor: Colors.white,
              onPressed: _showPendingSales,
            ),
          ),
        );
      }

      print('✅ Pending sale saved: $pendingId');
    } catch (e) {
      print('❌ Error saving pending sale: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Gagal menyimpan pending: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show pending sales dialog
  void _showPendingSales() {
    showDialog(
      context: context,
      builder:
          (context) => PendingSalesDialog(onLoadPending: _loadPendingToCart),
    );
  }

  /// Show sales history page
  void _showSalesHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesHistoryPage()),
    );
  }

  /// Load pending sale to cart
  void _loadPendingToCart(PendingSaleModel pending) async {
    try {
      // Clear current cart first
      context.read<CashierBloc>().add(ClearCart());

      // Add each item to cart
      for (final item in pending.items) {
        // Find product in local database
        final productData = HiveService.instance.productsBox.get(
          item.productId,
        );

        if (productData != null && productData is Map) {
          final product = ProductModel.fromJson(
            Map<String, dynamic>.from(productData),
          );

          // Add to cart
          context.read<CashierBloc>().add(
            AddToCart(product: product, quantity: item.quantity),
          );
        } else {
          print('⚠️ Product ${item.productId} not found in local DB');
        }
      }

      // Delete pending sale after loading
      await pendingSalesService.deletePending(pending.id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Pending dimuat ke keranjang (${pending.items.length} item)',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh widget to update pending count badge
        setState(() {});
      }

      print('✅ Pending sale loaded to cart: ${pending.id}');
    } catch (e) {
      print('❌ Error loading pending to cart: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Gagal memuat pending: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPaymentDialog(double total) {
    final paidController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Pembayaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${CurrencyFormatter.format(total)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Bayar',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () {
                  final paid = double.tryParse(paidController.text) ?? 0;
                  if (paid >= total) {
                    context.read<CashierBloc>().add(
                      ProcessPayment(
                        paidAmount: paid,
                        paymentMethod: 'cash',
                        customerId: _selectedCustomer?['id']?.toString(),
                        customerName: _selectedCustomer?['name']?.toString(),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jumlah bayar kurang!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('PROSES'),
              ),
            ],
          ),
    );
  }

  void _showPaymentSuccessDialog(PaymentSuccess state) {
    // Reset customer setelah transaksi selesai
    setState(() {
      _selectedCustomer = null;
      _customerCodeController.clear();
    });

    // Ambil settings untuk auto print
    final settings = cashierSettingsService.getSettings();

    // Jika auto print enabled, langsung cetak
    if (settings.autoPrintReceipt) {
      // Auto print di background
      Future.microtask(() {
        PrintOptionsDialog.autoPrintReceipt(
          context: context,
          sale: state.sale,
          format: settings.defaultPrintFormat,
        );
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Pembayaran Berhasil!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info transaksi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice: ${state.sale.invoiceNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text(
                        'Total: ${CurrencyFormatter.format(state.sale.total)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (state.sale.rounding != 0)
                        Text(
                          'Pembulatan: ${state.sale.rounding > 0 ? '+' : ''}${CurrencyFormatter.format(state.sale.rounding)}',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                state.sale.rounding > 0
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ),
                      Text(
                        'Grand Total: ${CurrencyFormatter.format(state.sale.grandTotal)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bayar: ${CurrencyFormatter.format(state.sale.paid)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kembalian: ${CurrencyFormatter.format(state.change)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info auto print
                if (settings.autoPrintReceipt)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.print, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nota sedang dicetak otomatis...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              // Tombol Print Manual (jika user ingin print ulang atau format lain)
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => PrintOptionsDialog(sale: state.sale),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Cetak Ulang'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Show discount dialog
  void _showDiscountDialog(BuildContext context, CashierLoaded state) {
    final discountController = TextEditingController(
      text:
          state.globalDiscount > 0
              ? state.globalDiscount.toStringAsFixed(0)
              : '',
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.percent, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                const Text('Diskon Total'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subtotal: ${CurrencyFormatter.format(state.subtotal)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Diskon (%)',
                    hintText: 'Masukkan persen diskon',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                    suffixIcon: Icon(Icons.percent, color: Colors.orange[700]),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.globalDiscountAmount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Potongan:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '-${CurrencyFormatter.format(state.globalDiscountAmount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Reset discount
                  context.read<CashierBloc>().add(ApplyGlobalDiscount(0));
                  Navigator.pop(dialogContext);
                },
                child: const Text('HAPUS'),
              ),
              ElevatedButton(
                onPressed: () {
                  final discount =
                      double.tryParse(discountController.text) ?? 0;
                  context.read<CashierBloc>().add(
                    ApplyGlobalDiscount(discount),
                  );
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('TERAPKAN'),
              ),
            ],
          ),
    );
  }

  /// Show tax (PPN) dialog
  void _showTaxDialog(BuildContext context, CashierLoaded state) {
    final taxController = TextEditingController(
      text: state.globalTax > 0 ? state.globalTax.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt, color: Colors.purple[700]),
                ),
                const SizedBox(width: 12),
                const Text('PPN Total'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subtotal: ${CurrencyFormatter.format(state.subtotal - state.totalDiscountAmount)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: taxController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'PPN (%)',
                    hintText: 'Masukkan persen PPN',
                    border: const OutlineInputBorder(),
                    suffixText: '%',
                    suffixIcon: Icon(Icons.receipt, color: Colors.purple[700]),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.globalTaxAmount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tambahan PPN:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+${CurrencyFormatter.format(state.globalTaxAmount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Reset tax
                  context.read<CashierBloc>().add(ApplyGlobalTax(0));
                  Navigator.pop(dialogContext);
                },
                child: const Text('HAPUS'),
              ),
              ElevatedButton(
                onPressed: () {
                  final tax = double.tryParse(taxController.text) ?? 0;
                  context.read<CashierBloc>().add(ApplyGlobalTax(tax));
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('TERAPKAN'),
              ),
            ],
          ),
    );
  }

  /// Handle logout with confirmation
  Future<void> _handleLogout() async {
    // Cek apakah ada transaksi yang belum selesai
    final currentState = context.read<CashierBloc>().state;
    bool hasUnfinishedTransaction = false;

    if (currentState is CashierLoaded) {
      hasUnfinishedTransaction = currentState.cartItems.isNotEmpty;
    }

    // Tampilkan dialog konfirmasi
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.orange),
                SizedBox(width: 12),
                Text('Konfirmasi Logout'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasUnfinishedTransaction) ...[
                  const Text(
                    '⚠️ Anda memiliki transaksi yang belum selesai di keranjang!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data keranjang akan hilang jika Anda logout.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Apakah Anda yakin ingin keluar?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Proses logout
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Logout dari auth service
      await authService.logout();
      print('✅ Auth logout successful');

      // Stop background sync
      syncService.stopBackgroundSync();
      print('✅ Background sync stopped');

      // Disconnect WebSocket
      try {
        socketService.disconnect();
        print('✅ Socket disconnected');
      } catch (e) {
        print('⚠️ Socket disconnect error (non-critical): $e');
      }

      // Clear cart if exists
      if (mounted) {
        try {
          context.read<CashierBloc>().add(ClearCart());
          print('✅ Cart cleared');
        } catch (e) {
          print('⚠️ Cart clear error (non-critical): $e');
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false, // Remove all previous routes
        );
        print('✅ Navigated to login page');
      }
    } catch (e) {
      print('❌ Logout error: $e');

      // Close loading if still showing
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Gagal logout: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
