import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../supplier/domain/entities/supplier.dart';
import '../../../supplier/presentation/bloc/supplier_bloc.dart';
import '../../../supplier/presentation/bloc/supplier_event.dart';
import '../../../supplier/presentation/bloc/supplier_state.dart';
import '../../../supplier/presentation/pages/supplier_form_page.dart';
import '../../domain/entities/purchase.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';

class PurchaseFormPage extends StatelessWidget {
  final Purchase? purchase;

  const PurchaseFormPage({super.key, this.purchase});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProductBloc>()..add(const LoadProducts()),
        ),
        BlocProvider(
          create:
              (_) =>
                  sl<SupplierBloc>()
                    ..add(const LoadSuppliersEvent(isActive: true)),
        ),
        BlocProvider(create: (_) => sl<PurchaseBloc>()),
      ],
      child: _PurchaseFormView(purchase: purchase),
    );
  }
}

class _PurchaseFormView extends StatefulWidget {
  final Purchase? purchase;

  const _PurchaseFormView({this.purchase});

  @override
  State<_PurchaseFormView> createState() => _PurchaseFormViewState();
}

class _PurchaseFormViewState extends State<_PurchaseFormView> {
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');

  DateTime _purchaseDate = DateTime.now();
  String _paymentMethod = 'cash';
  String _status = 'draft';
  bool _showPrices = true; // Toggle show/hide prices

  String? _selectedSupplierId;
  String? _selectedSupplierName;

