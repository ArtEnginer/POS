import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../bloc/cashier_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../main.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoadingProducts = false;
  Map<String, dynamic>? _syncStatus; // Status sync untuk header
  StreamSubscription? _socketStatusListener; // Listener untuk WebSocket status
  StreamSubscription? _syncEventListener; // Listener untuk sync events

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _updateSyncStatus(); // Load initial status
    _searchController.addListener(_filterProducts);

    // Listen to WebSocket status changes for REAL-TIME update (NO TIMER!)
    _socketStatusListener = socketService.serverStatus.listen((isOnline) {
      print(
        '🔔 WebSocket status changed in UI: ${isOnline ? "ONLINE" : "OFFLINE"}',
      );
      _updateSyncStatus(); // Instant update via Stream - NO DELAY!
    });

    // Listen to sync events untuk tampilkan notification
    _syncEventListener = syncService.syncEvents.listen((event) {
      print('📢 Sync Event: ${event.type} - ${event.message}');

      if (!mounted) return;

      // Tampilkan SnackBar notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                event.type == 'success' ? Icons.check_circle : Icons.sync,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(event.message)),
            ],
          ),
          backgroundColor: event.type == 'success' ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update status setelah sync
      _updateSyncStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _socketStatusListener?.cancel(); // Cancel WebSocket listener
    _syncEventListener?.cancel(); // Cancel sync event listener
    super.dispose();
  }

  /// Load products from ProductRepository
  void _loadProducts() async {
    setState(() => _isLoadingProducts = true);

    try {
      // Get products from local database
      final products = productRepository.getLocalProducts();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoadingProducts = false;
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
      setState(() => _isLoadingProducts = false);
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

  /// Update sync status untuk header indicator
  void _updateSyncStatus() {
    setState(() {
      _syncStatus = syncService.getSyncStatus();
    });
  }

  /// Manual refresh products
  Future<void> _refreshProducts() async {
    print('🔄 Manual refresh triggered');
    await syncService.syncAll();
    _loadProducts();
    _updateSyncStatus(); // Update status setelah refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POS Kasir'),
            Text(
              '${_allProducts.length} Produk',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Data',
          ),
          // Sync status indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Builder(
                builder: (context) {
                  final status = _syncStatus ?? syncService.getSyncStatus();
                  final isOnline = status['is_online'] ?? false;
                  final pendingSales = status['pending_sales'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.cloud_done : Icons.cloud_off,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (pendingSales > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pendingSales',
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              syncService.stopBackgroundSync();

              // Disconnect WebSocket if available
              try {
                socketService.disconnect();
              } catch (e) {
                print('⚠️ Socket service not available during logout: $e');
              }

              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            tooltip: 'Logout',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (value) {
              if (value == 'server_settings') {
                Navigator.pushNamed(context, '/server-settings');
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'server_settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 8),
                        Text('Server Settings'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Product List & Search
          Expanded(flex: 3, child: _buildProductSection()),

          // Right: Cart & Checkout
          Expanded(flex: 2, child: _buildCartSection()),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Search & Barcode Scanner
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Scan barcode
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('SCAN'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Grid (Real data from API)
          Expanded(
            child:
                _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
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
                            _allProducts.isEmpty
                                ? 'Belum ada produk.\nKlik refresh untuk sync dari server.'
                                : 'Produk tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_allProducts.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshProducts,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Data'),
                            ),
                          ],
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_filteredProducts[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      child: InkWell(
        onTap: () {
          context.read<CashierBloc>().add(AddToCart(product: product));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.shopping_bag, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Stok: ${product.stock}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Container(
      color: Colors.white,
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
        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.cartItems.length,
            itemBuilder: (context, index) {
              final item = state.cartItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(item.product.price),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                            onPressed: () {
                              context.read<CashierBloc>().add(
                                UpdateCartItemQuantity(
                                  productId: item.product.id,
                                  quantity: item.quantity - 1,
                                ),
                              );
                            },
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
                            onPressed: () {
                              context.read<CashierBloc>().add(
                                UpdateCartItemQuantity(
                                  productId: item.product.id,
                                  quantity: item.quantity + 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      // Subtotal
                      SizedBox(
                        width: 100,
                        child: Text(
                          CurrencyFormatter.format(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Summary and checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Subtotal', state.subtotal),
              _buildSummaryRow('Diskon', -state.discountAmount),
              const Divider(height: 24),
              _buildSummaryRow('TOTAL', state.total, isTotal: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<CashierBloc>().add(ClearCart());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('BATAL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(state.total),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'BAYAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 24 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
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
                      ProcessPayment(paidAmount: paid, paymentMethod: 'cash'),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Pembayaran Berhasil!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice: ${state.sale.invoiceNumber}'),
                const SizedBox(height: 8),
                Text(
                  'Total: ${CurrencyFormatter.format(state.sale.total)}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Bayar: ${CurrencyFormatter.format(state.sale.paid)}',
                  style: const TextStyle(fontSize: 18),
                ),
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
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
