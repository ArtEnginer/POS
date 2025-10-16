import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase_return.dart';
import '../../domain/entities/receiving.dart';
import '../bloc/purchase_return_bloc.dart';
import '../bloc/purchase_return_event.dart';
import '../bloc/purchase_return_state.dart';
import '../bloc/receiving_bloc.dart';
import '../bloc/receiving_event.dart';
import '../bloc/receiving_state.dart';

class PurchaseReturnFormPage extends StatefulWidget {
  final String receivingId;

  const PurchaseReturnFormPage({Key? key, required this.receivingId})
    : super(key: key);

  @override
  State<PurchaseReturnFormPage> createState() => _PurchaseReturnFormPageState();
}

class _PurchaseReturnFormPageState extends State<PurchaseReturnFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _processedByController = TextEditingController();

  DateTime _returnDate = DateTime.now();
  String _returnNumber = '';
  Receiving? _receiving;
  final Map<String, int> _returnQuantities = {};
  final Map<String, String> _itemReasons = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _processedByController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load receiving detail
    context.read<ReceivingBloc>().add(LoadReceivingById(widget.receivingId));

    // Generate return number
    context.read<PurchaseReturnBloc>().add(const GenerateReturnNumberEvent());
  }

  void _calculateTotals() {
    if (_receiving == null) return;

    // Recalculate totals when quantities change
    // This is called to trigger UI update
    setState(() {});
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _savePurchaseReturn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_receiving == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data receiving tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if at least one item is selected
    final hasSelectedItems = _returnQuantities.values.any((qty) => qty > 0);

    if (!hasSelectedItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 item untuk di-return'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Generate return ID first
    final returnId = const Uuid().v4();

    // Build return items with proper returnId
    final returnItems = <PurchaseReturnItem>[];
    double subtotal = 0;
    double itemDiscount = 0;
    double itemTax = 0;

    for (var item in _receiving!.items) {
      final returnQty = _returnQuantities[item.id] ?? 0;
      if (returnQty > 0) {
        final proportion = returnQty / item.receivedQuantity;
        final itemSubtotal = returnQty * item.receivedPrice;
        final itemDiscountAmount = item.discount * proportion;
        final itemTaxAmount = item.tax * proportion;
        final itemTotal = itemSubtotal - itemDiscountAmount + itemTaxAmount;

        returnItems.add(
          PurchaseReturnItem(
            id: const Uuid().v4(),
            returnId: returnId, // ✅ Use same returnId for all items
            receivingItemId: item.id,
            productId: item.productId,
            productName: item.productName,
            receivedQuantity: item.receivedQuantity,
            returnQuantity: returnQty,
            price: item.receivedPrice,
            discount: itemDiscountAmount,
            discountType: item.discountType,
            tax: itemTaxAmount,
            taxType: item.taxType,
            subtotal: itemSubtotal,
            total: itemTotal,
            reason: _itemReasons[item.id],
            createdAt: DateTime.now(),
          ),
        );

        subtotal += itemSubtotal;
        itemDiscount += itemDiscountAmount;
        itemTax += itemTaxAmount;
      }
    }

    // Calculate proportional total discount and tax
    final totalItemsValue = _receiving!.items.fold<double>(
      0,
      (sum, item) => sum + (item.receivedQuantity * item.receivedPrice),
    );
    final returnedItemsValue = subtotal;
    final proportion = returnedItemsValue / totalItemsValue;

    final totalDiscount = _receiving!.totalDiscount * proportion;
    final totalTax = _receiving!.totalTax * proportion;

    final total = subtotal - itemDiscount - totalDiscount + itemTax + totalTax;

    final purchaseReturn = PurchaseReturn(
      id: returnId, // ✅ Use same returnId
      returnNumber: _returnNumber,
      receivingId: _receiving!.id,
      receivingNumber: _receiving!.receivingNumber,
      purchaseId: _receiving!.purchaseId,
      purchaseNumber: _receiving!.purchaseNumber,
      supplierId: _receiving!.supplierId,
      supplierName: _receiving!.supplierName,
      returnDate: _returnDate,
      subtotal: subtotal,
      itemDiscount: itemDiscount,
      itemTax: itemTax,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      total: total,
      status: 'COMPLETED',
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
      processedBy: _processedByController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: returnItems, // ✅ Use items as-is (no need to copyWith)
    );

    context.read<PurchaseReturnBloc>().add(
      CreatePurchaseReturnEvent(purchaseReturn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Return Pembelian'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ReceivingBloc, ReceivingState>(
            listener: (context, state) {
              if (state is ReceivingDetailLoaded) {
                debugPrint(
                  'Purchase Return Form - Receiving loaded: ${state.receiving.receivingNumber}',
                );
                debugPrint(
                  'Purchase Return Form - Items count: ${state.receiving.items.length}',
                );
                for (var item in state.receiving.items) {
                  debugPrint(
                    '  - ${item.productName}: Qty ${item.receivedQuantity}',
                  );
                }

                setState(() {
                  _receiving = state.receiving;
                  // Initialize return quantities to 0
                  for (var item in _receiving!.items) {
                    _returnQuantities[item.id] = 0;
                  }
                });
              } else if (state is ReceivingError) {
                debugPrint('Purchase Return Form - Error: ${state.message}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<PurchaseReturnBloc, PurchaseReturnState>(
            listener: (context, state) {
              if (state is ReturnNumberGenerated) {
                setState(() {
                  _returnNumber = state.number;
                });
              } else if (state is PurchaseReturnOperationSuccess) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is PurchaseReturnError) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ReceivingBloc, ReceivingState>(
          builder: (context, state) {
            debugPrint('Purchase Return Form - BlocBuilder state: $state');
            debugPrint(
              'Purchase Return Form - _receiving is null: ${_receiving == null}',
            );
            if (_receiving != null) {
              debugPrint(
                'Purchase Return Form - _receiving items: ${_receiving!.items.length}',
              );
            }

            if (state is ReceivingLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data receiving...'),
                  ],
                ),
              );
            }

            if (state is ReceivingError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            if (_receiving == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text('Data receiving tidak ditemukan'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              );
            }

            if (_receiving!.items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('Tidak ada item dalam receiving ini'),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receiving Info Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Receiving',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            _buildInfoRow(
                              'No. Receiving',
                              _receiving!.receivingNumber,
                            ),
                            _buildInfoRow('No. PO', _receiving!.purchaseNumber),
                            _buildInfoRow(
                              'Supplier',
                              _receiving!.supplierName ?? 'N/A',
                            ),
                            _buildInfoRow(
                              'Tanggal Receiving',
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_receiving!.receivingDate),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Return Info
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Return',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            _buildInfoRow('No. Return', _returnNumber),
                            const SizedBox(height: 12),

                            // Return Date
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Return',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_returnDate),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Reason
                            TextFormField(
                              controller: _reasonController,
                              decoration: const InputDecoration(
                                labelText: 'Alasan Return *',
                                hintText: 'Contoh: Barang rusak, salah kirim',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Alasan return harus diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Processed By
                            TextFormField(
                              controller: _processedByController,
                              decoration: const InputDecoration(
                                labelText: 'Diproses Oleh',
                                hintText: 'Nama petugas',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Catatan',
                                hintText: 'Catatan tambahan (opsional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items to Return
                    Card(
                      elevation: 2,
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pilih Item untuk Return',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total ${_receiving!.items.length} item tersedia. Masukkan jumlah return untuk setiap produk.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show items count for debugging
                    if (_receiving!.items.isNotEmpty)
                      ...(_receiving!.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with number
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      radius: 16,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.receivedPrice)}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Info row
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Qty Diterima',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.receivedQuantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Harga',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0,
                                            ).format(item.receivedPrice),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Return Quantity Input
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Return',
                                    hintText: '0',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(
                                      Icons.assignment_return,
                                    ),
                                    suffixText: 'Max: ${item.receivedQuantity}',
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue:
                                      _returnQuantities[item.id]?.toString() ??
                                      '0',
                                  onChanged: (value) {
                                    final qty = int.tryParse(value) ?? 0;
                                    if (qty >= 0 &&
                                        qty <= item.receivedQuantity) {
                                      setState(() {
                                        _returnQuantities[item.id] = qty;
                                      });
                                      _calculateTotals();
                                    }
                                  },
                                  validator: (value) {
                                    final qty = int.tryParse(value ?? '0') ?? 0;
                                    if (qty < 0) {
                                      return 'Tidak boleh negatif';
                                    }
                                    if (qty > item.receivedQuantity) {
                                      return 'Melebihi qty diterima';
                                    }
                                    return null;
                                  },
                                ),

                                // Item reason (show when qty > 0)
                                if ((_returnQuantities[item.id] ?? 0) > 0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Return: ${_returnQuantities[item.id]} item',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Alasan Return Item Ini',
                                            hintText:
                                                'Contoh: Barang rusak, cacat produksi',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          maxLines: 2,
                                          onChanged: (value) {
                                            _itemReasons[item.id] = value;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList()),

                    const SizedBox(height: 24),

                    // Summary Card
                    Card(
                      elevation: 3,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Return',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Item yang Di-return:'),
                                Text(
                                  '${_returnQuantities.values.where((qty) => qty > 0).length} item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Qty Return:'),
                                Text(
                                  '${_returnQuantities.values.fold<int>(0, (sum, qty) => sum + qty)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Batal'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _savePurchaseReturn,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: Text(
                              _isLoading ? 'Menyimpan...' : 'Simpan Return',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
