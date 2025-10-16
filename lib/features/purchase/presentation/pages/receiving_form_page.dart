import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/receiving.dart';
import '../bloc/receiving_bloc.dart';
import '../bloc/receiving_event.dart' as receiving_event;
import '../bloc/receiving_state.dart';

class ReceivingFormPage extends StatefulWidget {
  final Purchase purchase;

  const ReceivingFormPage({Key? key, required this.purchase}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _initializeItems();

    // Generate receiving number
    context.read<ReceivingBloc>().add(
      const receiving_event.GenerateReceivingNumberEvent(),
    );
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

    // Create receiving items (TIDAK mengubah PO data)
    final receivingItems =
        _receivingItems.map((item) {
          return ReceivingItem(
            id: const Uuid().v4(),
            receivingId: '', // Will be set by receiving
            purchaseItemId: item.purchaseItem.id,
            productId: item.purchaseItem.productId,
            productName: item.purchaseItem.productName,
            poQuantity: item.purchaseItem.quantity, // Keep PO qty as reference
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
            createdAt: DateTime.now(),
          );
        }).toList();

    // Create receiving (TERPISAH dari PO)
    final receiving = Receiving(
      id: const Uuid().v4(),
      receivingNumber: _receivingNumber!,
      purchaseId: widget.purchase.id, // Reference only
      purchaseNumber: widget.purchase.purchaseNumber, // Copy for display
      supplierId: widget.purchase.supplierId,
      supplierName: widget.purchase.supplierName,
      receivingDate: DateTime.now(),
      subtotal: _calculateSubtotal(),
      itemDiscount: _calculateItemDiscountTotal(),
      itemTax: _calculateItemTaxTotal(),
      totalDiscount: _totalDiscount,
      totalTax: _totalTax,
      total: _calculateTotal(),
      status: 'COMPLETED',
      notes: _notes.isNotEmpty ? _notes : null,
      receivedBy: null, // TODO: Add user context
      syncStatus: 'PENDING',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: receivingItems,
    );

    // Dispatch event to create receiving
    context.read<ReceivingBloc>().add(
      receiving_event.CreateReceivingEvent(receiving),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proses Penerimaan Barang'),
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

              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: _receivingItems.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = _receivingItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.purchaseItem.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Qty PO: ${item.purchaseItem.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        initialValue:
                                            item.receivedQuantity.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Qty Diterima*',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                      Text(
                                        'Harga PO: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.purchaseItem.price)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
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
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(_calculateItemTotal(item)),
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
                    );
                  },
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

  _ReceivingItem({
    required this.purchaseItem,
    required this.receivedQuantity,
    required this.receivedPrice,
    required this.discount,
    required this.discountType,
    required this.tax,
    required this.taxType,
  });
}
