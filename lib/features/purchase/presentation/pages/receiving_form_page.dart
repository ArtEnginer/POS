import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../injection_container.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart' as product_event;
import '../../../product/presentation/bloc/product_state.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/receiving.dart';
import '../bloc/receiving_bloc.dart';
import '../bloc/receiving_event.dart' as receiving_event;
import '../bloc/receiving_state.dart';

// Export the new form as the main form
export 'receiving_form_page_new.dart';

class ReceivingFormPage extends StatefulWidget {
  final Purchase purchase;
  final Receiving? existingReceiving; // For edit mode

  const ReceivingFormPage({
    Key? key,
    required this.purchase,
    this.existingReceiving,
  }) : super(key: key);

  @override
  State<ReceivingFormPage> createState() => _ReceivingFormPageState();
}

class _ReceivingFormPageState extends State<ReceivingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final List<_ReceivingItem> _receivingItems = [];
  double _totalDiscount = 0;
  double _totalTax = 0;
  String _notes = '';
  String? _receivingNumber;
  String _invoiceNumber = ''; // Nomor Faktur
  String _deliveryOrderNumber = ''; // Nomor Surat Jalan
  String _vehicleNumber = ''; // Nomor Kendaraan
  String _driverName = ''; // Nama Sopir

  @override
  void initState() {
    super.initState();

    if (widget.existingReceiving != null) {
      // Edit mode: Load from existing receiving
      _initializeFromReceiving();
    } else {
      // New mode: Load from PO
      _initializeItems();
    }

    // Generate or use existing receiving number
    if (widget.existingReceiving != null) {
      _receivingNumber = widget.existingReceiving!.receivingNumber;
      _totalDiscount = widget.existingReceiving!.totalDiscount;
      _totalTax = widget.existingReceiving!.totalTax;
      _notes = widget.existingReceiving!.notes ?? '';
      _invoiceNumber = widget.existingReceiving!.invoiceNumber ?? '';
      _deliveryOrderNumber =
          widget.existingReceiving!.deliveryOrderNumber ?? '';
      _vehicleNumber = widget.existingReceiving!.vehicleNumber ?? '';
      _driverName = widget.existingReceiving!.driverName ?? '';
    } else {
      context.read<ReceivingBloc>().add(
        const receiving_event.GenerateReceivingNumberEvent(),
      );
    }
  }

  void _initializeItems() {
    _receivingItems.clear();
    for (var item in widget.purchase.items) {
      _receivingItems.add(
        _ReceivingItem(
          purchaseItem: item,
          receivedQuantity: item.quantity,
          receivedPrice: item.price,
          discount: 0,
          discountType: 'AMOUNT',
          tax: 0,
          taxType: 'AMOUNT',
          isAdditionalItem: false,
        ),
      );
    }
  }

  void _initializeFromReceiving() {
    _receivingItems.clear();
    final receiving = widget.existingReceiving!;

    for (var receivingItem in receiving.items) {
      // Check if item is additional (not in PO)
      final isAdditional = receivingItem.poQuantity == 0;

      // Find corresponding PurchaseItem or create dummy
      PurchaseItem purchaseItem;
      if (isAdditional) {
        // Create dummy PurchaseItem for additional items
        purchaseItem = PurchaseItem(
          id: receivingItem.purchaseItemId ?? const Uuid().v4(),
          purchaseId: widget.purchase.id,
          productId: receivingItem.productId,
          productName: receivingItem.productName,
          quantity: 0, // Mark as additional
          price: receivingItem.receivedPrice,
          subtotal: 0,
          createdAt: DateTime.now(),
        );
      } else {
        // Find from PO items (manual loop to avoid type issues)
        PurchaseItem? foundItem;
        for (var poItem in widget.purchase.items) {
          if (poItem.id == receivingItem.purchaseItemId) {
            foundItem = poItem;
            break;
          }
        }

        // Use found item or create fallback
        purchaseItem =
            foundItem ??
            PurchaseItem(
              id: receivingItem.purchaseItemId ?? const Uuid().v4(),
              purchaseId: widget.purchase.id,
              productId: receivingItem.productId,
              productName: receivingItem.productName,
              quantity: receivingItem.poQuantity,
              price: receivingItem.poPrice,
              subtotal: 0,
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

  double _calculateItemSubtotal(_ReceivingItem item) {
    return item.receivedQuantity * item.receivedPrice;
  }

  double _calculateItemDiscount(_ReceivingItem item) {
    final subtotal = _calculateItemSubtotal(item);
    if (item.discountType == 'PERCENTAGE') {
      return subtotal * (item.discount / 100);
    }
    return item.discount;
  }

  double _calculateItemTax(_ReceivingItem item) {
    final subtotal = _calculateItemSubtotal(item);
    final afterDiscount = subtotal - _calculateItemDiscount(item);
    if (item.taxType == 'PERCENTAGE') {
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
    return subtotal - itemDiscount + itemTax - _totalDiscount + _totalTax;
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
                  // Create a dummy PurchaseItem for the new product
                  final dummyPurchaseItem = PurchaseItem(
                    id: const Uuid().v4(),
                    purchaseId: widget.purchase.id,
                    productId: product.id,
                    productName: product.name,
                    quantity: 0, // 0 karena tidak ada di PO
                    price: price,
                    subtotal: 0,
                    createdAt: DateTime.now(),
                  );

                  _receivingItems.add(
                    _ReceivingItem(
                      purchaseItem: dummyPurchaseItem,
                      receivedQuantity: quantity,
                      receivedPrice: price,
                      discount: 0,
                      discountType: 'AMOUNT',
                      tax: 0,
                      taxType: 'AMOUNT',
                      isAdditionalItem: true,
                    ),
                  );
                });
              },
            ),
          ),
    );
  }

  Future<void> _showEditItemDialog(_ReceivingItem item, int index) async {
    final quantityController = TextEditingController(
      text: item.receivedQuantity.toString(),
    );
    final priceController = TextEditingController(
      text: item.receivedPrice.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Edit ${item.purchaseItem.productName}'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.purchaseItem.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (item.isAdditionalItem)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ITEM TAMBAHAN',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity input
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity*',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  const SizedBox(height: 12),

                  // Price input
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga*',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      item.receivedQuantity = int.parse(
                        quantityController.text,
                      );
                      item.receivedPrice = double.parse(priceController.text);
                    });
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    quantityController.dispose();
    priceController.dispose();
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

    // Use existing ID for edit mode, generate new for create mode
    final receivingId = widget.existingReceiving?.id ?? const Uuid().v4();

    // Create receiving items with proper receivingId
    final receivingItems =
        _receivingItems.map((item) {
          return ReceivingItem(
            id: const Uuid().v4(),
            receivingId: receivingId, // ✅ Set proper receiving ID
            purchaseItemId: item.purchaseItem.id,
            productId: item.purchaseItem.productId,
            productName: item.purchaseItem.productName,
            poQuantity:
                item
                    .purchaseItem
                    .quantity, // Keep PO qty as reference (0 for additional items)
            poPrice: item.purchaseItem.price, // Keep PO price as reference
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

    // Create receiving (TERPISAH dari PO)
    final receiving = Receiving(
      id: receivingId, // ✅ Use same ID
      receivingNumber: _receivingNumber!,
      purchaseId: widget.purchase.id, // Reference only
      purchaseNumber: widget.purchase.purchaseNumber, // Copy for display
      supplierId: widget.purchase.supplierId,
      supplierName: widget.purchase.supplierName,
      receivingDate: widget.existingReceiving?.receivingDate ?? DateTime.now(),
      invoiceNumber: _invoiceNumber.isNotEmpty ? _invoiceNumber : null,
      deliveryOrderNumber:
          _deliveryOrderNumber.isNotEmpty ? _deliveryOrderNumber : null,
      vehicleNumber: _vehicleNumber.isNotEmpty ? _vehicleNumber : null,
      driverName: _driverName.isNotEmpty ? _driverName : null,
      subtotal: _calculateSubtotal(),
      itemDiscount: _calculateItemDiscountTotal(),
      itemTax: _calculateItemTaxTotal(),
      totalDiscount: _totalDiscount,
      totalTax: _totalTax,
      total: _calculateTotal(),
      status: 'COMPLETED',
      notes: _notes.isNotEmpty ? _notes : null,
      receivedBy:
          widget.existingReceiving?.receivedBy, // Keep original receiver
      syncStatus: 'PENDING',
      createdAt: widget.existingReceiving?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      items: receivingItems,
    );

    // Dispatch event to create or update receiving
    if (widget.existingReceiving != null) {
      // Edit mode: Update existing
      context.read<ReceivingBloc>().add(
        receiving_event.UpdateReceivingEvent(receiving),
      );
    } else {
      // Create mode: Create new
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Informasi'),
                      content: const Text(
                        'Halaman ini untuk memproses penerimaan barang.\n\n'
                        'Anda dapat:\n'
                        '• Mengubah quantity yang diterima\n'
                        '• Mengubah harga\n'
                        '• Menambah diskon atau PPN\n'
                        '• Menambahkan catatan\n\n'
                        'Setelah proses, stok akan otomatis terupdate.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<ReceivingBloc, ReceivingState>(
        listener: (context, state) {
          if (state is ReceivingNumberGenerated) {
            setState(() {
              _receivingNumber = state.number;
            });
          } else if (state is ReceivingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ReceivingError) {
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
          child: Column(
            children: [
              // Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PO: ${widget.purchase.purchaseNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supplier: ${widget.purchase.supplierName ?? "-"}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      'Tanggal PO: ${DateFormat('dd/MM/yyyy').format(widget.purchase.purchaseDate)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              // Detail Penerimaan Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detail Penerimaan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _invoiceNumber,
                            decoration: InputDecoration(
                              labelText: 'Nomor Faktur*',
                              hintText: 'Nomor faktur dari supplier',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: const Icon(Icons.numbers, size: 20),
                              helperText: 'Sesuai nota pengiriman',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor faktur wajib diisi';
                              }
                              return null;
                            },
                            onSaved:
                                (value) => _invoiceNumber = value?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _deliveryOrderNumber,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Surat Jalan',
                              hintText: 'Nomor surat jalan',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.local_shipping, size: 20),
                            ),
                            onSaved:
                                (value) =>
                                    _deliveryOrderNumber = value?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _vehicleNumber,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Kendaraan',
                              hintText: 'Plat nomor kendaraan',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.directions_car, size: 20),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onSaved:
                                (value) => _vehicleNumber = value?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _driverName,
                            decoration: const InputDecoration(
                              labelText: 'Nama Sopir',
                              hintText: 'Nama pengemudi',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.person, size: 20),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onSaved:
                                (value) => _driverName = value?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items List with Add Button
              Expanded(
                child: Column(
                  children: [
                    // Add Item Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Tambah Barang Baru (Tidak Ada di PO)',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.blue.shade400),
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),

                    // Items List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _receivingItems.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final item = _receivingItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.purchaseItem.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (item.isAdditionalItem)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            'TAMBAHAN',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (item.isAdditionalItem) ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            _showEditItemDialog(item, index);
                                          },
                                          tooltip: 'Edit Item',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _receivingItems.removeAt(index);
                                            });
                                          },
                                          tooltip: 'Hapus Item',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!item.isAdditionalItem)
                                              Text(
                                                'Qty PO: ${item.purchaseItem.quantity}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            if (item.isAdditionalItem)
                                              Text(
                                                'Item Tambahan (Tidak di PO)',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              initialValue:
                                                  item.receivedQuantity
                                                      .toString(),
                                              decoration: const InputDecoration(
                                                labelText: 'Qty Diterima*',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Wajib diisi';
                                                }
                                                final qty = int.tryParse(value);
                                                if (qty == null || qty <= 0) {
                                                  return 'Harus > 0';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                final qty = int.tryParse(value);
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!item.isAdditionalItem)
                                              Text(
                                                'Harga PO: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.purchaseItem.price)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            if (item.isAdditionalItem)
                                              Text(
                                                'Harga Bebas',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              initialValue: item.receivedPrice
                                                  .toStringAsFixed(0),
                                              decoration: const InputDecoration(
                                                labelText: 'Harga Terima*',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                prefixText: 'Rp ',
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Wajib diisi';
                                                }
                                                final price = double.tryParse(
                                                  value,
                                                );
                                                if (price == null ||
                                                    price <= 0) {
                                                  return 'Harus > 0';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                final price = double.tryParse(
                                                  value,
                                                );
                                                if (price != null &&
                                                    price > 0) {
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
                                  const SizedBox(height: 12),

                                  // Discount & Tax per item
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextFormField(
                                              initialValue: item.discount
                                                  .toStringAsFixed(0),
                                              decoration: InputDecoration(
                                                labelText: 'Diskon',
                                                border:
                                                    const OutlineInputBorder(),
                                                isDense: true,
                                                prefixText:
                                                    item.discountType ==
                                                            'PERCENTAGE'
                                                        ? ''
                                                        : 'Rp ',
                                                suffixText:
                                                    item.discountType ==
                                                            'PERCENTAGE'
                                                        ? '%'
                                                        : '',
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  item.discount =
                                                      double.tryParse(value) ??
                                                      0;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: RadioListTile<String>(
                                                    dense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    title: const Text(
                                                      'Rp',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    value: 'AMOUNT',
                                                    groupValue:
                                                        item.discountType,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        item.discountType =
                                                            value!;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Expanded(
                                                  child: RadioListTile<String>(
                                                    dense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    title: const Text(
                                                      '%',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    value: 'PERCENTAGE',
                                                    groupValue:
                                                        item.discountType,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        item.discountType =
                                                            value!;
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextFormField(
                                              initialValue: item.tax
                                                  .toStringAsFixed(0),
                                              decoration: InputDecoration(
                                                labelText: 'PPN',
                                                border:
                                                    const OutlineInputBorder(),
                                                isDense: true,
                                                prefixText:
                                                    item.taxType == 'PERCENTAGE'
                                                        ? ''
                                                        : 'Rp ',
                                                suffixText:
                                                    item.taxType == 'PERCENTAGE'
                                                        ? '%'
                                                        : '',
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  item.tax =
                                                      double.tryParse(value) ??
                                                      0;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: RadioListTile<String>(
                                                    dense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    title: const Text(
                                                      'Rp',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    value: 'AMOUNT',
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
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    title: const Text(
                                                      '%',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    value: 'PERCENTAGE',
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
                                  const SizedBox(height: 12),

                                  // Item Calculation Summary
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Subtotal:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(
                                                _calculateItemSubtotal(item),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_calculateItemDiscount(item) >
                                            0) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Diskon:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                '- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_calculateItemDiscount(item))}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (_calculateItemTax(item) > 0) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'PPN:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                '+ ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_calculateItemTax(item))}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Divider(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(
                                                _calculateItemTotal(item),
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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

              // Additional Info & Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Total Discount
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _totalDiscount.toStringAsFixed(0),
                            decoration: const InputDecoration(
                              labelText: 'Diskon Total',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixText: 'Rp ',
                              helperText: 'Diskon untuk total receiving',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _totalDiscount = double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _totalTax.toStringAsFixed(0),
                            decoration: const InputDecoration(
                              labelText: 'PPN Total',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixText: 'Rp ',
                              helperText: 'PPN untuk total receiving',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _totalTax = double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextFormField(
                      initialValue: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Penerimaan',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      onSaved: (value) => _notes = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Total Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(_calculateSubtotal()),
                              ),
                            ],
                          ),
                          if (_calculateItemDiscountTotal() > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Diskon Item:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_calculateItemDiscountTotal())}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_calculateItemTaxTotal() > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PPN Item:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '+ ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_calculateItemTaxTotal())}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_totalDiscount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Diskon Total:'),
                                Text(
                                  '- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalDiscount)}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                          if (_totalTax > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('PPN Total:'),
                                Text(
                                  '+ ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalTax)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(_calculateTotal()),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
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
                        label: const Text('Proses Penerimaan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceivingItem {
  final PurchaseItem purchaseItem;
  int receivedQuantity;
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
  final Function(Product product, int quantity, double price) onItemAdded;

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

    final quantity = int.parse(_quantityController.text);
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
                  const Text(
                    'Tambah Barang Baru',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  border: const OutlineInputBorder(),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue.shade700),
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
              const Text(
                'Pilih Produk:',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                                isSelected ? Colors.blue.shade50 : Colors.white,
                            child: ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color:
                                    isSelected
                                        ? Colors.blue.shade700
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
                        decoration: const InputDecoration(
                          labelText: 'Quantity*',
                          border: OutlineInputBorder(),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli*',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: 'Rp ',
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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
