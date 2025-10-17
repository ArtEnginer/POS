import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/bloc/customer_event.dart';
import '../../../customer/presentation/bloc/customer_state.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_bloc.dart';
import '../bloc/sale_event.dart' as sale_event;
import '../bloc/sale_state.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _notesController = TextEditingController();

  final List<_CartItem> _cartItems = [];
  Customer? _selectedCustomer;
  List<Customer> _allCustomers = [];
  String _paymentMethod = 'CASH';
  double _paymentAmount = 0;
  double _taxPercentage = 0;
  double _discountAmount = 0;
  String _saleNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes active again
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

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  double get _tax => _subtotal * (_taxPercentage / 100);

  double get _total => _subtotal + _tax - _discountAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kasir / POS', style: TextStyle(fontSize: 20)),
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
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: _loadInitialData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _cartItems.clear();
                _paymentAmount = 0;
                _discountAmount = 0;
                _taxPercentage = 0;
                _selectedCustomer = null;
                _notesController.clear();
              });
              _generateSaleNumber();
            },
            tooltip: 'Reset Transaksi',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SaleBloc, SaleState>(
            listener: (context, state) {
              if (state is SaleNumberGenerated) {
                setState(() {
                  _saleNumber = state.number;
                });
              } else if (state is SaleOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reset form
                setState(() {
                  _cartItems.clear();
                  _paymentAmount = 0;
                  _discountAmount = 0;
                  _taxPercentage = 0;
                  _selectedCustomer = null;
                  _notesController.clear();
                });
                _generateSaleNumber();
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
              // Auto refresh when product state changes (added/updated)
              if (state is ProductOperationSuccess) {
                // Reload products silently
                context.read<ProductBloc>().add(const LoadProducts());
              }
            },
          ),
          BlocListener<CustomerBloc, CustomerState>(
            listener: (context, state) {
              // Auto refresh when customer state changes (added/updated)
              if (state is CustomerOperationSuccess) {
                // Reload customers silently
                context.read<CustomerBloc>().add(LoadAllCustomers());
              }
            },
          ),
        ],
        child: Row(
          children: [
            // Left Panel - Product Selection
            Expanded(flex: 3, child: _buildProductPanel()),
            // Right Panel - Cart & Payment
            SizedBox(width: 450, child: _buildCartPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              // Barcode Scanner
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: 'Scan atau ketik barcode produk',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchByBarcode,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _searchByBarcode(),
              ),
              const SizedBox(height: 12),
              // Product Search
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
                              context.read<ProductBloc>().add(
                                const LoadProducts(),
                              );
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    context.read<ProductBloc>().add(const LoadProducts());
                  } else {
                    context.read<ProductBloc>().add(SearchProducts(value));
                  }
                },
              ),
            ],
          ),
        ),
        // Product Grid
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ProductError) {
                return Center(child: Text(state.message));
              }

              if (state is ProductLoaded) {
                if (state.products.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada produk ditemukan'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return _buildProductCard(product);
                  },
                );
              }

              return const Center(child: Text('Memuat produk...'));
            },
          ),
        ),
      ],
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
        onTap: isOutOfStock ? null : () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image Placeholder
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: AppColors.primary.withOpacity(0.3),
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(product.sellingPrice),
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${product.stock}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOutOfStock ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'STOK HABIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Cart Header
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
            child: Column(
              children: [
                const Text(
                  'KERANJANG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_cartItems.length} Item',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          // Cart Items
          Expanded(
            child:
                _cartItems.isEmpty
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
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(_cartItems[index], index);
                      },
                    ),
          ),
          // Summary & Payment
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
            child: Column(
              children: [
                // Customer Selector
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, customerState) {
                    if (customerState is CustomerLoaded) {
                      _allCustomers = customerState.customers;
                    }
                    return DropdownButtonFormField<Customer?>(
                      value: _selectedCustomer,
                      decoration: InputDecoration(
                        labelText: 'Pelanggan (Opsional)',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<Customer?>(
                          value: null,
                          child: Text('-- Umum --'),
                        ),
                        ..._allCustomers.map(
                          (customer) => DropdownMenuItem<Customer?>(
                            value: customer,
                            child: Text(customer.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Tax & Discount
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Pajak (%)',
                          prefixIcon: const Icon(Icons.percent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _taxPercentage = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Diskon',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _discountAmount = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Summary
                _buildSummaryRow('Subtotal', currencyFormat.format(_subtotal)),
                if (_tax > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow('Pajak', currencyFormat.format(_tax)),
                ],
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Diskon',
                    '- ${currencyFormat.format(_discountAmount)}',
                  ),
                ],
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'TOTAL',
                  currencyFormat.format(_total),
                  isTotal: true,
                ),
                const Divider(height: 24),
                // Payment Method
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Metode Pembayaran',
                    prefixIcon: const Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
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
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Payment Amount (for CASH only)
                if (_paymentMethod == 'CASH') ...[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Jumlah Bayar',
                      prefixText: 'Rp ',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _paymentAmount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  if (_paymentAmount >= _total) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currencyFormat.format(_paymentAmount - _total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                // Process Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _cartItems.isEmpty ? null : _processTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(_CartItem item, int index) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(item.price),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () {
                      setState(() {
                        if (item.quantity > 1) {
                          item.quantity--;
                        } else {
                          _cartItems.removeAt(index);
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      if (item.quantity < item.maxStock) {
                        setState(() {
                          item.quantity++;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stok tidak mencukupi'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Subtotal & Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.price * item.quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _cartItems.removeAt(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _searchByBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    context.read<ProductBloc>().add(SearchProducts(barcode));
    _barcodeController.clear();
  }

  void _addToCart(Product product) {
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
    });
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

    // For non-cash payment, set payment amount equal to total
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
      cashierId: 'CASHIER001', // TODO: Get from auth
      cashierName: 'Kasir 1', // TODO: Get from auth
      saleDate: now,
      subtotal: _subtotal,
      tax: _tax,
      discount: _discountAmount,
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
                  saleId: saleId, // Use the same saleId
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  price: item.price,
                  discount: 0,
                  subtotal: item.price * item.quantity,
                  createdAt: now,
                ),
              )
              .toList(),
    );

    context.read<SaleBloc>().add(sale_event.CreateSale(sale));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _CartItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;
  final int maxStock;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.maxStock,
  });
}
