import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart' as product_event;
import '../../../product/presentation/bloc/product_state.dart';
import '../../domain/entities/purchase.dart';
import '../../../receiving/domain/entities/receiving.dart';
import '../../../receiving/presentation/bloc/receiving_bloc.dart';
import '../../../receiving/presentation/bloc/receiving_event.dart'
    as receiving_event;
import '../../../receiving/presentation/bloc/receiving_state.dart';

class ReceivingFormPageNew extends StatefulWidget {
  final Purchase purchase;
  final Receiving? existingReceiving;

  const ReceivingFormPageNew({
    Key? key,
    required this.purchase,
    this.existingReceiving,
  }) : super(key: key);

  @override
  State<ReceivingFormPageNew> createState() => _ReceivingFormPageNewState();
}

class _ReceivingFormPageNewState extends State<ReceivingFormPageNew>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<_ReceivingItem> _receivingItems = [];

  // Controllers
  late TabController _tabController;
  final _invoiceNumberController = TextEditingController();
  final _deliveryOrderController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalDiscountController = TextEditingController();
  final _totalTaxController = TextEditingController();

  String? _receivingNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.existingReceiving != null) {
      _initializeFromReceiving();
    } else {
      _initializeItems();
    }

    if (widget.existingReceiving != null) {
      _receivingNumber = widget.existingReceiving!.receivingNumber;
      _invoiceNumberController.text =
          widget.existingReceiving!.invoiceNumber ?? '';
      _deliveryOrderController.text =
          widget.existingReceiving!.deliveryOrderNumber ?? '';
      _vehicleNumberController.text =
          widget.existingReceiving!.vehicleNumber ?? '';
      _driverNameController.text = widget.existingReceiving!.driverName ?? '';
      _notesController.text = widget.existingReceiving!.notes ?? '';
      _totalDiscountController.text = widget.existingReceiving!.totalDiscount
          .toStringAsFixed(0);
      _totalTaxController.text = widget.existingReceiving!.totalTax
          .toStringAsFixed(0);
    } else {
      _totalDiscountController.text = '0';
      _totalTaxController.text = '0';
      context.read<ReceivingBloc>().add(
        const receiving_event.GenerateReceivingNumberEvent(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceNumberController.dispose();
    _deliveryOrderController.dispose();
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _notesController.dispose();
    _totalDiscountController.dispose();
    _totalTaxController.dispose();
    super.dispose();
  }

  void _initializeItems() {
    _receivingItems.clear();
    for (var item in widget.purchase.items) {
      _receivingItems.add(
        _ReceivingItem(
          purchaseItem: item,
          receivedQuantity: item.quantityOrdered.toDouble(),
          receivedPrice: item.unitPrice,
          discount: 0,
          discountType: 'amount',
          tax: 0,
          taxType: 'amount',
          isAdditionalItem: false,
        ),
      );
    }
  }

  void _initializeFromReceiving() {
    _receivingItems.clear();
    final receiving = widget.existingReceiving!;

    for (var receivingItem in receiving.items) {
      final isAdditional = receivingItem.poQuantity == 0;

      PurchaseItem purchaseItem;
      if (isAdditional) {
        purchaseItem = PurchaseItem(
          id: receivingItem.purchaseItemId ?? const Uuid().v4(),
          purchaseId: widget.purchase.id,
          productId: receivingItem.productId,
          productName: receivingItem.productName,
          sku: '',
          quantityOrdered: 0,
          unitPrice: receivingItem.receivedPrice,
          subtotal: 0,
          total: 0,
          createdAt: DateTime.now(),
        );
      } else {
        PurchaseItem? foundItem;
        for (var poItem in widget.purchase.items) {
          if (poItem.id == receivingItem.purchaseItemId) {
            foundItem = poItem;
            break;
          }
        }

        purchaseItem =
            foundItem ??
            PurchaseItem(
              id: receivingItem.purchaseItemId ?? const Uuid().v4(),
              purchaseId: widget.purchase.id,
              productId: receivingItem.productId,
              productName: receivingItem.productName,
              sku: '',
              quantityOrdered: receivingItem.poQuantity.toInt(),
              unitPrice: receivingItem.poPrice,
              subtotal: 0,
              total: 0,
              createdAt: DateTime.now(),
            );
      }

      _receivingItems.add(
        _ReceivingItem(
          purchaseItem: purchaseItem,
          receivedQuantity: receivingItem.receivedQuantity,
          receivedPrice: receivingItem.receivedPrice,
          discount: receivingItem.discount,
          discountType: receivingItem.discountType,
          tax: receivingItem.tax,
          taxType: receivingItem.taxType,
          isAdditionalItem: isAdditional,
        ),
      );
    }
  }

  // Calculation methods
  double _calculateItemSubtotal(_ReceivingItem item) {
    return item.receivedQuantity * item.receivedPrice;
  }

  double _calculateItemDiscount(_ReceivingItem item) {
    final subtotal = _calculateItemSubtotal(item);
    if (item.discountType == 'percentage') {
      return subtotal * (item.discount / 100);
    }
    return item.discount;
  }

  double _calculateItemTax(_ReceivingItem item) {
    final subtotal = _calculateItemSubtotal(item);
    final afterDiscount = subtotal - _calculateItemDiscount(item);
    if (item.taxType == 'percentage') {
      return afterDiscount * (item.tax / 100);
    }
    return item.tax;
  }

  double _calculateItemTotal(_ReceivingItem item) {
    final subtotal = _calculateItemSubtotal(item);
    final discount = _calculateItemDiscount(item);
    final tax = _calculateItemTax(item);
    return subtotal - discount + tax;
  }

  double _calculateSubtotal() {
    return _receivingItems.fold(
      0,
      (sum, item) => sum + _calculateItemSubtotal(item),
    );
  }

  double _calculateItemDiscountTotal() {
    return _receivingItems.fold(
      0,
      (sum, item) => sum + _calculateItemDiscount(item),
    );
  }

  double _calculateItemTaxTotal() {
    return _receivingItems.fold(
      0,
      (sum, item) => sum + _calculateItemTax(item),
    );
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final itemDiscount = _calculateItemDiscountTotal();
    final itemTax = _calculateItemTaxTotal();
    final totalDiscount = double.tryParse(_totalDiscountController.text) ?? 0;
    final totalTax = double.tryParse(_totalTaxController.text) ?? 0;
    return subtotal - itemDiscount + itemTax - totalDiscount + totalTax;
  }

  Future<void> _showAddItemDialog() async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider<ProductBloc>(
                create:
                    (context) =>
                        sl<ProductBloc>()
                          ..add(const product_event.LoadProducts()),
              ),
            ],
            child: _AddItemDialog(
              onItemAdded: (product, quantity, price) {
                setState(() {
                  final dummyPurchaseItem = PurchaseItem(
                    id: const Uuid().v4(),
                    purchaseId: widget.purchase.id,
                    productId: product.id,
                    productName: product.name,
                    sku: product.sku,
                    quantityOrdered: 0,
                    unitPrice: price,
                    subtotal: 0,
                    total: 0,
                    createdAt: DateTime.now(),
                  );

                  _receivingItems.add(
                    _ReceivingItem(
                      purchaseItem: dummyPurchaseItem,
                      receivedQuantity: quantity,
                      receivedPrice: price,
                      discount: 0,
                      discountType: 'amount',
                      tax: 0,
                      taxType: 'amount',
                      isAdditionalItem: true,
                    ),
                  );
                });
              },
            ),
          ),
    );
  }

  Future<void> _processReceiving() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_receivingNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receiving number belum tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final receivingId = widget.existingReceiving?.id ?? const Uuid().v4();

    final receivingItems =
        _receivingItems.map((item) {
          return ReceivingItem(
            id: const Uuid().v4(),
            receivingId: receivingId,
            purchaseItemId: item.purchaseItem.id,
            productId: item.purchaseItem.productId,
            productName: item.purchaseItem.productName,
            poQuantity: item.purchaseItem.quantityOrdered.toDouble(),
            poPrice: item.purchaseItem.unitPrice,
            receivedQuantity: item.receivedQuantity,
            receivedPrice: item.receivedPrice,
            discount: item.discount,
            discountType: item.discountType,
            tax: item.tax,
            taxType: item.taxType,
            subtotal: _calculateItemSubtotal(item),
            total: _calculateItemTotal(item),
            notes: null,
            createdAt: widget.existingReceiving?.createdAt ?? DateTime.now(),
          );
        }).toList();

    final receiving = Receiving(
      id: receivingId,
      receivingNumber: _receivingNumber!,
      purchaseId: widget.purchase.id,
      purchaseNumber: widget.purchase.purchaseNumber,
      supplierId: widget.purchase.supplierId,
      supplierName: widget.purchase.supplierName,
      receivingDate: widget.existingReceiving?.receivingDate ?? DateTime.now(),
      invoiceNumber:
          _invoiceNumberController.text.trim().isNotEmpty
              ? _invoiceNumberController.text.trim()
              : null,
      deliveryOrderNumber:
          _deliveryOrderController.text.trim().isNotEmpty
              ? _deliveryOrderController.text.trim()
              : null,
      vehicleNumber:
          _vehicleNumberController.text.trim().isNotEmpty
              ? _vehicleNumberController.text.trim()
              : null,
      driverName:
          _driverNameController.text.trim().isNotEmpty
              ? _driverNameController.text.trim()
              : null,
      subtotal: _calculateSubtotal(),
      itemDiscount: _calculateItemDiscountTotal(),
      itemTax: _calculateItemTaxTotal(),
      totalDiscount: double.tryParse(_totalDiscountController.text) ?? 0,
      totalTax: double.tryParse(_totalTaxController.text) ?? 0,
      total: _calculateTotal(),
      status: 'completed',
      notes:
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
      receivedBy: widget.existingReceiving?.receivedBy,
      syncStatus: 'pending',
      createdAt: widget.existingReceiving?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      items: receivingItems,
    );

    if (widget.existingReceiving != null) {
      context.read<ReceivingBloc>().add(
        receiving_event.UpdateReceivingEvent(receiving),
      );
    } else {
      context.read<ReceivingBloc>().add(
        receiving_event.CreateReceivingEvent(receiving),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingReceiving != null
              ? 'Edit Penerimaan Barang'
              : 'Proses Penerimaan Barang',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          indicatorColor: AppColors.textWhite,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Informasi'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Barang'),
          ],
        ),
      ),
      body: BlocListener<ReceivingBloc, ReceivingState>(
        listener: (context, state) {
          if (state is ReceivingNumberGenerated) {
            setState(() {
              _receivingNumber = state.receivingNumber;
            });
          } else if (state is ReceivingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ReceivingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [_buildInfoTab(), _buildItemsTab()],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PO Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Purchase Order',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Nomor PO', widget.purchase.purchaseNumber),
                  _buildDetailRow(
                    'Supplier',
                    widget.purchase.supplierName ?? '-',
                  ),
                  _buildDetailRow(
                    'Tanggal PO',
                    DateFormat(
                      'dd MMMM yyyy',
                      'id_ID',
                    ).format(widget.purchase.purchaseDate),
                  ),
                  _buildDetailRow(
                    'Total PO',
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(widget.purchase.totalAmount),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Receiving Details Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Detail Penerimaan',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Invoice Number - REQUIRED
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Faktur *',
                      hintText: 'Nomor faktur dari supplier',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Sesuai dengan nota pengiriman',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor faktur wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Delivery Order Number
                  TextFormField(
                    controller: _deliveryOrderController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Surat Jalan',
                      hintText: 'Nomor surat jalan (opsional)',
                      prefixIcon: const Icon(Icons.local_shipping),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Number
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Kendaraan',
                      hintText: 'Plat nomor kendaraan (opsional)',
                      prefixIcon: const Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),

                  // Driver Name
                  TextFormField(
                    controller: _driverNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Sopir',
                      hintText: 'Nama pengemudi (opsional)',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Catatan Penerimaan',
                      hintText: 'Catatan tambahan (opsional)',
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
          const SizedBox(height: 16),

          // Total Discount & Tax Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Diskon & Pajak Keseluruhan',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalDiscountController,
                          decoration: InputDecoration(
                            labelText: 'Diskon Total (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _totalTaxController,
                          decoration: InputDecoration(
                            labelText: 'Pajak Total (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return Column(
      children: [
        // Header with Add Button
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Daftar Barang (${_receivingItems.length})',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Barang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _receivingItems.length,
            itemBuilder: (context, index) {
              final item = _receivingItems[index];
              return _buildItemCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(_ReceivingItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isAdditionalItem ? AppColors.warning : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.purchaseItem.productName,
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.isAdditionalItem)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ITEM TAMBAHAN',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.isAdditionalItem)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _receivingItems.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const Divider(height: 20),

            // Quantity & Price Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!item.isAdditionalItem)
                        Text(
                          'Qty PO: ${item.purchaseItem.quantityOrdered}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: item.receivedQuantity.toString(),
                        decoration: InputDecoration(
                          labelText: 'Qty Terima *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wajib diisi';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Harus > 0';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final qty = double.tryParse(value);
                          if (qty != null && qty > 0) {
                            setState(() {
                              item.receivedQuantity = qty;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!item.isAdditionalItem)
                        Text(
                          'Harga PO: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.purchaseItem.unitPrice)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: item.receivedPrice.toStringAsFixed(0),
                        decoration: InputDecoration(
                          labelText: 'Harga Terima *',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wajib diisi';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Harus > 0';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          if (price != null && price > 0) {
                            setState(() {
                              item.receivedPrice = price;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Discount & Tax
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: item.discount.toStringAsFixed(0),
                        decoration: InputDecoration(
                          labelText: 'Diskon',
                          prefixText:
                              item.discountType == 'percentage' ? '' : 'Rp ',
                          suffixText:
                              item.discountType == 'percentage' ? '%' : '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            item.discount = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: Text('Rp', style: AppTextStyles.bodySmall),
                              value: 'amount',
                              groupValue: item.discountType,
                              onChanged: (value) {
                                setState(() {
                                  item.discountType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: Text('%', style: AppTextStyles.bodySmall),
                              value: 'percentage',
                              groupValue: item.discountType,
                              onChanged: (value) {
                                setState(() {
                                  item.discountType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: item.tax.toStringAsFixed(0),
                        decoration: InputDecoration(
                          labelText: 'PPN',
                          prefixText: item.taxType == 'percentage' ? '' : 'Rp ',
                          suffixText: item.taxType == 'percentage' ? '%' : '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            item.tax = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: Text('Rp', style: AppTextStyles.bodySmall),
                              value: 'amount',
                              groupValue: item.taxType,
                              onChanged: (value) {
                                setState(() {
                                  item.taxType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: Text('%', style: AppTextStyles.bodySmall),
                              value: 'percentage',
                              groupValue: item.taxType,
                              onChanged: (value) {
                                setState(() {
                                  item.taxType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', _calculateItemSubtotal(item)),
                  if (_calculateItemDiscount(item) > 0)
                    _buildSummaryRow(
                      'Diskon',
                      -_calculateItemDiscount(item),
                      color: AppColors.error,
                    ),
                  if (_calculateItemTax(item) > 0)
                    _buildSummaryRow(
                      'PPN',
                      _calculateItemTax(item),
                      color: AppColors.success,
                    ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    'Total Item',
                    _calculateItemTotal(item),
                    isBold: true,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', _calculateSubtotal()),
                  if (_calculateItemDiscountTotal() > 0)
                    _buildSummaryRow(
                      'Diskon Item',
                      -_calculateItemDiscountTotal(),
                      color: AppColors.error,
                    ),
                  if (_calculateItemTaxTotal() > 0)
                    _buildSummaryRow(
                      'PPN Item',
                      _calculateItemTaxTotal(),
                      color: AppColors.success,
                    ),
                  if ((double.tryParse(_totalDiscountController.text) ?? 0) > 0)
                    _buildSummaryRow(
                      'Diskon Total',
                      -(double.tryParse(_totalDiscountController.text) ?? 0),
                      color: AppColors.error,
                    ),
                  if ((double.tryParse(_totalTaxController.text) ?? 0) > 0)
                    _buildSummaryRow(
                      'PPN Total',
                      double.tryParse(_totalTaxController.text) ?? 0,
                      color: AppColors.success,
                    ),
                  const Divider(height: 16, thickness: 2),
                  _buildSummaryRow(
                    'TOTAL RECEIVING',
                    _calculateTotal(),
                    isBold: true,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Process Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processReceiving,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  widget.existingReceiving != null
                      ? 'Update Penerimaan'
                      : 'Proses Penerimaan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value.abs()),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivingItem {
  final PurchaseItem purchaseItem;
  double receivedQuantity;
  double receivedPrice;
  double discount;
  String discountType;
  double tax;
  String taxType;
  final bool isAdditionalItem;

  _ReceivingItem({
    required this.purchaseItem,
    required this.receivedQuantity,
    required this.receivedPrice,
    required this.discount,
    required this.discountType,
    required this.tax,
    required this.taxType,
    this.isAdditionalItem = false,
  });
}

// Dialog untuk menambah item baru
class _AddItemDialog extends StatefulWidget {
  final Function(Product product, double quantity, double price) onItemAdded;

  const _AddItemDialog({Key? key, required this.onItemAdded}) : super(key: key);

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  Product? _selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      context.read<ProductBloc>().add(const product_event.LoadProducts());
    } else {
      context.read<ProductBloc>().add(product_event.SearchProducts(query));
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _priceController.text = product.costPrice.toStringAsFixed(0);
    });
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = double.parse(_quantityController.text);
    final price = double.parse(_priceController.text);

    widget.onItemAdded(_selectedProduct!, quantity, price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Barang Baru',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Search Product
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Produk',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchProducts('');
                            },
                          )
                          : null,
                ),
                onChanged: _searchProducts,
              ),
              const SizedBox(height: 16),

              // Selected Product Display
              if (_selectedProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProduct!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'sku: ${_selectedProduct!.sku}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedProduct = null;
                            _priceController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Product List
              Text(
                'Pilih Produk:',
                style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductLoaded) {
                      if (state.products.isEmpty) {
                        return const Center(child: Text('Tidak ada produk'));
                      }

                      return ListView.builder(
                        itemCount: state.products.length,
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          final isSelected = _selectedProduct?.id == product.id;

                          return Card(
                            color:
                                isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.surface,
                            child: ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.grey,
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                'sku: ${product.sku} | Stok: ${product.stock}',
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(product.costPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _selectProduct(product),
                            ),
                          );
                        },
                      );
                    }

                    return const Center(child: Text('Tidak ada data'));
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Quantity and Price Input
              if (_selectedProduct != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wajib diisi';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Harus > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Harga Beli *',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wajib diisi';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Harus > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah ke Receiving'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