  final List<_CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      _loadExistingPurchase();
    }
  }

  void _loadExistingPurchase() {
    final purchase = widget.purchase!;
    _selectedSupplierId = purchase.supplierId;
    _selectedSupplierName = purchase.supplierName;
    _supplierNameController.text = purchase.supplierName ?? '';
    _notesController.text = purchase.notes ?? '';
    _taxController.text = purchase.taxAmount.toString();
    _discountController.text = purchase.discountAmount.toString();
    _purchaseDate = purchase.purchaseDate;
    _paymentMethod = purchase.paymentMethod?.toLowerCase() ?? 'cash';
    _status = purchase.status.toLowerCase();

    // Load existing items
    for (var item in purchase.items) {
      _cartItems.add(
        _CartItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantityOrdered,
          price: item.unitPrice,
        ),
      );
    }
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.quantity * item.price),
    );
  }

  double get _tax => double.tryParse(_taxController.text) ?? 0;
  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _total {
    return _subtotal + _tax - _discount;
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(
          _CartItem(
            productId: product.id,
            productName: product.name,
            quantity: 1,
            price: product.costPrice,
          ),
        );
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, double quantity) {
    if (quantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() {
        _cartItems[index].quantity = quantity;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  void _showProductSelector() {
    final productBloc = context.read<ProductBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => BlocProvider.value(
            value: productBloc,
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return _ProductSelectorSheet(
                  scrollController: scrollController,
                  onProductSelected: (product) {
                    _addToCart(product);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.purchase == null ? 'Pembelian Baru' : 'Edit Pembelian',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _savePurchaseWithStatus('draft'),
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text(
              'Simpan Draft',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<PurchaseBloc, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is PurchaseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              // Left Panel - Form
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSupplierSection(),
                      const SizedBox(height: 16),
                      _buildDatePaymentSection(),
                      const SizedBox(height: 16),
                      _buildCartSection(),
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),

              // Right Panel - Summary
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(left: BorderSide(color: AppColors.divider)),
                ),
                child: _buildSummaryPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Informasi Supplier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<SupplierBloc, SupplierState>(
                    builder: (context, state) {
                      List<Supplier> suppliers = [];
                      if (state is SuppliersLoaded) {
                        suppliers = state.suppliers;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Supplier *',
                          prefixIcon: Icon(Icons.business),
                        ),
                        hint: const Text('-- Pilih Supplier --'),
                        items:
                            suppliers.map((supplier) {
                              return DropdownMenuItem<String>(
                                value: supplier.id,
                                child: Text(supplier.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                            final selected = suppliers.firstWhere(
                              (s) => s.id == value,
                            );
                            _selectedSupplierName = selected.name;
                            _supplierNameController.text = selected.name;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Supplier harus dipilih';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BlocProvider(
                              create: (_) => sl<SupplierBloc>(),
                              child: const SupplierFormPage(),
                            ),
                      ),
                    );

                    if (result == true) {
                      // Reload suppliers
                      context.read<SupplierBloc>().add(
                        const LoadSuppliersEvent(isActive: true),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Baru'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Tanggal & Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pembelian',
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_purchaseDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('💵 Tunai')),
                DropdownMenuItem(value: 'transfer', child: Text('🏦 Transfer')),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text('📝 Kredit/Tempo'),
                ),
                DropdownMenuItem(value: 'card', child: Text('💳 Kartu')),
                DropdownMenuItem(value: 'ewallet', child: Text('📱 E-Wallet')),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Keranjang Belanja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showProductSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cartItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keranjang masih kosong',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cartItems.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return _buildCartItem(item, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(_CartItem item, int index) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name Row
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeFromCart(index),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Price, Quantity, and Subtotal Row
          Row(
            children: [
              // Price Field
              Flexible(
                flex: 2,
                child: TextFormField(
                  initialValue: item.price.toStringAsFixed(0),
                  decoration: InputDecoration(
                    labelText: 'Harga Beli',
                    prefixText: 'Rp ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    final newPrice = double.tryParse(value) ?? item.price;
                    setState(() {
                      item.price = newPrice;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Quantity Control
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed:
                          () => _updateQuantity(index, item.quantity - 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 30),
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed:
                          () => _updateQuantity(index, item.quantity + 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Subtotal
              Flexible(
                flex: 1,
                child: Text(
                  currencyFormat.format(item.quantity * item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Catatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan pembelian (opsional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'RINGKASAN',
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryRow('Subtotal', currencyFormat.format(_subtotal)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxController,
                  decoration: const InputDecoration(
                    labelText: 'Pajak (PPN)',
                    prefixText: 'Rp ',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Diskon',
                    prefixText: 'Rp ',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'TOTAL',
                  currencyFormat.format(_total),
                  isTotal: true,
                ),
                const SizedBox(height: 24),
                // Toggle Show/Hide Prices
                SwitchListTile(
                  title: const Text(
                    'Tampilkan Harga',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Cetak PO dengan harga',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _showPrices,
                  onChanged: (value) {
                    setState(() {
                      _showPrices = value;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status PO',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'draft',
                      child: Text(
                        'Draft',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ordered',
                      child: Text(
                        'Ordered',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text(
                        'Approved',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text(
                        'Partial',
                        style: TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Status Info Box
                if (_status == 'ordered')
                  _buildStatusInfo(
                    'PO sudah dikirim ke supplier. Stok akan bertambah saat proses Receiving.',
                    Colors.blue,
                    Icons.info_outline,
                  ),
                if (_status == 'approved')
                  _buildStatusInfo(
                    'PO sudah disetujui dan siap untuk proses receiving barang.',
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                if (_status == 'partial')
                  _buildStatusInfo(
                    'PO sebagian barang sudah diterima, menunggu sisa barang',
                    Colors.orange,
                    Icons.schedule,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _cartItems.isEmpty
                        ? null
                        : () => _savePurchaseWithStatus(_status),
                icon: const Icon(Icons.check_circle),
                label: const Text('Simpan Pembelian'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 11, color: color)),
          ),
        ],
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

  Future<void> _savePurchaseWithStatus(String status) async {
    if (!_formKey.currentState!.validate()) return;

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 produk ke keranjang'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get user data from AuthService
    final authService = sl<AuthService>();
    final userData = await authService.getUserProfile();
    final branchId = await authService.getCurrentBranchId();

    if (userData == null || branchId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: User session tidak valid. Silakan login ulang.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uuid = const Uuid();
    final now = DateTime.now();
    final purchaseId = widget.purchase?.id ?? uuid.v4();

    // Generate purchase number if new
    String purchaseNumber;
    if (widget.purchase == null) {
      final timestamp = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd').format(timestamp);
      final timeFormat =
          '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';
      purchaseNumber = 'PO-$dateFormat-$timeFormat';
    } else {
      purchaseNumber = widget.purchase!.purchaseNumber;
    }

    final purchase = Purchase(
      id: purchaseId,
      purchaseNumber: purchaseNumber,
      branchId: branchId, // ✅ Get from user session
      createdBy: userData['id'].toString(), // ✅ Get from user session
      supplierId: _selectedSupplierId,
      supplierName: _selectedSupplierName ?? _supplierNameController.text,
      purchaseDate: _purchaseDate,
      subtotal: _subtotal,
      taxAmount: _tax,
      discountAmount: _discount,
      totalAmount: _total,
      paymentMethod: _paymentMethod,
      paidAmount: _total,
      status: status,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: widget.purchase?.createdAt ?? now,
      updatedAt: now,
      items:
          _cartItems
              .map(
                (item) => PurchaseItem(
                  id: uuid.v4(),
                  purchaseId: purchaseId,
                  productId: item.productId,
                  productName: item.productName,
                  sku: '', // TODO: Get from product
                  quantityOrdered: item.quantity,
                  unitPrice: item.price,
                  subtotal: item.quantity * item.price,
                  total: item.quantity * item.price,
                  createdAt: now,
                ),
              )
              .toList(),
    );

    if (widget.purchase == null) {
      context.read<PurchaseBloc>().add(CreatePurchase(purchase));
    } else {
      context.read<PurchaseBloc>().add(UpdatePurchase(purchase));
    }
  }
}

class _CartItem {
  final String productId;
  final String productName;
  double quantity;
  double price;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}

class _ProductSelectorSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Product) onProductSelected;

  const _ProductSelectorSheet({
    required this.scrollController,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                context.read<ProductBloc>().add(const LoadProducts());
              } else {
                context.read<ProductBloc>().add(SearchProducts(value));
              }
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductLoaded) {
                if (state.products.isEmpty) {
                  return const Center(child: Text('Tidak ada produk'));
                }
                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        'Stok: ${product.stock} ${product.unit}\n'
                        'Rp ${NumberFormat('#,###', 'id_ID').format(product.costPrice)}',
                      ),
                      trailing: const Icon(
                        Icons.add_circle,
                        color: AppColors.secondary,
                      ),
                      onTap: () => widget.onProductSelected(product),
                    );
                  },
                );
              } else if (state is ProductError) {
                return Center(child: Text(state.message));
              }
              return const Center(
                child: Text('Pilih produk untuk ditambahkan'),
              );
            },
          ),
        ),
      ],
    );
  }
}
