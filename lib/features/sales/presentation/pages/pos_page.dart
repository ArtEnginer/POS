import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/print_settings.dart';
// import connection_status_indicator; // DELETED
// import hybrid_sync_manager; // DELETED
import '../../../../injection_container.dart' as di;
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/bloc/customer_event.dart';
import '../../../customer/presentation/bloc/customer_state.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/pending_sale.dart';
import '../bloc/sale_bloc.dart';
import '../bloc/sale_event.dart' as sale_event;
import '../bloc/sale_state.dart';
import 'printer_settings_page.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> with WidgetsBindingObserver {
  final _barcodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentController = TextEditingController();

  final List<_CartItem> _cartItems = [];
  Customer? _selectedCustomer;
  List<Customer> _allCustomers = [];
  List<Product> _allProducts = [];
  String _paymentMethod = 'CASH';
  double _paymentAmount = 0;
  double _globalTaxPercentage = 0;
  double _globalDiscountAmount = 0;
  String _saleNumber = '';
  String? _pendingCustomerId; // Store customer ID to auto-select after creation
  bool _isLoadingPending =
      false; // Flag to indicate loading pending transaction

  // Hybrid Sync Manager REMOVED - Backend V2 handles connection status
  // late final HybridSyncManager _hybridSyncManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    // Auto-load pending transaction jika ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleBloc>().add(sale_event.LoadPendingSales());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<CustomerBloc>().add(LoadAllCustomers());
    _generateSaleNumber();
  }

  void _generateSaleNumber() {
    context.read<SaleBloc>().add(const sale_event.GenerateSaleNumber());
  }

  // Calculations
  double get _subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _itemDiscountTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.discountAmount);

  double get _itemTaxTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get _globalTax => _subtotal * (_globalTaxPercentage / 100);

  double get _total =>
      _subtotal +
      _itemTaxTotal +
      _globalTax -
      _itemDiscountTotal -
      _globalDiscountAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Point of Sale', style: TextStyle(fontSize: 20)),
            if (_saleNumber.isNotEmpty)
              Text(
                _saleNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Status Koneksi Online/Offline - REMOVED, Backend V2 handles connection
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          //   child: StreamConnectionStatusIndicator(
          //     syncManager: _hybridSyncManager,
          //     showLabel: true,
          //     iconSize: 20,
          //     fontSize: 11,
          //   ),
          // ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _openPrinterSettings,
            tooltip: 'Pengaturan Printer',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _showLoadPendingDialog,
            tooltip: 'Buka Transaksi Pending',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _cartItems.isEmpty ? null : _savePendingTransaction,
            tooltip: 'Simpan sebagai Pending',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTransaction,
            tooltip: 'Reset Transaksi',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SaleBloc, SaleState>(
            listener: (context, state) async {
              if (state is SaleNumberGenerated) {
                setState(() => _saleNumber = state.number);
              } else if (state is SaleOperationSuccess) {
                // Check auto print setting
                final autoPrint = await PrintSettings.getAutoPrint();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                    action:
                        autoPrint
                            ? null
                            : SnackBarAction(
                              label: 'CETAK',
                              textColor: Colors.white,
                              onPressed: () => _printReceipt(),
                            ),
                  ),
                );

                if (autoPrint) {
                  _printReceipt();
                }

                _resetTransaction();
              } else if (state is PendingSaleOperationSuccess) {
                // Check if we're in the process of loading a pending transaction
                if (_isLoadingPending) {
                  // This is delete after load, ignore it
                  _isLoadingPending = false;
                } else {
                  // This is normal pending operation (save or explicit delete)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  // Only reset if it's from save pending operation
                  if (state.message.contains('disimpan')) {
                    _resetTransaction();
                  }
                }
              } else if (state is PendingSalesLoaded) {
                // Auto-load last pending sale if available
                if (state.pendingSales.isNotEmpty) {
                  _loadPendingTransactionToCart(state.pendingSales.last);
                }
              } else if (state is PendingSaleLoaded) {
                _loadPendingTransactionToCart(state.pendingSale);
              } else if (state is SaleError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state is ProductLoaded) {
                setState(() => _allProducts = state.products);
              } else if (state is ProductOperationSuccess) {
                context.read<ProductBloc>().add(const LoadProducts());
              }
            },
          ),
          BlocListener<CustomerBloc, CustomerState>(
            listener: (context, state) {
              if (state is CustomerLoaded) {
                setState(() {
                  // Remove duplicates by creating a map with id as key
                  final uniqueCustomersMap = <String, Customer>{};
                  for (final customer in state.customers) {
                    uniqueCustomersMap[customer.id] = customer;
                  }
                  _allCustomers = uniqueCustomersMap.values.toList();

                  // Auto-select pending customer if exists
                  if (_pendingCustomerId != null) {
                    _selectedCustomer = uniqueCustomersMap[_pendingCustomerId];
                    _pendingCustomerId = null; // Clear after use
                  }
                  // Otherwise, update selected customer to use the instance from the loaded list
                  else if (_selectedCustomer != null) {
                    _selectedCustomer =
                        uniqueCustomersMap[_selectedCustomer!.id];
                  }
                });
              } else if (state is CustomerOperationSuccess) {
                context.read<CustomerBloc>().add(LoadAllCustomers());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
        child: Row(
          children: [
            // LEFT PANEL - Shopping Cart
            Expanded(flex: 3, child: _buildCartPanel()),
            // RIGHT PANEL - Transaction Details
            Container(
              width: 450,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: _buildTransactionPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Cart Header with Barcode Scanner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_cartItems.length} item',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Add Product Button
                  ElevatedButton.icon(
                    onPressed: _showProductSelectionDialog,
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text('Pilih Produk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Barcode Scanner
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: 'Scan atau ketik barcode produk...',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchByBarcode,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onSubmitted: (_) => _searchByBarcode(),
              ),
            ],
          ),
        ),
        // Cart Items List
        Expanded(
          child:
              _cartItems.isEmpty
                  ? Center(
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan barcode atau pilih produk\nuntuk menambahkan ke keranjang',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : _buildCartTable(),
        ),
        // Cart Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartTable() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header Table
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                // No
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                // Produk
                Expanded(
                  flex: 3,
                  child: Text(
                    'Produk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                // Harga
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Harga',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                // Qty
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Diskon
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Diskon %',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Pajak
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Pajak %',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Subtotal
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Subtotal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                // Aksi
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Aksi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // List Items
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // No
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Produk Name
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Harga
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Text(
                          currencyFormat.format(item.price),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),

                      // Quantity
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => _decreaseQuantity(index),
                                icon: const Icon(Icons.remove, size: 16),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _increaseQuantity(index),
                                icon: const Icon(Icons.add, size: 16),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Diskon
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              item.discountPercentage =
                                  double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),

                      // Pajak
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              item.taxPercentage = double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),

                      // Subtotal
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(
                                item.subtotalWithTaxDiscount,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            if (item.discountAmount > 0 || item.taxAmount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${item.discountAmount > 0 ? '-${currencyFormat.format(item.discountAmount)}' : ''}${item.taxAmount > 0 ? ' +${currencyFormat.format(item.taxAmount)}' : ''}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Aksi
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: IconButton(
                          onPressed: () => _removeFromCart(index),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionPanel() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Transaction Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Detail Transaksi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Transaction Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
                const Text(
                  'Pelanggan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, customerState) {
                    return Card(
                      elevation: 1,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String?>(
                            value: _selectedCustomer?.id,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('-- Pelanggan Umum --'),
                              ),
                              ..._allCustomers.map(
                                (customer) => DropdownMenuItem<String?>(
                                  value: customer.id,
                                  child: Text(customer.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCustomer =
                                    value == null
                                        ? null
                                        : _allCustomers.firstWhere(
                                          (c) => c.id == value,
                                        );
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton.icon(
                              onPressed: _showAddCustomerDialog,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Tambah Pelanggan Baru'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Global Discount & Tax
                const Text(
                  'Diskon & Pajak Global',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Pajak Global (%)',
                          prefixIcon: const Icon(Icons.percent, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _globalTaxPercentage = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Diskon (Rp)',
                          prefixIcon: const Icon(Icons.discount, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _globalDiscountAmount = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total Summary
                const Text(
                  'Ringkasan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Subtotal',
                          currencyFormat.format(_subtotal),
                        ),
                        if (_itemDiscountTotal > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Diskon Item',
                            '- ${currencyFormat.format(_itemDiscountTotal)}',
                            color: Colors.red,
                          ),
                        ],
                        if (_itemTaxTotal > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Pajak Item',
                            currencyFormat.format(_itemTaxTotal),
                          ),
                        ],
                        if (_globalTax > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Pajak Global',
                            currencyFormat.format(_globalTax),
                          ),
                        ],
                        if (_globalDiscountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Diskon Global',
                            '- ${currencyFormat.format(_globalDiscountAmount)}',
                            color: Colors.red,
                          ),
                        ],
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'TOTAL',
                          currencyFormat.format(_total),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Payment Method
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Tunai')),
                    DropdownMenuItem(
                      value: 'CARD',
                      child: Text('Kartu Debit/Kredit'),
                    ),
                    DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                    DropdownMenuItem(
                      value: 'E_WALLET',
                      child: Text('E-Wallet'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _paymentMethod = value!);
                  },
                ),
                const SizedBox(height: 16),
                // Payment Amount (for CASH)
                if (_paymentMethod == 'CASH') ...[
                  TextField(
                    controller: _paymentController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Bayar',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _paymentAmount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  if (_paymentAmount >= _total) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            currencyFormat.format(_paymentAmount - _total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                // Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        // Process Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _cartItems.isEmpty ? null : _processTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'PROSES TRANSAKSI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? Colors.black : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: color ?? (isTotal ? AppColors.primary : Colors.black),
          ),
        ),
      ],
    );
  }

  // Actions
  void _openPrinterSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrinterSettingsPage()),
    );
  }

  Future<void> _printReceipt() async {
    final defaultPrinter = await PrintSettings.getDefaultPrinter();
    final printCopies = await PrintSettings.getPrintCopies();

    if (defaultPrinter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Printer belum dikonfigurasi. Silakan atur di menu pengaturan.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // TODO: Implementasi cetak struk
    // Contoh: menggunakan package seperti printing, pdf, atau esc_pos_printer
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mencetak $printCopies struk ke $defaultPrinter...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _resetTransaction() {
    setState(() {
      _cartItems.clear();
      _paymentAmount = 0;
      _globalDiscountAmount = 0;
      _globalTaxPercentage = 0;
      _selectedCustomer = null;
      _notesController.clear();
      _barcodeController.clear();
      _paymentController.clear();
    });
    _generateSaleNumber();
  }

  void _searchByBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final product = _allProducts.firstWhere(
      (p) => p.barcode == barcode,
      orElse:
          () => _allProducts.firstWhere(
            (p) => p.plu == barcode,
            orElse: () => throw Exception('Produk tidak ditemukan'),
          ),
    );

    _addToCart(product);
    _barcodeController.clear();
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok produk habis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.productId == product.id,
      );
      if (existingIndex != -1) {
        if (_cartItems[existingIndex].quantity < product.stock) {
          _cartItems[existingIndex].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok tidak mencukupi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _cartItems.add(
          _CartItem(
            productId: product.id,
            productName: product.name,
            price: product.sellingPrice,
            quantity: 1,
            maxStock: product.stock,
          ),
        );
      }
      _onCartChanged();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _onCartChanged();
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      if (_cartItems[index].quantity < _cartItems[index].maxStock) {
        _cartItems[index].quantity++;
        _onCartChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok tidak mencukupi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
        _onCartChanged();
      } else {
        _removeFromCart(index);
      }
    });
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ProductSelectionDialog(
          products: _allProducts,
          onProductSelected: (product) {
            _addToCart(product);
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_add, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Tambah Pelanggan Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pelanggan *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'No. Telepon',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama pelanggan harus diisi'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final customer = Customer(
                          id: const Uuid().v4(),
                          name: nameController.text.trim(),
                          phone:
                              phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                          email:
                              emailController.text.trim().isEmpty
                                  ? null
                                  : emailController.text.trim(),
                          address:
                              addressController.text.trim().isEmpty
                                  ? null
                                  : addressController.text.trim(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        context.read<CustomerBloc>().add(
                          CreateCustomerEvent(customer),
                        );
                        Navigator.of(dialogContext).pop();

                        // Store the customer ID to auto-select after reload
                        _pendingCustomerId = customer.id;
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processTransaction() {
    // Validation
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_paymentMethod == 'CASH' && _paymentAmount < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah bayar kurang dari total'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final actualPaymentAmount =
        _paymentMethod == 'CASH' ? _paymentAmount : _total;
    final changeAmount =
        _paymentMethod == 'CASH' ? (_paymentAmount - _total) : 0;

    final uuid = const Uuid();
    final now = DateTime.now();
    final saleId = uuid.v4();

    final sale = Sale(
      id: saleId,
      saleNumber: _saleNumber,
      customerId: _selectedCustomer?.id,
      cashierId: 'CASHIER001',
      cashierName: 'Kasir 1',
      saleDate: now,
      subtotal: _subtotal,
      tax: _itemTaxTotal + _globalTax,
      discount: _itemDiscountTotal + _globalDiscountAmount,
      total: _total,
      paymentMethod: _paymentMethod,
      paymentAmount: actualPaymentAmount,
      changeAmount: changeAmount.toDouble(),
      status: 'COMPLETED',
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
      items:
          _cartItems
              .map(
                (item) => SaleItem(
                  id: uuid.v4(),
                  saleId: saleId,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  price: item.price,
                  discount: item.discountAmount,
                  subtotal: item.subtotalWithTaxDiscount,
                  createdAt: now,
                ),
              )
              .toList(),
    );

    context.read<SaleBloc>().add(sale_event.CreateSale(sale));
  }

  // Pending Transaction Methods
  void _savePendingTransaction() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final notesController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.save, color: Colors.orange),
              SizedBox(width: 12),
              Text('Simpan sebagai Pending'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Transaksi akan disimpan dan bisa dilanjutkan nanti.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _savePending(notesController.text.trim());
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        );
      },
    );
  }

  void _savePending(String notes) {
    final items =
        _cartItems
            .map(
              (item) => {
                'id': const Uuid().v4(),
                'productId': item.productId,
                'productName': item.productName,
                'quantity': item.quantity,
                'price': item.price,
                'discount': item.discountAmount,
                'subtotal': item.subtotalWithTaxDiscount,
              },
            )
            .toList();

    // Generate pending number
    context.read<SaleBloc>().add(const sale_event.GeneratePendingNumber());

    // Listen for the generated number
    final subscription = context.read<SaleBloc>().stream.listen((state) {
      if (state is PendingNumberGenerated) {
        context.read<SaleBloc>().add(
          sale_event.SavePendingSale(
            pendingNumber: state.number,
            customerId: _selectedCustomer?.id,
            customerName: _selectedCustomer?.name,
            savedBy: 'CASHIER001',
            notes: notes.isEmpty ? null : notes,
            items: items,
            subtotal: _subtotal,
            tax: _itemTaxTotal + _globalTax,
            discount: _itemDiscountTotal + _globalDiscountAmount,
            total: _total,
          ),
        );
      }
    });

    // Cancel subscription after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      subscription.cancel();
    });
  }

  void _showLoadPendingDialog() {
    final saleBloc = context.read<SaleBloc>();
    saleBloc.add(const sale_event.LoadPendingSales());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocBuilder<SaleBloc, SaleState>(
          bloc: saleBloc,
          builder: (context, state) {
            if (state is SaleLoading) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is PendingSalesLoaded) {
              final pendingSales = state.pendingSales;

              if (pendingSales.isEmpty) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Text('Tidak ada transaksi pending'),
                    ],
                  ),
                  content: const Text(
                    'Belum ada transaksi yang disimpan sebagai pending.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 600,
                  height: 600,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Transaksi Pending',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pendingSales.length,
                          itemBuilder: (context, index) {
                            final pending = pendingSales[index];
                            final currencyFormat = NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  pending.pendingNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (pending.customerName != null)
                                      Text(
                                        'Pelanggan: ${pending.customerName}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    Text(
                                      '${pending.items.length} item - ${currencyFormat.format(pending.total)}',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy HH:mm',
                                      ).format(pending.savedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (pending.notes != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Catatan: ${pending.notes}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.folder_open,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        saleBloc.add(
                                          sale_event.LoadPendingSaleById(
                                            pending.id,
                                          ),
                                        );
                                      },
                                      tooltip: 'Buka',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _confirmDeletePending(
                                          dialogContext,
                                          pending.id,
                                          pending.pendingNumber,
                                        );
                                      },
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              content: const Text('Terjadi kesalahan'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePending(
    BuildContext dialogContext,
    String pendingId,
    String pendingNumber,
  ) {
    final saleBloc = context.read<SaleBloc>();

    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 12),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus transaksi pending\n$pendingNumber?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(confirmContext).pop();
                Navigator.of(dialogContext).pop();
                saleBloc.add(sale_event.DeletePendingSale(pendingId));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _loadPendingTransactionToCart(PendingSale pendingSale) {
    setState(() {
      _cartItems.clear();
      for (final item in pendingSale.items) {
        _cartItems.add(
          _CartItem(
            productId: item.productId,
            productName: item.productName,
            price: item.price,
            quantity: item.quantity,
            maxStock: 9999, // Atur sesuai kebutuhan
          ),
        );
      }
      _selectedCustomer =
          pendingSale.customerId != null
              ? _allCustomers.firstWhere(
                (c) => c.id == pendingSale.customerId,
                orElse: () => _selectedCustomer ?? _allCustomers.first,
              )
              : null;
    });
  }

  void _onCartChanged() {
    // Simpan otomatis ke pending setiap ada perubahan keranjang
    if (_cartItems.isNotEmpty) {
      _savePendingTransaction();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeController.dispose();
    _notesController.dispose();
    _paymentController.dispose();
    super.dispose();
  }
}

// Cart Item Model
class _CartItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;
  final int maxStock;
  double discountPercentage = 0;
  double taxPercentage = 0;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.maxStock,
  });

  double get subtotal => price * quantity;
  double get discountAmount => subtotal * (discountPercentage / 100);
  double get taxAmount => subtotal * (taxPercentage / 100);
  double get subtotalWithTaxDiscount => subtotal + taxAmount - discountAmount;
}

// Product Selection Dialog Widget
class _ProductSelectionDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductSelected;

  const _ProductSelectionDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  List<Product> _filteredProducts = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts =
            widget.products
                .where(
                  (product) =>
                      product.name.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      product.barcode.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      product.plu.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.search, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Produk',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),
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
                              'Tidak ada produk ditemukan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isOutOfStock ? null : () => widget.onProductSelected(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    currencyFormat.format(product.sellingPrice),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.grey,
                      fontSize: 12,
                      fontWeight:
                          isOutOfStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'STOK HABIS',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
